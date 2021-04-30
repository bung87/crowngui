import objc, foundation, strutils, math, sequtils, macros

# type
#   NSWindow* = object of NSObject # appkit

#   NSWindowController* = object of NSObject # appkit

# converter toId*(w: NSWindow): ID = w.id

proc objc_alloc(cls: string): ID =
  objc_msgSend(getClass(cls).ID, $$"alloc")

# proc autorelease(obj: NSObject) =
#   discard objc_msgSend(obj.id, $$"autorelease")

# proc init(x: typedesc[NSWindow], rect: CMRect, mask: int, backing: int, xdefer: BOOL): NSWindow =
#   var wnd = objc_alloc("NSWindow")
#   var cmd = $$"initWithContentRect:styleMask:backing:defer:"
#   result.id = wnd.objc_msgSend(cmd, rect, mask.uint64, backing.uint64, xdefer)

# proc init(x: typedesc[NSWindowController], window: NSWindow): NSWindowController =
#   var ctrl = objc_alloc("NSWindowController")
#   result.id = ctrl.objc_msgSend($$"initWithWindow:", window.id)

# proc contentView(self: NSWindow, view: NSView) =
#   discard objc_msgSend(self.id, $$"setContentView:", view.id)

# proc init(x: typedesc[NSTextView], rect: CMRect): NSTextView =
#   var view = objc_alloc("NSTextView")
#   result.id = view.objc_msgSend($$"initWithFrame:", rect)

# proc insertText(self: NSTextView, text: string) =
#   discard objc_msgSend(self.id, $$"insertText:", @text.id)

# proc call(cls: typedesc, cmd: SEL) =
#   discard objc_msgSend(getClass(cls.name).ID, cmd)

# proc `[]`(obj: NSObject, cmd: SEL) =
#   discard objc_msgSend(obj.id, cmd)

macro `[]`(id: ID, cmd: SEL, args: varargs[untyped]): ID =
  if args.len > 0:
    let p = "discard objc_msgSend($1, $2, $3)"
    var z = ""
    for a in args:
      z.add(a.toStrLit().strVal)
    var w = p % [id.toStrLit().strVal, cmd.toStrLit().strVal, z]
    result = parseStmt(w)
  else:
    let p = "discard objc_msgSend($1, $2)"
    var w = p % [id.toStrLit().strVal, cmd.toStrLit().strVal]
    result = parseStmt(w)

type
  AppDelegate* = object
    isa: Class
    window: ID

proc shouldTerminate(self: ID, cmd: SEL, notification: ID): BOOL {.cdecl.} =
  var cls = self.getClass()
  var ivar = cls.getIvar("apple")
  var res = cast[int](self.getIvar(ivar))
  echo res

  result = YES

proc makeDelegate(): Class =
  result = allocateClassPair(getClass("NSObject"), "AppDelegate", 0)
  discard result.addMethod($$"applicationShouldTerminateAfterLastWindowClosed:", cast[IMP](shouldTerminate), "c@:@")
  echo result.addIvar("apple", sizeof(int), log2(sizeof(int).float64).int, "q")
  result.registerClassPair()

proc getSuperMethod(id: ID, sel: SEL): Method =
  var superClass = getSuperClass(id.getClass)
  result = getInstanceMethod(superClass, sel)

macro callSuper(id: ID, cmd: SEL, args: varargs[untyped]): untyped =
  let sid = id.toStrLit().strVal
  let scmd = cmd.toStrLit().strVal
  let mm = "getSuperMethod($1, $2)" % [sid, scmd]

  if args.len > 0:
    let p = "discard method_invoke($1, $2, $3)"
    var z = ""
    for a in args:
      z.add(a.toStrLit().strVal)
    var w = p % [sid, mm, z]
    result = parseStmt(w)
  else:
    let p = "discard method_invoke($1, $2)"
    var w = p % [sid, mm]
    result = parseStmt(w)

proc canBe(self: ID, cmd: SEL): BOOL {.cdecl.} =
  result = YES

proc canBecome(id: ID) =
  var cls = getClass(id)
  var sel = $$"showsResizeIndicator"
  var im = getInstanceMethod(cls, sel)
  var types = getTypeEncoding(im)
  discard replaceMethod(cls, sel, cast[IMP](canBe), types)
