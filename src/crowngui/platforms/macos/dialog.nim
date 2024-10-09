import darwin / [objc/runtime, foundation, app_kit, objc/blocks]
import ./dialog_types

type DialogType = enum
  info = 0,
  warning = 1,
  error = 2

proc basicDialog(title: string; description: string; dt: DialogType) =
  let alert = NSAlert.alloc().init()

  # Handling different alert types (info, warning, error)
  case dt:
    of info:
      alert.setAlertStyle(NSAlertStyleInformational)
      alert.setIcon(NSImage.imageNamed(NSImageNameInfo))
    of warning:
      alert.setAlertStyle(NSAlertStyleWarning)
      alert.setIcon(NSImage.imageNamed(NSImageNameCaution))
    of error:
      alert.setAlertStyle(NSAlertStyleCritical)
      # alert.setIcon(NSImage.imageNamed(c"NSImageNameStatusUnavailable"))

  # Set alert properties
  alert.setShowsHelp(false)
  alert.setShowsSuppressionButton(false)
  alert.setMessageText(@title)
  alert.setInformativeText(@description)

  # Add button and run the modal
  alert.addButtonWithTitle(@"OK")
  alert.runModal()
  # alert.release()

proc info*(title: string; description: string) = 
  basicDialog(title, description, info)

proc warning*(title: string; description: string) = 
  basicDialog(title, description, warning)

proc error*(title: string; description: string) = 
  basicDialog(title, description, error)

proc chooseFile*(completionHandler:  proc (urls: seq[string];), root: string = ""; ) =
  # var pool = NSAutoreleasePool.alloc().init()
  var openPanel1 = NSOpenPanel.openPanel()
  openPanel1.setAllowsMultipleSelection(NO)
  openPanel1.setCanChooseFiles(YES)
  # let send = cast[proc(a: ID, b: SEL, c: NSArray[NSURL]){.cdecl, gcsafe.}](objc_msgSend)
  let b2 = toBlock() do(r: int):
    var urls = newSeq[string]()
    if r == NSModalResponseOK:
      for url in openPanel1.URLs:
        urls.add $url.path
      # send(cast[Id](completionHandler), $$"invoke", urls)
      completionHandler(urls)
    else:
      # send(cast[Id](completionHandler), $$"invoke", nil)
      completionHandler(urls)
  openPanel1.beginWithCompletionHandler(b2)
  # pool.drain

proc saveFile*(completionHandler: proc(a: string), root = ""; filename = "") =
  # var pool = NSAutoreleasePool.alloc().init()
  var savePanel = NSSavePanel.savePanel()
  savePanel.setCanCreateDirectories(YES)
  # let send = cast[proc(a: ID, b: SEL, c: BOOL, d: NSString){.cdecl, gcsafe.}](objc_msgSend)

  if filename.len > 0:
    savePanel.setNameFieldStringValue(@filename)
  let blk = toBlock() do(r: int):
    if r == NSModalResponseOK:
      var url = savePanel.URL
      var path = url.path
      completionHandler(path)
      # send(cast[Id](completionHandler), $$"invoke", YES, path)
    else:
      completionHandler("")
      # send(cast[Id](completionHandler), $$"invoke", No, nil)
  savePanel.beginWithCompletionHandler(blk)
  # pool.drain