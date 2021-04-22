import objc, foundation, strutils, macros, typetraits, math, sequtils
import regex
type
  NSObject* = object of RootObj
    id*: ID

  NSWindow = object of NSObject

  NSWindowController = object of NSObject

  NSView = object of NSObject

  NSTextView = object of NSView

  NSString* = object of NSObject

  NSApplication* = object of NSObject

converter toId*(w: NSWindow): ID = cast[ID](w.unsafeAddr)
proc `@`*(a: string): NSString =
  result.id = objc_msgSend(getClass("NSString").ID, $$"stringWithUTF8String:", a.cstring)

proc objc_alloc(cls: string): ID =
  objc_msgSend(getClass(cls).ID, $$"alloc")

proc autorelease(obj: NSObject) =
  discard objc_msgSend(obj.id, $$"autorelease")

proc init(x: typedesc[NSWindow], rect: CMRect, mask: int, backing: int, xdefer: BOOL): NSWindow =
  var wnd = objc_alloc("NSWindow")
  var cmd = $$"initWithContentRect:styleMask:backing:defer:"
  result.id = wnd.objc_msgSend(cmd, rect, mask.uint64, backing.uint64, xdefer)

proc init(x: typedesc[NSWindowController], window: NSWindow): NSWindowController =
  var ctrl = objc_alloc("NSWindowController")
  result.id = ctrl.objc_msgSend($$"initWithWindow:", window.id)

proc contentView(self: NSWindow, view: NSView) =
  discard objc_msgSend(self.id, $$"setContentView:", view.id)

proc init(x: typedesc[NSTextView], rect: CMRect): NSTextView =
  var view = objc_alloc("NSTextView")
  result.id = view.objc_msgSend($$"initWithFrame:", rect)

proc insertText(self: NSTextView, text: string) =
  discard objc_msgSend(self.id, $$"insertText:", @text.id)

proc call(cls: typedesc, cmd: SEL) =
  discard objc_msgSend(getClass(cls.name).ID, cmd)

proc `[]`(obj: NSObject, cmd: SEL) =
  discard objc_msgSend(obj.id, cmd)

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
  AppDelegate = object
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

proc newClass(cls: string): ID =
  objc_msgSend(objc_msgSend(getClass(cls).ID, $$"alloc"), $$"init")

proc genCall(args: var NimNode): NimNode =
  result = newCall(ident"objc_msgSend")
  for i in 0 ..< args.len:
    result.add args[i]
  if args[0].kind == nnkIdent:
    var m: RegexMatch
    if args[0].strVal.match(re"^[A-Z]+\w+", m):
      result[1] = newCall(ident"ID", nnkCall.newTree(ident"getClass", args[0].toStrLit))
    else:
      result[1] = newDotExpr(args[0], ident"ID")
  if args[1].kind == nnkIdent:
    result[2] = nnkCall.newTree(ident"registerName", args[1].toStrLit)
  elif args[1].kind == nnkStrLit:
    echo args[1].strVal
    result[2] = newCall(ident"get_nsstring", args[1])

proc replaceBracket(node: var NimNode) =
  var z = 0
  for s in node:
    var son = node[z]
    if son.kind == nnkCommand:
      node = genCall(son)
    elif son.kind == nnkExprColonExpr:
      var tmp = son[0]
      node = genCall(tmp)
    else:
      replaceBracket(son)
    # if son.kind == nnkReturnStmt:
    #   let value = if son[0].kind != nnkEmpty and son[0].kind = nnkBracket: genCall()
    #   node[z] = nnkReturnStmt.newTree(value)
    # elif son.kind == nnkAsgn and son[0].kind == nnkIdent and $son[0] == "result":
    #   node[z] = nnkAsgn.newTree(son[0], nnkCall.newTree(jsResolve, son[1]))
    # else:
    #   replaceBracket(son)
    inc z

proc generateOc(arg: NimNode): NimNode =
  result = arg
  replaceBracket(result)


macro objcr*(arg: untyped): untyped =
  if arg.kind == nnkStmtList:
    result = newStmtList()
    for one in arg:
      result.add generateOc(one)
  else:
    result = generateOc(arg)

# proc main() =

#   var pool = newClass("NSAutoReleasePool")
#   objcr:
#     [NSApplication sharedApplication]
#   # NSApplication.call $$"sharedApplication"

#   if NSApp.isNil:
#     echo "Failed to initialized NSApplication...  terminating..."
#     return
#   objcr:
#     [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular]
#   # NSApp[$$"setActivationPolicy:", NSApplicationActivationPolicyRegular]

#   var windowStyle = NSTitledWindowMask or NSClosableWindowMask or
#     NSMiniaturizableWindowMask or NSResizableWindowMask

#   var windowRect = NSMakeRect(100,100,400,400)
#   var window = NSWindow.init(windowRect, windowStyle, NSBackingStoreBuffered, NO)
#   window.autorelease()
#   objcr:
#     [window setTitle:"Hello"]

#   var AppDelegate = makeDelegate()
#   var appDel = newClass("AppDelegate")

#   var ivar = AppDelegate.getIvar("apple")

#   setIvar(appDel, ivar, cast[ID](123))
#   objcr:
#     [NSApp setDelegate:appDel]
#     [window display]
#     [window orderFrontRegardless]
#     [NSApp run]
#     [pool drain]
#   # window.id[$$"display"]
#   # window.id[$$"orderFrontRegardless"]
#   # NSApp[$$"run"]
#   # pool[$$"drain"]
#   AppDelegate.disposeClassPair()

# when isMainModule:
#   main()
