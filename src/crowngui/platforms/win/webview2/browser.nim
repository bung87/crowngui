
import winim
import com
import types
from environment_completed_handler import nil
from controller_completed_handler import nil
from environment_options import nil
from web_message_received_handler import nil
from com/icorewebview2domcontentloadedeventhandler import nil
import std/[os, atomics,pathnorm,sugar,json]
import loader

const  IID_ICoreWebView2Controller2 = DEFINE_GUID"C979903E-D4CA-4228-92EB-47EE3FA96EAB"

using
  self: ptr ICoreWebView2CreateCoreWebView2ControllerCompletedHandler


proc newControllerCompletedHandler(hwnd: HWND;controller: ptr ICoreWebView2Controller;view: ptr ICoreWebView2; settings: ptr ICoreWebView2Settings): ptr ICoreWebView2CreateCoreWebView2ControllerCompletedHandler =
  result = create(type result[])
  result.windowHandle = hwnd
  result.lpVtbl = create(ICoreWebView2CreateCoreWebView2ControllerCompletedHandlerVTBL)
  result.lpVtbl.QueryInterface = controller_completed_handler.QueryInterface
  result.lpVtbl.AddRef = controller_completed_handler.AddRef
  result.lpVtbl.Release = controller_completed_handler.Release
  result.lpVtbl.Invoke = proc (self: ptr ICoreWebView2CreateCoreWebView2ControllerCompletedHandler;
      errorCode: HRESULT;
      createdController: ptr ICoreWebView2Controller): HRESULT {.stdcall.} =
    if errorCode != S_OK:
      return errorCode
    assert createdController != nil
    # discard createdController.lpVtbl.QueryInterface(createdController, IID_ICoreWebView2Controller2.unsafeAddr, cast[ptr pointer](controller))
    var w = cast[Webview](GetWindowLongPtr(self.windowHandle, GWLP_USERDATA))
    
    w.browser.ctx.controller = createdController
    var bounds: RECT
    GetClientRect(self.windowHandle, bounds)
    discard w.browser.ctx.controller.lpVtbl.AddRef(w.browser.ctx.controller)
    discard w.browser.ctx.controller.lpVtbl.put_Bounds(w.browser.ctx.controller, bounds)
    discard w.browser.ctx.controller.lpVtbl.put_IsVisible(w.browser.ctx.controller, true)
    let hr = w.browser.ctx.controller.lpVtbl.get_CoreWebView2(w.browser.ctx.controller, w.browser.ctx.view.addr)
    discard w.browser.ctx.view.lpVtbl.AddRef(w.browser.ctx.view)
    if S_OK != hr:
      return hr
    w.created = true
    doAssert w.browser.ctx.view != nil
    let hr1 = w.browser.ctx.view.lpVtbl.get_Settings(w.browser.ctx.view, w.browser.ctx.settings.addr)
    discard w.browser.ctx.settings.lpVtbl.PutIsScriptEnabled(w.browser.ctx.settings, true)
    discard w.browser.ctx.settings.lpVtbl.PutAreDefaultScriptDialogsEnabled(w.browser.ctx.settings, true)
    discard w.browser.ctx.settings.lpVtbl.PutIsWebMessageEnabled(w.browser.ctx.settings, true)
    discard w.browser.ctx.settings.lpVtbl.PutAreDevToolsEnabled(w.browser.ctx.settings, true)
    var webMesssageReceivedHandler = create(ICoreWebView2WebMessageReceivedEventHandler)
    webMesssageReceivedHandler.lpVtbl = create(ICoreWebView2WebMessageReceivedEventHandlerVTBL)
    webMesssageReceivedHandler.windowHandle = self.windowHandle
    webMesssageReceivedHandler.lpVtbl.QueryInterface = web_message_received_handler.QueryInterface
    webMesssageReceivedHandler.lpVtbl.AddRef = web_message_received_handler.AddRef
    webMesssageReceivedHandler.lpVtbl.Release = web_message_received_handler.Release
    webMesssageReceivedHandler.lpVtbl.Invoke = proc (self: ptr ICoreWebView2WebMessageReceivedEventHandler;
        sender: ptr ICoreWebView2; args: ptr ICoreWebView2WebMessageReceivedEventArgs) {.stdcall.} =
      var w = cast[Webview](GetWindowLongPtr(self.windowHandle, GWLP_USERDATA))
      if (cast[pointer](w) == nil or w.invokeCb == nil):
        return
      var source: LPWSTR
      discard args.lpVtbl.TryGetWebMessageAsString(args, &source)
      cast[proc (w: Webview; arg: cstring) {.stdcall.}](w.invokeCb)(w, ($source).cstring)
      CoTaskMemFree(source)
    
    var token: EventRegistrationToken
    discard w.browser.ctx.view.lpVtbl.add_WebMessageReceived(w.browser.ctx.view, webMesssageReceivedHandler, token.addr)
    var script = T"""window.external = this; invoke = function(arg){
                   window.chrome.webview.postMessage(arg);
                    };"""
    discard w.browser.ctx.view.lpVtbl.AddScriptToExecuteOnDocumentCreated(w.browser.ctx.view, &script, NULL)
    discard w.browser.ctx.view.lpVtbl.Navigate(w.browser.ctx.view, L(w.url))
    return S_OK

proc newEnvironmentCompletedHandler*(hwnd: HWND;controllerCompletedHandler: ptr ICoreWebView2CreateCoreWebView2ControllerCompletedHandler): ptr ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler =
  result = create(type result[])
  result.windowHandle = hwnd
  result.controllerCompletedHandler = controllerCompletedHandler
  result.lpVtbl = create(ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandlerVTBL)
  result.lpVtbl.QueryInterface = environment_completed_handler.QueryInterface
  result.lpVtbl.AddRef = environment_completed_handler.AddRef
  result.lpVtbl.Release = environment_completed_handler.Release
  result.lpVtbl.Invoke = proc (self:ptr ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler;
          errorCode: HRESULT;
          createdEnvironment: ptr ICoreWebView2Environment): HRESULT {.stdcall.} =
    if errorCode != S_OK:
      return errorCode
    let hr = createdEnvironment.lpVtbl.CreateCoreWebView2Controller(
        createdEnvironment, self.windowHandle, self.controllerCompletedHandler)
    assert hr == S_OK
    return hr

proc resize*(b: Browser, hwnd: HWND): void =
  var bounds: RECT
  let g = GetClientRect(hwnd, bounds)
  doAssert g == TRUE, $GetLastError()
  doAssert b.ctx.controller != nil
  discard b.ctx.controller.lpVtbl.put_Bounds(b.ctx.controller, bounds)

proc embed*(b: Browser; wv: WebView) =
  b.ctx.windowHandle = wv.window[].handle
  let exePath = getAppFilename()
  var (dir, name, ext) = splitFile(exePath)
  var dataPath = normalizePath(getEnv("AppData") / name)
  createDir(dataPath)
  # var versionInfo: LPWSTR
  # GetAvailableCoreWebView2BrowserVersionString(NULL, versionInfo.addr)
  # echo versionInfo
  # CoTaskMemFree(versionInfo)
  var controllerCompletedHandler = newControllerCompletedHandler(b.ctx.windowHandle, b.ctx.controller, b.ctx.view, b.ctx.settings)
  var environmentCompletedHandler = newEnvironmentCompletedHandler(b.ctx.windowHandle, controllerCompletedHandler)
  var options = create(ICoreWebView2EnvironmentOptions)
  options.lpVtbl = create(ICoreWebView2EnvironmentOptionsVTBL)
  options.lpVtbl.QueryInterface = environment_options.QueryInterface
  options.lpVtbl.AddRef = environment_options.AddRef
  options.lpVtbl.Release = environment_options.Release
  options.lpVtbl.get_AdditionalBrowserArguments = environment_options.get_AdditionalBrowserArguments
  options.lpVtbl.put_AdditionalBrowserArguments = environment_options.put_AdditionalBrowserArguments
  options.lpVtbl.get_Language = environment_options.get_Language
  options.lpVtbl.put_Language = environment_options.put_Language
  options.lpVtbl.get_TargetCompatibleBrowserVersion = environment_options.get_TargetCompatibleBrowserVersion
  options.lpVtbl.put_TargetCompatibleBrowserVersion = environment_options.put_TargetCompatibleBrowserVersion
  options.lpVtbl.get_AllowSingleSignOnUsingOSPrimaryAccount = environment_options.get_AllowSingleSignOnUsingOSPrimaryAccount
  options.lpVtbl.put_AllowSingleSignOnUsingOSPrimaryAccount = environment_options.put_AllowSingleSignOnUsingOSPrimaryAccount
  options.lpVtbl.get_ExclusiveUserDataFolderAccess = environment_options.get_ExclusiveUserDataFolderAccess
  options.lpVtbl.put_ExclusiveUserDataFolderAccess = environment_options.put_ExclusiveUserDataFolderAccess

  let r1 = CreateCoreWebView2EnvironmentWithOptions("", dataPath, options, environmentCompletedHandler)
  # let folder = "C:\\Program Files (x86)\\Microsoft\\EdgeWebView\\Application\\104.0.1293.70"

  doAssert r1 == S_OK, "failed to call CreateCoreWebView2EnvironmentWithOptions"
  # simulate synchronous
  # https://github.com/MicrosoftEdge/WebView2Feedback/issues/740
  assert wv.created == false
  var msg: MSG
  while wv.created == false and GetMessage(msg.addr, 0, 0, 0).bool:
    TranslateMessage(msg.addr)
    DispatchMessage(msg.addr)

proc navigate*(b: Browser; url: string) =
  discard b.ctx.view.lpVtbl.Navigate(b.ctx.view, +$(url))

proc AddScriptToExecuteOnDocumentCreated*(b: Browser; script: string) =
  var script = T(script)
  discard b.ctx.view.lpVtbl.AddScriptToExecuteOnDocumentCreated(b.ctx.view, &script, NULL)

proc ExecuteScript*(b: Browser; script: string) =
  var script = T(script)
  discard b.ctx.view.lpVtbl.ExecuteScript(b.ctx.view, &script, NUll)

proc addUserScriptAtiptAtDocumentEnd*(b: Browser; script: string) =
  var token: EventRegistrationToken
  var handler = create(ICoreWebView2DOMContentLoadedEventHandler)
  handler.lpVtbl = create(ICoreWebView2DOMContentLoadedEventHandlerVTBL)
  handler.lpVtbl.QueryInterface = icorewebview2domcontentloadedeventhandler.QueryInterface
  handler.lpVtbl.AddRef = icorewebview2domcontentloadedeventhandler.AddRef
  handler.lpVtbl.Release = icorewebview2domcontentloadedeventhandler.Release
  handler.script = script
  handler.lpVtbl.Invoke = proc (self: ptr ICoreWebView2DOMContentLoadedEventHandler;
      sender: ptr ICoreWebView2;
      args: ptr ICoreWebView2DOMContentLoadedEventArgs): HRESULT {.stdcall.} =
    var script = T(self.script)
    echo self.script
    sender.lpVtbl.ExecuteScript(sender, &script, NUll)

  discard b.ctx.view.lpVtbl.add_DOMContentLoaded(b.ctx.view, handler , token.addr)

# proc saveSetting*(b: Browser;setter:pointer; enabled: bool) =
#   var flag:clong = 0

#   if enabled:
#     flag = 1
#   syscall(cast[clong](setter), 3, cast[clong](b.settings.addr), flag, 0)

# proc saveSettings*(b: Browser;) =
#   b.saveSetting(b.settings.lpVtbl.PutIsBuiltInErrorPageEnabled, b.config.builtInErrorPage)
#   b.saveSetting(b.settings.lpVtbl.PutAreDefaultContextMenusEnabled, b.config.defaultContextMenus)
#   b.saveSetting(b.settings.lpVtbl.PutAreDefaultScriptDialogsEnabled, b.config.defaultScriptDialogs)
#   b.saveSetting(b.settings.lpVtbl.PutAreDevToolsEnabled, b.config.devtools)
#   b.saveSetting(b.settings.lpVtbl.PutAreHostObjectsAllowed, b.config.hostObjects)
#   b.saveSetting(b.settings.lpVtbl.PutIsScriptEnabled, b.config.script)
#   b.saveSetting(b.settings.lpVtbl.PutIsStatusBarEnabled, b.config.statusBar)
#   b.saveSetting(b.settings.lpVtbl.PutIsWebMessageEnabled, b.config.webMessage)
#   b.saveSetting(b.settings.lpVtbl.PutIsZoomControlEnabled, b.config.zoomControl)

