import objc_runtime
import darwin / [app_kit, objc/runtime, core_graphics/cggeometry]

proc stopRunLoop*() {.objcr.} =
  # var app = NSApplication.sharedApplication
  var app = [NSApplication sharedApplication]
  [app stop: nil]
  # app.stop(nil)
  var event = [NSEvent $$"otherEventWithType:location:modifierFlags:timestamp:windowNumber:context:subtype:data1:data2:", 15, CGPointMake(0, 0), 0, 0, 0, nil, 0, 0, 0]
  [app $$"postEvent:atStart:", event, YES]
  # app.postEvent(event, YES)
