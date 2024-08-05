import objc_runtime
import darwin / [app_kit, foundation, objc/runtime]
import ./internal_dialogs

proc registerUIDelegate*(): ObjcClass =
  result = allocateClassPair(getClass("NSObject"), "PrivWKUIDelegate", 0)
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