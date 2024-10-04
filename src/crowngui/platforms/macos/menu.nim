import darwin/objc/runtime
import darwin/[app_kit, foundation]

proc createMenuItem*(title: NSString, action: string, key: string): NSMenuItem =
  result = NSMenuItem.alloc()
  result.initWithTitle(title, if action != "": registerName(action) else: cast[SEL](nil), @key)
  result.autorelease()

proc createMenu*() =
  let menubar = NSMenu.alloc()
  menubar.initWithTitle(@"")
  menubar.autorelease
  let appName = NSProcessInfo.processInfo.processName

  let appMenuItem = NSMenuItem.alloc()
  appMenuItem.initWithTitle(appName, cast[SEL](nil), @"")

  let appMenu = NSMenu.alloc()
  appMenu.initWithTitle(appName)
  appMenu.autorelease
  
  var hideTitle = @"Hide ".stringByAppendingString(appName)
  appMenu.addItem(createMenuItem(hideTitle, "hide:", "h"))
  
  appMenuItem.setSubmenu(appMenu)
  menubar.addItem(appMenuItem)

  cast[NSApplication](NSApp).setMainMenu(menubar)
  # send(cast[NSApplication](NSApp), $$"setMainMenu:", menubar)
  # objcr:
    # var item = createMenuItem(@"Hide Others", "hideOtherApplications:", "h")
    # [item setKeyEquivalentModifierMask: (NSEventModifierFlagOption.uint or NSEventModifierFlagCommand.uint)]
    # [appMenu addItem: item]
    # [appMenu addItem: createMenuItem(@"Show All", "unhideAllApplications:", "")]
    # [appMenu addItem: [NSMenuItem separatorItem]]
    # var quitTitle = ["Quit "stringByAppendingString: appName]
    # [appMenu addItem: createMenuItem(cast[NSString](quitTitle), "terminate:", "q")]
    # var editMenuItem = [NSMenuItem alloc]
    # [editMenuItem initWithTitle: "Edit", action: "", keyEquivalent: ""]
    # var editMenu = [NSMenu alloc]
    # [editMenu initWithTitle: "Edit"]
    # [editMenu autorelease]

    # [editMenu addItem: createMenuItem(@"Undo", "undo:", "z")]
    # [editMenu addItem: createMenuItem(@"Redo", "redo:", "y")]

    # [editMenu addItem: [NSMenuItem separatorItem]]

    # [editMenu addItem: createMenuItem(@"Cut", "cut:", "x")]

    # [editMenu addItem: createMenuItem(@"Copy", "copy:", "c")]

    # [editMenu addItem: createMenuItem(@"Paste", "paste:", "v")]

    # [editMenu addItem: createMenuItem(@"Select All", "selectAll:", "a")]
    # [editMenuItem setSubmenu: editMenu]
    # [menubar addItem: editMenuItem]
    # [[NSApplication sharedApplication]setMainMenu: menubar]
