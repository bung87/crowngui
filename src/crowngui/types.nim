when defined(windows):
  import ./platforms/win/webview2/types
elif defined(macosx):
  import ./platforms/macos/types

type
  WebView* = ptr WebViewObj
  WebViewObj* = object
    url* : string
    title* : string
    width* : int
    height* : int
    resizable*: bool
    debug* : bool
    invokeCb* : pointer
    priv*: WebviewPrivObj
    created*: bool
    onOpenFile*: OnOpenFile
    entryType*: EntryType
  EntryType* {.pure.} = enum
    url, file, html, dir
  OnOpenFile* = proc (w: Webview; filePath: string; name = ""):bool
  