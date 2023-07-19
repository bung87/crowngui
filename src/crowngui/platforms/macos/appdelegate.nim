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

# applicationWillFinishLaunching: -> application:openFile: -> applicationDidFinishLaunching:
proc applicationWillFinishLaunching(self: ID; cmd: SEL; notification: ID): void {.cdecl.} =
  echo "applicationWillFinishLaunching"
proc applicationDidFinishLaunching(self: ID; cmd: SEL; notification: ID): void {.cdecl.} =
  echo "applicationDidFinishLaunching"
proc applicationWillBecomeActive(self: ID; cmd: SEL; notification: ID): void {.cdecl.} =
  echo "applicationWillBecomeActive"

proc initAppDelegate*(): Class  =
  result = allocateClassPair(getClass("NSObject"), "AppDelegate", 0)
  discard result.addMethod($$"applicationWillFinishLaunching:", cast[IMP](applicationWillFinishLaunching), getProcEncode(applicationWillFinishLaunching))
  discard result.addMethod($$"applicationDidFinishLaunching:", cast[IMP](applicationDidFinishLaunching), getProcEncode(applicationDidFinishLaunching))
  discard result.addMethod($$"applicationWillBecomeActive:", cast[IMP](applicationWillBecomeActive), getProcEncode(applicationWillBecomeActive))
  discard result.addMethod($$"application:openFile:", cast[IMP](application), getProcEncode(application))

    
  discard addIvar(result, "webview", sizeof(Webview), log2(sizeof(Webview).float64).int, "@")