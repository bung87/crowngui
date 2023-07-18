import winim
import com
# import std/[atomics]

type
  BrowserContextObj* = object
    windowHandle*: HWND
    view*: ptr ICoreWebView2
    controller*: ptr ICoreWebView2Controller
    settings*: ptr ICoreWebView2Settings
  BrowserContext* = ref BrowserContextObj
  BrowserConfigObj* = object
    initialURL*:string
    builtInErrorPage*     :bool
    defaultContextMenus*  :bool
    defaultScriptDialogs* :bool
    devtools*             :bool
    hostObjects*          :bool
    script*               :bool
    statusBar*            :bool
    webMessage*           :bool
    zoomControl*          :bool
  BrowserConfig* = ref BrowserConfigObj
  BrowserObj = object
    ctx*: BrowserContext
    config*: BrowserConfig
    # controllerCompleted*:  Atomic[int32]
  Browser* = ref BrowserObj

type WindowConfig* = object
  title*: string
  width*, height*: int32
  maxWidth*, maxHeight*: int32
  minWidth*, minHeight*: int32

type
  WindowObj = object
    config*: WindowConfig
    handle*: HWND
  Window* = ref WindowObj

type
  WebViewObj = object
    window*: Window
    browser*: Browser
  WebView* = ref WebViewObj
