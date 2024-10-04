import darwin / [ foundation, objc/runtime] 

proc isAppBundled*(): bool =
  var bundle = NSBundle.mainBundle
  if bundle.isNil:
    return false
  var bundlePath = bundle.bundlePath
  var bundled = cast[bool](bundlePath.hasSuffix(@".app"))
  return bundled == true
