import objc, cocoa, foundation, menu

{.passL: "-framework Foundation".}
{.passL: "-framework AppKit".}
{.passL: "-framework ApplicationServices".}

const
  NSBorderlessWindowMask = 0
  NSTitledWindowMask = 1 shl 0
  NSClosableWindowMask = 1 shl 1
  NSMiniaturizableWindowMask = 1 shl 2
  NSResizableWindowMask = 1 shl 3

var NSApp {.importc.}: ID

type
  NSApplicationActivationPolicy {.size: sizeof(cint).} = enum
    NSApplicationActivationPolicyRegular
    NSApplicationActivationPolicyAccessory
    NSApplicationActivationPolicyProhibited

  CMRect = object
    x, y, w, h: float64

  CMPoint = object
    x, y: float64

proc main() =

  objcr:
    [NSApplication sharedApplication]

    if NSApp.isNil:
      echo "Failed to initialized NSApplication...  terminating..."
      return
    [NSApp setActivationPolicy: NSApplicationActivationPolicyRegular.cint]

    var menuBar = [[NSMenu alloc]init]
    var appMenuItem = [[NSMenuItem alloc]init]
    [menuBar addItem: appMenuItem]
    [NSApp setMainMenu: menuBar]

    var appMenu = [[NSMenu alloc]init]

    var quitTitle = @"Quit"
    var quitMenuItem = createMenuItem(quitTitle, "terminate:", "q")
    [appMenu addItem: quitMenuItem]
    [appMenuItem setSubmenu: appMenu]

    var mainWindow = [NSWindow alloc]
    var rect = CMRect(x: 0, y: 0, w: 200, h: 200)
    [mainWindow initWithContentRect: rect, styleMask: NSTitledWindowMask, backing: NSBackingStoreBuffered,
        `defer`: false]

    var pos = CMPoint(x: 20, y: 20)

    [mainWindow cascadeTopLeftFromPoint: pos]
    [mainWindow setTitle: "Hello"]
    [mainWindow makeKeyAndOrderFront: NSApp]
    [NSApp activateIgnoringOtherApps: true]
    [NSApp run]


when isMainModule:
  main()
