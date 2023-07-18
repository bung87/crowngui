import window, browser
import std/[os]
import types,com
import winim


proc newWebView*():WebView =
  result = new WebView
  var windowConfig = WindowConfig(width:640,height:480,title:"Webview")
  var window = Window(config:windowConfig)
  var browserConfig = BrowserConfig(
    initialURL:           "about:blank",
    builtInErrorPage:     true,
    defaultContextMenus:  true,
    defaultScriptDialogs: true,
    devtools:             true,
    hostObjects:          true,
    script:               true,
    statusBar:            true,
    webMessage:           true,
    zoomControl:          true,
  )
  var browser = Browser(
    config: browserConfig,
    ctx: BrowserContext()
    )
  result.window = window
  result.browser = browser
  try:
    if CoInitializeEx(nil, COINIT_APARTMENTTHREADED).FAILED: raise
    defer: CoUninitialize()
  except:
    discard
