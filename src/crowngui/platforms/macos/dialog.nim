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
    var openPanel = [NSOpenPanel openPanel]
    # [openPanel setAllowsMultipleSelection, [parameters allowsMultipleSelection]]
    [openPanel setCanChooseFiles: 1]
    let b2 = toBlock() do(r: Id):
      if r == cast[Id](NSModalResponseOK):
        objc_msgSend(cast[Id](completionHandler), $$"invoke", objc_msgSend(openPanel, $$"URLs"))
      else:
        objc_msgSend(cast[Id](completionHandler), $$"invoke", nil)
    [openPanel beginWithCompletionHandler: b2]

proc saveFile*(root: string = ""; completionHandler: Block[SaveCompletionHandler] = nil) =
  objcr:
    var savePanel = [NSSavePanel savePanel]
    [savePanel setCanCreateDirectories: 1]
    # [savePanel setNameFieldStringValue: filename]
    let blk = toBlock() do(r: Id):
      if r == cast[Id](NSModalResponseOK):
        var url: Id = objc_msgSend(savePanel, $$"URL")
        var path: Id = objc_msgSend(url, $$"path")
        objc_msgSend(cast[Id](completionHandler), $$"invoke", 1, path)
      else:
        objc_msgSend(cast[Id](completionHandler), $$"invoke", No, nil)

    [savePanel beginWithCompletionHandler: blk]