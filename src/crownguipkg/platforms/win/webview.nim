import std/ [os]
import winim
import winim/inc/winuser
import goto
# webview_init
# webview_eval
# webview_fix_ie_compat_mode
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
  ExternalInvokeCb* = proc (w: Webview; arg: string)  ## External CallBack Proc
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

proc UnEmbedBrowserObject(w: Webview) =
  if w.priv.browser != NULL:
    w.priv.browser[].Close( OLECLOSE_NOSAVE)
    w.priv.browser[].Release()
    GlobalFree(w.priv.browser)
    w.priv.browser = NULL

type  IServiceProviderEx = object
  provider: IServiceProvider 
  mgr:IInternetSecurityManagerEx

type 
  DOCHOSTUIINFO* {.pure.} = object
    cbSize*: ULONG
    dwFlags*: DWORD
    dwDoubleClick*: DWORD
    pchHostCss*: ptr OLECHAR
    pchHostNS*: ptr OLECHAR
  IDocHostUIHandler* {.pure.} = object
    lpVtbl*: ptr IDocHostUIHandlerVtbl
  IDocHostUIHandlerVtbl* {.pure, inheritable.} = object of IUnknownVtbl
    ShowContextMenu*: proc(self: ptr IDocHostUIHandler, dwID: DWORD, ppt: ptr POINT, pcmdtReserved: ptr IUnknown, pdispReserved: ptr IDispatch): HRESULT {.stdcall.}
    GetHostInfo*: proc(self: ptr IDocHostUIHandler, pInfo: ptr DOCHOSTUIINFO): HRESULT {.stdcall.}
    ShowUI*: proc(self: ptr IDocHostUIHandler, dwID: DWORD, pActiveObject: ptr IOleInPlaceActiveObject, pCommandTarget: ptr IOleCommandTarget, pFrame: ptr IOleInPlaceFrame, pDoc: ptr IOleInPlaceUIWindow): HRESULT {.stdcall.}
    HideUI*: proc(self: ptr IDocHostUIHandler): HRESULT {.stdcall.}
    UpdateUI*: proc(self: ptr IDocHostUIHandler): HRESULT {.stdcall.}
    EnableModeless*: proc(self: ptr IDocHostUIHandler, fEnable: WINBOOL): HRESULT {.stdcall.}
    OnDocWindowActivate*: proc(self: ptr IDocHostUIHandler, fActivate: WINBOOL): HRESULT {.stdcall.}
    OnFrameWindowActivate*: proc(self: ptr IDocHostUIHandler, fActivate: WINBOOL): HRESULT {.stdcall.}
    ResizeBorder*: proc(self: ptr IDocHostUIHandler, prcBorder: LPCRECT, pUIWindow: ptr IOleInPlaceUIWindow, fRameWindow: WINBOOL): HRESULT {.stdcall.}
    TranslateAccelerator*: proc(self: ptr IDocHostUIHandler, lpMsg: LPMSG, pguidCmdGroup: ptr GUID, nCmdID: DWORD): HRESULT {.stdcall.}
    GetOptionKeyPath*: proc(self: ptr IDocHostUIHandler, pchKey: ptr LPOLESTR, dw: DWORD): HRESULT {.stdcall.}
    GetDropTarget*: proc(self: ptr IDocHostUIHandler, pDropTarget: ptr IDropTarget, ppDropTarget: ptr ptr IDropTarget): HRESULT {.stdcall.}
    GetExternal*: proc(self: ptr IDocHostUIHandler, ppDispatch: ptr ptr IDispatch): HRESULT {.stdcall.}
    TranslateUrl*: proc(self: ptr IDocHostUIHandler, dwTranslate: DWORD, pchURLIn: LPWSTR, ppchURLOut: ptr LPWSTR): HRESULT {.stdcall.}
    FilterDataObject*: proc(self: ptr IDocHostUIHandler, pDO: ptr IDataObject, ppDORet: ptr ptr IDataObject): HRESULT {.stdcall.}

type  IOleClientSiteEx {.pure.} = object
    # view: wWebView
    # hwnd: HWND
    # hwndIe: HWND
    # style: DWORD
    # canGoBack: bool
    # canGoForward: bool
    # focusd: bool
    # cookie: DWORD
    # refs: LONG
    # ole: ptr IOleObject
    # browser: ptr IWebBrowser2
   
    client: IOleClientSite
    inplace: IOleInPlaceSiteEx
    # inPlaceFrame: IOleInPlaceFrame
    ui: IDocHostUIHandler
    external: IDispatch
    provider: IServiceProviderEx 

# https://github.com/khchen/wNim/blob/b446238744fd7e8c859b3ae8fe1942f03c966864/wNim/private/controls/wWebView.nim#L620
proc EmbedBrowserObject(w: Webview):int =
  var rect:RECT 
  var webBrowser2: ptr IWebBrowser2
  var pClassFactory:LPCLASSFACTORY = NULL
  var iOleClientSiteEx: ptr IOleClientSiteEx = NULL
  var browser: ptr ptr IOleObject = GlobalAlloc(
      GMEM_FIXED, sizeof(IOleObject ) + sizeof(IOleClientSiteEx))
  if browser == NULL:
    goto error
  
  w.priv.browser = browser

  # iOleClientSiteEx = (IOleClientSiteEx *)(browser + 1)
  # iOleClientSiteEx->client.lpVtbl = &MyIOleClientSiteTable
  # iOleClientSiteEx->inplace.inplace.lpVtbl = &MyIOleInPlaceSiteTable
  # iOleClientSiteEx->inplace.frame.frame.lpVtbl = &MyIOleInPlaceFrameTable
  # iOleClientSiteEx->inplace.frame.window = w->priv.hwnd
  # iOleClientSiteEx->ui.ui.lpVtbl = &MyIDocHostUIHandlerTable
  # iOleClientSiteEx->external.lpVtbl = &ExternalDispatchTable
  # iOleClientSiteEx->provider.provider.lpVtbl = &MyServiceProviderTable
  # iOleClientSiteEx->provider.mgr.mgr.lpVtbl = &MyInternetSecurityManagerTable

  if (CoGetClassObject(&CLSID_WebBrowser,
                       CLSCTX_INPROC_SERVER or CLSCTX_INPROC_HANDLER, NULL,
                       &IID_IClassFactory,
                       cast[ptr LPVOID](pClassFactory.addr)) != S_OK) :
    goto error

  if (pClassFactory == NULL):
    goto error

  if (pClassFactory.CreateInstance( cast[ptr IUnknown](0),
                                            &IID_IOleObject,
                                            cast[ptr pointer](browser)) != S_OK) :
    goto error

  discard pClassFactory.lpVtbl.Release(pClassFactory)
  if browser[].SetClientSite(cast[ptr IOleClientSite](iOleClientSiteEx)).FAILED:
    goto error
  
  # (*browser)->lpVtbl->SetHostNames(*browser, L"My Host Name", 0);

  if (OleSetContainedObject(browser[], TRUE) != S_OK):
    goto error
  GetClientRect(w.priv.hwnd, &rect)
  if browser[].DoVerb(OLEIVERB_SHOW, nil, cast[ptr IOleClientSite](iOleClientSiteEx), 0,
        w.priv.hwnd, &rect).FAILED:
    goto error

  if (browser[].QueryInterface( &IID_IWebBrowser2,
                                        cast[ptr pointer](webBrowser2.addr)) != S_OK) :
    goto error

  webBrowser2.put_Left( 0)
  webBrowser2.put_Top( 0)
  webBrowser2.put_Width( rect.right)
  webBrowser2.put_Height( rect.bottom)
  webBrowser2.Release()

  return 0

# label error:
#   UnEmbedBrowserObject(w)
#   if (pClassFactory != NULL):
#     pClassFactory.Release()
  
#   if (browser != NULL):
#     GlobalFree(browser)
  
#   return -1


proc wndproc(hwnd: HWND, msg: UINT, wParam: WPARAM, lParam: LPARAM): LRESULT
      {.stdcall.} =
    var w = cast[Webview](GetWindowLongPtr(hwnd, 0))

    case msg
    of WM_SIZE:
      var webBrowser2:ptr IWebBrowser2
      var browser = w.priv.browser
      if (cast[ptr IUnknown](browser[]).QueryInterface( &IID_IWebBrowser2,
                                        cast[ptr pointer](webBrowser2.addr)) == S_OK) :
        var rect: RECT
        GetClientRect(hwnd, &rect)
        webBrowser2.put_Width(rect.right)
        webBrowser2.put_Height(rect.bottom)

    of WM_CREATE:
      let cs = cast[ptr CREATESTRUCT](lParam)
      w = cast[Webview](cs)
      w.priv.hwnd = hwnd
      return EmbedBrowserObject(w)

    of WM_DESTROY:
      UnEmbedBrowserObject(w)
      PostQuitMessage(0)
      return TRUE

    else:
      return DefWindowProc(hwnd, msg, wParam, lParam)

const classname = "WebView"

proc  webview_init*(w: Webview): cint =
  var wc:WNDCLASSEX
  var hInstance:HINSTANCE
  var style:DWORD
  var clientRect:RECT
  var rect:RECT

  if (webview_fix_ie_compat_mode() < 0) :
    return -1;

  hInstance = GetModuleHandle(NULL)
  if hInstance == 0:
    return -1
  
  if (OleInitialize(NULL) != S_OK):
    return -1
  
  ZeroMemory(&wc, sizeof(WNDCLASSEX))
  wc.cbSize = sizeof(WNDCLASSEX).UINT
  wc.hInstance = hInstance
  wc.lpfnWndProc = wndproc
  wc.lpszClassName = classname
  RegisterClassEx(&wc)

  style = WS_OVERLAPPEDWINDOW;
  if (not w.resizable) :
    style = WS_OVERLAPPED or WS_CAPTION or WS_MINIMIZEBOX or WS_SYSMENU;

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

  w.priv.hwnd = CreateWindowEx(0, classname, w.title, style, rect.left, rect.top,
                     rect.right - rect.left, rect.bottom - rect.top,
                     HWND_DESKTOP, NULL, hInstance, w)
  if (w.priv.hwnd == 0):
    OleUninitialize()
    return -1;

  SetWindowLongPtr(w.priv.hwnd, GWLP_USERDATA, cast[LONG_PTR](w))

  DisplayHTMLPage(w)

  SetWindowText(w.priv.hwnd, w.title)
  ShowWindow(w.priv.hwnd, SW_SHOWDEFAULT)
  UpdateWindow(w.priv.hwnd)
  SetFocus(w.priv.hwnd)

  return 0;

proc webview_loop*(w: Webview, blocking:int):int =
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
    if (cast[ptr IUnknown](browser[]).QueryInterface( &IID_IWebBrowser2,
                                        cast[ptr pointer](webBrowser2.addr)) == S_OK) :
      var pIOIPAO:ptr IOleInPlaceActiveObject
      if (cast[ptr IUnknown](browser[]).QueryInterface( &IID_IOleInPlaceActiveObject,
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
