
import std/[strutils]
import crowngui / [webview, types]
export webview

type
  Application* = object
    entry: string
    entryType: EntryType
    webview*: Webview
  ApplicationRef* = ref Application


proc newApplication*(entry: static[string]): ApplicationRef =
  ## entry could be `html` file, `url` , `js` file or `nim` file
  ## when entry specific to nim file it will compile to js as script of bootstrap html

  result = new ApplicationRef
  
  when entry.startsWith"http":
    const url1 = entry
    const entryType = EntryType.url
  elif entry.endsWith".html" and not entry.startsWith"http":
    const url1 = fileLocalHeader & entry
    const entryType = EntryType.file
  elif entry.endsWith".js" or entry.endsWith".nim":
    const url1 = entry
    const entryType = EntryType.file
  else:
    const url1 =  entry.strip
    const entryType = EntryType.html
  result.entryType = entryType
  result.webview = newWebView(url1, entryType)


proc run*(app: ApplicationRef) = app.webview.run
proc css*(app: ApplicationRef, css: string) = app.webview.css(css)
proc eval*(app: ApplicationRef, js: string) = app.webview.eval(js)
proc destroy*(app: ApplicationRef) = app.webview.destroy
proc setOnOpenFile*(app: ApplicationRef; fn: OnOpenFile) = app.webview.onOpenFile = fn

template bindProcs*(app: ApplicationRef; scope: string; n: untyped): untyped = app.webview.bindProcs(scope, n)

type DialogData = object
  title: string
  description: string

when isMainModule:
  let app = newApplication(staticRead("assets/test.html"))
  app.bindProcs("api"):
    proc info(data:DialogData) =  dialog.info(data.title,data.description)
    proc warning(data:DialogData) = dialog.warning(data.title,data.description)
    proc error(data:DialogData) = dialog.error(data.title,data.description)
    proc chooseFile() = dialog.chooseFile()
    proc saveFile() = dialog.saveFile()
  const js = staticRead("assets/test.js")
  app.webview.addUserScriptAtDocumentEnd js
  app.run()
  app.destroy()
