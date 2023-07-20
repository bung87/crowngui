import objc_runtime

type
  Webview* = ptr WebviewObj
  WebviewObj* {.pure.} = object ## WebView Type
    url* : string                                          ## Current URL
    title* : string                                      ## Window Title
    width* : int                                         ## Window Width
    height* : int                                       ## Window Height
    resizable* : bool ## `true` to Resize the Window, `false` for Fixed size Window
    debug* : bool                                         ## Debug is `true` when not build for Release
    invokeCb* : pointer                       ## Callback proc js:window.external.invoke
    priv* : WebviewPrivObj
    userdata* : pointer
    onOpenFile*: OnOpenFile
  ExternalInvokeCb* = proc (w: Webview; arg: cstring) ## External CallBack Proc

  WebviewPrivObj* = object
    pool*: ID
    window*: ID
    webview*: ID
    windowDelegate*: ID

  OnOpenFile* = proc (w: Webview; filePath: string; name = ""):bool