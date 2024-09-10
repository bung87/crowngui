import objc_runtime
import darwin / [app_kit, foundation, objc/runtime]
import crowngui/types

proc webview_external_invoke(self: ID; cmd: SEL; contentController: Id;
                                    message: Id) =
  var w = cast[Webview](getAssociatedObject(contentController, cast[pointer]($$"webview")))
  if (cast[pointer](w) == nil or w.invokeCb == nil):
    return

  objcr:
    var msg = [[message body]UTF8String]
    cast[proc (w: Webview; arg: cstring) {.stdcall.}](w.invokeCb)(w, cast[cstring](msg))


proc registerScriptMessageHandler*(): ObjcClass =
  result = allocateClassPair(getClass("NSObject"), "PrivWKScriptMessageHandler", 0)
  discard  addMethod(result, $$"userContentController:didReceiveScriptMessage:", webview_external_invoke)
  registerClassPair(result)