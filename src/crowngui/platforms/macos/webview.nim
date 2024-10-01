# import strutils, base64
import std/[macros]
import objc_runtime
import darwin / [app_kit,web_kit, foundation, objc/runtime, objc/blocks, core_graphics/cggeometry]
# import menu
import types
export types
import dialog
export dialog
# import event
# import bundle
import ./message_handler
import ./download_delegate
import ./ui_delegate
import ./navigation_delegate
import ./window_delegate
import ./utils
import ./app_utils
import ../../types


{.passl: "-framework Cocoa -framework WebKit".}

type WKUserScriptInjectionTime {.size: sizeof(uint32).} = enum
  AtDocumentStart = 0
  AtDocumentEnd = 1

const DefaultWindowStyle = NSWindowStyleMaskTitled or NSWindowStyleMaskClosable or
                      NSWindowStyleMaskMiniaturizable;
type 
  NSAutoreleasePool = ptr object of NSObject
  WKUserScript = ptr object of NSObject
  WKWebViewConfiguration  = ptr object of NSObject
  WKUserContentController = ptr object of NSObject
  WKPreferences = ptr object of NSObject
# proc initWithSource*(self: WKUserScript, source: NSString, injectionTime: static[int], forMainFrameOnly: BOOL) {.objc: "initWithSource:injectionTime:forMainFrameOnly:".}
proc preferences(self: WKWebViewConfiguration;): WKPreferences {.objc.}

proc setHtml*(w: Webview; html: string) {.objcr.} =
  [w.priv.webview loadHTMLString: @html, baseURL: nil]

proc navigate*(w: Webview; url: string) {.objcr.} =
  var requestURL = [NSURL URLWithString: @url]
  [requestURL autorelease]
  var request = [NSURLRequest requestWithURL: requestURL]
  [request autorelease]
  [w.priv.webview loadRequest: request]

proc setSize*(w: Webview; width: int; height: int) {.objcr.} =
  let f = [w.priv.window frame]
  var frameRect = cast[CGRect](f)
  frameRect.size.width = width.CGFloat
  frameRect.size.height = height.CGFloat
  [w.priv.window setFrame: frameRect, display: true]

proc alloc*[T](o: typedesc[T]): T {.objc: "alloc".}

proc webview_init*(w: Webview): cint {.objcr.} =
  # w.priv.pool = objcr: [NSAutoreleasePool new]
  # objcr: [NSEvent addLocalMonitorForEventsMatchingMask: NSKeyDown, handler: toBlock(handler)]
  # expandMacros:
  var config = [WKWebViewConfiguration new]
  var wkPref = cast[WKWebViewConfiguration](config).preferences
  var nsYes = NSNumber.withBool(w.debug) # [NSNumber numberWithBool: w.debug]
  # [wkPref setValue: nsYes, forKey: "developerExtrasEnabled"]
  # [wkPref setValue: nsYes, forKey: "fullScreenEnabled"]
  # [wkPref setValue: nsYes, forKey: "javaScriptCanAccessClipboard"]
  # [wkPref setValue: nsYes, forKey: "DOMPasteAllowed"]

  var userController = [WKUserContentController new]
  setAssociatedObject(userController, cast[pointer]($$("webview")), (Id)(w),
                          OBJC_ASSOCIATION_ASSIGN)
  var PrivWKScriptMessageHandler = registerScriptMessageHandler()
  var scriptMessageHandler = [PrivWKScriptMessageHandler new]
  assert scriptMessageHandler != nil
  assert userController != nil
  # [userController addScriptMessageHandler: scriptMessageHandler, name: "invoke"]

  var userScript = [WKUserScript alloc]
  const source = """window.external = this; invoke = function(arg){ 
                  webkit.messageHandlers.invoke.postMessage(arg); };"""
  # [userScript initWithSource: NSString.withUTF8String(source.cstring), injectionTime: AtDocumentStart,
  #     forMainFrameOnly: NO]
  # [userController addUserScript: userScript]

  [config setUserContentController: userController]

  var PrivWKDownloadDelegate = registerDownloadDelegate()
  var downloadDelegate: Id = [PrivWKDownloadDelegate new]

  var processPool = [config processPool]
  # [processPool "_setDownloadDelegate": downloadDelegate]
  [config setProcessPool: processPool]

  var PrivNSWindowDelegate = registerWindowDelegate()
  w.priv.windowDelegate = [PrivNSWindowDelegate new]
  setAssociatedObject(w.priv.windowDelegate, cast[pointer]($$"webview"), (Id)(w),
                          OBJC_ASSOCIATION_ASSIGN)

  var frameRect = CGRectMake(0, 0, w.width, w.height)
  var style = DefaultWindowStyle
  if w.resizable:
    style = style or NSWindowStyleMaskResizable
  w.priv.window = [NSWindow alloc]
  [w.priv.window initWithContentRect: frameRect, styleMask: style, backing: NSBackingStoreBuffered, `defer`: 0]
  [w.priv.window autorelease]
  let setTitle = cast[proc(self:ID; sel: SEL; t: NSString){.cdecl,gcsafe.}](objc_msgSend)
  setTitle(w.priv.window, $$"setTitle:", @($w.title))
  let setDelegate = cast[proc(self:ID; sel: SEL; t: ID){.cdecl,gcsafe.}](objc_msgSend)
  setDelegate(w.priv.window, $$"setDelegate:", w.priv.windowDelegate)
  [w.priv.window center]
  var PrivWKUIDelegate = registerUIDelegate()
  var uiDel = [PrivWKUIDelegate new]

  var PrivWKNavigationDelegate = registerWKNavigationDelegate()
  var navDel = [PrivWKNavigationDelegate new]

  w.priv.webview = cast[ID](WKWebView.alloc())
  
  # let initWithFrame = cast[proc(self:ID; sel: SEL; rect: ID; c: ID){.cdecl,gcsafe.}](objc_msgSend)

  # [w.priv.webview initWithFrame: frameRect, configuration: config]
  
  # initWithFrame(cast[ID](w.priv.webview), $$"initWithFrame:configuration:", cast[ID](frameRect.addr), config)
  let performSend = cast[proc (self: WKWebView; selector: SEL; frame: CGRect;
                                 conf: WKWebViewConfiguration): WKWebView {.
        cdecl, gcsafe.}](objc_msgSend)
  discard performSend(cast[WKWebView](w.priv.webview), $$("initWithFrame:configuration:"), frameRect, cast[WKWebViewConfiguration](config))
  # discard initWithFrameAndConfiguration(cast[WKWebView](w.priv.webview), frameRect, cast[WKWebViewConfiguration](config))
  
  [w.priv.webview setUIDelegate: uiDel]
  [w.priv.webview setNavigationDelegate: navDel]
  let url = $(w.url)
  case w.entryType
  of EntryType.html:
  # if "data:text/html;charset=utf-8;base64," in url:
    # let html = base64.decode(url.split(",")[1])
    [w.priv.webview loadHTMLString: @url, baseURL: nil]
  else:
    var nsURL = [NSURL URLWithString: @url]
    [w.priv.webview loadRequest: [NSURLRequest requestWithURL: nsURL]]
  
  [w.priv.webview setAutoresizingMask: NSViewWidthSizable.uint or NSViewHeightSizable.uint]
  [w.priv.window setContentView: w.priv.webview]
  [w.priv.window orderFrontRegardless]

  return 0

proc run*(w: Webview) {.objcr.} =
  var app = [NSApplication sharedApplication]
  [app run]

proc addUserScript(w: Webview, js: string; location: WKUserScriptInjectionTime): void {.objcr.} =
  var userScript = [WKUserScript alloc]
  [userScript initWithSource: @js, injectionTime: location, forMainFrameOnly: 0]
  var config = [w.priv.webview valueForKey: "configuration"]
  var userContentController  = [config valueForKey: "userContentController"]
  [userContentController addUserScript: userScript]

proc addUserScriptAtDocumentStart*(w: Webview, js: string): void =
  w.addUserScript(js, AtDocumentStart)

proc addUserScriptAtDocumentEnd*(w: Webview, js: string): void =
  w.addUserScript(js, AtDocumentEnd)

proc eval*(w: Webview, js: string): void {.objcr.} =
  [w.priv.webview evaluateJavaScript: @js, completionHandler: nil]

proc eval*[T](w: Webview, js: string, cb: proc(res: T): void): void {.objcr.} =
  let bl = proc (res:ID; err:ID) =
    let isString = cast[bool]([res isKindOfClass:[NSString class]])
    let isNumber = cast[bool]([res isKindOfClass:[NSNumber class]])
    let isArray = cast[bool]([res isKindOfClass:[NSArray class]])
    let isObj = cast[bool]([res isKindOfClass:[NSDictionary class]])
    let isNil = res == nil
    if err != nil:
      let localStr = cast[NSString]([err valueForKey: "localizedDescription"])
      raise newException(CatchableError, $localStr) 
    when T is string:
      if isString:
        let str = $cast[NSString](res)
        cb(str)
      else:
        raise newException(ValueError, "type mismatched")
    elif T is bool:
      if isNumber:
        if strcmp([res objCType], @encode(BOOL)) == 0:
          let v = cast[bool]([res boolValue])
          cb(v)
        else:
          raise newException(ValueError, "type mismatched")
      else:
        raise newException(ValueError, "type mismatched")
    else:
      # TODO: 
      discard

  [w.priv.webview evaluateJavaScript: @js, completionHandler: toBlock(bl)]

proc setTitle*(w: Webview; title: string) {.objcr.} =
  w.title = title
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
  stopRunLoop()

proc destroy*(w: Webview) =
  w.terminate()
