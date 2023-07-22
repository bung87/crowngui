import webview2/[types,webview,browser,context,dialog]
import winim
import winim/inc/winuser
import winim/[utils]
import std/[os]
export types,webview,dialog


const classname = "WebView"

# Window size hints
const WEBVIEW_HINT_NONE = 0  # Width and height are default size
const WEBVIEW_HINT_MIN = 1   # Width and height are minimum bounds
const WEBVIEW_HINT_MAX = 2   # Width and height are maximum bounds
const WEBVIEW_HINT_FIXED = 3 # Window size can not be changed by a user

var m_maxsz: POINT
var m_minsz: POINT

proc terminate*(w: Webview): void

proc wndproc(hwnd: HWND, msg: UINT, wParam: WPARAM, lParam: LPARAM): LRESULT {.stdcall.} =
    var w = cast[Webview](GetWindowLongPtr(hwnd, GWLP_USERDATA))

    case msg
      of WM_SIZE:

        if w.browser.ctx.controller != nil:
          # SetWindowLongPtr trigger WM_SIZE too, controller has not initlization yet
          w.browser.resize(hwnd)
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
  rect.right = w.window.config.width
  rect.bottom = w.window.config.height
  AdjustWindowRect(&rect, WS_OVERLAPPEDWINDOW, 0)

  GetClientRect(GetDesktopWindow(), &clientRect)
  let left = (clientRect.right div 2) - ((rect.right - rect.left) div 2)
  let top = (clientRect.bottom div 2) - ((rect.bottom - rect.top) div 2)
  rect.right = rect.right - rect.left + left
  rect.left = left
  rect.bottom = rect.bottom - rect.top + top
  rect.top = top
  w.window.handle = CreateWindowW(classname, w.window.config.title, style, rect.left, rect.top,
    rect.right - rect.left, rect.bottom - rect.top,
    HWND_DESKTOP, cast[HMENU](NULL), hInstance, cast[LPVOID](w))
  if (w.window.handle == 0):
    OleUninitialize()
    return -1

  # SetWindowLongPtr(w.window.handle, GWLP_USERDATA, cast[LONG_PTR](w))
  # webviewContext.set(w.window.handle, w)
  # discard DisplayHTMLPage(w)

  SetWindowText(w.window.handle, w.window.config.title)
  ShowWindow(w.window.handle, SW_SHOW)
  UpdateWindow(w.window.handle)
  SetFocus(w.window.handle)
  w.browser.embed(w)
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
      let f = cast[proc(): void {.stdcall.}](msg.lParam)
      f()
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
  discard SetWindowTextW(w.browser.ctx.windowHandle, +$(title))

proc navigate*(w: Webview; urlOrData: string ): void =
  discard w.browser.ctx.view.lpVtbl.Navigate(w.browser.ctx.view, +$(urlOrData))

proc setHtml*(w: Webview; html: string): void =
  discard w.browser.ctx.view.lpVtbl.NavigateToString(w.browser.ctx.view, +$(html))

proc eval*(w: Webview; js: string): void =
  discard w.browser.ctx.view.lpVtbl.ExecuteScript(w.browser.ctx.view, +$(js), nil)

proc setSize*(w: Webview; width: int; height: int; hints: int): void =
  var style = GetWindowLong(w.browser.ctx.windowHandle, GWL_STYLE)
  if hints == WEBVIEW_HINT_FIXED:
    style = style and not(WS_THICKFRAME or WS_MAXIMIZEBOX)
  else:
    style = style or (WS_THICKFRAME or WS_MAXIMIZEBOX)

  SetWindowLong(w.browser.ctx.windowHandle, GWL_STYLE, style)

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
    discard SetWindowPos(w.browser.ctx.windowHandle, 0.HWND, r.left, r.top, r.right - r.left, r.bottom - r.top,
        SWP_NOZORDER or SWP_NOACTIVATE or SWP_NOMOVE or SWP_FRAMECHANGED)
    w.browser.resize(w.browser.ctx.windowHandle)

proc addUserScriptAtDocumentStart*(w: Webview, js: string): void =
  w.browser.AddScriptToExecuteOnDocumentCreated(js)

proc webview_dispatch*(w: Webview; fn: pointer; arg: pointer) {.stdcall.} =
  let mainThread = GetCurrentThreadId()
  PostThreadMessage(mainThread, WM_APP, 0, cast[LPARAM](fn))

proc addUserScriptAtDocumentEnd*(w: Webview, js: string): void =
  w.browser.AddScriptToExecuteOnDocumentCreated(js)

when isMainModule:
  SetCurrentProcessExplicitAppUserModelID("webview2 app")
  var v = newWebView()
  assert v.webview_init() == 0

  v.run