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
proc run_save_panel(self:id , cmd:SEL , download:id , filename:id ,
completionHandler:Block[CompletionHandler2]
                           ) =
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
                                   frame:id , completionHandler:Block[CompletionHandler3]) {
  objcr:
  var alert:id = [NSAlert new]
  [alert setIcon:[NSImage imageNamed:"NSCaution"]]
  [alert setShowsHelp:0]
  [alert setInformativeText:message]
  [alert addButtonWithTitle:"OK"]
  [alert addButtonWithTitle:"Cancel"]
  
  if [alert runModal] == (id)NSAlertFirstButtonReturn):
    completionHandler(true);
  else:
    completionHandler(false);
  
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

# static void make_nav_policy_decision(id self, SEL cmd, id webView, id response,
#                                      void (^decisionHandler)(int)) {
#   if (objc_msgSend(response, sel_registerName("canShowMIMEType")) == 0) {
#     decisionHandler(WKNavigationActionPolicyDownload);
#   } else {
#     decisionHandler(WKNavigationResponsePolicyAllow);
#   }
# }

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

  id *_Nullable (^handler)(id *_Nullable);

  handler = proc ( event:id)=
    NSUInteger flag = objc_msgSend(event,sel_registerName("modifierFlags"));
    NSString charactersIgnoringModifiers = objc_msgSend(event,sel_registerName("charactersIgnoringModifiers"));
    BOOL isX = objc_msgSend(charactersIgnoringModifiers,sel_registerName("isEqualToString:"),@"x");
    BOOL isC = objc_msgSend(charactersIgnoringModifiers,sel_registerName("isEqualToString:"),@"c");
    BOOL isV = objc_msgSend(charactersIgnoringModifiers,sel_registerName("isEqualToString:"),@"v");
    BOOL isZ = objc_msgSend(charactersIgnoringModifiers,sel_registerName("isEqualToString:"),@"z");
    BOOL isA = objc_msgSend(charactersIgnoringModifiers,sel_registerName("isEqualToString:"),@"a");
    BOOL isY = objc_msgSend(charactersIgnoringModifiers,sel_registerName("isEqualToString:"),@"y");
    if (flag  &  NSEventModifierFlagCommand)
    {
      if (isX)
      {
        BOOL cut = objc_msgSend(objc_getClass("NSApp"),sel_registerName("sendAction:"),sel_registerName("cut:"),sel_registerName("to:"),nil,sel_registerName("from:"),objc_getClass("NSApp"));
        if (cut)
          return NULL ;
      }
      else if (isC)
      {
        BOOL copy = objc_msgSend(objc_getClass("NSApp"),sel_registerName("sendAction:"),sel_registerName("copy:"),sel_registerName("to:"),nil,sel_registerName("from:"),objc_getClass("NSApp"));
        if (copy)
          return NULL ;
      }
      else if (isV)
      {
        BOOL paste = objc_msgSend(objc_getClass("NSApp"),sel_registerName("sendAction:"),sel_registerName("paste:"),sel_registerName("to:"),nil,sel_registerName("from:"),objc_getClass("NSApp"));
        if (paste)
          return NULL ;
      }
      else if (isZ)
      {
        BOOL undo = objc_msgSend(objc_getClass("NSApp"),sel_registerName("sendAction:"),sel_registerName("undo:"),sel_registerName("to:"),nil,sel_registerName("from:"),objc_getClass("NSApp"));
        if (undo)
          return NULL ;
      }
      else if (isA)
      {
        BOOL selectAll = objc_msgSend(objc_getClass("NSApp"),sel_registerName("sendAction:"),sel_registerName("selectAll:"),sel_registerName("to:"),nil,sel_registerName("from:"),objc_getClass("NSApp"));
        if (selectAll)
          return NULL ;
      }
    }
    else if (flag & NSEventModifierFlagDeviceIndependentFlagsMask == (NSEventModifierFlagCommand | NSEventModifierFlagShift))
    {
      BOOL isY = objc_msgSend(charactersIgnoringModifiers,sel_registerName("isEqualToString:"),@"y");
      if (isY)
      {
        BOOL redo = objc_msgSend(objc_getClass("NSApp"),sel_registerName("sendAction:"),sel_registerName("redo:"),sel_registerName("to:"),nil,sel_registerName("from:"),objc_getClass("NSApp"));
        if (redo)
          return NULL ;
      }
    }
    return event;
  

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
  
  objc_msgSend(wkPref, sel_registerName("setValue:forKey:"),
               objc_msgSend((id)objc_getClass("NSNumber"),
                            sel_registerName("numberWithBool:"), !!w->debug),
               objc_msgSend((id)objc_getClass("NSString"),
                            sel_registerName("stringWithUTF8String:"),
                            "developerExtrasEnabled"));

  id userController = objc_msgSend((id)objc_getClass("WKUserContentController"),
                                   sel_registerName("new"));
  objc_setAssociatedObject(userController, "webview", (id)(w),
                           OBJC_ASSOCIATION_ASSIGN);
  objc_msgSend(
      userController, sel_registerName("addScriptMessageHandler:name:"),
      scriptMessageHandler,
      objc_msgSend((id)objc_getClass("NSString"),
                   sel_registerName("stringWithUTF8String:"), "invoke"));

  id windowExternalOverrideScript = objc_msgSend(
      (id)objc_getClass("WKUserScript"), sel_registerName("alloc"));
  objc_msgSend(
      windowExternalOverrideScript,
      sel_registerName("initWithSource:injectionTime:forMainFrameOnly:"),
      get_nsstring("window.external = this; invoke = function(arg){ "
                   "webkit.messageHandlers.invoke.postMessage(arg); };"),
      WKUserScriptInjectionTimeAtDocumentStart, 0);

  objc_msgSend(userController, sel_registerName("addUserScript:"),
               windowExternalOverrideScript);

  id config = objc_msgSend((id)objc_getClass("WKWebViewConfiguration"),
                           sel_registerName("new"));
  id processPool = objc_msgSend(config, sel_registerName("processPool"));
  objc_msgSend(processPool, sel_registerName("_setDownloadDelegate:"),
               downloadDelegate);
  objc_msgSend(config, sel_registerName("setProcessPool:"), processPool);
  objc_msgSend(config, sel_registerName("setUserContentController:"),
               userController);
  objc_msgSend(config, sel_registerName("setPreferences:"), wkPref);

  Class __NSWindowDelegate = objc_allocateClassPair(objc_getClass("NSObject"),
                                                    "__NSWindowDelegate", 0);
  class_addProtocol(__NSWindowDelegate, objc_getProtocol("NSWindowDelegate"));
  class_replaceMethod(__NSWindowDelegate, sel_registerName("windowWillClose:"),
                      (IMP)webview_window_will_close, "v@:@");
  objc_registerClassPair(__NSWindowDelegate);

  w->priv.windowDelegate =
      objc_msgSend((id)__NSWindowDelegate, sel_registerName("new"));

  objc_setAssociatedObject(w->priv.windowDelegate, "webview", (id)(w),
                           OBJC_ASSOCIATION_ASSIGN);

  id nsTitle =
      objc_msgSend((id)objc_getClass("NSString"),
                   sel_registerName("stringWithUTF8String:"), w->title);

  CGRect r = CGRectMake(0, 0, w->width, w->height);

  unsigned int style = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable |
                       NSWindowStyleMaskMiniaturizable;
  if (w->resizable) {
    style = style | NSWindowStyleMaskResizable;
  }

  w->priv.window =
      objc_msgSend((id)objc_getClass("NSWindow"), sel_registerName("alloc"));
  objc_msgSend(w->priv.window,
               sel_registerName("initWithContentRect:styleMask:backing:defer:"),
               r, style, NSBackingStoreBuffered, 0);

  objc_msgSend(w->priv.window, sel_registerName("autorelease"));
  objc_msgSend(w->priv.window, sel_registerName("setTitle:"), nsTitle);
  objc_msgSend(w->priv.window, sel_registerName("setDelegate:"),
               w->priv.windowDelegate);
  objc_msgSend(w->priv.window, sel_registerName("center"));

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
  objc_registerClassPair(__WKUIDelegate);
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
  id navDel = objc_msgSend((id)__WKNavigationDelegate, sel_registerName("new"));

  w->priv.webview =
      objc_msgSend((id)objc_getClass("WKWebView"), sel_registerName("alloc"));
  objc_msgSend(w->priv.webview,
               sel_registerName("initWithFrame:configuration:"), r, config);
  objc_msgSend(w->priv.webview, sel_registerName("setUIDelegate:"), uiDel);
  objc_msgSend(w->priv.webview, sel_registerName("setNavigationDelegate:"),
               navDel);

  id nsURL = objc_msgSend((id)objc_getClass("NSURL"),
                          sel_registerName("URLWithString:"),
                          get_nsstring(webview_check_url(w->url)));

  objc_msgSend(w->priv.webview, sel_registerName("loadRequest:"),
               objc_msgSend((id)objc_getClass("NSURLRequest"),
                            sel_registerName("requestWithURL:"), nsURL));
  objc_msgSend(w->priv.webview, sel_registerName("setAutoresizesSubviews:"), 1);
  objc_msgSend(w->priv.webview, sel_registerName("setAutoresizingMask:"),
               (NSViewWidthSizable | NSViewHeightSizable));
  objc_msgSend(objc_msgSend(w->priv.window, sel_registerName("contentView")),
               sel_registerName("addSubview:"), w->priv.webview);
  objc_msgSend(w->priv.window, sel_registerName("orderFrontRegardless"));

  objc_msgSend(objc_msgSend((id)objc_getClass("NSApplication"),
                            sel_registerName("sharedApplication")),
               sel_registerName("setActivationPolicy:"),
               NSApplicationActivationPolicyRegular);

  // objc_msgSend(objc_msgSend((id)objc_getClass("NSApplication"),
  //                           sel_registerName("sharedApplication")),
  //              sel_registerName("finishLaunching"));

  // objc_msgSend(objc_msgSend((id)objc_getClass("NSApplication"),
  //                           sel_registerName("sharedApplication")),
  //              sel_registerName("activateIgnoringOtherApps:"), YES);

  
  w->priv.should_exit = 0;
  return 0;
}

WEBVIEW_API int webview_loop(struct webview *w, int blocking) {
  id until = (blocking ? objc_msgSend((id)objc_getClass("NSDate"),
                                      sel_registerName("distantFuture"))
                       : objc_msgSend((id)objc_getClass("NSDate"),
                                      sel_registerName("distantPast")));

  id event = objc_msgSend(
      objc_msgSend((id)objc_getClass("NSApplication"),
                   sel_registerName("sharedApplication")),
      sel_registerName("nextEventMatchingMask:untilDate:inMode:dequeue:"),
      ULONG_MAX, until,
      objc_msgSend((id)objc_getClass("NSString"),
                   sel_registerName("stringWithUTF8String:"),
                   "kCFRunLoopDefaultMode"),
      true);

  if (event) {
    objc_msgSend(objc_msgSend((id)objc_getClass("NSApplication"),
                              sel_registerName("sharedApplication")),
                 sel_registerName("sendEvent:"), event);
  }

  return w->priv.should_exit;
}


WEBVIEW_API int webview_eval(struct webview *w, const char *js) {
  id userScript = objc_msgSend(
      (id)objc_getClass("WKUserScript"), sel_registerName("alloc"));
  objc_msgSend(
      userScript,
      sel_registerName("initWithSource:injectionTime:forMainFrameOnly:"),
      get_nsstring(js),
      WKUserScriptInjectionTimeAtDocumentEnd, 0);  
      // should Inject the script after the document finishes loading, but before other subresources finish loading.
      // this also ensure webview give full html structure(html>head+body) in case content only has body inner part.
  id config = objc_msgSend(w->priv.webview, sel_registerName("valueForKey:"), get_nsstring("configuration"));
  id userContentController = objc_msgSend(config, sel_registerName("valueForKey:"), get_nsstring("userContentController"));
  objc_msgSend(userContentController, sel_registerName("addUserScript:"),
               userScript);

  return 0;
}

WEBVIEW_API void webview_set_title(struct webview *w, const char *title) {
  objc_msgSend(w->priv.window, sel_registerName("setTitle:"),
               get_nsstring(title));
}

WEBVIEW_API void webview_set_fullscreen(struct webview *w, int fullscreen) {
  unsigned long windowStyleMask = (unsigned long)objc_msgSend(
      w->priv.window, sel_registerName("styleMask"));
  int b = (((windowStyleMask & NSWindowStyleMaskFullScreen) ==
            NSWindowStyleMaskFullScreen)
               ? 1
               : 0);
  if (b != fullscreen) {
    objc_msgSend(w->priv.window, sel_registerName("toggleFullScreen:"), NULL);
  }
}

WEBVIEW_API void webview_set_iconify(struct webview *w, int iconify) {
  if (iconify) {
    objc_msgSend(w->priv.window, sel_registerName("miniaturize:"), NULL);
  }
  else {
    objc_msgSend(w->priv.window, sel_registerName("deminiaturize:"), NULL);
  }
}

WEBVIEW_API void webview_launch_external_URL(struct webview *w, const char *uri) {
  id url = objc_msgSend((id)objc_getClass("NSURL"),
                          sel_registerName("URLWithString:"),
                          get_nsstring(webview_check_url(uri)));

  objc_msgSend(objc_msgSend((id)objc_getClass("NSWorkspace"),
                                    sel_registerName("sharedWorkspace")),
                       sel_registerName("openURL:"), url);
}

WEBVIEW_API void webview_set_color(struct webview *w, uint8_t r, uint8_t g,
                                   uint8_t b, uint8_t a) {

  id color = objc_msgSend((id)objc_getClass("NSColor"),
                          sel_registerName("colorWithRed:green:blue:alpha:"),
                          (float)r / 255.0, (float)g / 255.0, (float)b / 255.0,
                          (float)a / 255.0);

  objc_msgSend(w->priv.window, sel_registerName("setBackgroundColor:"), color);

  if (0.5 >= ((r / 255.0 * 299.0) + (g / 255.0 * 587.0) + (b / 255.0 * 114.0)) /
                 1000.0) {
    objc_msgSend(w->priv.window, sel_registerName("setAppearance:"),
                 objc_msgSend((id)objc_getClass("NSAppearance"),
                              sel_registerName("appearanceNamed:"),
                              get_nsstring("NSAppearanceNameVibrantDark")));
  } else {
    objc_msgSend(w->priv.window, sel_registerName("setAppearance:"),
                 objc_msgSend((id)objc_getClass("NSAppearance"),
                              sel_registerName("appearanceNamed:"),
                              get_nsstring("NSAppearanceNameVibrantLight")));
  }
  objc_msgSend(w->priv.window, sel_registerName("setOpaque:"), 0);
  objc_msgSend(w->priv.window,
               sel_registerName("setTitlebarAppearsTransparent:"), 1);
  objc_msgSend(w->priv.webview, sel_registerName("_setDrawsBackground:"), 0);
}

WEBVIEW_API void webview_dialog(struct webview *w,
                                enum webview_dialog_type dlgtype, int flags,
                                const char *title, const char *arg,
                                char *result, size_t resultsz) {
  if (dlgtype == WEBVIEW_DIALOG_TYPE_OPEN ||
      dlgtype == WEBVIEW_DIALOG_TYPE_SAVE) {
    id panel = (id)objc_getClass("NSSavePanel");
    if (dlgtype == WEBVIEW_DIALOG_TYPE_OPEN) {
      id openPanel = objc_msgSend((id)objc_getClass("NSOpenPanel"),
                                  sel_registerName("openPanel"));
      if (flags & WEBVIEW_DIALOG_FLAG_DIRECTORY) {
        objc_msgSend(openPanel, sel_registerName("setCanChooseFiles:"), 0);
        objc_msgSend(openPanel, sel_registerName("setCanChooseDirectories:"),
                     1);
      } else {
        objc_msgSend(openPanel, sel_registerName("setCanChooseFiles:"), 1);
        objc_msgSend(openPanel, sel_registerName("setCanChooseDirectories:"),
                     0);
      }
      objc_msgSend(openPanel, sel_registerName("setResolvesAliases:"), 0);
      objc_msgSend(openPanel, sel_registerName("setAllowsMultipleSelection:"),
                   0);
      panel = openPanel;
    } else {
      panel = objc_msgSend((id)objc_getClass("NSSavePanel"),
                           sel_registerName("savePanel"));
    }

    objc_msgSend(panel, sel_registerName("setCanCreateDirectories:"), 1);
    objc_msgSend(panel, sel_registerName("setShowsHiddenFiles:"), 1);
    objc_msgSend(panel, sel_registerName("setExtensionHidden:"), 0);
    objc_msgSend(panel, sel_registerName("setCanSelectHiddenExtension:"), 0);
    objc_msgSend(panel, sel_registerName("setTreatsFilePackagesAsDirectories:"),
                 1);
    objc_msgSend(
        panel, sel_registerName("beginSheetModalForWindow:completionHandler:"),
        w->priv.window, ^(id result) {
          objc_msgSend(objc_msgSend((id)objc_getClass("NSApplication"),
                                    sel_registerName("sharedApplication")),
                       sel_registerName("stopModalWithCode:"), result);
        });

    if (objc_msgSend(objc_msgSend((id)objc_getClass("NSApplication"),
                                  sel_registerName("sharedApplication")),
                     sel_registerName("runModalForWindow:"),
                     panel) == (id)NSModalResponseOK) {
      id url = objc_msgSend(panel, sel_registerName("URL"));
      id path = objc_msgSend(url, sel_registerName("path"));
      const char *filename =
          (const char *)objc_msgSend(path, sel_registerName("UTF8String"));
      strlcpy(result, filename, resultsz);
    }
  } else if (dlgtype == WEBVIEW_DIALOG_TYPE_ALERT) {
    id a = objc_msgSend((id)objc_getClass("NSAlert"), sel_registerName("new"));
    switch (flags & WEBVIEW_DIALOG_FLAG_ALERT_MASK) {
    case WEBVIEW_DIALOG_FLAG_INFO:
      objc_msgSend(a, sel_registerName("setAlertStyle:"),
                   NSAlertStyleInformational);
      break;
    case WEBVIEW_DIALOG_FLAG_WARNING:
      printf("Warning\n");
      objc_msgSend(a, sel_registerName("setAlertStyle:"), NSAlertStyleWarning);
      break;
    case WEBVIEW_DIALOG_FLAG_ERROR:
      printf("Error\n");
      objc_msgSend(a, sel_registerName("setAlertStyle:"), NSAlertStyleCritical);
      break;
    }
    objc_msgSend(a, sel_registerName("setShowsHelp:"), 0);
    objc_msgSend(a, sel_registerName("setShowsSuppressionButton:"), 0);
    objc_msgSend(a, sel_registerName("setMessageText:"), get_nsstring(title));
    objc_msgSend(a, sel_registerName("setInformativeText:"), get_nsstring(arg));
    objc_msgSend(a, sel_registerName("addButtonWithTitle:"),
                 get_nsstring("OK"));
    objc_msgSend(a, sel_registerName("runModal"));
    objc_msgSend(a, sel_registerName("release"));
  }
}

static void webview_dispatch_cb(void *arg) {
  struct webview_dispatch_arg *context = (struct webview_dispatch_arg *)arg;
  (context->fn)(context->w, context->arg);
  free(context);
}

WEBVIEW_API void webview_dispatch(struct webview *w, webview_dispatch_fn fn,
                                  void *arg) {
  struct webview_dispatch_arg *context = (struct webview_dispatch_arg *)malloc(
      sizeof(struct webview_dispatch_arg));
  context->w = w;
  context->arg = arg;
  context->fn = fn;
  dispatch_async_f(dispatch_get_main_queue(), context, webview_dispatch_cb);
}

WEBVIEW_API void webview_terminate(struct webview *w) {
  w->priv.should_exit = 1;
}

WEBVIEW_API void webview_exit(struct webview *w) {
  id app = objc_msgSend((id)objc_getClass("NSApplication"),
                        sel_registerName("sharedApplication"));
  objc_msgSend(app, sel_registerName("terminate:"), app);
}

WEBVIEW_API void webview_print_log(const char *s) { printf("%s\n", s); }

