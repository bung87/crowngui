import darwin/objc/runtime
import darwin/app_kit/[nswindow,nsapplication]
import darwin/web_kit/wkwebview

type
  MyNSWindowDelegate* = ptr object of NSObject
  WebviewPrivObj* = object
    pool*: ID
    window*: NSWindow
    webview*: WKWebView
    windowDelegate*: MyNSWindowDelegate

type
  WKScriptMessage* = ptr object of NSObject

proc body*(self: WKScriptMessage): NSString {.objc.}

proc setNavigationDelegate*(s: WKWebview, d: NSObject) {.objc: "setNavigationDelegate:".}

proc setDelegate*(s: NSWindow, d: NSObject) {.objc: "setDelegate:".}

proc setDelegate*(s: NSApplication, d: NSObject) {.objc: "setDelegate:".}