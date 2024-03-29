
import os, strutils, crowngui / [webview, net_utils]
import static_server, mimetypes, asyncdispatch
import finder

export webview

type
  EntryType = enum
    url, file, html, dir
  Application* = object
    entry: string
    entryType: EntryType
    webview*: Webview
  ApplicationRef* = ref Application


proc server(ctx: tuple[data: string, port: int ]) {.thread.} =
  var settings: NimHttpSettings
  var finder = Finder(fType: FinderType.zip2mem)
  initFinder(finder, ctx.data)
  when not defined(release):
    settings.logging = true
  settings.finder = finder
  settings.mimes = newMimeTypes()
  settings.address = ""
  settings.port = Port(ctx.port)
  serve(settings)
  runForever()
  quit(0)

const bundle {.strdefine.} = ""
proc newApplication*(entry: static[string]): ApplicationRef =
  ## entry could be `html` file, `url` , `js` file or `nim` file
  ## when entry specific to nim file it will compile to js as script of bootstrap html
  ## when run command specific `--wwwroot` parameter it will bundle directory as http server root
  result = new ApplicationRef
  when defined(bundle):
    var port: int
  const entryType =
    when defined(bundle):
      EntryType.url
    elif entry.startsWith"http":
      const url = entry
      EntryType.url
    elif entry.endsWith".html" and not entry.startsWith"http":
      const url = fileLocalHeader & entry
      EntryType.file
    elif entry.endsWith".js" or entry.endsWith".nim":
      const url = entry
      EntryType.file
    else:
      const url = dataUriHtmlHeader entry.strip
      EntryType.html
  when defined(bundle):
    const data = staticRead bundle
    var serverthr: Thread[string]
    createThread(serverthr, server, (data, port))
  result.entryType = entryType
  when defined(bundle):
    port = findAvailablePort()
    let url = "http://localhost:" & $port
  result.webview = newWebView(url)
  when defined(bundle):
    result.webview.url = url


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
