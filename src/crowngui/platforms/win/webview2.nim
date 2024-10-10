import ../../types
import webview2/[types,controllers,context,dialog,com,environment_options,loader]
import winim
import winim/inc/winuser
import winim/[utils]
import std/[os, pathnorm]
import ./dpi_util
export types,dialog


const classname = "WebView"

# Window size hints
const WEBVIEW_HINT_NONE = 0  # Width and height are default size
const WEBVIEW_HINT_MIN = 1   # Width and height are minimum bounds
const WEBVIEW_HINT_MAX = 2   # Width and height are maximum bounds
const WEBVIEW_HINT_FIXED = 3 # Window size can not be changed by a user

var m_maxsz: POINT
var m_minsz: POINT

type WebviewDispatchCtx {.pure.} = object
  w: Webview
  arg: pointer
  fn: pointer

type WebviewDispatchCtx2 {.pure.} = object
  w: Webview
  arg: pointer
  fn: proc (w: Webview; arg: pointer)

proc terminate*(w: Webview): void
proc resize*(w: WebView;): void
proc embed*( w: WebView)

proc wndproc(hwnd: HWND, msg: UINT, wParam: WPARAM, lParam: LPARAM): LRESULT {.stdcall.} =
    var w = cast[Webview](GetWindowLongPtr(hwnd, GWLP_USERDATA))
    case msg
      of WM_SIZE:
        if w.priv.controller != nil:
          # SetWindowLongPtr trigger WM_SIZE too, controller has not initlization yet
          w.resize()
      of WM_CREATE:
        var
          pCreate = cast[ptr CREATESTRUCT](lParam)
          p = cast[LONG_PTR](pCreate.lpCreateParams)
        hwnd.SetWindowLongPtr(GWLP_USERDATA, p)
      of WM_CLOSE:
        DestroyWindow(hwnd)
      of WM_DESTROY:
        w.terminate()
        return TRUE
      else:
        return DefWindowProc(hwnd, msg, wParam, lParam)

proc  webview_init*(w: Webview): cint =
  var wc:WNDCLASSEX
  var hInstance:HINSTANCE
  var style:DWORD
  var clientRect:RECT
  var rect:RECT

  hInstance = GetModuleHandle(NULL)
  if hInstance == 0:
    return -1
  if OleInitialize(NULL) != S_OK:
    return -1
  ZeroMemory(&wc, sizeof(WNDCLASSEX))
  wc.cbSize = sizeof(WNDCLASSEX).UINT
  wc.hInstance = hInstance
  wc.lpfnWndProc = wndproc
  wc.lpszClassName = classname
  RegisterClassExW(&wc)

  style = WS_OVERLAPPEDWINDOW
  # if not w.resizable:
  #   style = WS_OVERLAPPED or WS_CAPTION or WS_MINIMIZEBOX or WS_SYSMENU
  rect.top = 0
  rect.left = 0
  rect.right = w.width.LONG
  rect.bottom = w.height.LONG
  AdjustWindowRect(&rect, WS_OVERLAPPEDWINDOW, 0)

  GetClientRect(GetDesktopWindow(), &clientRect)
  let left = (clientRect.right div 2) - ((rect.right - rect.left) div 2)
  let top = (clientRect.bottom div 2) - ((rect.bottom - rect.top) div 2)
  rect.right = rect.right - rect.left + left
  rect.left = left
  rect.bottom = rect.bottom - rect.top + top
  rect.top = top
  setDpiAwareness(DPI_AWARENESS_CONTEXT_SYSTEM_AWARE)
  w.priv.windowHandle = CreateWindowW(classname, w.title, style, rect.left, rect.top,
    rect.right - rect.left, rect.bottom - rect.top,
    HWND_DESKTOP, cast[HMENU](NULL), hInstance, cast[LPVOID](w))
  if (w.priv.windowHandle == 0):
    OleUninitialize()
    return -1

  # SetWindowLongPtr(w.priv.windowHandle, GWLP_USERDATA, cast[LONG_PTR](w))
  # webviewContext.set(w.priv.windowHandle, w)
  # discard DisplayHTMLPage(w)
  SetWindowText(w.priv.windowHandle, w.title)
  ShowWindow(w.priv.windowHandle, SW_SHOW)
  UpdateWindow(w.priv.windowHandle)
  SetFocus(w.priv.windowHandle)
  try:
    if CoInitializeEx(nil, COINIT_APARTMENTTHREADED).FAILED: raise
    defer: CoUninitialize()
  except:
    discard

  w.embed()
  return 0

proc run*(w: Webview) =
  ## `run` starts the main UI loop until the user closes the window or `exit()` is called.
  var msg: MSG
  while GetMessage(msg.addr, 0, 0, 0) != -1:
    if msg.hwnd != 0:
      TranslateMessage(msg.addr)
      DispatchMessage(msg.addr)
      continue
    case msg.message:
    of WM_APP:
      let fn = cast[proc(env:pointer):void {.stdcall.}](msg.lParam)
      fn(cast[pointer](msg.wParam))
    of WM_QUIT:
      return
    of WM_COMMAND,
      WM_KEYDOWN,
      WM_KEYUP:
      if (msg.wParam == VK_F5):
        return
    else:
      discard

proc terminate*(w: Webview): void =
  PostQuitMessage(0)

proc destroy*(w: Webview): void =
  w.terminate()

proc setTitle*(w: Webview; title: string ): void =
  discard SetWindowTextW(w.priv.windowHandle, &T(title))

proc navigate*(w: Webview; urlOrData: string ): void =
  discard w.priv.view.Navigate(&T(urlOrData))

proc setHtml*(w: Webview; html: string): void =
  discard w.priv.view.NavigateToString(&T(html))

proc eval*(w: Webview; js: string): void =
  discard w.priv.view.ExecuteScript(&T(js), nil)

proc setSize*(w: Webview; width: int; height: int; hints: int): void =
  var style = GetWindowLong(w.priv.windowHandle, GWL_STYLE)
  if hints == WEBVIEW_HINT_FIXED:
    style = style and not(WS_THICKFRAME or WS_MAXIMIZEBOX)
  else:
    style = style or (WS_THICKFRAME or WS_MAXIMIZEBOX)

  SetWindowLong(w.priv.windowHandle, GWL_STYLE, style)

  if hints == WEBVIEW_HINT_MAX:
    m_maxsz.x = width.LONG
    m_maxsz.y = height.LONG
  elif hints == WEBVIEW_HINT_MIN:
    m_minsz.x = width.LONG
    m_minsz.y = height.LONG
  else:
    var r: RECT
    r.left = 0
    r.top = 0
    r.right = width.LONG
    r.bottom = height.LONG
    AdjustWindowRect(r.addr, WS_OVERLAPPEDWINDOW, 0)
    discard SetWindowPos(w.priv.windowHandle, 0.HWND, r.left, r.top, r.right - r.left, r.bottom - r.top,
        SWP_NOZORDER or SWP_NOACTIVATE or SWP_NOMOVE or SWP_FRAMECHANGED)
    w.resize()

proc webview_dispatch*(w: Webview; fn: pointer; arg: pointer) {.stdcall.} =
  let mainThread = GetCurrentThreadId()
  var cb = proc() = cast[proc (w: Webview;arg: pointer){.stdcall.}](fn)(w, arg)
  PostThreadMessage(mainThread, WM_APP, cast[WPARAM](cb.rawEnv), cast[LPARAM](cb.rawProc))

proc resize*(w: WebView;): void =
  var bounds: RECT
  let g = GetClientRect(w.priv.windowHandle, bounds)
  doAssert g == TRUE, $GetLastError()
  doAssert w.priv.controller != nil
  discard w.priv.controller.put_Bounds(bounds)

proc embed*( w: WebView) =
  let exePath = getAppFilename()
  var (dir, name, ext) = splitFile(exePath)
  var dataPath = normalizePath(getEnv("AppData") / name)
  createDir(dataPath)
  # var versionInfo: LPWSTR
  # GetAvailableCoreWebView2BrowserVersionString(NULL, versionInfo.addr)
  # echo versionInfo
  # CoTaskMemFree(versionInfo)
  var controllerCompletedHandler = newControllerCompletedHandler(w.priv.windowHandle, w.priv.controller, w.priv.view, w.priv.settings)
  var environmentCompletedHandler = newEnvironmentCompletedHandler(w.priv.windowHandle, controllerCompletedHandler)
  var options = create(ICoreWebView2EnvironmentOptions)
  options.lpVtbl = create(ICoreWebView2EnvironmentOptionsVTBL)
  options.lpVtbl.QueryInterface = environment_options.QueryInterface
  options.lpVtbl.AddRef = environment_options.AddRef
  options.lpVtbl.Release = environment_options.Release
  options.lpVtbl.get_AdditionalBrowserArguments = environment_options.get_AdditionalBrowserArguments
  options.lpVtbl.put_AdditionalBrowserArguments = environment_options.put_AdditionalBrowserArguments
  options.lpVtbl.get_Language = environment_options.get_Language
  options.lpVtbl.put_Language = environment_options.put_Language
  options.lpVtbl.get_TargetCompatibleBrowserVersion = environment_options.get_TargetCompatibleBrowserVersion
  options.lpVtbl.put_TargetCompatibleBrowserVersion = environment_options.put_TargetCompatibleBrowserVersion
  options.lpVtbl.get_AllowSingleSignOnUsingOSPrimaryAccount = environment_options.get_AllowSingleSignOnUsingOSPrimaryAccount
  options.lpVtbl.put_AllowSingleSignOnUsingOSPrimaryAccount = environment_options.put_AllowSingleSignOnUsingOSPrimaryAccount
  options.lpVtbl.get_ExclusiveUserDataFolderAccess = environment_options.get_ExclusiveUserDataFolderAccess
  options.lpVtbl.put_ExclusiveUserDataFolderAccess = environment_options.put_ExclusiveUserDataFolderAccess

  let r1 = CreateCoreWebView2EnvironmentWithOptions("", dataPath, options, environmentCompletedHandler)

  doAssert r1 == S_OK, "failed to call CreateCoreWebView2EnvironmentWithOptions"
  # simulate synchronous
  # https://github.com/MicrosoftEdge/WebView2Feedback/issues/740
  assert w.created == false
  var msg: MSG
  while w.created == false and GetMessage(msg.addr, 0, 0, 0).bool:
    TranslateMessage(msg.addr)
    DispatchMessage(msg.addr)

proc addUserScriptAtDocumentStart*(w: WebView; script: string) =
  var script = T(script)
  discard w.priv.view.AddScriptToExecuteOnDocumentCreated(&script, NULL)

proc addUserScriptAtDocumentEnd*(w: WebView; script: string) =
  var token: EventRegistrationToken
  var handler = create(ICoreWebView2DOMContentLoadedEventHandler)
  handler.lpVtbl = create(ICoreWebView2DOMContentLoadedEventHandlerVTBL)
  handler.lpVtbl.QueryInterface = icorewebview2domcontentloadedeventhandler.QueryInterface
  handler.lpVtbl.AddRef = icorewebview2domcontentloadedeventhandler.AddRef
  handler.lpVtbl.Release = icorewebview2domcontentloadedeventhandler.Release
  handler.script = script
  handler.lpVtbl.Invoke = proc (self: ptr ICoreWebView2DOMContentLoadedEventHandler;
      sender: ptr ICoreWebView2;
      args: ptr ICoreWebView2DOMContentLoadedEventArgs): HRESULT {.stdcall.} =
    var script = T(self.script)
    sender.ExecuteScript(&script, NUll)

  discard w.priv.view.add_DOMContentLoaded(handler, token.addr)

# when isMainModule:
#   SetCurrentProcessExplicitAppUserModelID("webview2 app")
#   var v = newWebView()
#   assert v.webview_init() == 0

#   v.run