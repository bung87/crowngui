import objc_runtime
import darwin / [ foundation, objc/runtime] 
type
    NSBundle* = ptr object of NSObject

proc mainBundle*(self: typedesc[NSBundle]): NSBundle {.objc: "mainBundle" .}
proc bundlePath*(self: NSBundle): NSString {.objc: "bundlePath".}

proc isAppBundled*(): bool =
  objcr:
    var bundle = [NSBundle mainBundle]
    if bundle.isNil:
      return false
    var bundlePath = [bundle bundlePath]
    var bundled = cast[bool]([bundlePath hasSuffix: @".app"])
    return bundled == true
