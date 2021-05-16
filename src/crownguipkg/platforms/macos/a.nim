import objc_runtime,macros
import darwin / [app_kit, foundation,objc/runtime ,objc/blocks,core_graphics/cggeometry]
const NSAlertFirstButtonReturn = 1
when isMainModule:
  expandMacros:
    objcr:
      var event:Id
      var flag:NSUInteger = cast[NSUInteger]([event modifierFlags])