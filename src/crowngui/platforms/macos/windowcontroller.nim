
import objc_runtime
import darwin / [app_kit, foundation, objc/runtime]
import ./types

type MyWindowController* = ptr object of NSObject


when false:
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

proc draggingEntered(self: MyWindowController; cmd: SEL; sender: NSDraggingInfo): NSDragOperation {.cdecl.} =
  return NSDragOperationCopy

proc registerWindowController*(): ObjcClass =
  result = allocateClassPair(getClass("NSWindowController"), "WindowController", 0)
  # discard result.replaceMethod($$"initWithCoder:", initWithCoder)
  discard result.replaceMethod($$"draggingEntered:", draggingEntered)
  result.registerClassPair()