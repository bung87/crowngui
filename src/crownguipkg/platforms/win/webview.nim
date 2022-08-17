import std/ [os]
import winim
import winim/inc/winuser
import winim/inc/mshtml
import winim/[utils]
import goto

converter toLPCWSTR*(s: string): LPCWSTR = 
  ## Converts a Nim string to Sciter-expected ptr wchar_t (LPCWSTR)
  var widestr = newWideCString(s)
  result = cast[LPCWSTR](addr widestr[0])
# webview_eval
# webview_set_title
# webview_set_fullscreen
# webview_set_iconify
# webview_launch_external_URL
# webview_dialog
# webview_terminate
# webview_exit
# webview_print_log
const headerC = currentSourcePath.parentDir.parentDir.parentDir / "webview.h"

type
  ExternalInvokeCb* = proc (w: Webview; arg: cstring)  ## External CallBack Proc
  WebviewPrivObj {.importc: "struct webview_priv", header: headerC, bycopy.} = object
    hwnd {.importc: "hwnd".}:HWND
    browser {.importc: "browser".}:ptr ptr IOleObject
    is_fullscreen {.importc: "is_fullscreen".}:BOOL
    saved_style {.importc: "saved_style".}:DWORD
    saved_ex_style {.importc: "saved_ex_style".}:DWORD
    saved_rect {.importc: "saved_rect".}:RECT
  WebviewObj* {.importc: "struct webview", header: headerC, bycopy.} = object ## WebView Type
    url* {.importc: "url".}: cstring                    ## Current URL
    title* {.importc: "title".}: cstring                ## Window Title
    width* {.importc: "width".}: cint                   ## Window Width
    height* {.importc: "height".}: cint                 ## Window Height
    resizable* {.importc: "resizable".}: cint           ## `true` to Resize the Window, `false` for Fixed size Window
    debug* {.importc: "debug".}: cint                   ## Debug is `true` when not build for Release
    invokeCb {.importc: "external_invoke_cb".}: pointer ## Callback proc
    priv* {.importc: "priv".}: WebviewPrivObj
    userdata {.importc: "userdata".}: pointer
  Webview* = ptr WebviewObj

func webview_dispatch*(w: Webview; fn: pointer; arg: pointer) {.importc: "webview_dispatch", header: headerC.}
func webview_terminate*(w: Webview) {.importc: "webview_terminate", header: headerC.}
func webview_exit*(w: Webview) {.importc: "webview_exit", header: headerC.}
proc EmbedBrowserObject*(w: Webview):cint {.importc: "EmbedBrowserObject", header: headerC.}

proc UnEmbedBrowserObject*(w: Webview) {.importc: "UnEmbedBrowserObject", header: headerC.}

proc wndproc(hwnd: HWND, msg: UINT, wParam: WPARAM, lParam: LPARAM): LRESULT {.stdcall.} =
    var w = cast[Webview](GetWindowLongPtr(hwnd, GWLP_USERDATA))

    case msg
      of WM_SIZE:
        var webBrowser2:ptr IWebBrowser2
        var browser = w[].priv.browser
        if browser[].QueryInterface( &IID_IWebBrowser2,
                                          cast[ptr pointer](webBrowser2.addr)) == S_OK:
          var rect: RECT
          GetClientRect(hwnd, &rect)
          webBrowser2.put_Width(rect.right)
          webBrowser2.put_Height(rect.bottom)

      of WM_CREATE:
        let cs = cast[ptr CREATESTRUCT](lParam)
        w = cast[Webview](cs.lpCreateParams)
        w[].priv.hwnd = hwnd
        return EmbedBrowserObject(w)

      of WM_DESTROY:
        UnEmbedBrowserObject(w)
        PostQuitMessage(0)
        return TRUE
      else:
        return DefWindowProc(hwnd, msg, wParam, lParam)

const classname = "WebView"

const WEBVIEW_KEY_FEATURE_BROWSER_EMULATION = "Software\\Microsoft\\Internet Explorer\\Main\\FeatureControl\\FEATURE_BROWSER_EMULATION"

proc webview_fix_ie_compat_mode():int =
  var hKey:HKEY
  var ie_version:DWORD = 11000
  let p = extractFilename(getAppFilename())
  if (RegCreateKey(HKEY_CURRENT_USER, WEBVIEW_KEY_FEATURE_BROWSER_EMULATION,
                   &hKey) != ERROR_SUCCESS) :
    return -1
  
  if (RegSetValueEx(hKey, p, 0, REG_DWORD, cast[ptr BYTE](ie_version.addr),
                    sizeof(ie_version).DWORD) != ERROR_SUCCESS) :
    RegCloseKey(hKey)
    return -1
  
  RegCloseKey(hKey)
  return 0

# proc getWeb(self: Webview): ptr WebviewPrivObj =
#   result = cast[ptr WebviewPrivObj](GetWindowLongPtr(self[].pirv.hwnd, 0))
#   assert result != nil
  
proc webview_load_URL*(w: Webview, url: cstring) =
  ## Navigating the given url.
  var vUrl: VARIANT
  vUrl.vt = VT_BSTR
  vUrl.bstrVal = SysAllocString(url)

  var vFlag: VARIANT
  vFlag.vt = VT_I4

  var webBrowser2:ptr IWebBrowser2
  if (w.priv.browser[].QueryInterface( &IID_IWebBrowser2,
                                        cast[ptr pointer](webBrowser2.addr)) == S_OK) :
    webBrowser2.Navigate2(&vUrl, &vFlag, nil, nil, nil)
    VariantClear(&vUrl)

proc getDocument(w: Webview): ptr IHTMLDocument2 =
  var dispatch: ptr IDispatch
  var webBrowser2:ptr IWebBrowser2
  if (w.priv.browser[].QueryInterface( &IID_IWebBrowser2,
                                        cast[ptr pointer](webBrowser2.addr)) == S_OK) :
    # if webBrowser2.get_Document(&dispatch).FAILED or dispatch == nil:
    #   # always try to get a document object, event a blank one
    #   w.webview_load_HTML("about:blank".cstring)
    #   if webBrowser2.get_Document(&dispatch).FAILED or dispatch == nil:
    #     raise newException(CatchableError, "wWebView.getDocument failure")

    defer: dispatch.Release()
    if dispatch.QueryInterface(&IID_IHTMLDocument2, cast[ptr pointer](&result)).FAILED:
      raise newException(CatchableError, "wWebView.getDocument failure")

proc webview_load_HTML*(self: Webview, html: cstring) =
  ## Set the displayed page HTML source to the contents of the given string.
  let document = self.getDocument()
  assert document != nil
  defer: document.Release()

  var safeArray = SafeArrayCreateVector(VT_VARIANT, 0, 1)
  if safeArray == nil:
    raise newException(CatchableError, "wWebView.setHtml failure")
  defer: SafeArrayDestroy(safeArray)

  var param: ptr VARIANT
  SafeArrayAccessData(safeArray, cast[ptr pointer](&param))
  param[].vt = VT_BSTR
  param[].bstrVal = SysAllocString(html)
  SafeArrayUnaccessData(safeArray)

  document.write(safeArray)
  document.close()

proc runScript*(self: Webview, code: string) =
  ## Runs the given javascript code. This function discard the result. If you
  ## need the result from the javascript code, use *eval* instead. For example:
  ##
  ## .. code-block:: Nim
  ##   var obj = webView.getComObject()
  ##   echo obj.document.script.call("eval", "1 + 2 * 3")
  let document = self.getDocument()
  assert document != nil
  defer: document.Release()

  var window: ptr IHTMLWindow2
  if document.get_parentWindow(&window).FAILED or window == nil:
    raise newException(CatchableError, "wWebView.runScript failure")
  defer: window.Release()

  var
    bstrCode = SysAllocString(code)
    bstrLang = SysAllocString("javascript")
    ret: VARIANT

  defer:
    SysFreeString(bstrCode)
    SysFreeString(bstrLang)
    VariantClear(&ret)

  window.execScript(bstrCode, bstrLang, &ret)

proc getHtml*(self: Webview): string =
  ## Get the HTML source code of the currently displayed document.
  let document = self.getDocument()
  assert document != nil
  defer: document.Release()

  var body: ptr IHTMLElement
  if document.get_body(&body).FAILED or body == nil:
    raise newException(CatchableError, "wWebView.getHtml failure")
  defer: body.Release()

  var html: ptr IHTMLElement
  if body.get_parentElement(&html).FAILED or body == nil:
    raise newException(CatchableError, "wWebView.getHtml failure")
  defer: html.Release()

  var bstr: BSTR
  if html.get_outerHTML(&bstr).FAILED or bstr == nil:
    raise newException(CatchableError, "wWebView.getHtml failure")
  defer: SysFreeString(bstr)

  result = $bstr

proc DisplayHTMLPage*(w: Webview):cint {.importc: "DisplayHTMLPage", header: headerC.}
# proc webview_init*(w: Webview) {.importc: "webview_init", header: headerC.}
proc  webview_init*(w: Webview): cint =
  var wc:WNDCLASSEX
  var hInstance:HINSTANCE
  var style:DWORD
  var clientRect:RECT
  var rect:RECT

  if (webview_fix_ie_compat_mode() < 0):
    return -1

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
  RegisterClassEx(&wc)

  style = WS_OVERLAPPEDWINDOW
  if not w.resizable:
    style = WS_OVERLAPPED or WS_CAPTION or WS_MINIMIZEBOX or WS_SYSMENU

  rect.left = 0;
  rect.top = 0;
  rect.right = w.width;
  rect.bottom = w.height;
  AdjustWindowRect(&rect, WS_OVERLAPPEDWINDOW, 0)

  GetClientRect(GetDesktopWindow(), &clientRect)
  let left = (clientRect.right div 2) - ((rect.right - rect.left) div 2)
  let top = (clientRect.bottom div 2) - ((rect.bottom - rect.top) div 2)
  rect.right = rect.right - rect.left + left
  rect.left = left
  rect.bottom = rect.bottom - rect.top + top
  rect.top = top

  w[].priv.hwnd = CreateWindowEx(0, classname, w.title, style, rect.left, rect.top,
                     rect.right - rect.left, rect.bottom - rect.top,
                     HWND_DESKTOP, cast[HMENU](NULL), hInstance, w)
  if (w[].priv.hwnd == 0):
    OleUninitialize()
    return -1

  SetWindowLongPtr(w[].priv.hwnd, GWLP_USERDATA, cast[LONG_PTR](w))

  discard DisplayHTMLPage(w)

  SetWindowText(w[].priv.hwnd, w.title)
  ShowWindow(w[].priv.hwnd, SW_SHOWDEFAULT)
  UpdateWindow(w[].priv.hwnd)
  SetFocus(w[].priv.hwnd)

  return 0

proc webview_loop*(w: Webview, blocking:cint):cint =
  var msg: MSG
  if blocking == 1:
    if (GetMessage(msg.addr, 0, 0, 0)<0): return 0
  else:
    if not PeekMessage(msg.addr, 0, 0, 0, PM_REMOVE) == TRUE: return 0
  
  case msg.message:
  of WM_QUIT:
    return -1
  of WM_COMMAND,
   WM_KEYDOWN,
   WM_KEYUP: 
    if (msg.wParam == VK_F5):
      return 0
    var r:HRESULT = S_OK
    var webBrowser2:ptr IWebBrowser2
    var browser = w.priv.browser
    if (browser[].QueryInterface( &IID_IWebBrowser2,
                                        cast[ptr pointer](webBrowser2.addr)) == S_OK) :
      var pIOIPAO:ptr IOleInPlaceActiveObject
      if (browser[].QueryInterface( &IID_IOleInPlaceActiveObject,
              cast[ptr pointer](pIOIPAO.addr)) == S_OK):
        r = pIOIPAO.TranslateAccelerator(msg.addr)
        discard pIOIPAO.lpVtbl.Release(cast[ptr IUnknown](pIOIPAO))
      discard webBrowser2.lpVtbl.Release(cast[ptr IUnknown](webBrowser2))
    
    if (r != S_FALSE):
      return
  
  else:
    TranslateMessage(msg.addr)
    DispatchMessage(msg.addr)
  
  return 0
