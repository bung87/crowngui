import std/[math]
import darwin / [app_kit, foundation, objc/runtime]
import ../../types
import ./bundle
import ./menu

type MyAppDelegate* = ptr object of NSObject

proc applicationOpenFile(self: MyAppDelegate; cmd: SEL; sender: NSApplication; openFile: NSString): Bool {.cdecl.} =
  let path = cast[cstring](objc_msgSend(cast[ID](openFile), $$"UTF8String"))
  var cls = self.getClass()
  var ivar = cls.getIvar("webview")
  var wv = cast[Webview](self.getIvar(ivar))
  if wv.onOpenFile != nil:
    return cast[Bool](wv.onOpenFile(wv, $path))

proc applicationShouldTerminateAfterLastWindowClosed(self: MyAppDelegate; cmd: SEL; notification: ID): bool {.cdecl.} =
  # return true, so will not stay in dock and wait for reactivation
  return true

# applicationWillFinishLaunching: -> application:openFile: -> applicationDidFinishLaunching:
proc applicationWillFinishLaunching(self: MyAppDelegate; cmd: SEL; notification: ID): void {.cdecl.} =
  when not defined(release):
    echo "applicationWillFinishLaunching"

proc on_application_did_finish_launching(delegate: ID; app: NSApplication) =
  # if m_owns_window:
  # stopRunLoop()
  # createMenu()
  if not isAppBundled():
    app.setActivationPolicy(NSApplicationActivationPolicyRegular)
    app.activate()
    # app.activateIgnoringOtherApps(YES)
  # set_up_window()

proc applicationDidFinishLaunching(self: MyAppDelegate; cmd: SEL; notification: NSNotification): void {.cdecl.} =
  when not defined(release):
    echo "applicationDidFinishLaunching"
  # var w = getAssociatedObject(self, cast[pointer]($$"webview"))
  # var wv = cast[Webview](w)
  let app = cast[NSApplication](notification.`object`)
  on_application_did_finish_launching(self, app)

proc applicationWillBecomeActive(self: MyAppDelegate; cmd: SEL; notification: ID): void {.cdecl.} =
  # close button pressed, stay in dock. then press from dock to activate app.
  when not defined(release):
    echo "applicationWillBecomeActive"
  # var w = getAssociatedObject(self, cast[pointer]($$"webview"))
  # var wv = cast[Webview](w)
  # wv.webview_init()

proc registerAppDelegate*(): ObjcClass =
  result = allocateClassPair(getClass("NSResponder"), "MyAppDelegate", 0)
  discard result.addMethod($$"applicationShouldTerminateAfterLastWindowClosed:", applicationShouldTerminateAfterLastWindowClosed)
  discard result.addMethod($$"applicationWillFinishLaunching:", applicationWillFinishLaunching)
  discard result.addMethod($$"applicationDidFinishLaunching:", applicationDidFinishLaunching)
  discard result.addMethod($$"applicationWillBecomeActive:", applicationWillBecomeActive)
  discard result.addMethod($$"application:openFile:", applicationOpenFile)

  discard addIvar(result, "webview", sizeof(Webview), log2(sizeof(Webview).float64).int, "@")
  result.registerClassPair()