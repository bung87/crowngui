import std/ [os]
import winim
import winim/inc/winuser
import winim/inc/mshtml
import winim/[utils]
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
    GlobalFree(cast[HGLOBAL](w.priv.browser))
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

var MyIOleClientSiteTable: IOleClientSiteVtbl

proc Site_QueryInterface(web: ptr IUnknown, riid: REFIID, ppvObject: ptr pointer): HRESULT {.stdcall, noSideEffect, gcsafe, locks: 0.} =
  if ppvObject.isNil:
    return E_POINTER

  elif IsEqualIID(riid, &IID_IUnknown):
    ppvObject[] = cast[ptr IOleClientSiteEx](web)[].external.addr

  elif IsEqualIID(riid, &IID_IDispatch) or
      IsEqualIID(riid, &DIID_DWebBrowserEvents) or
      IsEqualIID(riid, &DIID_DWebBrowserEvents2):
    ppvObject[] =  cast[ptr IOleClientSiteEx](web)[].external.addr

  elif IsEqualIID(riid, &IID_IOleClientSite):
    ppvObject[] =  cast[ptr IOleClientSiteEx](web)[].client.addr

  elif IsEqualIID(riid, &IID_IOleWindow) or
      IsEqualIID(riid, &IID_IOleInPlaceSite) or
      IsEqualIID(riid, &IID_IOleInPlaceSiteEx):
    ppvObject[] =  cast[ptr IOleClientSiteEx](web)[].inplace.addr

  # elif IsEqualIID(riid, &IID_IOleInPlaceFrame):
  #   ppvObject[] = &web.inPlaceFrame

  elif IsEqualIID(riid, &IID_IDocHostUIHandler):
    ppvObject[] = cast[ptr IOleClientSiteEx](web)[].ui.addr

  else:
    ppvObject[] = nil
    return E_NOINTERFACE

  # web.AddRef()
  return S_OK

MyIOleClientSiteTable.QueryInterface = Site_QueryInterface
MyIOleClientSiteTable.AddRef = proc(self: ptr IUnknown): ULONG {.stdcall.} =
  return 1

MyIOleClientSiteTable.Release = proc(self: ptr IUnknown): ULONG {.stdcall.} =
  return 1

MyIOleClientSiteTable.SaveObject = proc(self: ptr IOleClientSite): HRESULT {.stdcall.} =
  return E_NOTIMPL

MyIOleClientSiteTable.GetMoniker = proc(self: ptr IOleClientSite, dwAssign: DWORD, dwWhichMoniker: DWORD, ppmk: ptr ptr IMoniker): HRESULT {.stdcall.} =
  return E_NOTIMPL

MyIOleClientSiteTable.GetContainer = proc(self: ptr IOleClientSite, ppContainer: ptr ptr IOleContainer): HRESULT {.stdcall.} =
  ppContainer[] = nil
  return E_NOINTERFACE

MyIOleClientSiteTable.ShowObject = proc(self: ptr IOleClientSite): HRESULT {.stdcall.} =
  return S_OK

MyIOleClientSiteTable.OnShowWindow = proc(self: ptr IOleClientSite, fShow: WINBOOL): HRESULT {.stdcall.} =
  return E_NOTIMPL

MyIOleClientSiteTable.RequestNewObjectLayout = proc(self: ptr IOleClientSite): HRESULT {.stdcall.} =
  return E_NOTIMPL


template `+`[T](p: ptr T, off: int): ptr T =
  cast[ptr type(p[])](cast[ByteAddress](p) +% off * sizeof(p[]))
# https://github.com/khchen/wNim/blob/b446238744fd7e8c859b3ae8fe1942f03c966864/wNim/private/controls/wWebView.nim#L620
proc EmbedBrowserObject(w: Webview):int =
  var rect:RECT 
  var webBrowser2: ptr IWebBrowser2
  var pClassFactory:LPCLASSFACTORY = NULL
  var iOleClientSiteEx: ptr IOleClientSiteEx = NULL
  var browser: ptr ptr IOleObject = cast[ptr ptr IOleObject](GlobalAlloc(
      GMEM_FIXED, sizeof(ptr IOleObject ) + sizeof(IOleClientSiteEx)))
  if browser == NULL:
    goto error
  
  w.priv.browser = browser

  iOleClientSiteEx = cast[ptr IOleClientSiteEx](browser + 1)
  iOleClientSiteEx[].client.lpVtbl = &MyIOleClientSiteTable
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
  label error:
    UnEmbedBrowserObject(w)
    if (pClassFactory != NULL):
      pClassFactory.Release()
    
    if (browser != NULL):
      GlobalFree(cast[HGLOBAL](browser))
    
    return -1
  return 0

proc wndproc(hwnd: HWND, msg: UINT, wParam: WPARAM, lParam: LPARAM): LRESULT
      {.stdcall.} =
    var w = cast[Webview](GetWindowLongPtr(hwnd, 0))

    case msg
      of WM_SIZE:
        var webBrowser2:ptr IWebBrowser2
        var browser = w.priv.browser
        if browser[].QueryInterface( &IID_IWebBrowser2,
                                          cast[ptr pointer](webBrowser2.addr)) == S_OK:
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
  
proc navigate*(w: Webview, url: string, noHistory = false) =
  ## Navigating the given url.
  var vUrl: VARIANT
  vUrl.vt = VT_BSTR
  vUrl.bstrVal = SysAllocString(url)

  var vFlag: VARIANT
  vFlag.vt = VT_I4
  if noHistory:
    vFlag.lVal = navNoHistory
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
    if webBrowser2.get_Document(&dispatch).FAILED or dispatch == nil:
      # always try to get a document object, event a blank one
      w.navigate("about:blank")
      if webBrowser2.get_Document(&dispatch).FAILED or dispatch == nil:
        raise newException(CatchableError, "wWebView.getDocument failure")

    defer: dispatch.Release()
    if dispatch.QueryInterface(&IID_IHTMLDocument2, cast[ptr pointer](&result)).FAILED:
      raise newException(CatchableError, "wWebView.getDocument failure")

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

proc setHtml*(self: Webview, html: string) =
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
                     HWND_DESKTOP, cast[HMENU](NULL), hInstance, w)
  if (w.priv.hwnd == 0):
    OleUninitialize()
    return -1

  SetWindowLongPtr(w.priv.hwnd, GWLP_USERDATA, cast[LONG_PTR](w))

  DisplayHTMLPage(w)

  SetWindowText(w.priv.hwnd, w.title)
  ShowWindow(w.priv.hwnd, SW_SHOWDEFAULT)
  UpdateWindow(w.priv.hwnd)
  SetFocus(w.priv.hwnd)

  return 0

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
