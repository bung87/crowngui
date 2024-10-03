import objc_runtime
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
  alert.release()

proc info*(title: string; description: string) = 
  basicDialog(title, description, info)

proc warning*(title: string; description: string) = 
  basicDialog(title, description, warning)

proc error*(title: string; description: string) = 
  basicDialog(title, description, error)

proc chooseFile*(root: string = ""; completionHandler: Block[OpenCompletionHandler] = nil) =
  var openPanel1 = NSOpenPanel.openPanel()
  openPanel1.setAllowsMultipleSelection(NO)
  openPanel1.setCanChooseFiles(YES)
  let send = cast[proc(a: ID, b: SEL, c: seq[string]){.cdecl, gcsafe.}](objc_msgSend)
  let b2 = toBlock() do(r: int):
    if r == NSModalResponseOK:
      let urls = openPanel1.URLs
      var newUrls = newSeq[string]()
      for one in urls:
        let path = one.path
        newUrls.add path
      send(cast[Id](completionHandler), $$"invoke", newUrls)
    else:
      send(cast[Id](completionHandler), $$"invoke", newSeq[string]())
  openPanel1.beginWithCompletionHandler(b2)

proc saveFile*(root = ""; filename = "", completionHandler: Block[SaveCompletionHandler] = nil) =
  var savePanel = NSSavePanel.savePanel()
  savePanel.setCanCreateDirectories(YES)
  let send = cast[proc(a: ID, b: SEL, c: BOOL, d: NSString){.cdecl, gcsafe.}](objc_msgSend)

  if filename.len > 0:
    savePanel.setNameFieldStringValue(@filename)
  let blk = toBlock() do(r: int):
    if r == NSModalResponseOK:
      var url = savePanel.URL
      var path = url.path
      send(cast[Id](completionHandler), $$"invoke", YES, path)
    else:
      send(cast[Id](completionHandler), $$"invoke", No, nil)

  savePanel.beginWithCompletionHandler(blk)