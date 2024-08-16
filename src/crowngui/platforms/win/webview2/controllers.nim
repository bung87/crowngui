
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
import ../../../types

proc newControllerCompletedHandler*(hwnd: HWND;controller: ptr ICoreWebView2Controller;view: ptr ICoreWebView2; settings: ptr ICoreWebView2Settings): ptr ICoreWebView2CreateCoreWebView2ControllerCompletedHandler =
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
    var w = cast[Webview](GetWindowLongPtr(self.windowHandle, GWLP_USERDATA))
    
    w.priv.controller = createdController
    var bounds: RECT
    GetClientRect(self.windowHandle, bounds)
    discard w.priv.controller.AddRef()
    discard w.priv.controller.put_Bounds( bounds)
    discard w.priv.controller.put_IsVisible( true)
    let hr = w.priv.controller.get_CoreWebView2( w.priv.view.addr)
    discard w.priv.view.AddRef()
    if S_OK != hr:
      return hr
    w.created = true
    doAssert w.priv.view != nil
    let hr1 = w.priv.view.get_Settings( w.priv.settings.addr)
    discard w.priv.settings.PutIsScriptEnabled(true)
    discard w.priv.settings.PutAreDefaultScriptDialogsEnabled(true)
    discard w.priv.settings.PutIsWebMessageEnabled(true)
    discard w.priv.settings.PutAreDevToolsEnabled(true)
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
      discard args.TryGetWebMessageAsString(&source)
      cast[proc (w: Webview; arg: cstring) {.stdcall.}](w.invokeCb)(w, ($source).cstring)
      CoTaskMemFree(source)
    
    var token: EventRegistrationToken
    discard w.priv.view.add_WebMessageReceived(webMesssageReceivedHandler, token.addr)
    var script = T"""window.external = this; invoke = function(arg){
                   window.chrome.webview.postMessage(arg);
                    };"""
    discard w.priv.view.AddScriptToExecuteOnDocumentCreated(&script, NULL)
    if w.entryType == EntryType.html:
      discard w.priv.view.NavigateToString(T(w.url))
    else:
      discard w.priv.view.Navigate(T(w.url))
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
    let hr = createdEnvironment.CreateCoreWebView2Controller(self.windowHandle, self.controllerCompletedHandler)
    assert hr == S_OK
    return hr


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

