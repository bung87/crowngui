
import os,strutils,crownguipkg/webview


type 
  EntryType =  enum
    url,file,html
  Application* = object
    entry:string
    entryType:EntryType
    webview:Webview
  ApplicationRef* = ref Application

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
    else: 
      const url = dataUriHtmlHeader entry.strip
      EntryType.html
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
