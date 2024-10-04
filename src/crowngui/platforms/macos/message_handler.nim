
import darwin / [app_kit, web_kit, foundation, objc/runtime]
import ../../types

proc webview_external_invoke(self: ID; cmd: SEL; contentController: WKUserContentController;
                                    message: WKScriptMessage) =
  var w = cast[Webview](getAssociatedObject(contentController, cast[pointer]($$"webview")))
  if (cast[pointer](w) == nil or w.invokeCb == nil):
    return

  var msg = cast[NSString](message.body).UTF8String
  cast[proc (w: Webview; arg: cstring) {.stdcall.}](w.invokeCb)(w, cast[cstring](msg))


proc registerScriptMessageHandler*(): ObjcClass =
  result = allocateClassPair(getClass("NSObject"), "PrivWKScriptMessageHandler", 0)
  discard  addMethod(result, $$"userContentController:didReceiveScriptMessage:", webview_external_invoke)
  registerClassPair(result)