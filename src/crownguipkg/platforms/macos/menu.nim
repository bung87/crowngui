import objc, foundation

type NSMenu = object of NSObject # appkit
type NSMenuItem = object of NSObject # appkit
const NSEventModifierFlagCommand = (1 shl 20)
const NSEventModifierFlagOption = (1 shl 19)

func createMenuItem(title: ID, action: string, key: string): ID =
  result = objc_msgSend(getClass("NSMenuItem").ID, registerName("alloc"))
  objc_msgSend(result, registerName("initWithTitle:action:keyEquivalent:"),
              title, if action != "": registerName(action) else: nil, get_nsstring(key))
  objc_msgSend(result, registerName("autorelease"))

func createMenu*() =
  objcr:
    let menubar: ID = [NSMenu alloc]
    [menubar initWithTitle: ""]
    [menubar autorelease]
    let appName = [[NSProcessInfo processInfo]processName]
    let appMenuItem = [NSMenuItem alloc]
    [appMenuItem initWithTitle: appName, action: nil, keyEquivalent: ""]
    let appMenu = [NSMenu alloc]
    [appMenu initWithTitle: appName]
    [appMenu autorelease]
    [appMenuItem setSubmenu: appMenu]
    [menubar addItem: appMenuItem]
    var hideTitle = ["Hide "stringByAppendingString: appName]
    [appMenu addItem: createMenuItem(hideTitle, "hide:", "h")]
    var item = createMenuItem(@"Hide Others", "hideOtherApplications:", "h")
    [item setKeyEquivalentModifierMask: (NSEventModifierFlagOption or NSEventModifierFlagCommand)]
    [appMenu addItem: item]
    [appMenu addItem: createMenuItem(@"Show All", "unhideAllApplications:", "")]
    [appMenu addItem: [NSMenuItem separatorItem]]
    var quitTitle = ["Quit "stringByAppendingString: appName]
    [appMenu addItem: createMenuItem(quitTitle, "terminate:", "q")]
    var editMenuItem = [NSMenuItem alloc]
    [editMenuItem initWithTitle: "Edit", action: "", keyEquivalent: ""]
    var editMenu = [NSMenu alloc]
    [editMenu initWithTitle: "Edit"]
    [editMenu autorelease]

    [editMenu addItem: createMenuItem(@"Undo", "undo:", "z")]
    [editMenu addItem: createMenuItem(@"Redo", "redo:", "y")]

    [editMenu addItem: [NSMenuItem separatorItem]]

    [editMenu addItem: createMenuItem(@"Cut", "cut:", "x")]

    [editMenu addItem: createMenuItem(@"Copy", "copy:", "c")]

    [editMenu addItem: createMenuItem(@"Paste", "paste:", "v")]

    [editMenu addItem: createMenuItem(@"Select All", "selectAll:", "a")]
    [editMenuItem setSubmenu: editMenu]
    [menubar addItem: editMenuItem]
    [[NSApplication sharedApplication]setMainMenu: menubar]
