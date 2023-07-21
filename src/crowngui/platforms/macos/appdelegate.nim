import std/[math]
import objc_runtime
import darwin / [app_kit, foundation, objc/runtime]
import types

proc application(self: ID; cmd: SEL; sender: NSApplication; openFile: NSString): Bool {.cdecl.} =
  let path = cast[cstring](objc_msgSend(cast[ID](openFile), $$"UTF8String"))
  var cls = self.getClass()
  var ivar = cls.getIvar("webview")
  var wv = cast[Webview](self.getIvar(ivar))
  if wv.onOpenFile != nil:
    return cast[Bool](wv.onOpenFile(wv, $path))

proc applicationShouldTerminateAfterLastWindowClosed(self: ID; cmd: SEL; notification: ID): bool {.cdecl.} =
  return true

# applicationWillFinishLaunching: -> application:openFile: -> applicationDidFinishLaunching:
proc applicationWillFinishLaunching(self: ID; cmd: SEL; notification: ID): void {.cdecl.} =
  echo "applicationWillFinishLaunching"
proc applicationDidFinishLaunching(self: ID; cmd: SEL; notification: ID): void {.cdecl.} =
  echo "applicationDidFinishLaunching"
  objcr:
    let app = [notification $$"object"]
    [app stop: nil]

proc applicationWillBecomeActive(self: ID; cmd: SEL; notification: ID): void {.cdecl.} =
  echo "applicationWillBecomeActive"

proc initAppDelegate*(): ObjcClass =
  result = allocateClassPair(getClass("NSResponder"), "WebviewAppDelegate", 0)
  discard result.addMethod($$"applicationShouldTerminateAfterLastWindowClosed:", applicationShouldTerminateAfterLastWindowClosed)
  discard result.addMethod($$"applicationWillFinishLaunching:", applicationWillFinishLaunching)
  discard result.addMethod($$"applicationDidFinishLaunching:", applicationDidFinishLaunching)
  discard result.addMethod($$"applicationWillBecomeActive:", applicationWillBecomeActive)
  discard result.addMethod($$"application:openFile:", application)

  discard addIvar(result, "webview", sizeof(Webview), log2(sizeof(Webview).float64).int, "@")