import darwin/objc/runtime
import darwin/app_kit/[nswindow]
import darwin/web_kit/wkwebview

type
  MyNSWindowDelegate* = ptr object of NSObject
  WebviewPrivObj* = object
    pool*: ID
    window*: NSWindow
    webview*: WKWebView
    windowDelegate*: MyNSWindowDelegate
