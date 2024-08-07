import std/[math]
import objc_runtime
import darwin / [app_kit, foundation, objc/runtime]
import ./types
import ./bundle

proc applicationOpenFile(self: ID; cmd: SEL; sender: NSApplication; openFile: NSString): Bool {.cdecl.} =
  let path = cast[cstring](objc_msgSend(cast[ID](openFile), $$"UTF8String"))
  var cls = self.getClass()
  var ivar = cls.getIvar("webview")
  var wv = cast[Webview](self.getIvar(ivar))
  if wv.onOpenFile != nil:
    return cast[Bool](wv.onOpenFile(wv, $path))

proc applicationShouldTerminateAfterLastWindowClosed(self: ID; cmd: SEL; notification: ID): bool {.cdecl.} =
  return false

# applicationWillFinishLaunching: -> application:openFile: -> applicationDidFinishLaunching:
proc applicationWillFinishLaunching(self: ID; cmd: SEL; notification: ID): void {.cdecl.} =
  echo "applicationWillFinishLaunching"

proc on_application_did_finish_launching(delegate: ID; app: ID) {.objcr.}=
  # if m_owns_window:
  # stopRunLoop()
  if not isAppBundled():
    [app setActivationPolicy: NSApplicationActivationPolicyRegular]
    [app activateIgnoringOtherApps: YES]
  # set_up_window()

proc applicationDidFinishLaunching(self: ID; cmd: SEL; notification: ID): void {.cdecl.} =
  echo "applicationDidFinishLaunching"
  # var w = getAssociatedObject(self, cast[pointer]($$"webview"))
  # var wv = cast[Webview](w)
  
  objcr:
    let app = [notification $$"object"]
    on_application_did_finish_launching(self, app)

proc applicationWillBecomeActive(self: ID; cmd: SEL; notification: ID): void {.cdecl.} =
  echo "applicationWillBecomeActive"

proc registerAppDelegate*(): ObjcClass =
  result = allocateClassPair(getClass("NSResponder"), "MyAppDelegate", 0)
  discard result.addMethod($$"applicationShouldTerminateAfterLastWindowClosed:", applicationShouldTerminateAfterLastWindowClosed)
  # discard result.addMethod($$"applicationWillFinishLaunching:", applicationWillFinishLaunching)
  discard result.addMethod($$"applicationDidFinishLaunching:", applicationDidFinishLaunching)
  # discard result.addMethod($$"applicationWillBecomeActive:", applicationWillBecomeActive)
  discard result.addMethod($$"application:openFile:", applicationOpenFile)

  discard addIvar(result, "webview", sizeof(Webview), log2(sizeof(Webview).float64).int, "@")
  result.registerClassPair()