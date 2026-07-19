
{.passc: staticExec"pkg-config --cflags gtk+-3.0".}
{.passl: staticExec"pkg-config --libs gtk+-3.0".}
{.compile: "gtk_helpers.c".}

proc crowngui_dialog_info(message: cstring): pointer {.importc, header: "<gtk/gtk.h>".}
proc crowngui_dialog_warning(message: cstring): pointer {.importc, header: "<gtk/gtk.h>".}
proc crowngui_dialog_error(message: cstring): pointer {.importc, header: "<gtk/gtk.h>".}
proc crowngui_file_chooser_open(title: cstring, initial_folder: cstring): pointer {.importc, header: "<gtk/gtk.h>".}
proc crowngui_file_chooser_save(title: cstring, initial_folder: cstring): pointer {.importc, header: "<gtk/gtk.h>".}
proc crowngui_file_chooser_dir(title: cstring, initial_folder: cstring): pointer {.importc, header: "<gtk/gtk.h>".}

proc gtk_dialog_run(dialog: pointer): cint {.importc, header: "<gtk/gtk.h>".}
proc gtk_widget_destroy(widget: pointer) {.importc, header: "<gtk/gtk.h>".}
proc gtk_file_chooser_get_filename(chooser: pointer): cstring {.importc, header: "<gtk/gtk.h>".}
proc g_free(mem: pointer) {.importc, header: "<glib.h>".}

const
  GTK_RESPONSE_ACCEPT = -3

proc info*(title: string; description: string) =
  let msg = title & "\n\n" & description
  let dialog = crowngui_dialog_info(cstring(msg))
  discard gtk_dialog_run(dialog)
  gtk_widget_destroy(dialog)

proc warning*(title: string; description: string) =
  let msg = title & "\n\n" & description
  let dialog = crowngui_dialog_warning(cstring(msg))
  discard gtk_dialog_run(dialog)
  gtk_widget_destroy(dialog)

proc error*(title: string; description: string) =
  let msg = title & "\n\n" & description
  let dialog = crowngui_dialog_error(cstring(msg))
  discard gtk_dialog_run(dialog)
  gtk_widget_destroy(dialog)

proc chooseFile*(root: string = "", description: string = ""): string =
  let dialog = crowngui_file_chooser_open(cstring("Open File"), cstring(root))
  let response = gtk_dialog_run(dialog)
  result = ""
  if response == GTK_RESPONSE_ACCEPT:
    let filename = gtk_file_chooser_get_filename(dialog)
    if filename != nil:
      result = $filename
      g_free(filename)
  gtk_widget_destroy(dialog)

proc chooseFiles*(root: string = "", description: string = ""): seq[string] =
  result = @[]
  let file = chooseFile(root, description)
  if file.len > 0:
    result.add(file)

proc chooseFile*(cb: proc (a: seq[string]); root = "") =
  let files = chooseFiles(root, "")
  cb(files)

proc saveFile*(root: string = "", description: string = ""): string =
  let dialog = crowngui_file_chooser_save(cstring("Save File"), cstring(root))
  let response = gtk_dialog_run(dialog)
  result = ""
  if response == GTK_RESPONSE_ACCEPT:
    let filename = gtk_file_chooser_get_filename(dialog)
    if filename != nil:
      result = $filename
      g_free(filename)
  gtk_widget_destroy(dialog)

proc saveFile*(cb: proc (a: string); root = ""; filename = "") =
  let path = saveFile(root)
  cb(path)

proc chooseDir*(root: string = "", description: string = ""): string =
  let dialog = crowngui_file_chooser_dir(cstring("Select Folder"), cstring(root))
  let response = gtk_dialog_run(dialog)
  result = ""
  if response == GTK_RESPONSE_ACCEPT:
    let filename = gtk_file_chooser_get_filename(dialog)
    if filename != nil:
      result = $filename
      g_free(filename)
  gtk_widget_destroy(dialog)
