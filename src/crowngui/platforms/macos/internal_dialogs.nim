import darwin/objc/[runtime, blocks]
import darwin/foundation/[nsstring, nsurl]
import darwin/app_kit
import darwin/web_kit
import ./dialog_types
import ../../types

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

type OpenPanelCompletionHandler = proc (a: ID; urls: NSArray[NSURL];): void

# Run the open panel dialog
proc run_open_panel*(self: Id; cmd: SEL; webView: WKWebView; parameters: WKOpenPanelParameters;
                           frame: WKFrameInfo; completionHandler: Block[OpenPanelCompletionHandler] = nil) =
  var openPanel = NSOpenPanel.openPanel()
  openPanel.setAllowsMultipleSelection(parameters.allowsMultipleSelection())
  openPanel.setCanChooseFiles(YES)
  let send = cast[proc(a: ID, b: SEL, c: NSArray[NSURL]){.cdecl, gcsafe.}](objc_msgSend)
  let b2 = toBlock() do (r: int):
    if r == NSModalResponseOK:
      let urls = openPanel.URLs()
      send(cast[ID](completionHandler), $$"invoke", urls)
    else:
      send(cast[ID](completionHandler), $$"invoke", nil)
  openPanel.beginWithCompletionHandler(b2)

# Run the save panel dialog
proc run_save_panel*(self: Id; cmd: SEL; download: Id; filename: Id; completionHandler: Block[SaveCompletionHandler]) =
  var savePanel = NSSavePanel.savePanel()
  savePanel.setCanCreateDirectories(true)
  savePanel.setNameFieldStringValue(cast[NSString](filename))
  let blk = toBlock() do (r: int):
    if r == NSModalResponseOK:
      let url = savePanel.URL()
      let path = url.path()
      objc_msgSend(cast[Id](completionHandler), $$"invoke", 1, path)
    else:
      objc_msgSend(cast[Id](completionHandler), $$"invoke", No, nil)
  savePanel.beginWithCompletionHandler(blk)

# Run a confirmation panel
proc run_confirmation_panel*(self: Id; cmd: SEL; webView: Id; message: Id;
                                   frame: Id; completionHandler: Block[ConfirmCompletionHandler]) =
  var alert = NSAlert.alloc().init()
  # alert.setIcon(NSImage.imageNamed(NSCaution))
  alert.setShowsHelp(false)
  alert.setInformativeText(cast[NSString](message))
  alert.addButtonWithTitle(@"OK")
  alert.addButtonWithTitle(@"Cancel")
  let response = alert.runModal()
  if response == NSAlertFirstButtonReturn:
    objc_msgSend(cast[Id](completionHandler), $$"invoke", true)
  else:
    objc_msgSend(cast[Id](completionHandler), $$"invoke", false)
  alert.release()

# Run an alert panel
proc run_alert_panel*(self: Id; cmd: SEL; webView: Id; message: Id; frame: Id;
                            completionHandler: Block[AlertCompletionHandler]) =
  var alert = NSAlert.alloc().init()
  alert.setIcon(NSImage.imageNamed(NSImageNameCaution))
  alert.setShowsHelp(false)
  alert.setInformativeText(cast[NSString](message))
  alert.addButtonWithTitle(@"OK")
  alert.runModal()
  alert.release()
  objc_msgSend(cast[Id](completionHandler), $$"invoke")

# Main webview dialog handling
proc webview_dialog*(w: Webview; dlgtype: WebviewDialogType; flags: int;
                                title: cstring; arg: cstring; result: var cstring; resultsz: csize_t) =
  if dlgtype == WEBVIEW_DIALOG_TYPE_OPEN or dlgtype == WEBVIEW_DIALOG_TYPE_SAVE:
    var panel: NSSavePanel

    if dlgtype == WEBVIEW_DIALOG_TYPE_OPEN:
      var openPanel = NSOpenPanel.openPanel()
      if (flags and WEBVIEW_DIALOG_FLAG_DIRECTORY) > 0:
        openPanel.setCanChooseFiles(false)
        openPanel.setCanChooseDirectories(true)
      else:
        openPanel.setCanChooseFiles(true)
        openPanel.setCanChooseDirectories(false)
        openPanel.setResolvesAliases(false)
        openPanel.setAllowsMultipleSelection(false)
      panel = openPanel
    else:
      panel = NSSavePanel.savePanel()

    panel.setCanCreateDirectories(YES)
    panel.setShowsHiddenFiles(YES)
    panel.setExtensionHidden(NO)
    panel.setCanSelectHiddenExtension(NO)
    panel.setTreatsFilePackagesAsDirectories(YES)

    let blk = toBlock() do (r: int):
      NSApplication.sharedApplication().stopModalWithCode(r)

    panel.beginSheetModalForWindow(w.priv.window, blk)
    
    if NSApplication.sharedApplication().runModalForWindow(panel) == NSModalResponseOK:
      let url = panel.URL
      let path = url.path
      let filename = cast[cstring](path.UTF8String())
      copyMem(result, filename, resultsz)

  elif dlgtype == WEBVIEW_DIALOG_TYPE_ALERT:
    var alert = NSAlert.alloc().init()
    case flags and WEBVIEW_DIALOG_FLAG_ALERT_MASK:
    of WEBVIEW_DIALOG_FLAG_INFO:
      alert.setAlertStyle(NSAlertStyleInformational)
    of WEBVIEW_DIALOG_FLAG_WARNING:
      alert.setAlertStyle(NSAlertStyleWarning)
    of WEBVIEW_DIALOG_FLAG_ERROR:
      alert.setAlertStyle(NSAlertStyleCritical)
    else:
      discard
    alert.setShowsHelp(false)
    alert.setShowsSuppressionButton(false)
    alert.setMessageText(@($title))
    alert.setInformativeText(@($arg))
    alert.addButtonWithTitle(@"OK")
    alert.runModal()
    alert.release()
