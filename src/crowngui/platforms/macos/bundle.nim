import objc_runtime
import darwin / [ foundation, objc/runtime] 

proc isAppBundled*(): bool =
  objcr:
    var bundle = [NSBundle mainBundle]
    if bundle.isNil:
      return false
    var bundlePath = [bundle bundlePath]
    var bundled = cast[bool]([bundlePath hasSuffix: @".app"])
    return bundled == true