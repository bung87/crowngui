import std/[os]
import objc_runtime

type
  Webview* = ptr WebviewObj
  WebviewObj* {.pure.} = object ## WebView Type
    url* : cstring                                          ## Current URL
    title* : cstring                                      ## Window Title
    width* : cint                                         ## Window Width
    height* : cint                                       ## Window Height
    resizable* : cint ## `true` to Resize the Window, `false` for Fixed size Window
    debug* : cint                                         ## Debug is `true` when not build for Release
    invokeCb* : pointer                       ## Callback proc js:window.external.invoke
    priv* : WebviewPrivObj
    userdata* : pointer
  ExternalInvokeCb* = proc (w: Webview; arg: cstring) ## External CallBack Proc

  WebviewPrivObj* = object
    pool*: ID
    window*: ID
    webview*: ID
    windowDelegate*: ID
    should_exit*: cint