
import darwin / [app_kit, objc/runtime]
import ../../types

proc webview_window_will_close(self: Id; cmd: SEL; notification: Id) =
  var w = getAssociatedObject(self, cast[pointer]($$"webview"))
  var wv = cast[Webview](w)
  wv.priv.webview = nil
  wv.priv.window  = nil
  wv = nil
  # webview_terminate(cast[Webview](w))

proc registerWindowDelegate*(): ObjcClass =
  result = allocateClassPair(getClass("NSObject"),
                                                    "PrivNSWindowDelegate", 0)
  discard addProtocol(result, getProtocol("NSWindowDelegate"))
  discard replaceMethod(result, $$"windowWillClose:", webview_window_will_close)
  registerClassPair(result)
