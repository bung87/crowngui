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

const DefaultWindowStyle = NSWindowStyleMaskTitled or NSWindowStyleMaskClosable or
                      NSWindowStyleMaskMiniaturizable;
type 
  NSAutoreleasePool = ptr object of NSObject

proc setHtml*(w: Webview; html: string) =
  w.priv.webview.loadHTMLString(@html, nil)

proc navigate*(w: Webview; url: string) {.objcr.} =
  var requestURL = NSURL.URLWithString(@url)
  [requestURL autorelease]
  var request = NSURLRequest.requestWithURL(requestURL)
  [request autorelease]
  w.priv.webview.loadRequest(request)

proc setSize*(w: Webview; width: int; height: int) {.objcr.} =
  let f = w.priv.window.frame
  var frameRect = cast[CGRect](f)
  frameRect.size.width = width.CGFloat
  frameRect.size.height = height.CGFloat
  w.priv.window.setFrame(frameRect, YES)

proc webview_init*(w: Webview): cint {.objcr.} =
  # w.priv.pool = objcr: [NSAutoreleasePool new]
  # objcr: [NSEvent addLocalMonitorForEventsMatchingMask: NSKeyDown, handler: toBlock(handler)]
  var config = WKWebViewConfiguration.alloc().init()#newWKWebViewConfiguration(WKWebViewConfiguration)
  var wkPref = config.preferences
  wkPref.setDeveloperExtrasEnabled(YES)
  wkPref.setFullScreenEnabled(YES)
  wkPref.setJavaScriptCanAccessClipboard(YES)
  wkPref.setDOMPasteAllowed(YES)

  var userController = WKUserContentController.alloc().init()
  setAssociatedObject(userController, cast[pointer]($$("webview")), (Id)(w),
                          OBJC_ASSOCIATION_ASSIGN)
  var PrivWKScriptMessageHandler = registerScriptMessageHandler()
  var scriptMessageHandler = [PrivWKScriptMessageHandler new]
  assert scriptMessageHandler != nil
  assert userController != nil
  let send3 = cast[proc(self:ID; sel: SEL; c: ID, b: NSString){.cdecl,gcsafe.}](objc_msgSend)
  send3(cast[ID](userController), $$"addScriptMessageHandler:name:", scriptMessageHandler, @"invoke")
  const source = """window.external = this; invoke = function(arg){ 
                  webkit.messageHandlers.invoke.postMessage(arg); };"""
  var userScript = WKUserScript.alloc()
  userScript.initWithSource(@source, AtDocumentStart, NO)
  userController.addUserScript(userScript)
  config.setUserContentController(userController)

  # var PrivWKDownloadDelegate = registerDownloadDelegate()
  # var downloadDelegate: Id = [PrivWKDownloadDelegate new]

  # var processPool = [config processPool]
  # [processPool "_setDownloadDelegate": downloadDelegate]
  # [config setProcessPool: processPool]

  var PrivNSWindowDelegate = registerWindowDelegate()
  w.priv.windowDelegate = [PrivNSWindowDelegate new]
  setAssociatedObject(w.priv.windowDelegate, cast[pointer]($$"webview"), (Id)(w),
                          OBJC_ASSOCIATION_ASSIGN)

  var frameRect = CGRectMake(0.float, 0.float, w.width.float, w.height.float)
  var style = DefaultWindowStyle
  if w.resizable:
    style = style or NSWindowStyleMaskResizable
  w.priv.window = NSWindow.alloc()
  w.priv.window.initWithContentRect(frameRect, cast[NSWindowStyleMask](style), NSBackingStoreBuffered, NO)
  [w.priv.window autorelease]
  w.priv.window.setTitle(@($w.title))
  let send = cast[proc(self:ID; sel: SEL; t: ID){.cdecl,gcsafe.}](objc_msgSend)
  send(w.priv.window, $$"setDelegate:", w.priv.windowDelegate)
  w.priv.window.center()
  var PrivWKUIDelegate = registerUIDelegate()
  var uiDel = [PrivWKUIDelegate new]

  var PrivWKNavigationDelegate = registerWKNavigationDelegate()
  var navDel = [PrivWKNavigationDelegate new]

  w.priv.webview = WKWebView.alloc()

  discard initWithFrameAndConfiguration(w.priv.webview, frameRect, config)
  send(w.priv.webview, $$"setUIDelegate:", uiDel)
  send(w.priv.webview, $$"setNavigationDelegate:", navDel)
  let url = $(w.url)
  case w.entryType
  of EntryType.html:
    loadHTMLString(w.priv.webview, @url, nil)
  else:
    var nsURL = NSURL.URLWithString(@url)
    loadRequest(w.priv.webview, NSURLRequest.requestWithURL(nsURL))
  
  w.priv.webview.setAutoresizingMask(cast[NSAutoresizingMaskOptions](NSViewWidthSizable.uint or NSViewHeightSizable.uint))
  w.priv.window.setContentView(cast[NSView](w.priv.webview))
  w.priv.window.orderFrontRegardless()

  return 0

proc run*(w: Webview) {.objcr.} =
  var app = [NSApplication sharedApplication]
  [app run]

proc addUserScript(w: Webview, js: string; location: WKUserScriptInjectionTime): void =
  var userScript = WKUserScript.alloc()
  userScript.initWithSource(@js, location, NO)
  var config = w.priv.webview.configuration
  var userContentController = config.userContentController
  userContentController.addUserScript(userScript)

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
  w.priv.window.setTitle(@title)

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
