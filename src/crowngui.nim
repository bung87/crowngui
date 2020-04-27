
import os,strutils,crownguipkg/webview
import nimhttpd,mimetypes,net,asyncdispatch

type 
  EntryType =  enum
    url,file,html,dir
  Application* = object
    entry:string
    entryType:EntryType
    webview:Webview
  ApplicationRef* = ref Application


proc server() {.thread.} = 
    var settings: NimHttpSettings
    settings.directory = currentSourcePath().parentDir() / "docs"
    settings.mimes = newMimeTypes()
    settings.mimes.register("html", "text/html")
    settings.mimes.register("css", "text/css")
    settings.address = ""
    settings.port = Port(8000)
    serve(settings)
    runForever()
    quit(0)

proc newApplication*(entry:static[string]):ApplicationRef =
  result = new ApplicationRef
  const entryType =
    when entry.startsWith"http": 
      const url = entry
      EntryType.url
    elif entry.endsWith".html" and not entry.startsWith"http": 
      const url = fileLocalHeader & entry
      EntryType.file
    elif entry.endsWith".js" or entry.endsWith".nim":
      const url = dataUriHtmlHeader "<!DOCTYPE html><html><head><meta content='width=device-width,initial-scale=1' name=viewport></head><body id=body ><div id=ROOT ><div></body></html>"  # Copied from Karax
      EntryType.file
    elif defined(bundle):
      const bundle {.strdefine.} = ""
      const url = "localhost"
      discard staticRead bundle
      EntryType.url
    else: 
      const url = dataUriHtmlHeader entry.strip
      EntryType.html
  var serverthr:Thread[void]
  createThread(serverthr,server)
  result.entryType = entryType
  result.webview = newWebView( url )

proc run(app:ApplicationRef) = app.webview.run
proc css(app:ApplicationRef,css:cstring) = app.webview.css(css)
proc exit(app:ApplicationRef) = app.webview.exit

when isMainModule:
  const   
    cssDark = staticRead"assets/dark.css".strip.unindent.cstring
    cssLight = staticRead"assets/light.css".strip.unindent.cstring

  let app = newApplication( staticRead("assets/demo.html") )
  let theme = if "--light-theme" in commandLineParams(): cssLight else: cssDark
  app.css(theme)
  app.run()
  app.exit()
