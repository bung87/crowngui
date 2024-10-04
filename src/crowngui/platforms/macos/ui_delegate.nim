
import darwin / [app_kit, web_kit, foundation, objc/runtime]
import ./internal_dialogs

type MyUIDelegate* = ptr object of NSObject

proc setUIDelegate*(s: WKWebview, d: NSObject) {.objc: "setUIDelegate:".}

proc registerUIDelegate*(): ObjcClass =
  result = allocateClassPair(getClass("NSObject"), "MyWKUIDelegate", 0)
  discard addProtocol(result, getProtocol("WKUIDelegate"))
  discard addMethod(result,
                  $$"webView:runOpenPanelWithParameters:initiatedByFrame:completionHandler:",
                  run_open_panel)
  discard addMethod(result,
                  $$"webView:runJavaScriptAlertPanelWithMessage:initiatedByFrame:completionHandler:",
                  run_alert_panel)
  discard addMethod(
      result,
      $$"webView:runJavaScriptConfirmPanelWithMessage:initiatedByFrame:completionHandler:",
      run_confirmation_panel)
  registerClassPair(result)