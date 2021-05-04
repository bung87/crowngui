
import os, strutils, crownguipkg/webview
import static_server, mimetypes, asyncdispatch
import finder

export webview

type
  EntryType = enum
    url, file, html, dir
  Application* = object
    entry: string
    entryType: EntryType
    webview: Webview
  ApplicationRef* = ref Application


proc server(data: string) {.thread.} =
  var settings: NimHttpSettings
  var finder = Finder(fType: FinderType.zip2mem)
  initFinder(finder, data)
  when not defined(release):
    settings.logging = true
  settings.finder = finder
  settings.mimes = newMimeTypes()
  settings.address = ""
  settings.port = Port(8000)
  serve(settings)
  runForever()
  quit(0)

const bundle {.strdefine.} = ""
proc newApplication*(entry: static[string]): ApplicationRef =
  ## entry could be `html` file, `url` , `js` file or `nim` file
  ## when entry specific to nim file it will compile to js as script of bootstrap html
  ## when run command specific `--wwwroot` parameter it will bundle directory as http server root
  result = new ApplicationRef
  const entryType =
    when defined(bundle):
      const url = "http://localhost:8000"
      EntryType.url
    elif entry.startsWith"http":
      const url = entry
      EntryType.url
    elif entry.endsWith".html" and not entry.startsWith"http":
      const url = fileLocalHeader & entry
      EntryType.file
    elif entry.endsWith".js" or entry.endsWith".nim":
      const url = dataUriHtmlHeader "<!DOCTYPE html><html><head><meta content='width=device-width,initial-scale=1' name=viewport></head><body id=body ><div id=ROOT ><div></body></html>" # Copied from Karax
      EntryType.file
    else:
      const url = dataUriHtmlHeader entry.strip
      EntryType.html
  when defined(bundle):
    const data = staticRead bundle
    var serverthr: Thread[string]
    createThread(serverthr, server, data)
  result.entryType = entryType
  result.webview = newWebView(url)

proc run*(app: ApplicationRef) = app.webview.run
proc css*(app: ApplicationRef, css: cstring) = app.webview.css(css)
proc css*(app: ApplicationRef, css: string) = app.webview.css(css.cstring)
proc js*(app: ApplicationRef, js: cstring) = app.webview.js(js)
proc js*(app: ApplicationRef, js: string) = app.webview.js(js.cstring)
proc exit*(app: ApplicationRef) = app.webview.exit
template bindProcs*(app: ApplicationRef; scope: string; n: untyped): untyped = app.webview.bindProcs(scope, n)

when isMainModule:

  const
    cssDark = staticRead"assets/dark.css".strip.unindent.cstring
    cssLight = staticRead"assets/light.css".strip.unindent.cstring

  let app = newApplication(staticRead("assets/demo.html"))
  when not defined(bundle):
    let theme = if "--light-theme" in commandLineParams(): cssLight else: cssDark
    app.css(theme)

  app.run()
  app.exit()
