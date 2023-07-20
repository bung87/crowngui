import strutils, base64
import objc_runtime
import darwin / [app_kit, foundation, objc/runtime, objc/blocks, core_graphics/cggeometry]
import menu
import types
export types
import dialog

{.passc: "-DOBJC_OLD_DISPATCH_PROTOTYPES=1 -x objective-c",
    passl: "-framework Cocoa -framework WebKit".}

const WKNavigationActionPolicyDownload = 2
const WKNavigationResponsePolicyAllow = 1
const WKUserScriptInjectionTimeAtDocumentStart = 0
const WKUserScriptInjectionTimeAtDocumentEnd = 1

proc webview_window_will_close*(self: Id; cmd: SEL; notification: Id) =
  var w = getAssociatedObject(self, cast[pointer]($$"webview"))
  # webview_terminate(cast[Webview](w))

proc webview_external_invoke*(self: ID; cmd: SEL; contentController: Id;
                                    message: Id) =
  var w = cast[Webview](getAssociatedObject(contentController, cast[pointer]($$"webview")))
  if (cast[pointer](w) == nil or w.invokeCb == nil):
    return

  objcr:
    var msg = [[message body]UTF8String]
    cast[proc (w: Webview; arg: cstring) {.stdcall.}](w.invokeCb)(w, cast[cstring](msg))

type CompletionHandler4 = proc (): void
# type CompletionHandler5 = proc (c: cint): void
proc make_nav_policy_decision(self: Id; cmd: SEL; webView: Id; response: Id;
                                     decisionHandler: Block[CompletionHandler4]) =
  objcr:
    if [response canShowMIMEType] == cast[Id](0):
      objc_msgSend(cast[Id](decisionHandler), $$"invoke", WKNavigationActionPolicyDownload)
    else:
      objc_msgSend(cast[Id](decisionHandler), $$"invoke", WKNavigationResponsePolicyAllow)

proc setHtml*(w: Webview; html: string) =
  objcr: [w.priv.webview, loadHTMLString: @html, baseURL: nil]

proc navigate*(w: Webview; url: string) =
  objcr:
    var requestURL: Id = [NSURL URLWithString: @url]
    [requestURL autorelease]
    var request = [NSURLRequest requestWithURL: requestURL]
    [request autorelease]
    [w.priv.webview loadRequest: request]

proc webview_reload*(w: Webview) =
  objcr: [w.priv.webview $$"reload"]

proc webview_show*(w: Webview) =
  objcr:
    [w.priv.window reload]
    if cast[bool]([w.priv.window isMiniaturized]):
      [w.priv.window deminiaturize: nil]
    [w.priv.window makeKeyAndOrderFront: nil]

proc webview_hide*(w: Webview) =
  objcr: [w.priv.window orderOut: nil]

proc webview_minimize*(w: Webview) =
  objcr: [w.priv.window miniaturize: nil]

proc webview_close*(w: Webview) =
  objcr: [w.priv.window close]

proc setSize*(w: Webview; width: int; height: int) =
  objcr:
    let f = [w.priv.window frame]
    var frame: CGRect = cast[CGRect](f)
    frame.size.width = width.CGFloat
    frame.size.height = height.CGFloat
    [w.priv.window setFrame: frame, display: true]

proc webview_set_developer_tools_enabled*(w: Webview; enabled: bool) =
  objcr: [[w.priv.window configuration]"_setDeveloperExtrasEnabled": enabled]

proc webview_init*(w: Webview): cint =
  objcr:
    w.priv.pool = [NSAutoreleasePool new]
    [NSApplication sharedApplication]

  var handler = proc (event: Id): Id {.closure.} =
    objcr:
      var flag: NSUInteger = cast[NSUInteger]([event modifierFlags])
      var charactersIgnoringModifiers = [event charactersIgnoringModifiers]
      let isX = cast[Bool]([charactersIgnoringModifiers isEqualToString: @"x"])
      let isC = cast[Bool]([charactersIgnoringModifiers isEqualToString: @"c"])
      let isV = cast[Bool]([charactersIgnoringModifiers isEqualToString: @"v"])
      let isZ = cast[Bool]([charactersIgnoringModifiers isEqualToString: @"z"])
      let isA = cast[Bool]([charactersIgnoringModifiers isEqualToString: @"a"])
      let isY = cast[Bool]([charactersIgnoringModifiers isEqualToString: @"y"])
      if (flag.uint and NSEventModifierFlagCommand.uint) > 0:
        if isX == Yes:
          let cut = cast[Bool]([NSApp "sendAction:cut:to": nil, `from`: NSApp])
          if cut:
            return nil
        elif isC:
          let copy = cast[Bool]([NSApp "sendAction:copy:to": nil, `from`: NSApp])
          if copy:
            return nil
        elif isV:
          let paste = cast[Bool]([NSApp "sendAction:paste:t:": nil, `from`: NSApp])
          if paste:
            return nil
        elif isZ:
          let undo = cast[Bool]([NSApp "sendAction:undo:to": nil, `from`: NSApp])
          if undo:
            return nil
        elif isA:
          let selectAll = cast[Bool]([NSApp "sendAction:selectAll:to": nil, `from`: NSApp])
          if selectAll:
            return nil
      elif (flag.uint and NSEventModifierFlagDeviceIndependentFlagsMask.uint) == (NSEventModifierFlagCommand.uint or
          NSEventModifierFlagShift.uint):
        let isY = cast[Bool]([charactersIgnoringModifiers isEqualToString: @"y"])
        if isY:
          let redo = cast[Bool]([NSApp "sendAction:redo:to": nil, `from`: NSApp])
          if redo:
            return nil
      return event
  objcr: [NSEvent addLocalMonitorForEventsMatchingMask: NSKeyDown, handler: toBlock(handler)]
  var PrivWKScriptMessageHandler = allocateClassPair(getClass("NSObject"), "PrivWKScriptMessageHandler", 0)
  discard  addMethod(PrivWKScriptMessageHandler, $$"userContentController:didReceiveScriptMessage:", webview_external_invoke)
  registerClassPair(PrivWKScriptMessageHandler)
  var scriptMessageHandler: Id = objcr: [PrivWKScriptMessageHandler new]

  var PrivWKDownloadDelegate = allocateClassPair(getClass("NSObject"), "PrivWKDownloadDelegate", 0)
  discard addMethod(
      PrivWKDownloadDelegate,
      $$"_download:decideDestinationWithSuggestedFilename:completionHandler:",
      run_save_panel)
  # discard addMethod(PrivWKDownloadDelegate,registerName("_download:didFailWithError:"),cast[IMP](download_failed), "v@:@@")
  registerClassPair(PrivWKDownloadDelegate)
  var downloadDelegate: Id = objcr: [PrivWKDownloadDelegate new]

  var PrivWKPreferences = allocateClassPair(getClass("WKPreferences"), "PrivWKPreferences", 0)
  var typ = objc_property_attribute_t(name: "T".cstring, value: "c".cstring)
  var ownership = objc_property_attribute_t(name: "N".cstring, value: "".cstring)
  replaceProperty(PrivWKPreferences, "developerExtrasEnabled", [typ, ownership])
  registerClassPair(PrivWKPreferences)
  

  objcr:
    var config: Id = [WKWebViewConfiguration new]
    var wkPref = objc_msgSend(ID(getClass("PrivWKPreferences")), $$"new")
    [wkPref setValue: [NSNumber numberWithBool: w.debug], forKey: "developerExtrasEnabled"]
    [config setPreferences: wkPref]

    var userController: Id = [WKUserContentController new]
    setAssociatedObject(userController, cast[pointer]($$("webview")), (Id)(w),
                            OBJC_ASSOCIATION_ASSIGN)
    [userController addScriptMessageHandler: scriptMessageHandler, name: "invoke"]
    var windowExternalOverrideScript: Id = [WKUserScript alloc]
    const source = """window.external = this; invoke = function(arg){ 
                   webkit.messageHandlers.invoke.postMessage(arg); };"""
    [windowExternalOverrideScript initWithSource: @(source), injectionTime: WKUserScriptInjectionTimeAtDocumentStart,
        forMainFrameOnly: 0]
    [userController addUserScript: windowExternalOverrideScript]
    [config setUserContentController: userController]

    var processPool: Id = [config processPool]
    [processPool "_setDownloadDelegate": downloadDelegate]
    [config setProcessPool: processPool]

  var PrivNSWindowDelegate = allocateClassPair(getClass("NSObject"),
                                                    "PrivNSWindowDelegate", 0)
  discard addProtocol(PrivNSWindowDelegate, getProtocol("NSWindowDelegate"))
  discard replaceMethod(PrivNSWindowDelegate, $$"windowWillClose:", webview_window_will_close)
  registerClassPair(PrivNSWindowDelegate);

  w.priv.windowDelegate = objcr: [PrivNSWindowDelegate new]

  setAssociatedObject(w.priv.windowDelegate, cast[pointer]($$"webview"), (Id)(w),
                           OBJC_ASSOCIATION_ASSIGN)
  proc CGRectMake(x, y, w, h: SomeNumber): CGRect =
    result = CGRect(origin: CGPoint(x: x.CGFloat, y: y.CGFloat), size: CGSize(width: w.CGFloat, height: h.CGFloat))
  objcr:
    var nsTitle = @($w.title)
    var r: CGRect = CGRectMake(0, 0, w.width, w.height)
    var style = NSWindowStyleMaskTitled or NSWindowStyleMaskClosable or
                       NSWindowStyleMaskMiniaturizable;
    if w.resizable:
      style = style or NSWindowStyleMaskResizable
    w.priv.window = [NSWindow alloc]
    [w.priv.window initWithContentRect: r, styleMask: style, backing: NSBackingStoreBuffered, `defer`: 0]
    [w.priv.window autorelease]
    [w.priv.window setTitle: nsTitle]
    [w.priv.window setDelegate: w.priv.windowDelegate]
    [w.priv.window center]
    

  var PrivWKUIDelegate = allocateClassPair(getClass("NSObject"), "PrivWKUIDelegate", 0)
  discard addProtocol(PrivWKUIDelegate, getProtocol("WKUIDelegate"))
  discard addMethod(PrivWKUIDelegate,
                  $$"webView:runOpenPanelWithParameters:initiatedByFrame:completionHandler:",
                  run_open_panel)
  discard addMethod(PrivWKUIDelegate,
                  $$"webView:runJavaScriptAlertPanelWithMessage:initiatedByFrame:completionHandler:",
                  run_alert_panel)
  discard addMethod(
      PrivWKUIDelegate,
      $$"webView:runJavaScriptConfirmPanelWithMessage:initiatedByFrame:completionHandler:",
      run_confirmation_panel)
  registerClassPair(PrivWKUIDelegate)
  var uiDel: Id = objcr: [PrivWKUIDelegate new]

  var PrivWKNavigationDelegate = allocateClassPair(
      getClass("NSObject"), "PrivWKNavigationDelegate", 0)
  discard addProtocol(PrivWKNavigationDelegate, getProtocol("WKNavigationDelegate"))
  discard addMethod(
      PrivWKNavigationDelegate,
      $$"webView:decidePolicyForNavigationResponse:decisionHandler:",
      make_nav_policy_decision)
  registerClassPair(PrivWKNavigationDelegate)
  objcr:
    var navDel: Id = [PrivWKNavigationDelegate new]
    w.priv.webview = [WKWebView alloc]
    [w.priv.webview initWithFrame: r, configuration: config]
    [w.priv.webview setUIDelegate: uiDel]
    [w.priv.webview setNavigationDelegate: navDel]
    let url = $(w.url)
    if "data:text/html;charset=utf-8;base64," in url:
      let html = base64.decode(url.split(",")[1])
      [w.priv.webview loadHTMLString: @html, baseURL: nil]
    else:
      var nsURL: Id = [NSURL URLWithString: @url]
      [w.priv.webview loadRequest: [NSURLRequest requestWithURL: nsURL]]
    [w.priv.webview setAutoresizesSubviews: 1]
    [w.priv.webview setAutoresizingMask: NSViewWidthSizable.uint or NSViewHeightSizable.uint]
    [[w.priv.window contentView]addSubview: w.priv.webview]
    [w.priv.window orderFrontRegardless]
    [[NSApplication sharedApplication]setActivationPolicy: NSApplicationActivationPolicyRegular]

  return 0

# proc webview_loop*(w: Webview; blocking: cint): cint =
#   objcr:
#     var until: Id = if blocking > 0: [NSDate distantFuture] else: [NSDate distantPast]
#     [NSApplication sharedApplication]
#     var event: Id = [NSApp nextEventMatchingMask: culong.high, untilDate: until, inMode: "kCFRunLoopDefaultMode", dequeue: true]
#     if cast[pointer](event) != nil:
#       [NSApp sendEvent: event]
#     return w.priv.should_exit
proc run*(w:Webview) =
  objcr:
    var app: Id = [NSApplication sharedApplication]
    [app run]

proc addUserScript(w:Webview, js:string; location: int): void =
  objcr:
    var userScript:Id = [WKUserScript alloc]
    [userScript initWithSource: @js,injectionTime: location,forMainFrameOnly: 0]
    var config:Id = [w.priv.webview valueForKey: "configuration"]
    var userContentController:Id  = [config valueForKey: "userContentController"]
    [userContentController addUserScript: userScript]

proc addUserScriptAtDocumentStart*(w:Webview, js:string): void =
  w.addUserScript(js, WKUserScriptInjectionTimeAtDocumentStart)

proc addUserScriptAtDocumentEnd*(w:Webview, js:string): void =
  w.addUserScript(js, WKUserScriptInjectionTimeAtDocumentEnd)

proc eval*(w:Webview, js:string): void =
  objcr:
    [w.priv.webview evaluateJavaScript: @js, completionHandler: nil]

proc setTitle*(w: Webview; title: string) =
  objcr: [w.priv.window setTitle: @title]

proc webview_set_fullscreen*(w: Webview; fullscreen: int) =
  objcr:
    var windowStyleMask = cast[NSWindowStyleMask]([w.priv.window styleMask])
    var b: int = if (windowStyleMask.uint and NSWindowStyleMaskFullScreen.uint) == NSWindowStyleMaskFullScreen.uint: 1 else: 0
    if b != fullscreen:
      [w.priv.window toggleFullScreen: nil]

proc webview_set_iconify*(w: Webview; iconify: int) {.objcr.}  =
  if iconify > 0:
    [w.priv.window miniaturize: nil]
  else:
    [w.priv.window deminiaturize: nil]

proc webview_launch_external_URL*(w: Webview; uri: string) {.objcr.} =
  var url: Id = [NSURL URLWithString: @uri]
  [[NSWorkspace sharedWorkspace]openURL: url]

proc webview_set_color*(w: Webview; r, g, b, a: uint8) {.objcr.} =
  var color: Id = [NSColor colorWithRed: r.float64 / 255.0, green: g.float64 / 255.0, blue: b.float64 / 255.0,
      alpha: a.float64 / 255.0]
  [w.priv.window setBackgroundColor: color]

  if (0.5 >= ((r.float64 / 255.0 * 299.0) + (g.float64 / 255.0 * 587.0) + (b.float64 / 255.0 * 114.0)) /
                1000.0):
    [w.priv.window setAppearance: [NSAppearance appearanceNamed: "NSAppearanceNameVibrantDark"]]
  else:
    [w.priv.window setAppearance: [NSAppearance appearanceNamed: "NSAppearanceNameVibrantLight"]]
    [w.priv.window setOpaque: 0]
    [w.priv.window setTitlebarAppearsTransparent: 1]
    [w.priv.window "_setDrawsBackground": 0]



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

proc terminate*(w: Webview): void =
  objcr:
    var app: Id = [NSApplication sharedApplication]
    [app terminate: app]

proc destroy*(w: Webview) =
  w.terminate()
