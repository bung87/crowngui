import objc_runtime
import darwin / [app_kit, objc/runtime, core_graphics/cggeometry]
import ./types

proc stop_run_loop() {.objcr.} =
  var app = [NSApplication sharedApplication]
  [app stop: nil]
  var event = [NSEvent $$"otherEventWithType:location:modifierFlags:timestamp:windowNumber:context:subtype:data1:data2:", 15, CGPointMake(0, 0), 0, 0, 0, nil, 0, 0, 0]
  [app $$"postEvent:atStart:", event, YES]

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
