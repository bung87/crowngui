type
  WebviewPrivObj* = object
    window*: pointer    # GtkWidget*
    webview*: pointer   # WebKitWebView*
    contentManager*: pointer  # WebKitUserContentManager*
