import objc
const NSEventModifierFlagCommand = (1 shl 20)
const NSEventModifierFlagOption = (1 shl 19)
func create_menu_item(title: ID, action: string, key: string): ID =
  result = objc_msgSend(getClass("NSMenuItem").ID, registerName("alloc"))
  objc_msgSend(result, registerName("initWithTitle:action:keyEquivalent:"),
              title, registerName(action), get_nsstring(key))
  objc_msgSend(result, registerName("autorelease"))

func createMenu*() =
  let menubar: ID =
    objc_msgSend(getClass("NSMenu").ID, $$"alloc");
  objc_msgSend(menubar, $$"initWithTitle:", get_nsstring(""));
  discard objc_msgSend(menubar, $$"autorelease")

  let appName = objc_msgSend(objc_msgSend(getClass("NSProcessInfo").ID,
                                         registerName("processInfo")),
                            registerName("processName"))

  let appMenuItem =
    objc_msgSend(getClass("NSMenuItem").ID, registerName("alloc"))
  discard objc_msgSend(appMenuItem,
               registerName("initWithTitle:action:keyEquivalent:"), appName,
               nil, get_nsstring(""));

  let appMenu =
    objc_msgSend(getClass("NSMenu").ID, registerName("alloc"))
  discard objc_msgSend(appMenu, registerName("initWithTitle:"), appName)
  discard objc_msgSend(appMenu, registerName("autorelease"))

  objc_msgSend(appMenuItem, registerName("setSubmenu:"), appMenu)
  objc_msgSend(menubar, registerName("addItem:"), appMenuItem)

  var title =
    objc_msgSend(get_nsstring("Hide "),
                 registerName("stringByAppendingString:"), appName)
  var item = create_menu_item(title, "hide:", "h")
  objc_msgSend(appMenu, registerName("addItem:"), item)

  item = create_menu_item(get_nsstring("Hide Others"), "hideOtherApplications:", "h")
  objc_msgSend(item, registerName("setKeyEquivalentModifierMask:"),
               (NSEventModifierFlagOption or NSEventModifierFlagCommand))
  objc_msgSend(appMenu, registerName("addItem:"), item);

  item =
    create_menu_item(get_nsstring("Show All"), "unhideAllApplications:", "");
  objc_msgSend(appMenu, registerName("addItem:"), item)

  objc_msgSend(appMenu, registerName("addItem:"),
               objc_msgSend(getClass("NSMenuItem").ID, registerName("separatorItem")))

  title = objc_msgSend(get_nsstring("Quit "),
                       registerName("stringByAppendingString:"), appName);
  item = create_menu_item(title, "terminate:", "q");
  objc_msgSend(appMenu, registerName("addItem:"), item);

  var editMenuItem = objc_msgSend(getClass("NSMenuItem").ID, registerName("alloc"))

  objc_msgSend(editMenuItem,
               registerName("initWithTitle:action:keyEquivalent:"), get_nsstring("Edit"),
               nil, get_nsstring(""));

  var editMenu =
    objc_msgSend(getClass("NSMenu").ID, registerName("alloc"))
  objc_msgSend(editMenu, registerName("initWithTitle:"), get_nsstring("Edit"));
  objc_msgSend(editMenu, registerName("autorelease"));

  objc_msgSend(editMenuItem, registerName("setSubmenu:"), editMenu);
  objc_msgSend(menubar, registerName("addItem:"), editMenuItem);

  item = create_menu_item(get_nsstring("Undo"), "undo:", "z");
  objc_msgSend(editMenu, registerName("addItem:"), item);

  item = create_menu_item(get_nsstring("Redo"), "redo:", "y");
  objc_msgSend(editMenu, registerName("addItem:"), item);

  item = objc_msgSend(getClass("NSMenuItem").ID, registerName("separatorItem"))
  objc_msgSend(editMenu, registerName("addItem:"), item);

  item = create_menu_item(get_nsstring("Cut"), "cut:", "x");
  objc_msgSend(editMenu, registerName("addItem:"), item);

  item = create_menu_item(get_nsstring("Copy"), "copy:", "c");
  objc_msgSend(editMenu, registerName("addItem:"), item);

  item = create_menu_item(get_nsstring("Paste"), "paste:", "v");
  objc_msgSend(editMenu, registerName("addItem:"), item);

  item = create_menu_item(get_nsstring("Select All"), "selectAll:", "a");
  objc_msgSend(editMenu, registerName("addItem:"), item);

  objc_msgSend(objc_msgSend(getClass("NSApplication").ID,
                            registerName("sharedApplication")),
               registerName("setMainMenu:"), menubar)
