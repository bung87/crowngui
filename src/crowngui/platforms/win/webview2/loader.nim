import winim
import com
import std/[os, strscans]

# {.passL:"/link /ASSEMBLYDEBUG /DEBUG"}

type PACKAGE_VERSION {.pure.} = object
  Version:UINT64
  Revision: USHORT
  Build: USHORT
  Minor: USHORT
  Major: USHORT

# https://docs.microsoft.com/en-us/windows/win32/api/appmodel/ns-appmodel-package_id
type PACKAGE_ID {.pure.} = object
  reserved: UINT32
  processorArchitecture: UINT32
  version: PACKAGE_VERSION
  name: LPWSTR
  publisher: LPWSTR
  resourceId: LPWSTR
  publisherId: LPWSTR

# https://docs.microsoft.com/en-us/windows/win32/api/appmodel/ns-appmodel-package_info
type PACKAGE_INFO {.pure.} = object
  reserved: UINT32
  flags: UINT32
  path: LPWSTR
  packageFullName: LPWSTR
  packageFamilyName: LPWSTR
  packageId: PACKAGE_ID

type GetCurrentPackageInfoProc = proc(flags: UINT32, bufferLength: ptr UINT32,
    buffer: ptr BYTE, count: ptr UINT32): ULONG {.gcsafe, stdcall.}

type WebView2ReleaseChannelPreference = enum
  kStable,
  kCanary

type WebView2RunTimeType = enum
  kInstalled = 0x0,
  kRedistributable

const kNumChannels = 5
const kChannelName = [
  "",
  "beta",
  "dev",
  "canary",
  "internal"
]
const kChannelUuid = [
  "{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}",
  "{2CD8A007-E189-409D-A2C8-9AF4EF3C72AA}",
  "{0D50BFEC-CD6A-4F9A-964C-C7416E3ACB10}",
  "{65C35B14-6C1D-4122-AC46-7148CC9D6497}",
  "{BE59E8FD-089A-411B-A3B0-051D9E417818}"
]

const kChannelPackageFamilyName = [
  "Microsoft.WebView2Runtime.Stable_8wekyb3d8bbwe",
  "Microsoft.WebView2Runtime.Beta_8wekyb3d8bbwe",
  "Microsoft.WebView2Runtime.Dev_8wekyb3d8bbwe",
  "Microsoft.WebView2Runtime.Canary_8wekyb3d8bbwe",
  "Microsoft.WebView2Runtime.Internal_8wekyb3d8bbwe"
]
const kInstallKeyPath =
  "Software\\Microsoft\\EdgeUpdate\\ClientState\\"

const kRedistOverrideKey =
  "Software\\Policies\\Microsoft\\Edge\\WebView2\\"

const kEmbeddedOverrideKey =
  "Software\\Policies\\Microsoft\\EmbeddedBrowserWebView\\LoaderOverride\\"

const kMinimumCompatibleVersion = [86'i32, 0, 616, 0]

when defined(amd64):
  const kEmbeddedWebViewPath = "EBWebView\\x64\\EmbeddedBrowserWebView.dll"
elif defined(i386):
  const kEmbeddedWebViewPath = "EBWebView\\x86\\EmbeddedBrowserWebView.dll"
elif defined(arm64):
  const kEmbeddedWebViewPath = "EBWebView\\arm64\\EmbeddedBrowserWebView.dll"

proc FindClientDllInFolder(folder: var string): bool =
  folder.add "\\"
  folder.add kEmbeddedWebViewPath
  return GetFileAttributes(folder) != INVALID_FILE_ATTRIBUTES

proc GetInstallKeyPathForChannel(channel: DWORD): string =
  let guid = kChannelUuid[channel]
  result = kInstallKeyPath & guid

proc CheckVersionAndFindClientDllInFolder(version: array[4, int];
    path: var string): bool =
  for component in 0..<4:
    if version[component] < kMinimumCompatibleVersion[component]:
      return false
    if version[component] > kMinimumCompatibleVersion[component]:
      break
  return FindClientDllInFolder(path)

proc FindInstalledClientDllForChannel(lpSubKey: string; system: bool;
    clientPath: var string; version: var array[4, int]): bool =
  var phkResult: HKEY
  var cbPath: int32 = MAX_PATH
  var buffer = T(when not winimAnsi: MAX_PATH div sizeof(Utf16Char) - 1 else: MAX_PATH - 1)

  if RegOpenKeyExW(if system: HKEY_LOCAL_MACHINE else: HKEY_CURRENT_USER, lpSubKey,
                      0, KEY_READ or KEY_WOW64_32KEY, &phkResult) != ERROR_SUCCESS:
    return false

  let r = RegQueryValueEx(phkResult, L"EBWebView", nil, nil, cast[LPBYTE](
      &buffer), &cbPath)

  RegCloseKey(phkResult)
  if r != ERROR_SUCCESS:
    return false
  buffer.setLen(cbPath div sizeof(Utf16Char) - 1)
  clientPath = $buffer

  let versionPart = lastPathPart clientPath
  if not scanf(versionPart, "$i.$i.$i.$i", version[0], version[1], version[2],
      version[3]):
    return false
  return CheckVersionAndFindClientDllInFolder(version, clientPath)

type CreateWebViewEnvironmentWithOptionsInternal = proc (unknown: bool;
    runtimeType: WebView2RunTimeType; userDataDir: PCWSTR;
    environmentOptions: ptr IUnknown;
    envCompletedHandler: ptr ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler): HRESULT{.stdcall.}
type DllCanUnloadNow = proc (): HRESULT {.stdcall.}

proc CreateWebViewEnvironmentWithClientDll(lpLibFileName: string; unknown: bool;
    runtimeType: WebView2RunTimeType; userDataDir: string;
    environmentOptions: ptr IUnknown;
    envCompletedHandler: ptr ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler): HRESULT =
  doAssert environmentOptions != nil
  doAssert envCompletedHandler != nil
  let clientDll = LoadLibrary(lpLibFileName)
  if clientDll == 0:
    return HRESULT_FROM_WIN32(GetLastError())
  let createProcAddr = GetProcAddress(clientDll, "CreateWebViewEnvironmentWithOptionsInternal")
  if createProcAddr == nil:
    return HRESULT_FROM_WIN32(GetLastError())
  let canUnloadProc = GetProcAddress(clientDll, "DllCanUnloadNow")
  if canUnloadProc == nil:
    return HRESULT_FROM_WIN32(GetLastError())

  let createWebViewEnvironmentWithOptionsInternalProc = cast[CreateWebViewEnvironmentWithOptionsInternal](createProcAddr)
  var wStr = +$(userDataDir)
  let hr = createWebViewEnvironmentWithOptionsInternalProc(true, runtimeType, wStr, environmentOptions, envCompletedHandler)
  if canUnloadProc != nil and SUCCEEDED(cast[DllCanUnloadNow](canUnloadProc)()):
    FreeLibrary(clientDll)
  return hr

proc FindInstalledClientDll(clientPath: var string;
    preference: WebView2ReleaseChannelPreference;
    channelStr: var string): int =
  let getCurrentPackageInfoProc = cast[GetCurrentPackageInfoProc](GetProcAddress(
          GetModuleHandleW(L"kernelbase.dll"), "GetCurrentPackageInfo"))
  var channel: int = 0
  var lpSubKey: string
  var version: array[4, int]
  for i in 0 ..< kNumChannels:
    channel = if preference == WebView2ReleaseChannelPreference.kCanary: 4 - i else: i
    lpSubKey = GetInstallKeyPathForChannel(channel.DWORD)
    if FindInstalledClientDllForChannel(lpSubKey, false, clientPath, version):
        break
    if FindInstalledClientDllForChannel(lpSubKey, true, clientPath, version):
        break
    if getCurrentPackageInfoProc == nil:
      continue
    var cPackages:UINT32
    var len:UINT32
    # APPMODEL_ERROR_NO_PACKAGE
    let r = getCurrentPackageInfoProc(1, len.addr, nil, &cPackages)
    if r != ERROR_INSUFFICIENT_BUFFER:
      continue

    if cPackages == 0:
      continue
    var packages = cast[ptr UncheckedArray[PACKAGE_INFO]](cPackages.addr)
    var package: PACKAGE_INFO
    for j in 0 ..< cPackages:
      if packages[j].packageFamilyName == kchannelPackageFamilyName[channel] == 0:
        package = packages[j]
        break
    if package == nil:
      continue
    version[0] = package.packageId.version.Major.int
    version[1] = package.packageId.version.Minor.int
    version[2] = package.packageId.version.Build.int
    version[3] = package.packageId.version.Revision.int
    clientPath = $package.path

    doAssert CheckVersionAndFindClientDllInFolder(version, clientPath) == true
  channelStr = kChannelName[channel]
  return 0

proc CreateCoreWebView2EnvironmentWithOptions*(browserExecutableFolder: string;
    userDataFolder: string;
    environmentOptions: ptr ICoreWebView2EnvironmentOptions;
    environmentCreatedHandler: ptr ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler): HRESULT =
  var clientPath: string
  var channelStr: string
  if browserExecutableFolder == "":
    doAssert FindInstalledClientDll(clientPath,
        WebView2ReleaseChannelPreference.kCanary, channelStr) == 0
  else:
    clientPath = $browserExecutableFolder
  return CreateWebViewEnvironmentWithClientDll(clientPath, true,
      WebView2RunTimeType.kInstalled, userDataFolder, cast[ptr IUnknown](
      environmentOptions), environmentCreatedHandler)

type GetCurrentApplicationUserModelIdProc = proc(
    applicationUserModelIdLength: ptr UINT32,
    applicationUserModelId: PWSTR) {.stdcall.}

proc GetAppUserModelIdForCurrentProcess(idOut: var PWSTR): int =
  let getCurrentApplicationUserModelIdAddr = GetProcAddress(GetModuleHandleW(L"Kernel32.dll"),
                           "GetCurrentApplicationUserModelId")
  # SetCurrentProcessExplicitAppUserModelID
  # if getCurrentApplicationUserModelIdAddr != nil:
  #   if (!getCurrentApplicationUserModelIdAddr()):
  #     return E_UNEXPECTED
  #   return S_OK
  var appId: PWSTR
  let hr = GetCurrentProcessExplicitAppUserModelID(&appId)
  if (FAILED(hr)):
    CoTaskMemFree(appId)
    return hr
  idOut = appId

  CoTaskMemFree(appId);
  return S_OK

proc DoesPolicyExistInRoot(hKey: HKEY): bool =
  var phkResult: HKEY
  var r = RegOpenKeyExW(hKey, L"Software\\Policies\\Microsoft\\Edge\\WebView2\\", 0,
                      0x20019u.DWORD, &phkResult)
  RegCloseKey(phkResult)
  return r == ERROR_SUCCESS

proc ReadOverrideFromRegistry(key: PWSTR; root: HKEY; subKey: PWSTR;
    redist: bool; ): bool = discard
  # "Software\\Policies\\Microsoft\\EmbeddedBrowserWebView\\LoaderOverride\\browserExecutableFolder" exeName | aumId
proc UpdateParamsWithRegOverrides(key: PWSTR; root: HKEY;
    shouldCheckPolicyOverride: bool; redist: bool; ): bool =
  let exePath = getAppFilename()
  let exeName = lastPathPart(exePath)
  var aumId: PWSTR
  discard GetAppUserModelIdForCurrentProcess(aumId)
  if shouldCheckPolicyOverride and redist:
    if ReadOverrideFromRegistry(key, root, aumId, redist):
        return true
    if ReadOverrideFromRegistry(key, root, exeName, redist):
        return true
    if ReadOverrideFromRegistry(key, root, "*", redist):
        return true
    return false
  if ReadOverrideFromRegistry(aumId, root, key, redist):
    return true
  if ReadOverrideFromRegistry(exeName, root, key, redist):
    return true
  if ReadOverrideFromRegistry("*", root, key, redist):
    return true
  return false

proc UpdateParamsWithOverrides(env: PWSTR; key: PWSTR; outBuf: PWSTR;
    checkOverride: bool): bool =
  # env > registry > options
  var shouldCheckPolicyOverride: bool
  if checkOverride:
    shouldCheckPolicyOverride = true

  if getEnv($env).len > 0:
    return true

  if not checkOverride:
    return false

  shouldCheckPolicyOverride = DoesPolicyExistInRoot(HKEY_CURRENT_USER) or
                                 DoesPolicyExistInRoot(HKEY_LOCAL_MACHINE)

  return UpdateParamsWithRegOverrides(key, HKEY_LOCAL_MACHINE,
      shouldCheckPolicyOverride, true) or
           UpdateParamsWithRegOverrides(key, HKEY_CURRENT_USER,
                   shouldCheckPolicyOverride, true) or
           UpdateParamsWithRegOverrides(key, HKEY_LOCAL_MACHINE,
                   shouldCheckPolicyOverride, false) or
           UpdateParamsWithRegOverrides(key, HKEY_CURRENT_USER,
                   shouldCheckPolicyOverride, false)

proc UpdateWebViewEnvironmentParamsWithOverrideValues(
  browserExecutableFolder: PWSTR; userDataDir: PWSTR;
    releaseChannelPreference: PWSTR) =
  discard UpdateParamsWithOverrides("WEBVIEW2_BROWSER_EXECUTABLE_FOLDER",
      "browserExecutableFolder", nil, true)
  discard UpdateParamsWithOverrides("WEBVIEW2_USER_DATA_FOLDER",
      "userDataFolder", userDataDir, false)
  discard UpdateParamsWithOverrides("WEBVIEW2_RELEASE_CHANNEL_PREFERENCE",
      "releaseChannelPreference", releaseChannelPreference, false);

when isMainModule:
  var clientPath: string
  var channelStr: string
  echo FindInstalledClientDll(clientPath,
      WebView2ReleaseChannelPreference.kCanary, channelStr)
  let clientDll = LoadLibrary(clientPath)
  echo "clientPath:", repr cast[seq[uint8]](clientPath)
  echo "channelStr:", repr channelStr
  # SetCurrentProcessExplicitAppUserModelID("webview2")
  var appId: PWSTR
  echo GetAppUserModelIdForCurrentProcess(appId)
  echo appId
