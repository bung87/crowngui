import objc_runtime
import darwin / [app_kit, foundation, objc/runtime, objc/blocks, core_graphics/cggeometry]
import menu
import macros, os, strutils, base64
var NSApp {.importc.}: ID
{.passc: "-DOBJC_OLD_DISPATCH_PROTOTYPES=1 -x objective-c",
    passl: "-framework Cocoa -framework WebKit".}
#include <objc/objc-runtime.h>
#include <CoreGraphics/CoreGraphics.h>
#include <Block.h>
#include <limits.h>
const NSKeyDown = (1 shl 10)
const NSEventModifierFlagDeviceIndependentFlagsMask = 0xffff0000.culong
const WEBVIEW_DIALOG_FLAG_FILE = (0 shl 0)
const WEBVIEW_DIALOG_FLAG_DIRECTORY = (1 shl 0)

const WEBVIEW_DIALOG_FLAG_INFO = (1 shl 1)
const WEBVIEW_DIALOG_FLAG_WARNING = (2 shl 1)
const WEBVIEW_DIALOG_FLAG_ERROR = (3 shl 1)
const WEBVIEW_DIALOG_FLAG_ALERT_MASK = (3 shl 1)
const NSAlertStyleWarning = 0
const NSAlertStyleCritical = 2
const NSWindowStyleMaskResizable = 8
const NSWindowStyleMaskMiniaturizable = 4
const NSWindowStyleMaskTitled = 1
const NSWindowStyleMaskClosable = 2
const NSWindowStyleMaskFullScreen = (1 shl 14)
const NSViewWidthSizable = 2
const NSViewHeightSizable = 16
const NSBackingStoreBuffered = 2
# const NSEventMaskAny = ULONG_MAX
const NSEventModifierFlagCommand = (1 shl 20)
const NSEventModifierFlagShift = (1 shl 17)
const NSEventModifierFlagOption = (1 shl 19)
const NSAlertStyleInformational = 1
const NSAlertFirstButtonReturn = 1000
const WKNavigationActionPolicyDownload = 2
const NSModalResponseOK = 1
const WKNavigationResponsePolicyAllow = 1
const WKUserScriptInjectionTimeAtDocumentStart = 0
const WKUserScriptInjectionTimeAtDocumentEnd = 1
const NSApplicationActivationPolicyRegular = 0
const headerC = currentSourcePath.parentDir.parentDir.parentDir / "webview.h"
proc webview_external_invoke(self: Id, cmd: Sel, contentController: Id, message: Id) {.
    importc: "webview_external_invoke", header: headerC.}
proc webview_check_url(s: cstring): cstring {.importc: "webview_check_url", header: headerC.}
type
  Webview* = ptr WebviewObj
  ExternalInvokeCb* = proc (w: Webview; arg: cstring) ## External CallBack Proc
  WebviewPrivObj {.importc: "struct webview_priv", header: headerC, bycopy.} = object
    when defined(macosx):
      pool: ID
      window: ID
      webview: ID
      windowDelegate: ID
      should_exit: cint
  WebviewObj* {.importc: "struct webview", header: headerC, bycopy.} = object ## WebView Type
    url* {.importc: "url".}: cstring                                          ## Current URL
    title* {.importc: "title".}: cstring                                      ## Window Title
    width* {.importc: "width".}: cint                                         ## Window Width
    height* {.importc: "height".}: cint                                       ## Window Height
    resizable* {.importc: "resizable".}: cint ## `true` to Resize the Window, `false` for Fixed size Window
    debug* {.importc: "debug".}: cint                                         ## Debug is `true` when not build for Release
    invokeCb {.importc: "external_invoke_cb".}: pointer                       ## Callback proc js:window.external.invoke
    priv {.importc: "priv".}: WebviewPrivObj
    userdata {.importc: "userdata".}: pointer
  WebviewDialogType = enum
    WEBVIEW_DIALOG_TYPE_OPEN, WEBVIEW_DIALOG_TYPE_SAVE, WEBVIEW_DIALOG_TYPE_ALERT



proc webview_terminate*(w: Webview) =
  w.priv.should_exit = 1

proc webview_window_will_close*(self: Id; cmd: SEL; notification: Id) =
  var w = getAssociatedObject(self, cast[pointer]($$"webview"))
  webview_terminate(cast[Webview](w))

# proc webview_external_invoke*(self: ID; cmd: SEL; contentController: Id;
#                                     message: Id) =
#   var w = getAssociatedObject(contentController, cast[pointer]($$"webview"))
#   if (cast[pointer](w) == nil or cast[Webview](w).external_invoke_cb == nil):
#     return

#   objcr:
#     var msg = [[message body]UTF8String]
#     cast[Webview](w).external_invoke_cb(cast[Webview](w), cast[cstring](msg))

type CompletionHandler = proc (Id: Id): void

proc `==`(x, y: Id): bool = cast[pointer](x) == cast[pointer](y)

proc run_open_panel(self: Id; cmd: SEL; webView: Id; parameters: Id;
                           frame: Id; completionHandler: Block[CompletionHandler]) =
  objcr:
    var openPanel = [NSOpenPanel openPanel]
    [openPanel setAllowsMultipleSelection, [parameters allowsMultipleSelection]]
    [openPanel setCanChooseFiles: 1]
    let b2 = toBlock() do(r: Id):
      if r == cast[Id](NSModalResponseOK):
        objc_msgSend(cast[Id](completionHandler), $$"invoke", objc_msgSend(openPanel, $$("URLs")))
      else:
        objc_msgSend(cast[Id](completionHandler), $$"invoke", nil)
    [openPanel beginWithCompletionHandler: b2]

type CompletionHandler2 = proc (allowOverwrite: int; destination: Id): void

proc run_save_panel(self: Id; cmd: SEL; download: Id; filename: Id; completionHandler: Block[CompletionHandler2]) =
  objcr:
    var savePanel = [NSSavePanel savePanel]
    [savePanel setCanCreateDirectories: 1]
    [savePanel setNameFieldStringValue: filename]
    let blk = toBlock() do(r: Id):
      if r == cast[Id](NSModalResponseOK):
        var url: Id = objc_msgSend(savePanel, $$"URL")
        var path: Id = objc_msgSend(url, $$"path")
        objc_msgSend(cast[Id](completionHandler), $$"invoke", 1, path)
      else:
        objc_msgSend(cast[Id](completionHandler), $$"invoke", No, nil)

    [savePanel beginWithCompletionHandler: blk]

type CompletionHandler3 = proc (b: bool): void
proc run_confirmation_panel(self: Id; cmd: SEL; webView: Id; message: Id;
                                   frame: Id; completionHandler: Block[CompletionHandler3]) =
  objcr:
    var alert: Id = [NSAlert new]
    [alert setIcon: [NSImage imageNamed: "NSCaution"]]
    [alert setShowsHelp: 0]
    [alert setInformativeText: message]
    [alert addButtonWithTitle: "OK"]
    [alert addButtonWithTitle: "Cancel"]
    if [alert runModal] == cast[ID](NSAlertFirstButtonReturn):
      objc_msgSend(cast[Id](completionHandler), $$"invoke", true)
    else:
      objc_msgSend(cast[Id](completionHandler), $$"invoke", false)
    [alert release]

type CompletionHandler4 = proc (): void
proc run_alert_panel(self: Id; cmd: SEL; webView: Id; message: Id; frame: Id;
                            completionHandler: Block[CompletionHandler4]) =
  objcr:
    var alert: Id = [NSAlert new]
    [alert setIcon: [NSImage imageNamed: NSCaution]]
    [alert setShowsHelp: 0]
    [alert setInformativeText: message]
    [alert addButtonWithTitle: "OK"]
    [alert runModal]
    [alert release]
    objc_msgSend(cast[Id](completionHandler), $$"invoke")

# static void download_failed(Id self, SEL cmd, Id download, Id error) {
#   printf("%s",
#          (const char *)objc_msgSend(
#              objc_msgSend(error, registerName("localizedDescription")),
#              registerName("UTF8String")));
# }
type CompletionHandler5 = proc (c: cint): void
proc make_nav_policy_decision(self: Id; cmd: SEL; webView: Id; response: Id;
                                     decisionHandler: Block[CompletionHandler4]) =
  objcr:
    if [response canShowMIMEType] == cast[Id](0):
      objc_msgSend(cast[Id](decisionHandler), $$"invoke", WKNavigationActionPolicyDownload)
    else:
      objc_msgSend(cast[Id](decisionHandler), $$"invoke", WKNavigationResponsePolicyAllow)

proc webview_load_HTML*(w: Webview; html: cstring) =
  objcr: [w.priv.webview, loadHTMLString: @($html), baseURL: nil]

proc webview_load_URL*(w: Webview; url: cstring) =
  objcr:
    var requestURL: Id = [NSURL URLWithString: @($url)]
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

proc webview_set_size*(w: Webview; width: int; height: int) =
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
      let isX: Bool = cast[Bool]([charactersIgnoringModifiers isEqualToString: @"x"])
      let isC: Bool = cast[Bool]([charactersIgnoringModifiers isEqualToString: @"c"])
      let isV: Bool = cast[Bool]([charactersIgnoringModifiers isEqualToString: @"v"])
      let isZ: Bool = cast[Bool]([charactersIgnoringModifiers isEqualToString: @"z"])
      let isA: Bool = cast[Bool]([charactersIgnoringModifiers isEqualToString: @"a"])
      let isY: Bool = cast[Bool]([charactersIgnoringModifiers isEqualToString: @"y"])
      if (flag.uint and NSEventModifierFlagCommand) > 0:
        if isX == Yes:
          let cut: Bool = cast[Bool]([NSApp "sendAction:cut:to": nil, `from`: NSApp])
          if cut:
            return nil
        elif isC:
          let copy: Bool = cast[Bool]([NSApp "sendAction:copy:to": nil, `from`: NSApp])
          if copy:
            return nil
        elif isV:
          let paste: Bool = cast[Bool]([NSApp "sendAction:paste:t:": nil, `from`: NSApp])
          if paste:
            return nil
        elif isZ:
          let undo: Bool = cast[Bool]([NSApp "sendAction:undo:to": nil, `from`: NSApp])
          if undo:
            return nil
        elif isA:
          let selectAll: Bool = cast[Bool]([NSApp "sendAction:selectAll:to": nil, `from`: NSApp])
          if selectAll:
            return nil
      elif (flag.uint and NSEventModifierFlagDeviceIndependentFlagsMask) == (NSEventModifierFlagCommand or
          NSEventModifierFlagShift):
        let isY: Bool = cast[Bool]([charactersIgnoringModifiers isEqualToString: @"y"])
        if isY:
          let redo: Bool = cast[Bool]([NSApp "sendAction:redo:to": nil, `from`: NSApp])
          if redo:
            return nil
      return event
  objcr: [NSEvent addLocalMonitorForEventsMatchingMask: NSKeyDown, handler: toBlock(handler)]
  var PrivWKScriptMessageHandler: Class = allocateClassPair(getClass("NSObject"), "PrivWKScriptMessageHandler", 0)
  discard addMethod(PrivWKScriptMessageHandler, $$"userContentController:didReceiveScriptMessage:", cast[
      IMP](webview_external_invoke), "v@:@@")
  registerClassPair(PrivWKScriptMessageHandler)

  var scriptMessageHandler: Id = objcr: [PrivWKScriptMessageHandler new]

  var PrivWKDownloadDelegate: Class = allocateClassPair(getClass("NSObject"), "PrivWKDownloadDelegate", 0)
  discard addMethod(
      PrivWKDownloadDelegate,
      registerName("_download:decideDestinationWithSuggestedFilename:completionHandler:"),
      cast[IMP](run_save_panel), "v@:@@?");
  # discard addMethod(PrivWKDownloadDelegate,registerName("_download:didFailWithError:"),cast[IMP](download_failed), "v@:@@")
  registerClassPair(PrivWKDownloadDelegate);
  var downloadDelegate: Id = objcr: [PrivWKDownloadDelegate new]

  var PrivWKPreferences: Class = allocateClassPair(getClass("WKPreferences"), "PrivWKPreferences", 0)
  var typ = objc_property_attribute_t(name: "T".cstring, value: "c".cstring)
  var ownership = objc_property_attribute_t(name: "N".cstring, value: "".cstring)
  replaceProperty(PrivWKPreferences, "developerExtrasEnabled", [typ, ownership])
  registerClassPair(PrivWKPreferences);
  var wkPref: Id = objcr: [PrivWKPreferences new]

  objcr:
    [wkPref setValue: [NSNumber numberWithBool: w.debug], forKey: "developerExtrasEnabled"]
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
    var config: Id = [WKWebViewConfiguration new]
    var processPool: Id = [config processPool]
    [processPool "_setDownloadDelegate": downloadDelegate]
    [config setProcessPool: processPool]
    [config setUserContentController: userController]
    [config setPreferences: wkPref]

  var PrivNSWindowDelegate: Class = allocateClassPair(getClass("NSObject"),
                                                    "PrivNSWindowDelegate", 0)
  discard addProtocol(PrivNSWindowDelegate, getProtocol("NSWindowDelegate"))
  discard replaceMethod(PrivNSWindowDelegate, registerName("windowWillClose:"), cast[IMP](webview_window_will_close), "v@:@")
  registerClassPair(PrivNSWindowDelegate);

  w.priv.windowDelegate = objc_msgSend(cast[ID](PrivNSWindowDelegate), $$"new")

  setAssociatedObject(w.priv.windowDelegate, cast[pointer]($$"webview"), (Id)(w),
                           OBJC_ASSOCIATION_ASSIGN)
  proc CGRectMake(x, y, w, h: SomeNumber): CGRect =
    result = CGRect(origin: CGPoint(x: x.CGFloat, y: y.CGFloat), size: CGSize(width: w.CGFloat, height: h.CGFloat))
  objcr:
    var nsTitle = @($w.title)
    var r: CGRect = CGRectMake(0, 0, w.width, w.height)
    var style = NSWindowStyleMaskTitled or NSWindowStyleMaskClosable or
                       NSWindowStyleMaskMiniaturizable;
    if w.resizable > 0:
      style = style or NSWindowStyleMaskResizable
    w.priv.window = [NSWindow alloc]
    [w.priv.window initWithContentRect: r, styleMask: style, backing: NSBackingStoreBuffered, `defer`: 0]
    [w.priv.window autorelease]
    [w.priv.window setTitle: nsTitle]
    [w.priv.window setDelegate: w.priv.windowDelegate]
    [w.priv.window center]

  var PrivWKUIDelegate: Class = allocateClassPair(getClass("NSObject"), "PrivWKUIDelegate", 0)
  discard addProtocol(PrivWKUIDelegate, getProtocol("WKUIDelegate"))
  discard addMethod(PrivWKUIDelegate,
                  $$"webView:runOpenPanelWithParameters:initiatedByFrame:completionHandler:",
                  cast[IMP](run_open_panel), "v@:@@@?")
  discard addMethod(PrivWKUIDelegate,
                  $$"webView:runJavaScriptAlertPanelWithMessage:initiatedByFrame:completionHandler:",
                  cast[IMP](run_alert_panel), "v@:@@@?")
  discard addMethod(
      PrivWKUIDelegate,
      $$"webView:runJavaScriptConfirmPanelWithMessage:initiatedByFrame:completionHandler:",
      cast[IMP](run_confirmation_panel), "v@:@@@?")
  registerClassPair(PrivWKUIDelegate)
  var uiDel: Id = objcr: [PrivWKUIDelegate new]

  var PrivWKNavigationDelegate: Class = allocateClassPair(
      getClass("NSObject"), "PrivWKNavigationDelegate", 0)
  discard addProtocol(PrivWKNavigationDelegate, getProtocol("WKNavigationDelegate"))
  discard addMethod(
      PrivWKNavigationDelegate,
      $$"webView:decidePolicyForNavigationResponse:decisionHandler:",
      cast[IMP](make_nav_policy_decision), "v@:@@?")
  registerClassPair(PrivWKNavigationDelegate)
  objcr:
    var navDel: Id = [PrivWKNavigationDelegate new]
    w.priv.webview = [WKWebView alloc]
    [w.priv.webview initWithFrame: r, configuration: config]
    [w.priv.webview setUIDelegate: uiDel]
    [w.priv.webview setNavigationDelegate: navDel]
    let url = $webview_check_url(w.url)
    if "data:text/html;charset=utf-8;base64," in url:
      let html = base64.decode(url.split(",")[1])
      [w.priv.webview loadHTMLString: @(html), baseURL: nil]
    else:
      var nsURL: Id = [NSURL URLWithString: @(url)]
      [w.priv.webview loadRequest: [NSURLRequest requestWithURL: nsURL]]
    [w.priv.webview setAutoresizesSubviews: 1]
    [w.priv.webview setAutoresizingMask: NSViewWidthSizable or NSViewHeightSizable]
    [[w.priv.window contentView]addSubview: w.priv.webview]
    [w.priv.window orderFrontRegardless]
    [[NSApplication sharedApplication]setActivationPolicy: NSApplicationActivationPolicyRegular]
  w.priv.should_exit = 0
  return 0

proc webview_loop*(w: Webview; blocking: cint): cint =
  objcr:
    var until: Id = if blocking > 0: [NSDate distantFuture] else: [NSDate distantPast]
    [NSApplication sharedApplication]
    var event: Id = [NSApp nextEventMatchingMask: culong.high, untilDate: until, inMode: "kCFRunLoopDefaultMode", dequeue: true]
    if cast[pointer](event) != nil:
      [NSApp sendEvent: event]
    return w.priv.should_exit




# proc webview_eval*(w:Webview, js:cstring) :cint =
#   objcr:
#     var userScript:Id = [WKUserScript alloc]
#     [userScript initWithSource: @($js),injectionTime: WKUserScriptInjectionTimeAtDocumentEnd,forMainFrameOnly: 0]
#     var config:Id = [w.priv.webview valueForKey:"configuration"]
#     var userContentController:Id  = [config valueForKey:"userContentController"]
#     [userContentController addUserScript:userScript]
#   return 0.cint

proc webview_set_title*(w: Webview; title: cstring) =
  objcr: [w.priv.window setTitle: @($title)]

proc webview_set_fullscreen*(w: Webview; fullscreen: int) =
  objcr:
    var windowStyleMask: culong = cast[culong]([w.priv.window styleMask])
    var b: int = if (windowStyleMask and NSWindowStyleMaskFullScreen) == NSWindowStyleMaskFullScreen: 1 else: 0
    if b != fullscreen:
      [w.priv.window toggleFullScreen: nil]

proc webview_set_iconify*(w: Webview; iconify: int) =
  objcr:
    if iconify > 0:
      [w.priv.window miniaturize: nil]
    else:
      [w.priv.window deminiaturize: nil]

proc webview_launch_external_URL*(w: Webview; uri: cstring) =
  objcr:
    var url: Id = [NSURL URLWithString: @($webview_check_url(uri))]
    [[NSWorkspace sharedWorkspace]openURL: url]

proc webview_set_color*(w: Webview; r, g, b, a: uint8) =
  objcr:
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

proc webview_dialog*(w: Webview; dlgtype: WebviewDialogType; flags: int;
                                title: cstring; arg: cstring; result: var cstring; resultsz: csize_t) =
  objcr:
    if (dlgtype == WEBVIEW_DIALOG_TYPE_OPEN or
        dlgtype == WEBVIEW_DIALOG_TYPE_SAVE):
      var panel = cast[Id](getClass("NSSavePanel"))

      if (dlgtype == WEBVIEW_DIALOG_TYPE_OPEN):
        var openPanel = [NSOpenPanel openPanel]
        if (flags and WEBVIEW_DIALOG_FLAG_DIRECTORY) > 0:
          [openPanel setCanChooseFiles: 0]
          [openPanel setCanChooseDirectories: 1]
        else:
          [openPanel setCanChooseFiles: 1]
          [openPanel setCanChooseDirectories: 0]
          [openPanel setResolvesAliases: 0]
          [openPanel setAllowsMultipleSelection: 0]
        panel = openPanel
      else:
        panel = [NSSavePanel savePanel]
      [panel setCanCreateDirectories: 1]
      [panel setShowsHiddenFiles: 1]
      [panel setExtensionHidden: 0]
      [panel setCanSelectHiddenExtension: 0]
      [panel setTreatsFilePackagesAsDirectories: 1]
      let blk = toBlock() do (r: Id):
        objcr:
          [[NSApplication sharedApplication]stopModalWithCode: r]

      [panel beginSheetModalForWindow: w.priv.window, completionHandler: blk]
      if [[NSApplication sharedApplication]runModalForWindow: panel] == cast[Id](NSModalResponseOK):
        var url: Id = [panel URL]
        var path: Id = [url path]
        var filename: cstring = cast[cstring]([path UTF8String])
        copyMem(result, filename, resultsz)
        # strlcpy(result, filename, resultsz)

      elif (dlgtype == WEBVIEW_DIALOG_TYPE_ALERT):
        var a: Id = [NSAlert new]
        case flags and WEBVIEW_DIALOG_FLAG_ALERT_MASK:
        of WEBVIEW_DIALOG_FLAG_INFO:
          [a setAlertStyle: NSAlertStyleInformational]
        of WEBVIEW_DIALOG_FLAG_WARNING:
          # printf("Warning\n");
          [a setAlertStyle: NSAlertStyleWarning]
        of WEBVIEW_DIALOG_FLAG_ERROR:
          # printf("Error\n");
          [a setAlertStyle: NSAlertStyleCritical]
        else:
          discard
        [a setShowsHelp: 0]
        [a setShowsSuppressionButton: 0]
        [a setMessageText: @($title)]
        [a setInformativeText: @($arg)]
        [a addButtonWithTitle: "OK"]
        [a runModal]
        [a release]

type webview_dispatch_arg[T] = object
  w: Webview
  arg: pointer
  fn: T

type webview_dispatch_arg2 = object
  w: Webview
  arg: pointer
  fn: proc (w: Webview; arg: pointer)

proc webview_dispatch_cb*(arg: pointer) =
  # struct webview_dispatch_arg *context = (struct webview_dispatch_arg *)arg;
  let context = cast[webview_dispatch_arg2](arg)
  context.fn(context.w, context.arg)
  # cfree(context)

proc dispatch_async_f(q: pointer; b: pointer; c: pointer){.importc, header: "<dispatch/dispatch.h>".}
proc dispatch_get_main_queue(): pointer{.importc, header: "<dispatch/dispatch.h>".}

proc webview_dispatch*[T](w: Webview; webview_dispatch_fn: T; arg: pointer) =
  var context = webview_dispatch_arg[T](w: w, fn: webview_dispatch_fn, arg: arg)
  dispatch_async_f(dispatch_get_main_queue(), context.addr, cast[pointer](webview_dispatch_cb))

proc webview_exit*(w: Webview) =
  objcr:
    var app: Id = [NSApplication sharedApplication]
    [app terminate: app]

# proc webview_print_log*(s:cstring) = printf("%s\n", s)
# proc webview*(title:cstring, url:cstring,  width:cint,
#                          height:cint,  resizable:cint):cint =
#   var webview:Webview
#   webview.title = title
#   webview.url = url
#   echo url
#   webview.width = width
#   webview.height = height
#   webview.resizable = resizable
#   let r = webview_init(webview)
#   if r != 0:
#     return r

#   while (webview_loop(webview, 1) == 0) : discard
#   webview_exit(webview);
#   return 0
