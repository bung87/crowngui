import strutils, base64
import objc_runtime
import darwin / [app_kit,web_kit, foundation, objc/runtime, core_graphics/cggeometry]
# import menu
import types
export types
import dialog
export dialog
# import event
import bundle
import ./message_handler
import ./download_delegate
import ./ui_delegate
import ./navigation_delegate
import ./window_delegate
import ./utils
import std/[macros]

{.passl: "-framework Cocoa -framework WebKit".}


const WKUserScriptInjectionTimeAtDocumentStart = 0
const WKUserScriptInjectionTimeAtDocumentEnd = 1
const DefaultWindowStyle = NSWindowStyleMaskTitled or NSWindowStyleMaskClosable or
                      NSWindowStyleMaskMiniaturizable;
type 
  NSAutoreleasePool = ptr object of NSObject
  WKUserScript = ptr object of NSObject
  WKWebViewConfiguration  = ptr object of NSObject
  WKUserContentController = ptr object of NSObject
# proc initWithSource*(self: WKUserScript, source: NSString, injectionTime: static[int], forMainFrameOnly: BOOL) {.objc: "initWithSource:injectionTime:forMainFrameOnly:".}

proc setHtml*(w: Webview; html: string) =
  objcr: [w.priv.webview loadHTMLString: @html, baseURL: nil]

proc navigate*(w: Webview; url: string) =
  objcr:
    var requestURL = [NSURL URLWithString: @url]
    [requestURL autorelease]
    var request = [NSURLRequest requestWithURL: requestURL]
    [request autorelease]
    [w.priv.webview loadRequest: request]

proc setSize*(w: Webview; width: int; height: int) =
  objcr:
    let f = [w.priv.window frame]
    var frame: CGRect = cast[CGRect](f)
    frame.size.width = width.CGFloat
    frame.size.height = height.CGFloat
    [w.priv.window setFrame: frame, display: true]

proc webview_init*(w: Webview): cint =
  # w.priv.pool = objcr: [NSAutoreleasePool new]
  # objcr: [NSEvent addLocalMonitorForEventsMatchingMask: NSKeyDown, handler: toBlock(handler)]
  objcr:
    var config = [WKWebViewConfiguration new]
    var wkPref = [config preferences]
    var nsYes = [NSNumber numberWithBool: w.debug]
    [wkPref setValue: nsYes, forKey: "developerExtrasEnabled"]
    [wkPref setValue: nsYes, forKey: "fullScreenEnabled"]
    [wkPref setValue: nsYes, forKey: "javaScriptCanAccessClipboard"]
    [wkPref setValue: nsYes, forKey: "DOMPasteAllowed"]
    [config setPreferences: wkPref]

    var userController = [[WKUserContentController alloc] init]
    setAssociatedObject(userController, cast[pointer]($$("webview")), (Id)(w),
                            OBJC_ASSOCIATION_ASSIGN)
    var PrivWKScriptMessageHandler = registerScriptMessageHandler()
    var scriptMessageHandler = [PrivWKScriptMessageHandler new]

    [userController addScriptMessageHandler: scriptMessageHandler, name: "invoke"]

    var userScript = [WKUserScript alloc]
    const source = """window.external = this; invoke = function(arg){ 
                   webkit.messageHandlers.invoke.postMessage(arg); };"""
    [userScript initWithSource: @source, injectionTime: WKUserScriptInjectionTimeAtDocumentStart,
        forMainFrameOnly: 0]
    [userController addUserScript: userScript]

    [config setUserContentController: userController]

    var PrivWKDownloadDelegate = registerDownloadDelegate()
    var downloadDelegate: Id = [PrivWKDownloadDelegate new]

    var processPool = [config processPool]
    [processPool "_setDownloadDelegate": downloadDelegate]
    [config setProcessPool: processPool]

  var PrivNSWindowDelegate = registerWindowDelegate()
  w.priv.windowDelegate = objcr: [PrivNSWindowDelegate new]
  setAssociatedObject(w.priv.windowDelegate, cast[pointer]($$"webview"), (Id)(w),
                           OBJC_ASSOCIATION_ASSIGN)

  var nsTitle = @($w.title)

  var frame: CGRect = CGRectMake(0, 0, w.width, w.height)
  var style = DefaultWindowStyle
  if w.resizable:
    style = style or NSWindowStyleMaskResizable
  objcr: 
    w.priv.window = [NSWindow alloc]
    [w.priv.window initWithContentRect: frame, styleMask: style, backing: NSBackingStoreBuffered, `defer`: 0]
    [w.priv.window autorelease]
    [w.priv.window setTitle: nsTitle]
    [w.priv.window setDelegate: w.priv.windowDelegate]
    [w.priv.window center]
    var PrivWKUIDelegate = registerUIDelegate()
    var uiDel = [[PrivWKUIDelegate alloc] init]

    var PrivWKNavigationDelegate = registerWKNavigationDelegate()
    var navDel = [[PrivWKNavigationDelegate alloc] init]
    w.priv.webview = [WKWebView alloc]

    [w.priv.webview initWithFrame: frame, configuration: config]
    [w.priv.webview setUIDelegate: uiDel]
    [w.priv.webview setNavigationDelegate: navDel]
    let url = $(w.url)
    if "data:text/html;charset=utf-8;base64," in url:
      let html = base64.decode(url.split(",")[1])
      [w.priv.webview loadHTMLString: @html, baseURL: nil]
    else:
      var nsURL = [NSURL URLWithString: @url]
      [w.priv.webview loadRequest: [NSURLRequest requestWithURL: nsURL]]
    
    [w.priv.webview setAutoresizingMask: NSViewWidthSizable.uint or NSViewHeightSizable.uint]
    [w.priv.window setContentView: w.priv.webview]
    [w.priv.window orderFrontRegardless]
    if not isAppBundled():
      [NSApp setActivationPolicy: NSApplicationActivationPolicyRegular]
      [NSApp activateIgnoringOtherApps: YES]

  return 0

proc run*(w: Webview) {.objcr.} =
  var app = [NSApplication sharedApplication]
  [app run]

proc addUserScript(w: Webview, js: string; location: int): void {.objcr.} =
  var userScript = [WKUserScript alloc]
  [userScript initWithSource: @js, injectionTime: location, forMainFrameOnly: 0]
  var config = [w.priv.webview valueForKey: "configuration"]
  var userContentController  = [config valueForKey: "userContentController"]
  [userContentController addUserScript: userScript]

proc addUserScriptAtDocumentStart*(w: Webview, js: string): void =
  w.addUserScript(js, WKUserScriptInjectionTimeAtDocumentStart)

proc addUserScriptAtDocumentEnd*(w: Webview, js: string): void =
  w.addUserScript(js, WKUserScriptInjectionTimeAtDocumentEnd)

proc eval*(w: Webview, js: string): void {.objcr.} =
  [w.priv.webview evaluateJavaScript: @js, completionHandler: nil]

proc setTitle*(w: Webview; title: string) {.objcr.} =
  [w.priv.window setTitle: @title]

type WebviewDispatchCtx {.pure.} = object
  w: Webview
  arg: pointer
  fn: pointer

type WebviewDispatchCtx2 {.pure.} = object
  w: Webview
  arg: pointer
  fn: proc (w: Webview; arg: pointer)

proc webview_dispatch_cb(arg: pointer) {.stdcall.} =
  let context = cast[ptr WebviewDispatchCtx2](arg)
  context.fn(context.w, context.arg)

proc dispatch_async_f(q: pointer; b: pointer; c: pointer){.importc, header: "<dispatch/dispatch.h>".}
proc dispatch_get_main_queue(): pointer{.importc, header: "<dispatch/dispatch.h>".}

proc webview_dispatch*(w: Webview; fn: pointer; arg: pointer) {.stdcall.} =
  var context = create(WebviewDispatchCtx)
  context.w = w
  context.fn = fn
  context.arg = arg
  dispatch_async_f(dispatch_get_main_queue(), context, cast[pointer](webview_dispatch_cb))

proc terminate*(w: Webview): void {.objcr.} =
  var app: Id = [NSApplication sharedApplication]
  [app terminate: app]

proc destroy*(w: Webview) =
  w.terminate()
