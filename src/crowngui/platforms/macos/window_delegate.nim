import objc_runtime
import darwin / [objc/runtime]

proc webview_window_will_close(self: Id; cmd: SEL; notification: Id) =
  var w = getAssociatedObject(self, cast[pointer]($$"webview"))
  # webview_terminate(cast[Webview](w))

proc registerWindowDelegate*(): ObjcClass =
  result = allocateClassPair(getClass("NSObject"),
                                                    "PrivNSWindowDelegate", 0)
  discard addProtocol(result, getProtocol("NSWindowDelegate"))
  discard replaceMethod(result, $$"windowWillClose:", webview_window_will_close)
  registerClassPair(result)
