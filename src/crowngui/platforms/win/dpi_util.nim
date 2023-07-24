
import winim

type
  DPI_AWARENESS_CONTEXT* = enum
    DPI_AWARENESS_CONTEXT_UNAWARE,
    DPI_AWARENESS_CONTEXT_SYSTEM_AWARE,
    DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE,
    DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2,
    DPI_AWARENESS_CONTEXT_UNAWARE_GDISCABLED

proc wGetWinVersionImpl*(): float =
  type RtlGetVersion = proc (lp: ptr OSVERSIONINFO) {.stdcall.}
  var osv = OSVERSIONINFO(dwOSVersionInfoSize: sizeof(OSVERSIONINFO).DWORD)
  let hDll = LoadLibrary("ntdll.dll")
  if hDll != 0:
    defer: FreeLibrary(hDll)

    var rtlGetVersion = cast[RtlGetVersion](GetProcAddress(hDll, "RtlGetVersion"))
    if not rtlGetVersion.isNil:
      try:
        rtlGetVersion(osv)
        return osv.dwMajorVersion.float + osv.dwMinorVersion.float / 10
      except: discard

  GetVersionEx(osv)
  return osv.dwMajorVersion.float + osv.dwMinorVersion.float / 10

const
  PROCESS_DPI_UNAWARE = 0
  PROCESS_SYSTEM_DPI_AWARE = 1
  PROCESS_PER_MONITOR_DPI_AWARE = 2

proc setDpiAwareness*(dpiAwarenessContext: DPI_AWARENESS_CONTEXT) =
  let version = wGetWinVersionImpl()
  if version >= 6.3 :  # Windows 8.1 and newer
    var SetProcessDpiAwarenessFunc = cast[proc (a: int) {.stdcall.}](GetProcAddress(GetModuleHandle("Shcore.dll"), "SetProcessDpiAwareness"))
    if SetProcessDpiAwarenessFunc != nil:
      var dpiAwareness: int
      case dpiAwarenessContext:
        of DPI_AWARENESS_CONTEXT_UNAWARE:
          dpiAwareness = PROCESS_DPI_UNAWARE
        of DPI_AWARENESS_CONTEXT_SYSTEM_AWARE:
          dpiAwareness = PROCESS_SYSTEM_DPI_AWARE
        else:
          dpiAwareness = PROCESS_PER_MONITOR_DPI_AWARE
      SetProcessDpiAwarenessFunc(dpiAwareness)
  else:  # Windows 8 or older
    var SetProcessDPIAwareFunc = cast[proc () {.stdcall.}](GetProcAddress(GetModuleHandle("user32.dll"), "SetProcessDPIAware"))
    if SetProcessDPIAwareFunc != nil:
      SetProcessDPIAwareFunc()
