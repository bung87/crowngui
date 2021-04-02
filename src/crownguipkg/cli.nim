import cligen, os
import json
import plists
import tables
import osproc
import sequtils
import zippy/ziparchives
import strformat
import icon
import icon/icns
import icon/ico
include packageinfo
import imageman/images
import imageman/colors
import imageman/resize
import zopflipng
import rcedit, options
include cocoaappinfo
import oids

type
  MyImage = ref Image[ColorRGBAU]

const DEBUG_OPTS = " --verbose --debug "
const RELEASE_OPTS = " -d:release -d:noSignalHandler --exceptions:quirky"

proc getPkgInfo(): PackageInfo =
  # let r = execProcess(fmt"nimble",args=["dump", "--json", getCurrentDir()],options={poUsePath})
  let r = execCmdEx("nimble dump --json -l --silent " & getCurrentDir())
  let jsonNode = parseJson(r.output)
  result = to(jsonNode, PackageInfo)

proc zipBundle(dir: string): string =
  let p = getTempDir() / "zipBundle.zip"
  createZipArchive(dir, p)
  return p

proc handleBundle(wwwroot: string): string =
  var zip: string
  if len(wwwroot) > 0:
    let path = absolutePath wwwroot
    if not dirExists(path):
      raise newException(OSError, fmt"dir {path} not existed.")
    debugEcho path
    zip = zipBundle(path)
    debugEcho zip
  return zip

proc baseCmd(base: seq[string], wwwroot: string, release: bool, flags: seq[string]): seq[string] =
  result = base
  let zip = handleBundle(wwwroot)
  if len(wwwroot) > 0:
    result.add fmt" -d:bundle='{zip}'"
  result.add "--threads:on"
  result.add flags
  let opts = if not release: DEBUG_OPTS else: RELEASE_OPTS
  result.add opts

proc genImages[T](png: zopflipng.PNGResult[T], sizes: seq[int]): seq[ImageInfo] =
  let tempDir = getTempDir()
  let id = $genOid()
  result = sizes.map(proc (size: int): ImageInfo{.closure.} =
    let tmpName = tempDir & id & $size & ".png"
    let optName = tempDir & id & $size & "opt" & ".png"
    let img = cast[MyImage](png)
    let img2 = img[].resizedBicubic(size, size)
    let ad = cast[ptr UnCheckedArray[byte]](img2.data[0].unsafeAddr)
    discard zopflipng.savePNG32(tmpName, toOpenArray(ad, 0, img2.data.len * 4 - 1), img2.width, img2.height)
    try:
      optimizePNG(tmpName, optName)
    except Exception as e:
      stderr.write(e.msg & "\n")
      return ImageInfo(size: size, filePath: tmpName)
    result = ImageInfo(size: size, filePath: optName)
  )

proc buildMacos(wwwroot = "", release = false, flags: seq[string]) =
  let pwd: string = getCurrentDir()
  let pkgInfo = getPkgInfo()
  let buildDir = pwd / "build" / "macos"
  if not dirExists(buildDir):
    createDir(buildDir)
  let subDir = if release: "Release" else: "Debug"
  removeDir(buildDir)
  let appDir = buildDir / subDir / pkgInfo.name & ".app"
  createDir(appDir)
  let nSAppTransportSecurityJson = create(NSAppTransportSecurity,
    NSAllowsArbitraryLoads = some(true),
      NSAllowsLocalNetworking = some(true),
      NSExceptionDomains = some( %* @[
          {"localhost": {"NSExceptionAllowsInsecureHTTPLoads": true}.toTable}.toTable
          ])
  )
  let sec = if len(wwwroot) > 0: some(nSAppTransportSecurityJson): else: none(NSAppTransportSecurity)
  let appInfo = create(CocoaAppInfo,
    NSHighResolutionCapable = some(true),
    CFBundlePackageType = some("APPL"),
    CFBundleExecutable = pkgInfo.name,
    CFBundleDisplayName = pkgInfo.name,
    CFBundleVersion = pkgInfo.version,
    CFBundleIdentifier = none(string),
    NSAppTransportSecurity = sec,
    CFBundleIconName = none(string)
    )
  var plist = appInfo.JsonNode
  let app_logo = getCurrentDir() / "logo.png"
  if fileExists(app_logo):
    let outDir = appDir / "Contents" / "Resources"
    if not dirExists(outDir):
      createDir(outDir)
    let png = zopflipng.loadPNG32(app_logo)
    let images = genImages(png, @(icns.REQUIRED_IMAGE_SIZES))
    let path = generateICNS(images.filterIt(it != default(ImageInfo)), outDir)
    discard images.mapIt(tryRemoveFile(it.filePath))
    plist["CFBundleIconFile"] = newJString(extractFilename path)
  writePlist(plist, appDir / "Contents" / "Info.plist")
  var cmd = baseCmd(@["nimble", "build", "--silent", "-y"], wwwroot, release, flags)
  let finalCMD = cmd.join(" ")
  debugEcho finalCMD
  let (output, exitCode) = execCmdEx(finalCMD, options = {poUsePath})
  if exitCode == 0:
    debugEcho output
    let binOutDir = appDir / "Contents" / "MacOS"
    if not dirExists(binOutDir):
      createDir(binOutDir)
    moveFile(pwd / pkgInfo.name, binOutDir / pkgInfo.name)
  else:
    debugEcho output

proc runMacos(wwwroot = "", release = false, flags: seq[string]) =
  let pkgInfo = getPkgInfo()
  var cmd = baseCmd(@["nimble"], wwwroot, release, flags)
  let finalCMD = cmd.concat(@["run", pkgInfo.name]).join(" ")
  debugEcho finalCMD
  let (output, exitCode) = execCmdEx(finalCMD)
  if exitCode == 0:
    debugEcho output
  else:
    debugEcho output

proc runWindows(wwwroot = "", release = false, flags: seq[string]) =
  let pkgInfo = getPkgInfo()
  var cmd = baseCmd(@["nimble"], wwwroot, release, flags)
  let finalCMD = cmd.concat(@["run", pkgInfo.name]).join(" ")
  debugEcho finalCMD
  let (output, exitCode) = execCmdEx(finalCMD)
  if exitCode == 0:
    debugEcho output
  else:
    debugEcho output

proc buildWindows(wwwroot = "", release = false, flags: seq[string]) =
  let pwd: string = getCurrentDir()
  let pkgInfo = getPkgInfo()
  let buildDir = pwd / "build" / "windows"
  if not dirExists(buildDir):
    createDir(buildDir)
  let subDir = if release: "Release" else: "Debug"
  removeDir(buildDir)
  let appDir = buildDir / subDir
  createDir(appDir)
  let app_logo = getCurrentDir() / "logo.png"
  let logoExists = fileExists(app_logo)
  # var res: string
  # var output: string
  # var exitCode: int
  var icoPath: string
  if logoExists:
    let png = zopflipng.loadPNG32(app_logo)
    let tempDir = getTempDir()
    let images = genImages(png, @(ico.REQUIRED_IMAGE_SIZES))
    icoPath = generateICO(images.filterIt(it != default(ImageInfo)), tempDir)
    discard images.mapIt(tryRemoveFile(it.filePath))
    # for windres
    # let content = &"id ICON \"{path}\""
    # let rc = getTempDir() / "my.rc"
    # writeFile(rc, content)
    # res = getTempDir() / "my.res"
    # let resCmd = &"windres {rc} -O coff -o {res}"
    # (output, exitCode) = execCmdEx(resCmd)
  var myflags: seq[string]
  when not defined(windows):
    myflags.add "-d:mingw"
  var cmd = baseCmd(@["nimble", "build", "--silent", "-y"], wwwroot, release, myflags.concat flags)
  # for windres
  # if logoExists and exitCode == 0:
  #   discard cmd.concat @[&"--passL:{res}"]
  #   debugEcho output
  # else:
  #   debugEcho output

  let finalCMD = cmd.join(" ")
  debugEcho finalCMD
  let (o, e) = execCmdEx(finalCMD)

  if e == 0:
    debugEcho o
    let exePath = pwd / pkgInfo.name & ".exe"
    rcedit(none(string), exePath, {"icon": icoPath}.toTable())
    moveFile(exePath, appDir / pkgInfo.name & ".exe")
  else:
    debugEcho o

proc build(target: string, wwwroot = "", release = false, flags: seq[string]): int =
  case target:
    of "macos":
      # nim c -r -f src/crownguipkg/cli.nim build --target macos --wwwroot ./docs
      buildMacos(wwwroot, release, flags)
    of "windows":
      buildWindows(wwwroot, release, flags)

proc run(target: string, wwwroot = "", release = false, flags: seq[string]): int =
  case target:
    of "macos":
      # nim c -r -f src/crownguipkg/cli.nim run --target macos --wwwroot ./docs
      runMacos(wwwroot, release, flags)
    of "windows":
      runWindows(wwwroot, release, flags)

dispatchMulti([build], [run])
