import objc_runtime
import darwin/app_kit/nswindow
import darwin/web_kit/wkwebview

type
  WebviewPrivObj* = object
    pool*: ID
    window*: NSWindow
    webview*: WKWebView
    windowDelegate*: ID
