import std/[os]
import objc_runtime
const headerC = currentSourcePath.parentDir.parentDir.parentDir / "webview.h"

type
  Webview* = ptr WebviewObj
  WebviewObj* {.importc: "struct webview", header: headerC, bycopy.} = object ## WebView Type
    url* {.importc: "url".}: cstring                                          ## Current URL
    title* {.importc: "title".}: cstring                                      ## Window Title
    width* {.importc: "width".}: cint                                         ## Window Width
    height* {.importc: "height".}: cint                                       ## Window Height
    resizable* {.importc: "resizable".}: cint ## `true` to Resize the Window, `false` for Fixed size Window
    debug* {.importc: "debug".}: cint                                         ## Debug is `true` when not build for Release
    invokeCb* {.importc: "external_invoke_cb".}: pointer                       ## Callback proc js:window.external.invoke
    priv* {.importc: "priv".}: WebviewPrivObj
    userdata* {.importc: "userdata".}: pointer
  ExternalInvokeCb* = proc (w: Webview; arg: cstring) ## External CallBack Proc

  WebviewPrivObj* = object
    pool*: ID
    window*: ID
    webview*: ID
    windowDelegate*: ID
    should_exit*: cint