import winim
import com
# import std/[atomics]

type
  WebView* = ptr WebViewObj
  OnOpenFile* = proc (w: Webview; filePath: string; name = ""):bool
  WebViewObj* = object
    url* : string
    title* : string
    width* : int
    height* : int
    resizable*: bool
    debug* : bool
    invokeCb* : pointer
    priv*: WebviewPrivObj
    created*: bool
    onOpenFile*: OnOpenFile
  WebviewPrivObj* = object
    windowHandle*: HWND
    view*: ptr ICoreWebView2
    controller*: ptr ICoreWebView2Controller
    settings*: ptr ICoreWebView2Settings

