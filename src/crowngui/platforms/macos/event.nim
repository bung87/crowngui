import objc_runtime
import darwin / [app_kit, foundation, objc/runtime]

var handler* = proc (event: Id): Id {.closure.} =
    objcr:
      var flag: NSUInteger = cast[NSUInteger]([event modifierFlags])
      var charactersIgnoringModifiers = [event charactersIgnoringModifiers]
      let isX = cast[Bool]([charactersIgnoringModifiers isEqualToString: @"x"])
      let isC = cast[Bool]([charactersIgnoringModifiers isEqualToString: @"c"])
      let isV = cast[Bool]([charactersIgnoringModifiers isEqualToString: @"v"])
      let isZ = cast[Bool]([charactersIgnoringModifiers isEqualToString: @"z"])
      let isA = cast[Bool]([charactersIgnoringModifiers isEqualToString: @"a"])
      let isY = cast[Bool]([charactersIgnoringModifiers isEqualToString: @"y"])
      if (flag.uint and NSEventModifierFlagCommand.uint) > 0:
        if isX:
          let cut = cast[Bool]([NSApp "sendAction:cut:to": nil, `from`: NSApp])
          if cut:
            return nil
        elif isC:
          let copy = cast[Bool]([NSApp "sendAction:copy:to": nil, `from`: NSApp])
          if copy:
            return nil
        elif isV:
          let paste = cast[Bool]([NSApp "sendAction:paste:t:": nil, `from`: NSApp])
          if paste:
            return nil
        elif isZ:
          let undo = cast[Bool]([NSApp "sendAction:undo:to": nil, `from`: NSApp])
          if undo:
            return nil
        elif isA:
          let selectAll = cast[Bool]([NSApp "sendAction:selectAll:to": nil, `from`: NSApp])
          if selectAll:
            return nil
      elif (flag.uint and NSEventModifierFlagDeviceIndependentFlagsMask.uint) == (NSEventModifierFlagCommand.uint or
          NSEventModifierFlagShift.uint):
        let isY = cast[Bool]([charactersIgnoringModifiers isEqualToString: @"y"])
        if isY:
          let redo = cast[Bool]([NSApp "sendAction:redo:to": nil, `from`: NSApp])
          if redo:
            return nil
      return event