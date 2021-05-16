import objc_runtime
import darwin / [app_kit, foundation]
import menu
var NSApp {.importc.}: ID
{.passc: "-DOBJC_OLD_DISPATCH_PROTOTYPES=1 -DWEBVIEW_COCOA=1 -x objective-c",
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
  ExternalInvokeCb* = proc (w: Webview; arg: string) ## External CallBack Proc
  WebviewPrivObj {. bycopy.} = object
      pool: ID
      window: ID
      webview: ID
      windowDelegate: ID
      should_exit: int
  WebviewObj* {.bycopy.} = object ## WebView Type
    url* : cstring                                          ## Current URL
    title* : cstring                                      ## Window Title
    width* : cint                                         ## Window Width
    height* : cint                                       ## Window Height
    resizable*: cint ## `true` to Resize the Window, `false` for Fixed size Window
    debug* : cint                                         ## Debug is `true` when not build for Release
    invokeCb : pointer                       ## Callback proc js:window.external.invoke
    priv : WebviewPrivObj
    userdata : pointer
  WebviewDialogType = enum
    WEBVIEW_DIALOG_TYPE_OPEN,WEBVIEW_DIALOG_TYPE_SAVE,WEBVIEW_DIALOG_TYPE_ALERT

proc webview_window_will_close( self:id, cmd:SEL , notification:id ) =
  var w = objc_getAssociatedObject(self, "webview")
  webview_terminate(w)

proc webview_external_invoke(self:id ,cmd: SEL ,contentController: id ,
                                    message:id ) =
  var w = objc_getAssociatedObject(contentController, "webview")
  if (w == nil or w.external_invoke_cb == nil) :
    return
  
  objcr:
    var msg = [[message body] UTF8String]
    w.external_invoke_cb(w, cast[cstring](msg))

type CompletionHandler = proc (id:Id):void
proc run_open_panel(self:id ,cmd: SEL ,webView: id , parameters:id ,
                           frame:id ,completionHandler:Block[CompletionHandler]) =
  objcr:
    var openPanel = [NSOpenPanel openPanel]
    [[openPanel setAllowsMultipleSelection,[parameters allowsMultipleSelection]] 
    [openPanel setCanChooseFiles:1]
    [openPanelbeginWithCompletionHandler:proc (result:id ) =
      if (result == (id)NSModalResponseOK):
        completionHandler([openPanel URLs])
      else :
        completionHandler(nil)
    ]
type CompletionHandler2 = proc (allowOverwrite:int,destination:id):void
proc run_save_panel(self:id, cmd:SEL , download:id , filename:id ,completionHandler:Block[CompletionHandler2]) =
  objcr:
    var savePanel = [NSSavePanel savePanel]
    [savePanel setCanCreateDirectories:1]
    [savePanel setNameFieldStringValue:filename]
    [savePanel beginWithCompletionHandler:proc (result:id) = 
      if (result == (id)NSModalResponseOK) :
        var url:id = [savePanel URL]
        var  path :id= [url path]
        completionHandler(1, path);
      else:
        completionHandler(NO, nil);
    ]

type CompletionHandler3 = proc (b:bool):void
proc run_confirmation_panel(self:id , cmd:SEL , webView:id ,message: id ,
                                   frame:id , completionHandler:Block[CompletionHandler3])=
  objcr:
    var alert:id = [NSAlert new]
    [alert setIcon:[NSImage imageNamed:"NSCaution"]]
    [alert setShowsHelp:0]
    [alert setInformativeText:message]
    [alert addButtonWithTitle:"OK"]
    [alert addButtonWithTitle:"Cancel"]
    
    if [alert runModal] == NSAlertFirstButtonReturn):
      completionHandler(true)
    else:
      completionHandler(false)
    
    [alert release]

type CompletionHandler4 = proc ():void
proc run_alert_panel(self:id , cmd:SEL ,webView: id ,message: id ,frame: id ,
                            completionHandler:Block[CompletionHandler4]) =
  objcr:
    var alert:id = [NSAlert new]
    [alert setIcon:[NSImage imageNamed:NSCaution]]
    [alert setShowsHelp:0]
    [alert setInformativeText:message]
    [alert addButtonWithTitle:"OK"]
    [alert runModal]
    [alert release]
    completionHandler()

# static void download_failed(id self, SEL cmd, id download, id error) {
#   printf("%s",
#          (const char *)objc_msgSend(
#              objc_msgSend(error, sel_registerName("localizedDescription")),
#              sel_registerName("UTF8String")));
# }
type CompletionHandler5 = proc (c:cint):void
proc make_nav_policy_decision( self:id,cmd: SEL ,webView: id ,response: id ,
                                     decisionHandler:Block[CompletionHandler4]) =
  objcr:
    
    if ([response canShowMIMEType] == 0) :
      decisionHandler(WKNavigationActionPolicyDownload)
    else:
      decisionHandler(WKNavigationResponsePolicyAllow)

proc webview_load_HTML(w:webview,html:cstring) =
  objcr:[w.priv.webview,loadHTMLString:get_nsstring(html),baseURL:nil]


proc webview_load_URL(w:webview,url:cstring) =
  objcr:
    var requestURL:id = [NSURL URLWithString: get_nsstring(url)]
    [requestURL autorelease]
    var request = [NSURLRequest requestWithURL:requestURL]
    [request autorelease]
    [w.priv.webview loadRequest:request]

proc webview_reload(w:webview) =
    objc_msgSend(w.priv.webview, sel_registerName("reload"));

proc webview_show(w:webview) =
  objcr:
    [w.priv.window reload]
    if [w.priv.window isMiniaturized]:
      [w.priv.window deminiaturize:nil]
    [w.priv.window makeKeyAndOrderFront:nil]

proc webview_hide(w:webview) =
  objc_msgSend(w.priv.window, sel_registerName("orderOut:"), nil);

proc webview_minimize(w:webview) =
  objc_msgSend(w.priv.window, sel_registerName("miniaturize:"), nil)

proc webview_close(w:webview) =
  objc_msgSend(w.priv.window, sel_registerName("close"))

proc webview_set_size(w:webview,int width, int height) =
  CGRect frame = cast[CGRect](objc_msgSend(w.priv.window, sel_registerName("frame")))
  frame.size.width = width
  frame.size.height = height
  objc_msgSend(w.priv.window, sel_registerName("setFrame:display:"), frame, true)

proc webview_set_developer_tools_enabled(w:webview,enabled:bool ) =
  objcr:
    [[w.priv.window configuration] _setDeveloperExtrasEnabled:enabled]

proc webview_init(w:webview):int =
  objcr:
    w.priv.pool = [NSAutoreleasePool new]
    [NSApplication sharedApplication]

  # id *_Nullable (^handler)(id *_Nullable);

  var handler = proc ( event:id)=
    NSUInteger flag = [event modifierFlags]
    NSString charactersIgnoringModifiers = [event charactersIgnoringModifiers] 
    BOOL isX =[charactersIgnoringModifiers isEqualToString:"x"] 
    BOOL isC =[charactersIgnoringModifiers isEqualToString:"c"]  
    BOOL isV = [charactersIgnoringModifiers isEqualToString:"v"] 
    BOOL isZ = [charactersIgnoringModifiers isEqualToString:"z"] 
    BOOL isA = [charactersIgnoringModifiers isEqualToString:"a"] 
    BOOL isY = [charactersIgnoringModifiers isEqualToString:"y"] 
    if (flag  &  NSEventModifierFlagCommand):
      if (isX):
        BOOL cut = objc_msgSend(objc_getClass("NSApp"),sel_registerName("sendAction:"),sel_registerName("cut:"),sel_registerName("to:"),nil,sel_registerName("from:"),objc_getClass("NSApp"));
        if (cut):
          return nil
      elif (isC):
        BOOL copy = objc_msgSend(objc_getClass("NSApp"),sel_registerName("sendAction:"),sel_registerName("copy:"),sel_registerName("to:"),nil,sel_registerName("from:"),objc_getClass("NSApp"));
        if (copy):
          return nil
      
      elif (isV):
        BOOL paste = objc_msgSend(objc_getClass("NSApp"),sel_registerName("sendAction:"),sel_registerName("paste:"),sel_registerName("to:"),nil,sel_registerName("from:"),objc_getClass("NSApp"));
        if (paste)
          return nil
      
      elif (isZ):
        BOOL undo = objc_msgSend(objc_getClass("NSApp"),sel_registerName("sendAction:"),sel_registerName("undo:"),sel_registerName("to:"),nil,sel_registerName("from:"),objc_getClass("NSApp"));
        if (undo)
          return nil
      elif (isA):
      
        BOOL selectAll = objc_msgSend(objc_getClass("NSApp"),sel_registerName("sendAction:"),sel_registerName("selectAll:"),sel_registerName("to:"),nil,sel_registerName("from:"),objc_getClass("NSApp"))
        if (selectAll):
          return nil
    elif (flag & NSEventModifierFlagDeviceIndependentFlagsMask == (NSEventModifierFlagCommand | NSEventModifierFlagShift)):
      BOOL isY = objc_msgSend(charactersIgnoringModifiers,sel_registerName("isEqualToString:"),@"y")
      if (isY):
        BOOL redo = objc_msgSend(objc_getClass("NSApp"),sel_registerName("sendAction:"),sel_registerName("redo:"),sel_registerName("to:"),nil,sel_registerName("from:"),objc_getClass("NSApp"))
        if (redo):
          return nil
    return event
  

  var addLocalMonitorForEventsMatchingMask:SEL = sel_registerName("addLocalMonitorForEventsMatchingMask:handler:");
  objc_msgSend(objc_getClass("NSEvent"), addLocalMonitorForEventsMatchingMask,NSKeyDown , handler);
  Class __WKScriptMessageHandler = objc_allocateClassPair(
      objc_getClass("NSObject"), "__WKScriptMessageHandler", 0);
  class_addMethod(
      __WKScriptMessageHandler,
      sel_registerName("userContentController:didReceiveScriptMessage:"),
      (IMP)webview_external_invoke, "v@:@@");
  objc_registerClassPair(__WKScriptMessageHandler);

  id scriptMessageHandler =
      objc_msgSend((id)__WKScriptMessageHandler, sel_registerName("new"));

  Class __WKDownloadDelegate = objc_allocateClassPair(
      objc_getClass("NSObject"), "__WKDownloadDelegate", 0);
  class_addMethod(
      __WKDownloadDelegate,
      sel_registerName("_download:decideDestinationWithSuggestedFilename:"
                       "completionHandler:"),
      (IMP)run_save_panel, "v@:@@?");
  class_addMethod(__WKDownloadDelegate,
                  sel_registerName("_download:didFailWithError:"),
                  (IMP)download_failed, "v@:@@");
  objc_registerClassPair(__WKDownloadDelegate);
  id downloadDelegate =
      objc_msgSend((id)__WKDownloadDelegate, sel_registerName("new"));

  Class __WKPreferences = objc_allocateClassPair(objc_getClass("WKPreferences"),
                                                 "__WKPreferences", 0);
  objc_property_attribute_t type = {"T", "c"};
  objc_property_attribute_t ownership = {"N", ""};
  objc_property_attribute_t attrs[] = {type, ownership};
  class_replaceProperty(__WKPreferences, "developerExtrasEnabled", attrs, 2);
  objc_registerClassPair(__WKPreferences);
  id wkPref = objc_msgSend((id)__WKPreferences, sel_registerName("new"))

  objcr:
    [wkPref setValue:[NSNumber numberWithBool:w.debug] forKey:"developerExtrasEnabled"]

    var userController:id = [WKUserContentController new]

    objc_setAssociatedObject(userController, "webview", (id)(w),
                            OBJC_ASSOCIATION_ASSIGN)
    [userController addScriptMessageHandler:scriptMessageHandler name:"invoke"]

    var windowExternalOverrideScript:id =[WKUserScript alloc] 
    const source = """window.external = this; invoke = function(arg){ 
                   webkit.messageHandlers.invoke.postMessage(arg); };"""
    [windowExternalOverrideScript initWithSource:source,injectionTime:WKUserScriptInjectionTimeAtDocumentStart,forMainFrameOnly:0]
    [userController addUserScript:windowExternalOverrideScript]
    var config:id = [WKWebViewConfiguration new]
    var processPool:id = [config processPool]
    [processPool _setDownloadDelegate:downloadDelegate]
    [config setProcessPool:processPool]
    [config setUserContentController:userController]
    [config setPreferences:wkPref]


  Class __NSWindowDelegate = objc_allocateClassPair(objc_getClass("NSObject"),
                                                    "__NSWindowDelegate", 0);
  class_addProtocol(__NSWindowDelegate, objc_getProtocol("NSWindowDelegate"));
  class_replaceMethod(__NSWindowDelegate, sel_registerName("windowWillClose:"),
                      (IMP)webview_window_will_close, "v@:@");
  objc_registerClassPair(__NSWindowDelegate);

  w.priv.windowDelegate = [__NSWindowDelegate `new`]

  objc_setAssociatedObject(w->priv.windowDelegate, "webview", (id)(w),
                           OBJC_ASSOCIATION_ASSIGN)
  objcr:
    var nsTitle:id = @(w.title)
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

  Class __WKUIDelegate =
      objc_allocateClassPair(objc_getClass("NSObject"), "__WKUIDelegate", 0);
  class_addProtocol(__WKUIDelegate, objc_getProtocol("WKUIDelegate"));
  class_addMethod(__WKUIDelegate,
                  sel_registerName("webView:runOpenPanelWithParameters:"
                                   "initiatedByFrame:completionHandler:"),
                  (IMP)run_open_panel, "v@:@@@?");
  class_addMethod(__WKUIDelegate,
                  sel_registerName("webView:runJavaScriptAlertPanelWithMessage:"
                                   "initiatedByFrame:completionHandler:"),
                  (IMP)run_alert_panel, "v@:@@@?");
  class_addMethod(
      __WKUIDelegate,
      sel_registerName("webView:runJavaScriptConfirmPanelWithMessage:"
                       "initiatedByFrame:completionHandler:"),
      (IMP)run_confirmation_panel, "v@:@@@?");
  objc_registerClassPair(__WKUIDelegate)
  id uiDel = objc_msgSend((id)__WKUIDelegate, sel_registerName("new"));

  Class __WKNavigationDelegate = objc_allocateClassPair(
      objc_getClass("NSObject"), "__WKNavigationDelegate", 0);
  class_addProtocol(__WKNavigationDelegate,
                    objc_getProtocol("WKNavigationDelegate"));
  class_addMethod(
      __WKNavigationDelegate,
      sel_registerName(
          "webView:decidePolicyForNavigationResponse:decisionHandler:"),
      (IMP)make_nav_policy_decision, "v@:@@?");
  objc_registerClassPair(__WKNavigationDelegate);
  objcr:
    var navDel:id = [__WKNavigationDelegate `new`] 
    w.priv.webview =[WKWebView alloc]
    [w.priv.webview initWithFrame:r,configuration:config]
    [w.priv.webview setUIDelegate:uiDel]
    [w.priv.webview setNavigationDelegate:navDel]
    var nsURL:id = [NSURL URLWithString:@(webview_check_url(w->url))]
    [w.priv.webview loadRequest:[NSURLRequest requestWithURL:nsURL]]
    [w.priv.webview setAutoresizesSubviews:1]
    [w.priv.webview setAutoresizingMask:NSViewWidthSizable or NSViewHeightSizable]
    [[w.priv.webview contentView] addSubview:w.priv.webview]
    [w.priv.webview orderFrontRegardless]
    [[NSApplication sharedApplication] setActivationPolicy:NSApplicationActivationPolicyRegular]
  w.priv.should_exit = 0
  return 0

proc webview_loop(w:webview, blocking:int ):int=
  objcr:
    var until:id = if blocking > 0 : [NSDate distantFuture] else: [NSDate distantPast]
    [NSApplication sharedApplication]
    var event:id = [NSApp nextEventMatchingMask:ULONG_MAX,untilDate:until,inMode:"kCFRunLoopDefaultMode",dequeue:true]
  if event != nil:
    objcr:
      [NSApp sendEvent:event]
  return w.priv.should_exit

proc webview_eval(w:webview, js:cstring) :int =
  objcr:
    var userScript:id = [WKUserScript alloc]
    [userScript initWithSource:@(js),injectionTime:WKUserScriptInjectionTimeAtDocumentEnd,forMainFrameOnly:0]
    var userScript:id = objc_msgSend(
      (id)objc_getClass("WKUserScript"), sel_registerName("alloc"));
    var config:id = [w.priv.webview valueForKey:"configuration"]
    var userContentController:id  = [config valueForKey:"userContentController"]
    [userContentController addUserScript:userScript]
  return 0

proc webview_set_title(w:webview,title:cstring) =
  objcr: [w.priv.window setTitle:@(title)]

proc webview_set_fullscreen(w:webview, fullscreen:int ) =
  objcr:
    var windowStyleMask:culong = [w.priv.window styleMask]
    var b:int = if windowStyleMask and NSWindowStyleMaskFullScreen == NSWindowStyleMaskFullScreen:1 else:0

    if b != fullscreen:
      [w.priv.window toggleFullScreen:nil]

proc webview_set_iconify(w:webview, iconify:int ) =
  objcr:
  if (iconify):
    [w.priv.window miniaturize:nil]
  else:
    [w.priv.window deminiaturize:nil]

proc webview_launch_external_URL(w:webview, uri:cstring) =
  objcr:
    var url:id = [NSURL @(webview_check_url(uri))]
    [[NSWorkspace sharedWorkspace] openURL:url]

proc webview_set_color(w:webview;r,g,b,a:uint8) =
  var color:id = [NSColor colorWithRed:r / 255.0,green:g / 255.0,blue:b / 255.0,alpha:a / 255.0]
  [w.priv.window setBackgroundColor:color]

  if (0.5 >= ((r / 255.0 * 299.0) + (g / 255.0 * 587.0) + (b / 255.0 * 114.0)) /
                 1000.0) :
    [w.priv.window setAppearance:[ NSAppearance appearanceNamed:"NSAppearanceNameVibrantDark"]]
  else:
    [w.priv.window setAppearance:[NSAppearance appearanceNamed:"NSAppearanceNameVibrantLight"]]
    [w.priv.window setOpaque:0]
    [w.priv.window setTitlebarAppearsTransparent:1]
    [w.priv.window _setDrawsBackground:0]

proc webview_dialog(w:webview,dlgtype:webview_dialog_type , flags:int ,
                                title:cstring,arg:cstring,result:var cstring,resultsz:size_t) =
  if (dlgtype == WEBVIEW_DIALOG_TYPE_OPEN or
      dlgtype == WEBVIEW_DIALOG_TYPE_SAVE) :
    var panel:id = objc_getClass("NSSavePanel")
   
    if (dlgtype == WEBVIEW_DIALOG_TYPE_OPEN) :
      var openPanel:id =[NSOpenPanel openPanel] 
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
    [panel beginSheetModalForWindow:completionHandler:w.priv.window, proc (result:id) = 
      [[NSApplication sharedApplication] stopModalWithCode:result]
    ]
    if [[NSApplication sharedApplication]runModalForWindow:panel] == NSModalResponseOK:
      var url:id = [panel URL] 
      var path:id = [url path]
      var filename:cstring = [path "UTF8String"]
      strlcpy(result, filename, resultsz)
    
    elif (dlgtype == WEBVIEW_DIALOG_TYPE_ALERT):
      var a:id = [NSAlert `new`] 
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

proc webview_terminate(w:webview) =
  w.priv.should_exit = 1

proc webview_exit(w:webview) =
  var app:id = [NSApplication sharedApplication]
  [app terminate: app]

# proc webview_print_log(s:cstring) = printf("%s\n", s)