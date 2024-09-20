import objc_runtime
import darwin / [objc/runtime, foundation, app_kit, objc/blocks]
import ./dialog_types

type DialogType = enum
  info = 0,
  warning = 1,
  error = 2

proc basicDialog(title: string; description: string; dt: DialogType) =
  objcr:
    var a: Id = [NSAlert new]
    case dt:
      of info:
        [a setAlertStyle: NSAlertStyleInformational]
        [a setIcon: NSImage.imageNamed(NSImageNameInfo)]
      of warning:
        [a setAlertStyle: NSAlertStyleWarning]
        [a setIcon: NSImage.imageNamed(NSImageNameCaution)]
      of error:
        [a setAlertStyle: NSAlertStyleCritical]
        # [a setIcon: NSImage.imageNamed(NSImageNameStatusUnavailable)]
    [a setShowsHelp: 0]
    [a setShowsSuppressionButton: 0]
    [a setMessageText: @title]
    [a setInformativeText: @description]
    [a addButtonWithTitle: "OK"]
    [a runModal]
    [a release]

proc info*(title: string; description: string) = 
  basicDialog(title, description, info)

proc warning*(title: string; description: string) = 
  basicDialog(title, description, warning)

proc error*(title: string; description: string) = 
  basicDialog(title, description, error)

proc chooseFile*(root: string = ""; completionHandler: Block[OpenCompletionHandler] = nil) =
  objcr:
    var openPanel1 = [NSOpenPanel openPanel]
    [cast[Id](openPanel1) setAllowsMultipleSelection:NO]
    [cast[Id](openPanel1) setCanChooseFiles: YES]
    let b2 = toBlock() do(r: Id):
      if r == cast[Id](NSModalResponseOK):
        let urls = [cast[Id](openPanel1) valueForKey: "URLs"]
        var newUrls = newSeq[string]()
        let urls2 = cast[NSArray[NSURL]](urls)
        for one in urls2:
          let path = [one valueForKey: "path"]
          newUrls.add $(cast[NSString](path))
        objc_msgSend(cast[Id](completionHandler), $$"invoke", newUrls)
      else:
        objc_msgSend(cast[Id](completionHandler), $$"invoke", nil)
    [cast[ID](openPanel1) beginWithCompletionHandler: b2]

proc saveFile*(root = ""; filename = "", completionHandler: Block[SaveCompletionHandler] = nil) =
  objcr:
    var savePanel = [NSSavePanel savePanel]
    [savePanel setCanCreateDirectories: 1]
    if filename.len > 0:
      [savePanel setNameFieldStringValue: NSString(filename)]
    let blk = toBlock() do(r: Id):
      if r == cast[Id](NSModalResponseOK):
        var url: Id = objc_msgSend(savePanel, $$"URL")
        var path: Id = objc_msgSend(url, $$"path")
        objc_msgSend(cast[Id](completionHandler), $$"invoke", 1, path)
      else:
        objc_msgSend(cast[Id](completionHandler), $$"invoke", No, nil)

    [savePanel beginWithCompletionHandler: blk]