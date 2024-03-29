import objc_runtime
import darwin / [app_kit, foundation, objc/runtime, objc/blocks]
import types
import ./dialog_types

const WEBVIEW_DIALOG_FLAG_FILE = (0 shl 0)
const WEBVIEW_DIALOG_FLAG_DIRECTORY = (1 shl 0)

const WEBVIEW_DIALOG_FLAG_INFO = (1 shl 1)
const WEBVIEW_DIALOG_FLAG_WARNING = (2 shl 1)
const WEBVIEW_DIALOG_FLAG_ERROR = (3 shl 1)
const WEBVIEW_DIALOG_FLAG_ALERT_MASK = (3 shl 1)

type WebviewDialogType = enum
  WEBVIEW_DIALOG_TYPE_OPEN = 0,
  WEBVIEW_DIALOG_TYPE_SAVE = 1,
  WEBVIEW_DIALOG_TYPE_ALERT = 2


proc run_open_panel*(self: Id; cmd: SEL; webView: Id; parameters: Id;
                           frame: Id; completionHandler: Block[OpenCompletionHandler]) =
  objcr:
    var openPanel = [NSOpenPanel openPanel]
    [openPanel setAllowsMultipleSelection, [parameters allowsMultipleSelection]]
    [openPanel setCanChooseFiles: 1]
    let b2 = toBlock() do(r: Id):
      if r == cast[Id](NSModalResponseOK):
        objc_msgSend(cast[Id](completionHandler), $$"invoke", objc_msgSend(openPanel, $$"URLs"))
      else:
        objc_msgSend(cast[Id](completionHandler), $$"invoke", nil)
    [openPanel beginWithCompletionHandler: b2]


proc run_save_panel*(self: Id; cmd: SEL; download: Id; filename: Id; completionHandler: Block[SaveCompletionHandler]) =
  objcr:
    var savePanel = [NSSavePanel savePanel]
    [savePanel setCanCreateDirectories: 1]
    [savePanel setNameFieldStringValue: filename]
    let blk = toBlock() do(r: Id):
      if r == cast[Id](NSModalResponseOK):
        var url: Id = objc_msgSend(savePanel, $$"URL")
        var path: Id = objc_msgSend(url, $$"path")
        objc_msgSend(cast[Id](completionHandler), $$"invoke", 1, path)
      else:
        objc_msgSend(cast[Id](completionHandler), $$"invoke", No, nil)

    [savePanel beginWithCompletionHandler: blk]


proc run_confirmation_panel*(self: Id; cmd: SEL; webView: Id; message: Id;
                                   frame: Id; completionHandler: Block[ConfirmCompletionHandler]) =
  objcr:
    var alert: Id = [NSAlert new]
    [alert setIcon: [NSImage imageNamed: "NSCaution"]]
    [alert setShowsHelp: 0]
    [alert setInformativeText: message]
    [alert addButtonWithTitle: "OK"]
    [alert addButtonWithTitle: "Cancel"]
    if [alert runModal] == cast[ID](NSAlertFirstButtonReturn):
      objc_msgSend(cast[Id](completionHandler), $$"invoke", true)
    else:
      objc_msgSend(cast[Id](completionHandler), $$"invoke", false)
    [alert release]


proc run_alert_panel*(self: Id; cmd: SEL; webView: Id; message: Id; frame: Id;
                            completionHandler: Block[AlertCompletionHandler]) =
  objcr:
    var alert: Id = [NSAlert new]
    [alert setIcon: [NSImage imageNamed: NSImageNameCaution]]
    [alert setShowsHelp: 0]
    [alert setInformativeText: message]
    [alert addButtonWithTitle: "OK"]
    [alert runModal]
    [alert release]
    objc_msgSend(cast[Id](completionHandler), $$"invoke")

proc webview_dialog*(w: Webview; dlgtype: WebviewDialogType; flags: int;
                                title: cstring; arg: cstring; result: var cstring; resultsz: csize_t) =
  objcr:
    if (dlgtype == WEBVIEW_DIALOG_TYPE_OPEN or
        dlgtype == WEBVIEW_DIALOG_TYPE_SAVE):
      var panel = cast[Id](getClass("NSSavePanel"))

      if (dlgtype == WEBVIEW_DIALOG_TYPE_OPEN):
        var openPanel = [NSOpenPanel openPanel]
        if (flags and WEBVIEW_DIALOG_FLAG_DIRECTORY) > 0:
          [openPanel setCanChooseFiles: 0]
          [openPanel setCanChooseDirectories: 1]
        else:
          [openPanel setCanChooseFiles: 1]
          [openPanel setCanChooseDirectories: 0]
          [openPanel setResolvesAliases: 0]
          [openPanel setAllowsMultipleSelection: 0]
        panel = openPanel
      else:
        panel = [NSSavePanel savePanel]
      [panel setCanCreateDirectories: 1]
      [panel setShowsHiddenFiles: 1]
      [panel setExtensionHidden: 0]
      [panel setCanSelectHiddenExtension: 0]
      [panel setTreatsFilePackagesAsDirectories: 1]
      let blk = toBlock() do (r: Id):
        objcr:
          [[NSApplication sharedApplication]stopModalWithCode: r]

      [panel beginSheetModalForWindow: w.priv.window, completionHandler: blk]
      if [[NSApplication sharedApplication]runModalForWindow: panel] == cast[Id](NSModalResponseOK):
        var url: Id = [panel URL]
        var path: Id = [url path]
        var filename: cstring = cast[cstring]([path UTF8String])
        copyMem(result, filename, resultsz)

      elif (dlgtype == WEBVIEW_DIALOG_TYPE_ALERT):
        var a: Id = [NSAlert new]
        case flags and WEBVIEW_DIALOG_FLAG_ALERT_MASK:
        of WEBVIEW_DIALOG_FLAG_INFO:
          [a setAlertStyle: NSAlertStyleInformational]
        of WEBVIEW_DIALOG_FLAG_WARNING:
          [a setAlertStyle: NSAlertStyleWarning]
        of WEBVIEW_DIALOG_FLAG_ERROR:
          [a setAlertStyle: NSAlertStyleCritical]
        else:
          discard
        [a setShowsHelp: 0]
        [a setShowsSuppressionButton: 0]
        [a setMessageText: @($title)]
        [a setInformativeText: @($arg)]
        [a addButtonWithTitle: "OK"]
        [a runModal]
        [a release]
