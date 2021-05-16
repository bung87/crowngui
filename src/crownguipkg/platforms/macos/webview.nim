import objc_runtime
import darwin / [app_kit, foundation,objc/runtime ,objc/blocks,core_graphics/cggeometry]
import menu
var NSApp {.importc.}: ID
{.passc: "-DOBJC_OLD_DISPATCH_PROTOTYPES=1 -x objective-c",
    passl: "-framework Cocoa -framework WebKit".}

const NSKeyDown = (1 shl 10)
const NSEventModifierFlagDeviceIndependentFlagsMask = 0xffff0000.culong
# const WEBVIEW_DIALOG_FLAG_FILE = (0 shl 0)
# const WEBVIEW_DIALOG_FLAG_DIRECTORY= (1 shl 0)

# const WEBVIEW_DIALOG_FLAG_INFO= (1 shl 1)
# const WEBVIEW_DIALOG_FLAG_WARNING= (2 shl 1)
# const WEBVIEW_DIALOG_FLAG_ERROR =(3 shl 1)
# const WEBVIEW_DIALOG_FLAG_ALERT_MASK= (3 shl 1)
const NSAlertStyleWarning = 0
const NSAlertStyleCritical =2
const NSWindowStyleMaskResizable= 8
const NSWindowStyleMaskMiniaturizable =4
const NSWindowStyleMaskTitled =1
const NSWindowStyleMaskClosable =2
const NSWindowStyleMaskFullScreen =(1 shl 14)
const NSViewWidthSizable =2
const NSViewHeightSizable= 16
const NSBackingStoreBuffered =2
# const NSEventMaskAny = ULONG_MAX
const NSEventModifierFlagCommand =(1 shl 20)
const NSEventModifierFlagShift = (1 shl 17)
const NSEventModifierFlagOption =(1 shl 19)
const NSAlertStyleInformational =1
const NSAlertFirstButtonReturn =1000
const WKNavigationActionPolicyDownload =2
const NSModalResponseOK =1
const WKNavigationResponsePolicyAllow= 1
const WKUserScriptInjectionTimeAtDocumentStart= 0
const WKUserScriptInjectionTimeAtDocumentEnd =1
const NSApplicationActivationPolicyRegular =0

type
  Webview* = ptr WebviewObj
  ExternalInvokeCb* = proc (w: Webview; arg: cstring) ## External CallBack Proc
  WebviewPrivObj {. bycopy.} = object
      pool: ID
      window: ID
      webview: ID
      windowDelegate: ID
      should_exit*: int
  WebviewObj* {.bycopy.} = object ## WebView Type
    url* : cstring                                          ## Current URL
    title* : cstring                                      ## Window Title
    width* : cint                                         ## Window Width
    height* : cint                                       ## Window Height
    resizable*: cint ## `true` to Resize the Window, `false` for Fixed size Window
    debug* : cint                                         ## Debug is `true` when not build for Release
    external_invoke_cb : ExternalInvokeCb                       ## Callback proc js:window.external.invoke
    priv: WebviewPrivObj
    userdata : pointer
  WebviewDialogType = enum
    WEBVIEW_DIALOG_TYPE_OPEN,WEBVIEW_DIALOG_TYPE_SAVE,WEBVIEW_DIALOG_TYPE_ALERT

proc webview_terminate(w:Webview) =
  w.priv.should_exit = 1

proc webview_window_will_close( self:Id, cmd:SEL , notification:Id ) =
  var w = getAssociatedObject(self, cast[pointer]($$"webview") )
  webview_terminate(cast[Webview](w) )

proc webview_external_invoke(self:ID ,cmd: SEL ,contentController: Id ,
                                    message:Id ) =
  var w = getAssociatedObject(contentController, cast[pointer]($$"webview"))
  if (cast[pointer](w) == nil or cast[Webview](w).external_invoke_cb == nil) :
    return
  
  objcr:
    var msg = [[message body] UTF8String]
    cast[Webview](w).external_invoke_cb(cast[Webview](w), cast[cstring](msg))

type CompletionHandler = proc (Id:Id):void
proc run_open_panel(self:Id ,cmd: SEL ,webView: Id , parameters:Id ,
                           frame:Id ,completionHandler:Block[CompletionHandler]) =
  objcr:
    var openPanel = [NSOpenPanel openPanel]
    [openPanel setAllowsMultipleSelection,[parameters allowsMultipleSelection]] 
    [openPanel setCanChooseFiles:1]
    [openPanel beginWithCompletionHandler:proc (r:Id ) =
      if r == cast[Id](NSModalResponseOK):
        completionHandler([openPanel URLs])
      else :
        completionHandler(nil)
    ]
type CompletionHandler2 = proc (allowOverwrite:int,destination:Id):void
proc run_save_panel(self:Id, cmd:SEL , download:Id , filename:Id ,completionHandler:Block[CompletionHandler2]) =
  objcr:
    var savePanel = [NSSavePanel savePanel]
    [savePanel setCanCreateDirectories:1]
    [savePanel setNameFieldStringValue:filename]
    [savePanel beginWithCompletionHandler:proc (result:Id) = 
      if result == cast[Id](NSModalResponseOK) :
        var url:Id = [savePanel URL]
        var  path :Id= [url path]
        completionHandler(1, path);
      else:
        completionHandler(NO, nil);
    ]

type CompletionHandler3 = proc (b:bool):void
proc run_confirmation_panel(self:Id , cmd:SEL , webView:Id ,message: Id ,
                                   frame:Id , completionHandler:Block[CompletionHandler3])=
  objcr:
    var alert:Id = [NSAlert new]
    [alert setIcon:[NSImage imageNamed:"NSCaution"]]
    [alert setShowsHelp:0]
    [alert setInformativeText:message]
    [alert addButtonWithTitle:"OK"]
    [alert addButtonWithTitle:"Cancel"]
    
    if [alert runModal] == cast[ID](NSAlertFirstButtonReturn) :
      completionHandler(true)
    else:
      completionHandler(false)
    
    [alert release]

type CompletionHandler4 = proc ():void
proc run_alert_panel(self:Id , cmd:SEL ,webView: Id ,message: Id ,frame: Id ,
                            completionHandler:Block[CompletionHandler4]) =
  objcr:
    var alert:Id = [NSAlert new]
    [alert setIcon:[NSImage imageNamed:NSCaution]]
    [alert setShowsHelp:0]
    [alert setInformativeText:message]
    [alert addButtonWithTitle:"OK"]
    [alert runModal]
    [alert release]
    completionHandler()

# static void download_failed(Id self, SEL cmd, Id download, Id error) {
#   printf("%s",
#          (const char *)objc_msgSend(
#              objc_msgSend(error, registerName("localizedDescription")),
#              registerName("UTF8String")));
# }
type CompletionHandler5 = proc (c:cint):void
proc make_nav_policy_decision( self:Id,cmd: SEL ,webView: Id ,response: Id ,
                                     decisionHandler:Block[CompletionHandler4]) =
  objcr:
    if [response canShowMIMEType] == 0:
      decisionHandler(WKNavigationActionPolicyDownload)
    else:
      decisionHandler(WKNavigationResponsePolicyAllow)

proc webview_load_HTML(w:Webview,html:cstring) =
  objcr:[w.priv.webview,loadHTMLString:@(html),baseURL:nil]

proc webview_load_URL(w:Webview,url:cstring) =
  objcr:
    var requestURL:Id = [NSURL URLWithString: @(url)]
    [requestURL autorelease]
    var request = [NSURLRequest requestWithURL:requestURL]
    [request autorelease]
    [w.priv.webview loadRequest:request]

proc webview_reload(w:Webview) =
    objc_msgSend(w.priv.webview, registerName("reload"));

proc webview_show(w:Webview) =
  objcr:
    [w.priv.window reload]
    if [w.priv.window isMiniaturized]:
      [w.priv.window deminiaturize:nil]
    [w.priv.window makeKeyAndOrderFront:nil]

proc webview_hide(w:Webview) =
  objc_msgSend(w.priv.window, registerName("orderOut:"), nil);

proc webview_minimize(w:Webview) =
  objc_msgSend(w.priv.window, registerName("miniaturize:"), nil)

proc webview_close(w:Webview) =
  objc_msgSend(w.priv.window, registerName("close"))

proc webview_set_size(w:Webview,width:int , height:int ) =
  var frame:CGRect = cast[CGRect](objc_msgSend(w.priv.window, registerName("frame")))
  frame.size.width = width.CGFloat
  frame.size.height = height.CGFloat
  objc_msgSend(w.priv.window, registerName("setFrame:display:"), frame, true)

proc webview_set_developer_tools_enabled(w:Webview,enabled:bool ) =
  objcr:
    [[w.priv.window configuration] registerName("_setDeveloperExtrasEnabled"):enabled]

proc webview_init(w:Webview):int =
  objcr:
    w.priv.pool = [NSAutoreleasePool new]
    [NSApplication sharedApplication]

  var handler = proc ( event:Id) =
    objcr:
      var flag:NSUInteger = [event modifierFlags]
      NSString charactersIgnoringModifiers = [event charactersIgnoringModifiers] 
      BOOL isX =[charactersIgnoringModifiers isEqualToString:"x"] 
      BOOL isC =[charactersIgnoringModifiers isEqualToString:"c"]  
      BOOL isV = [charactersIgnoringModifiers isEqualToString:"v"] 
      BOOL isZ = [charactersIgnoringModifiers isEqualToString:"z"] 
      BOOL isA = [charactersIgnoringModifiers isEqualToString:"a"] 
      BOOL isY = [charactersIgnoringModifiers isEqualToString:"y"] 
      if (flag  and  NSEventModifierFlagCommand):
        if (isX):
          BOOL cut = objc_msgSend(getClass("NSApp"),registerName("sendAction:"),registerName("cut:"),registerName("to:"),nil,registerName("from:"),getClass("NSApp"));
          if (cut):
            return nil
        elif (isC):
          BOOL copy = objc_msgSend(getClass("NSApp"),registerName("sendAction:"),registerName("copy:"),registerName("to:"),nil,registerName("from:"),getClass("NSApp"));
          if (copy):
            return nil
        
        elif (isV):
          BOOL paste = objc_msgSend(getClass("NSApp"),registerName("sendAction:"),registerName("paste:"),registerName("to:"),nil,registerName("from:"),getClass("NSApp"));
          if (paste):
            return nil
        
        elif (isZ):
          BOOL undo = objc_msgSend(getClass("NSApp"),registerName("sendAction:"),registerName("undo:"),registerName("to:"),nil,registerName("from:"),getClass("NSApp"));
          if (undo):
            return nil
        elif (isA):
          BOOL selectAll = objc_msgSend(getClass("NSApp"),registerName("sendAction:"),registerName("selectAll:"),registerName("to:"),nil,registerName("from:"),getClass("NSApp"))
          if (selectAll):
            return nil
      elif (flag & NSEventModifierFlagDeviceIndependentFlagsMask == (NSEventModifierFlagCommand | NSEventModifierFlagShift)):
        BOOL isY = objc_msgSend(charactersIgnoringModifiers,registerName("isEqualToString:"),@"y")
        if (isY):
          BOOL redo = objc_msgSend(getClass("NSApp"),registerName("sendAction:"),registerName("redo:"),registerName("to:"),nil,registerName("from:"),getClass("NSApp"))
          if (redo):
            return nil
      return event
  

  objcr: [NSEvent addLocalMonitorForEventsMatchingMask:NSKeyDown,handler:handler]
  var PrivWKScriptMessageHandler:Class = allocateClassPair(getClass("NSObject"), "PrivWKScriptMessageHandler", 0);
  discard addMethod(PrivWKScriptMessageHandler,registerName("userContentController:didReceiveScriptMessage:"),cast[IMP](webview_external_invoke), "v@:@@")
  registerClassPair(PrivWKScriptMessageHandler);

  var scriptMessageHandler:Id = objc_msgSend((Id)PrivWKScriptMessageHandler, registerName("new"))

  var PrivWKDownloadDelegate:Class  = allocateClassPair(getClass("NSObject"), "PrivWKDownloadDelegate", 0)
  discard addMethod(
      PrivWKDownloadDelegate,
      registerName("_download:decideDestinationWithSuggestedFilename:completionHandler:"),
      cast[IMP](run_save_panel), "v@:@@?");
  discard addMethod(PrivWKDownloadDelegate,registerName("_download:didFailWithError:"),cast[IMP](download_failed), "v@:@@")
  registerClassPair(PrivWKDownloadDelegate);
  var downloadDelegate:Id  = objc_msgSend((Id)PrivWKDownloadDelegate, registerName("new"))

  var PrivWKPreferences:Class = allocateClassPair(getClass("WKPreferences"),"PrivWKPreferences", 0)
  var typ = PropertyAttribute(name:"T",value:"c")
  var ownership = PropertyAttribute(name:"N",value:"")
  replaceProperty(PrivWKPreferences, "developerExtrasEnabled", [typ,ownership])
  registerClassPair(PrivWKPreferences);
  var wkPref:Id = objc_msgSend((Id)PrivWKPreferences, registerName("new"))

  objcr:
    [wkPref setValue:[NSNumber numberWithBool:w.debug], forKey:"developerExtrasEnabled"]

    var userController:Id = [WKUserContentController new]

    setAssociatedObject(userController, $$"webview", (Id)(w),
                            OBJC_ASSOCIATION_ASSIGN)
    [userController addScriptMessageHandler:scriptMessageHandler, name:"invoke"]

    var windowExternalOverrideScript:Id =[WKUserScript alloc] 
    const source = """window.external = this; invoke = function(arg){ 
                   webkit.messageHandlers.invoke.postMessage(arg); };"""
    [windowExternalOverrideScript initWithSource:source,injectionTime:WKUserScriptInjectionTimeAtDocumentStart,forMainFrameOnly:0]
    [userController addUserScript:windowExternalOverrideScript]
    var config:Id = [WKWebViewConfiguration new]
    var processPool:Id = [config processPool]
    [processPool $$"_setDownloadDelegate": downloadDelegate]
    [config setProcessPool:processPool]
    [config setUserContentController:userController]
    [config setPreferences:wkPref]

  var PrivNSWindowDelegate:Class = allocateClassPair(getClass("NSObject"),
                                                    "PrivNSWindowDelegate", 0)
  discard addProtocol(PrivNSWindowDelegate, getProtocol("NSWindowDelegate"))
  discard replaceMethod(PrivNSWindowDelegate, registerName("windowWillClose:"),cast[IMP](webview_window_will_close), "v@:@")
  registerClassPair(PrivNSWindowDelegate);

  w.priv.windowDelegate = objc_msgSend(cast[ID](PrivNSWindowDelegate),$$"new")

  setAssociatedObject(w.priv.windowDelegate, cast[pointer]($$"webview"), (Id)(w),
                           OBJC_ASSOCIATION_ASSIGN)
  objcr:
    var nsTitle:Id = @(w.title)
    var r:CGRect = CGRectMake(0, 0, w.width, w.height)
    var style = NSWindowStyleMaskTitled or NSWindowStyleMaskClosable or
                       NSWindowStyleMaskMiniaturizable;
    if (w.resizable) :
      style = style or NSWindowStyleMaskResizable
    w.priv.window =[NSWindow alloc]
    [w.priv.window initWithContentRect:r,:styleMask:style,backing:NSBackingStoreBuffered,`defer`:0]
    [w.priv.window autorelease]
    [w.priv.window setTitle:nsTitle]
    [w.priv.window setDelegate:w.priv.windowDelegate]
    [w.priv.window center]

  var PrivWKUIDelegate:Class = allocateClassPair(getClass("NSObject"), "PrivWKUIDelegate", 0)
  discard addProtocol(PrivWKUIDelegate, getProtocol("WKUIDelegate"))
  discard addMethod(PrivWKUIDelegate,
                  registerName("webView:runOpenPanelWithParameters:initiatedByFrame:completionHandler:"),
                  cast[IMP](run_open_panel), "v@:@@@?")
  discard addMethod(PrivWKUIDelegate,
                  registerName("webView:runJavaScriptAlertPanelWithMessage:initiatedByFrame:completionHandler:"),
                  cast[IMP](run_alert_panel), "v@:@@@?")
  discard addMethod(
      PrivWKUIDelegate,
      registerName("webView:runJavaScriptConfirmPanelWithMessage:initiatedByFrame:completionHandler:"),
      cast[IMP](run_confirmation_panel), "v@:@@@?")
  registerClassPair(PrivWKUIDelegate)
  var uiDel:Id = objc_msgSend((Id)PrivWKUIDelegate, registerName("new"))

  var PrivWKNavigationDelegate:Class  = allocateClassPair(
      getClass("NSObject"), "PrivWKNavigationDelegate", 0)
  discard addProtocol(PrivWKNavigationDelegate,getProtocol("WKNavigationDelegate"))
  discard addMethod(
      PrivWKNavigationDelegate,
      registerName(
          "webView:decidePolicyForNavigationResponse:decisionHandler:"),
      cast[IMP](make_nav_policy_decision), "v@:@@?")
  registerClassPair(PrivWKNavigationDelegate);
  objcr:
    var navDel:Id = [PrivWKNavigationDelegate `new`] 
    w.priv.webview =[WKWebView alloc]
    [w.priv.webview initWithFrame:r,configuration:config]
    [w.priv.webview setUIDelegate:uiDel]
    [w.priv.webview setNavigationDelegate:navDel]
    var nsURL:Id = [NSURL URLWithString:@(webview_check_url(w->url))]
    [w.priv.webview loadRequest:[NSURLRequest requestWithURL:nsURL]]
    [w.priv.webview setAutoresizesSubviews:1]
    [w.priv.webview setAutoresizingMask:NSViewWidthSizable or NSViewHeightSizable]
    [[w.priv.webview contentView] addSubview:w.priv.webview]
    [w.priv.webview orderFrontRegardless]
    [[NSApplication sharedApplication] setActivationPolicy:NSApplicationActivationPolicyRegular]
  w.priv.should_exit = 0
  return 0

proc webview_loop(w:Webview, blocking:int ):int=
  objcr:
    var until:Id = if blocking > 0 : [NSDate distantFuture] else: [NSDate distantPast]
    [NSApplication sharedApplication]
    var event:Id = [NSApp nextEventMatchingMask:ULONG_MAX,untilDate:until,inMode:"kCFRunLoopDefaultMode",dequeue:true]
    if cast[pointer](event) != nil:
      [NSApp sendEvent:event]
    return w.priv.should_exit

proc webview_eval(w:Webview, js:cstring) :int =
  objcr:
    var userScript:Id = [WKUserScript alloc]
    [userScript initWithSource:@(js),injectionTime:WKUserScriptInjectionTimeAtDocumentEnd,forMainFrameOnly:0]
    var userScript:Id = [WKUserScript alloc]
    var config:Id = [w.priv.webview valueForKey:"configuration"]
    var userContentController:Id  = [config valueForKey:"userContentController"]
    [userContentController addUserScript:userScript]
  return 0

proc webview_set_title(w:Webview,title:cstring) =
  objcr: [w.priv.window setTitle:@(title)]

proc webview_set_fullscreen(w:Webview, fullscreen:int ) =
  objcr:
    var windowStyleMask:culong = [w.priv.window styleMask]
    var b:int = if windowStyleMask and NSWindowStyleMaskFullScreen == NSWindowStyleMaskFullScreen:1 else:0
    if b != fullscreen:
      [w.priv.window toggleFullScreen:nil]

proc webview_set_iconify(w:Webview, iconify:int ) =
  objcr:
    if (iconify):
      [w.priv.window miniaturize:nil]
    else:
      [w.priv.window deminiaturize:nil]

proc webview_launch_external_URL(w:Webview, uri:cstring) =
  objcr:
    var url:Id = [NSURL @(webview_check_url(uri))]
    [[NSWorkspace sharedWorkspace] openURL:url]

proc webview_set_color(w:Webview;r,g,b,a:uint8) =
  objcr:
    var color:Id = [NSColor colorWithRed:r / 255.0,green:g / 255.0,blue:b / 255.0,alpha:a / 255.0]
    [w.priv.window setBackgroundColor:color]

    if (0.5 >= ((r / 255.0 * 299.0) + (g / 255.0 * 587.0) + (b / 255.0 * 114.0)) /
                  1000.0) :
      [w.priv.window setAppearance:[ NSAppearance appearanceNamed:"NSAppearanceNameVibrantDark"]]
    else:
      [w.priv.window setAppearance:[NSAppearance appearanceNamed:"NSAppearanceNameVibrantLight"]]
      [w.priv.window setOpaque:0]
      [w.priv.window setTitlebarAppearsTransparent:1]
      [w.priv.window $$"_setDrawsBackground":0]

proc webview_dialog(w:Webview,dlgtype:WebviewDialogType , flags:int ,
                                title:cstring,arg:cstring,result:var cstring,resultsz:csize_t) =
  objcr:
    if (dlgtype == WEBVIEW_DIALOG_TYPE_OPEN or
        dlgtype == WEBVIEW_DIALOG_TYPE_SAVE) :
      var panel:Id = getClass("NSSavePanel")
    
      if (dlgtype == WEBVIEW_DIALOG_TYPE_OPEN) :
        var openPanel:Id =[NSOpenPanel openPanel] 
        if (flags and WEBVIEW_DIALOG_FLAG_DIRECTORY) :
          [openPanel setCanChooseFiles:0]
          [openPanel setCanChooseDirectories:1]
        else :
          [openPanel setCanChooseFiles:1]
          [openPanel setCanChooseDirectories:0]
          [openPanel setResolvesAliases:0]
          [openPanel setAllowsMultipleSelection:0]
        panel = openPanel
      else:
        panel = [NSSavePanel savePanel]
      [panel setCanCreateDirectories:1]
      [panel setShowsHiddenFiles:1]
      [panel setExtensionHidden:0]
      [panel setCanSelectHiddenExtension:0]
      [panel setTreatsFilePackagesAsDirectories:1]
      [panel beginSheetModalForWindow:w.priv.window,completionHandler: proc (result:Id) = 
        [[NSApplication sharedApplication] stopModalWithCode:result]
      ]
      if [[NSApplication sharedApplication] runModalForWindow:panel] == NSModalResponseOK:
        var url:Id = [panel URL] 
        var path:Id = [url path]
        var filename:cstring = [path "UTF8String"]
        strlcpy(result, filename, resultsz)
      
      elif (dlgtype == WEBVIEW_DIALOG_TYPE_ALERT):
        var a:Id = [NSAlert `new`] 
        case flags and WEBVIEW_DIALOG_FLAG_ALERT_MASK:
        of WEBVIEW_DIALOG_FLAG_INFO:
          [a setAlertStyle:NSAlertStyleInformational]
          break
        of WEBVIEW_DIALOG_FLAG_WARNING:
          # printf("Warning\n");
          [a setAlertStyle:NSAlertStyleWarning]
          break
        of WEBVIEW_DIALOG_FLAG_ERROR:
          # printf("Error\n");
          [a setAlertStyle:NSAlertStyleCritical]
          break
        [a setShowsHelp:0]
        [a setShowsSuppressionButton:0]
        [a setMessageText: @(title)]
        [a setInformativeText: @(arg)]
        [a addButtonWithTitle:"OK"]
        [a runModal]
        [a release]

# proc webview_dispatch_cb(void *arg) =
#   struct webview_dispatch_arg *context = (struct webview_dispatch_arg *)arg;
#   (context->fn)(context->w, context->arg);
#   free(context)
# 

# WEBVIEW_API void webview_dispatch(struct webview *w, webview_dispatch_fn fn,
#                                   void *arg) {
#   struct webview_dispatch_arg *context = (struct webview_dispatch_arg *)malloc(
#       sizeof(struct webview_dispatch_arg));
#   context->w = w;
#   context->arg = arg;
#   context->fn = fn;
#   dispatch_async_f(dispatch_get_main_queue(), context, webview_dispatch_cb);
# }



proc webview_exit(w:Webview) =
  objcr:
    var app:Id = [NSApplication sharedApplication]
    [app terminate: app]

# proc webview_print_log(s:cstring) = printf("%s\n", s)