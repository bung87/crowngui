
import std/[math]
import objc_runtime
import darwin / [app_kit, foundation, objc/runtime]
import types

proc awakeFromNib(self: ID; cmd: SEL; ): void {.cdecl.} =
  objcr:
    var super = ObjcSuper(receiver: self, superClass: self.getClass().getSuperclass())
    discard objc_msgSendSuper(super, $$"awakeFromNib")
    var typs = [[MutableArray alloc]init]
    [typs addObject: @"xlsx"]
    let tid = cast[ID](typs.unsafeAddr)
    [self registerForDraggedTypes: tid]

proc initWithCoder(self: ID; cmd: SEL; code: ID): ID {.cdecl.} =
  objcr:
    var super = ObjcSuper(receiver: self, superClass: self.getClass().getSuperclass())
    discard objc_msgSendSuper(super, $$"initWithCoder")
    var typs = [[MutableArray alloc]init]
    [typs addObject: @"xlsx"]
    let tid = cast[ID](typs.unsafeAddr)
    [self registerForDraggedTypes: tid]
    return self

proc draggingEntered(self: ID; cmd: SEL; sender: NSDraggingInfo): NSDragOperation {.cdecl.} =
  return NSDragOperationCopy

proc initWindowControlelr*(): Class =
  result = allocateClassPair(getClass("NSWindowController"), "WindowController", 0)
  discard result.replaceMethod($$"initWithCoder:", cast[IMP](initWithCoder), getProcEncode(initWithCoder))
  discard result.replaceMethod($$"draggingEntered:", cast[IMP](draggingEntered), getProcEncode(draggingEntered))