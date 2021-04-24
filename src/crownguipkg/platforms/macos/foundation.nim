import objc, strutils

{.passL: "-framework Foundation".}
{.passL: "-framework AppKit".}
{.passL: "-framework ApplicationServices".}

const
  NSBorderlessWindowMask* = 0
  NSTitledWindowMask* = 1 shl 0
  NSClosableWindowMask* = 1 shl 1
  NSMiniaturizableWindowMask* = 1 shl 2
  NSResizableWindowMask* = 1 shl 3

var NSApp* {.importc.}: ID

type
  NSApplicationActivationPolicy* {.size: sizeof(cint).} = enum
    NSApplicationActivationPolicyRegular
    NSApplicationActivationPolicyAccessory
    NSApplicationActivationPolicyProhibited

  CMRect* = object
    x*, y*, w*, h*: float64

  CMPoint* = object
    x*, y*: float64

  CMSize* = object
    w*, h*: float64
  NSURLRequest* = object of NSObject
  NSProcessInfo* = object of NSObject
const
  NSBackingStoreRetained* = 0
  NSBackingStoreNonRetained* = 1
  NSBackingStoreBuffered* = 2

proc newClass*(cls: string): ID =
  objc_msgSend(objc_msgSend(getClass(cls).ID, $$"alloc"), $$"init")

proc NSMakeRect*(x, y, w, h: float64): CMRect =
  result = CMRect(x: x, y: y, w: w, h: h)

const
  NSLeftMouseDown* = 1
  NSLeftMouseUp* = 2
  NSRightMouseDown* = 3
  NSRightMouseUp* = 4
  NSMouseMoved* = 5
  NSLeftMouseDragged* = 6
  NSRightMouseDragged* = 7
  NSMouseEntered* = 8
  NSMouseExited* = 9
  NSKeyDown* = 10
  NSKeyUp* = 11
  NSFlagsChanged* = 12
  NSAppKitDefined* = 13
  NSSystemDefined* = 14
  NSApplicationDefined* = 15
  NSPeriodic* = 16
  NSCursorUpdate* = 17
  NSScrollWheel* = 22
  NSTabletPoint* = 23
  NSTabletProximity* = 24
  NSOtherMouseDown* = 25
  NSOtherMouseUp* = 26
  NSOtherMouseDragged* = 27
  # The following event types are available on some hardware on 10.5.2 and later
  NSEventTypeGesture* = 29
  NSEventTypeMagnify* = 30
  NSEventTypeSwipe* = 31
  NSEventTypeRotate* = 18
  NSEventTypeBeginGesture* = 19
  NSEventTypeEndGesture* = 20
  NSEventTypeSmartMagnify* = 32
  NSEventTypeQuickLook* = 33
  NSEventTypePressure* = 34


  NSAlphaShiftKeyMask* = 1 shl 16
  NSShiftKeyMask* = 1 shl 17
  NSControlKeyMask* = 1 shl 18
  NSAlternateKeyMask* = 1 shl 19
  NSCommandKeyMask* = 1 shl 20
  NSNumericPadKeyMask* = 1 shl 21
  NSHelpKeyMask* = 1 shl 22
  NSFunctionKeyMask* = 1 shl 23
  NSDeviceIndependentModifierFlagsMask* = 0xffff0000

  NSUpArrowFunctionKey* = 0xF700
  NSDownArrowFunctionKey* = 0xF701
  NSLeftArrowFunctionKey* = 0xF702
  NSRightArrowFunctionKey* = 0xF703
  NSF1FunctionKey* = 0xF704
  NSF2FunctionKey* = 0xF705
  NSF3FunctionKey* = 0xF706
  NSF4FunctionKey* = 0xF707
  NSF5FunctionKey* = 0xF708
  NSF6FunctionKey* = 0xF709
  NSF7FunctionKey* = 0xF70A
  NSF8FunctionKey* = 0xF70B
  NSF9FunctionKey* = 0xF70C
  NSF10FunctionKey* = 0xF70D
  NSF11FunctionKey* = 0xF70E
  NSF12FunctionKey* = 0xF70F
  NSF13FunctionKey* = 0xF710
  NSF14FunctionKey* = 0xF711
  NSF15FunctionKey* = 0xF712
  NSF16FunctionKey* = 0xF713
  NSF17FunctionKey* = 0xF714
  NSF18FunctionKey* = 0xF715
  NSF19FunctionKey* = 0xF716
  NSF20FunctionKey* = 0xF717
  NSF21FunctionKey* = 0xF718
  NSF22FunctionKey* = 0xF719
  NSF23FunctionKey* = 0xF71A
  NSF24FunctionKey* = 0xF71B
  NSF25FunctionKey* = 0xF71C
  NSF26FunctionKey* = 0xF71D
  NSF27FunctionKey* = 0xF71E
  NSF28FunctionKey* = 0xF71F
  NSF29FunctionKey* = 0xF720
  NSF30FunctionKey* = 0xF721
  NSF31FunctionKey* = 0xF722
  NSF32FunctionKey* = 0xF723
  NSF33FunctionKey* = 0xF724
  NSF34FunctionKey* = 0xF725
  NSF35FunctionKey* = 0xF726
  NSInsertFunctionKey* = 0xF727
  NSDeleteFunctionKey* = 0xF728
  NSHomeFunctionKey* = 0xF729
  NSBeginFunctionKey* = 0xF72A
  NSEndFunctionKey* = 0xF72B
  NSPageUpFunctionKey* = 0xF72C
  NSPageDownFunctionKey* = 0xF72D
  NSPrintScreenFunctionKey* = 0xF72E
  NSScrollLockFunctionKey* = 0xF72F
  NSPauseFunctionKey* = 0xF730
  NSSysReqFunctionKey* = 0xF731
  NSBreakFunctionKey* = 0xF732
  NSResetFunctionKey* = 0xF733
  NSStopFunctionKey* = 0xF734
  NSMenuFunctionKey* = 0xF735
  NSUserFunctionKey* = 0xF736
  NSSystemFunctionKey* = 0xF737
  NSPrintFunctionKey* = 0xF738
  NSClearLineFunctionKey* = 0xF739
  NSClearDisplayFunctionKey* = 0xF73A
  NSInsertLineFunctionKey* = 0xF73B
  NSDeleteLineFunctionKey* = 0xF73C
  NSInsertCharFunctionKey* = 0xF73D
  NSDeleteCharFunctionKey* = 0xF73E
  NSPrevFunctionKey* = 0xF73F
  NSNextFunctionKey* = 0xF740
  NSSelectFunctionKey* = 0xF741
  NSExecuteFunctionKey* = 0xF742
  NSUndoFunctionKey* = 0xF743
  NSRedoFunctionKey* = 0xF744
  NSFindFunctionKey* = 0xF745
  NSHelpFunctionKey* = 0xF746
  NSModeSwitchFunctionKey* = 0xF747

  kVK_ANSI_A* = 0x00
  kVK_ANSI_S* = 0x01
  kVK_ANSI_D* = 0x02
  kVK_ANSI_F* = 0x03
  kVK_ANSI_H* = 0x04
  kVK_ANSI_G* = 0x05
  kVK_ANSI_Z* = 0x06
  kVK_ANSI_X* = 0x07
  kVK_ANSI_C* = 0x08
  kVK_ANSI_V* = 0x09
  kVK_ANSI_B* = 0x0B
  kVK_ANSI_Q* = 0x0C
  kVK_ANSI_W* = 0x0D
  kVK_ANSI_E* = 0x0E
  kVK_ANSI_R* = 0x0F
  kVK_ANSI_Y* = 0x10
  kVK_ANSI_T* = 0x11
  kVK_ANSI_1* = 0x12
  kVK_ANSI_2* = 0x13
  kVK_ANSI_3* = 0x14
  kVK_ANSI_4* = 0x15
  kVK_ANSI_6* = 0x16
  kVK_ANSI_5* = 0x17
  kVK_ANSI_Equal* = 0x18
  kVK_ANSI_9* = 0x19
  kVK_ANSI_7* = 0x1A
  kVK_ANSI_Minus* = 0x1B
  kVK_ANSI_8* = 0x1C
  kVK_ANSI_0* = 0x1D
  kVK_ANSI_RightBracket* = 0x1E
  kVK_ANSI_O* = 0x1F
  kVK_ANSI_U* = 0x20
  kVK_ANSI_LeftBracket* = 0x21
  kVK_ANSI_I* = 0x22
  kVK_ANSI_P* = 0x23
  kVK_ANSI_L* = 0x25
  kVK_ANSI_J* = 0x26
  kVK_ANSI_Quote* = 0x27
  kVK_ANSI_K* = 0x28
  kVK_ANSI_Semicolon* = 0x29
  kVK_ANSI_Backslash* = 0x2A
  kVK_ANSI_Comma* = 0x2B
  kVK_ANSI_Slash* = 0x2C
  kVK_ANSI_N* = 0x2D
  kVK_ANSI_M* = 0x2E
  kVK_ANSI_Period* = 0x2F
  kVK_ANSI_Grave* = 0x32
  kVK_ANSI_KeypadDecimal* = 0x41
  kVK_ANSI_KeypadMultiply* = 0x43
  kVK_ANSI_KeypadPlus* = 0x45
  kVK_ANSI_KeypadClear* = 0x47
  kVK_ANSI_KeypadDivide* = 0x4B
  kVK_ANSI_KeypadEnter* = 0x4C
  kVK_ANSI_KeypadMinus* = 0x4E
  kVK_ANSI_KeypadEquals* = 0x51
  kVK_ANSI_Keypad0* = 0x52
  kVK_ANSI_Keypad1* = 0x53
  kVK_ANSI_Keypad2* = 0x54
  kVK_ANSI_Keypad3* = 0x55
  kVK_ANSI_Keypad4* = 0x56
  kVK_ANSI_Keypad5* = 0x57
  kVK_ANSI_Keypad6* = 0x58
  kVK_ANSI_Keypad7* = 0x59
  kVK_ANSI_Keypad8* = 0x5B
  kVK_ANSI_Keypad9* = 0x5C


  # keycodes for keys that are independent of keyboard layout
  kVK_Return* = 0x24
  kVK_Tab* = 0x30
  kVK_Space* = 0x31
  kVK_Delete* = 0x33
  kVK_Escape* = 0x35
  kVK_Command* = 0x37
  kVK_Shift* = 0x38
  kVK_CapsLock* = 0x39
  kVK_Option* = 0x3A
  kVK_Control* = 0x3B
  kVK_RightShift* = 0x3C
  kVK_RightOption* = 0x3D
  kVK_RightControl* = 0x3E
  kVK_Function* = 0x3F
  kVK_F17* = 0x40
  kVK_VolumeUp* = 0x48
  kVK_VolumeDown* = 0x49
  kVK_Mute* = 0x4A
  kVK_F18* = 0x4F
  kVK_F19* = 0x50
  kVK_F20* = 0x5A
  kVK_F5* = 0x60
  kVK_F6* = 0x61
  kVK_F7* = 0x62
  kVK_F3* = 0x63
  kVK_F8* = 0x64
  kVK_F9* = 0x65
  kVK_F11* = 0x67
  kVK_F13* = 0x69
  kVK_F16* = 0x6A
  kVK_F14* = 0x6B
  kVK_F10* = 0x6D
  kVK_F12* = 0x6F
  kVK_F15* = 0x71
  kVK_Help* = 0x72
  kVK_Home* = 0x73
  kVK_PageUp* = 0x74
  kVK_ForwardDelete* = 0x75
  kVK_F4* = 0x76
  kVK_End* = 0x77
  kVK_F2* = 0x78
  kVK_PageDown* = 0x79
  kVK_F1* = 0x7A
  kVK_LeftArrow* = 0x7B
  kVK_RightArrow* = 0x7C
  kVK_DownArrow* = 0x7D
  kVK_UpArrow* = 0x7E
