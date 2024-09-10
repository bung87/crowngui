import objc_runtime

type
  WebviewPrivObj* = object
    pool*: ID
    window*: ID
    webview*: ID
    windowDelegate*: ID
