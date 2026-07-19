import ../../types
import types as linuxTypes
import dialog

export types
export dialog

# GTK+3 and WebKit2GTK FFI bindings
{.passc: staticExec"pkg-config --cflags gtk+-3.0 webkit2gtk-4.0".}
{.passl: staticExec"pkg-config --libs gtk+-3.0 webkit2gtk-4.0".}

# GTK+3 FFI
proc gtk_init_check(argc: ptr cint, argv: ptr cstringArray): cint {.importc, header: "<gtk/gtk.h>".}
proc gtk_main() {.importc, header: "<gtk/gtk.h>".}
proc gtk_main_quit() {.importc, header: "<gtk/gtk.h>".}
proc gtk_widget_show_all(widget: pointer) {.importc, header: "<gtk/gtk.h>".}
proc gtk_container_add(container: pointer, child: pointer) {.importc, header: "<gtk/gtk.h>".}
proc gtk_window_new(window_type: cint): pointer {.importc, header: "<gtk/gtk.h>".}
proc gtk_window_set_title(window: pointer, title: cstring) {.importc, header: "<gtk/gtk.h>".}
proc gtk_window_set_default_size(window: pointer, width: cint, height: cint) {.importc, header: "<gtk/gtk.h>".}
proc gtk_window_set_resizable(window: pointer, resizable: cint) {.importc, header: "<gtk/gtk.h>".}
proc g_signal_connect(instance: pointer, detailed_signal: cstring, c_handler: pointer, data: pointer): cuint {.importc, header: "<glib.h>".}
proc g_idle_add(function: pointer, data: pointer): cuint {.importc, header: "<glib.h>".}

# WebKit2GTK FFI
proc webkit_web_view_new(): pointer {.importc, header: "<webkit2/webkit2.h>".}
proc webkit_web_view_load_html(web_view: pointer, content: cstring, base_uri: cstring) {.importc, header: "<webkit2/webkit2.h>".}
proc webkit_web_view_load_uri(web_view: pointer, uri: cstring) {.importc, header: "<webkit2/webkit2.h>".}
proc webkit_web_view_run_javascript(web_view: pointer, script: cstring, cancellable: pointer,
                                    callback: pointer, user_data: pointer) {.importc, header: "<webkit2/webkit2.h>".}
proc webkit_web_view_get_settings(web_view: pointer): pointer {.importc, header: "<webkit2/webkit2.h>".}
proc webkit_settings_set_enable_developer_extras(settings: pointer, enable: cint) {.importc, header: "<webkit2/webkit2.h>".}
proc webkit_settings_set_javascript_can_access_clipboard(settings: pointer, enable: cint) {.importc, header: "<webkit2/webkit2.h>".}
proc webkit_web_view_get_user_content_manager(web_view: pointer): pointer {.importc, header: "<webkit2/webkit2.h>".}
proc webkit_user_content_manager_add_script(content_manager: pointer, script: pointer) {.importc, header: "<webkit2/webkit2.h>".}
proc webkit_user_script_new(source: cstring, injected_at_document_start: cint,
                            injected_in_top_frame_only: cint, whitelisted_origin_prefixes: ptr cstring,
                            num_whitelisted_origin_prefixes: cuint): pointer {.importc, header: "<webkit2/webkit2.h>".}

# Types
type
  WebviewDispatchCtx {.pure.} = object
    w: Webview
    arg: pointer
    fn: pointer

# Constants
const
  GTK_WINDOW_TOPLEVEL = 0

# Forward declarations
proc destroy*(w: Webview)
proc terminate*(w: Webview)

proc webviewDispatchCb(data: pointer): cint {.cdecl.} =
  let context = cast[ptr WebviewDispatchCtx](data)
  let fn = cast[proc(w: Webview; arg: pointer) {.cdecl.}](context.fn)
  fn(context.w, context.arg)
  return 0  # G_SOURCE_REMOVE

proc webview_dispatch*(w: Webview; fn: pointer; arg: pointer) {.cdecl.} =
  let ctx = cast[ptr WebviewDispatchCtx](alloc0(sizeof(WebviewDispatchCtx)))
  ctx.w = w
  ctx.fn = fn
  ctx.arg = arg
  discard g_idle_add(cast[pointer](webviewDispatchCb), ctx)

proc embed*(w: Webview) =
  w.priv.webview = webkit_web_view_new()
  if w.priv.webview == nil:
    return

  let settings = webkit_web_view_get_settings(w.priv.webview)
  if settings != nil:
    webkit_settings_set_enable_developer_extras(settings, cint(w.debug))
    webkit_settings_set_javascript_can_access_clipboard(settings, 1)

  w.priv.contentManager = webkit_web_view_get_user_content_manager(w.priv.webview)

  const bridgeScript = "window.external = { invoke: function(arg) { window._externalInvokeCallback(arg); } };"
  let userScript = webkit_user_script_new(
    cstring(bridgeScript),
    1,  # injected_at_document_start
    1,  # injected_in_top_frame_only
    nil,
    0
  )
  webkit_user_content_manager_add_script(w.priv.contentManager, userScript)

  gtk_container_add(w.priv.window, w.priv.webview)

  case w.entryType
  of EntryType.html:
    webkit_web_view_load_html(w.priv.webview, cstring(w.url), nil)
  else:
    webkit_web_view_load_uri(w.priv.webview, cstring(w.url))

  gtk_widget_show_all(w.priv.window)

proc onWindowDestroy(widget: pointer, data: pointer) {.cdecl.} =
  let w = cast[Webview](data)
  if w != nil:
    w.terminate()

proc webview_init*(w: Webview): cint =
  var argc: cint = 0
  var argv: cstringArray = nil
  if gtk_init_check(addr argc, addr argv) == 0:
    return -1

  w.priv.window = gtk_window_new(GTK_WINDOW_TOPLEVEL)
  if w.priv.window == nil:
    return -1

  gtk_window_set_title(w.priv.window, cstring(w.title))
  gtk_window_set_default_size(w.priv.window, cint(w.width), cint(w.height))
  gtk_window_set_resizable(w.priv.window, cint(if w.resizable: 1 else: 0))

  discard g_signal_connect(w.priv.window, cstring("destroy"), cast[pointer](onWindowDestroy), w)

  w.embed()

  return 0

proc run*(w: Webview) =
  gtk_main()

proc terminate*(w: Webview) =
  gtk_main_quit()

proc destroy*(w: Webview) =
  w.terminate()

proc eval*(w: Webview, js: string) =
  if w.priv.webview != nil:
    webkit_web_view_run_javascript(w.priv.webview, cstring(js), nil, nil, nil)

proc setTitle*(w: Webview; title: string) =
  if w.priv.window != nil:
    gtk_window_set_title(w.priv.window, cstring(title))

proc navigate*(w: Webview; url: string) =
  if w.priv.webview != nil:
    webkit_web_view_load_uri(w.priv.webview, cstring(url))

proc setHtml*(w: Webview; html: string) =
  if w.priv.webview != nil:
    webkit_web_view_load_html(w.priv.webview, cstring(html), nil)

proc setSize*(w: Webview; width: int; height: int) =
  if w.priv.window != nil:
    gtk_window_set_default_size(w.priv.window, cint(width), cint(height))

proc addUserScript(w: Webview, js: string; atStart: bool) =
  if w.priv.contentManager == nil:
    return
  let userScript = webkit_user_script_new(
    cstring(js),
    cint(if atStart: 1 else: 0),
    1,
    nil,
    0
  )
  webkit_user_content_manager_add_script(w.priv.contentManager, userScript)

proc addUserScriptAtDocumentStart*(w: Webview, js: string) =
  w.addUserScript(js, atStart = true)

proc addUserScriptAtDocumentEnd*(w: Webview, js: string) =
  w.addUserScript(js, atStart = false)
