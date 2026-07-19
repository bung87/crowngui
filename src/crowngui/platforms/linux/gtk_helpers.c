#include <gtk/gtk.h>

GtkWidget* crowngui_dialog_info(const char* message) {
    GtkWidget* dialog = gtk_message_dialog_new(NULL, GTK_DIALOG_MODAL, GTK_MESSAGE_INFO, GTK_BUTTONS_OK, "%s", message);
    return dialog;
}

GtkWidget* crowngui_dialog_warning(const char* message) {
    GtkWidget* dialog = gtk_message_dialog_new(NULL, GTK_DIALOG_MODAL, GTK_MESSAGE_WARNING, GTK_BUTTONS_OK, "%s", message);
    return dialog;
}

GtkWidget* crowngui_dialog_error(const char* message) {
    GtkWidget* dialog = gtk_message_dialog_new(NULL, GTK_DIALOG_MODAL, GTK_MESSAGE_ERROR, GTK_BUTTONS_OK, "%s", message);
    return dialog;
}

GtkWidget* crowngui_file_chooser_open(const char* title, const char* initial_folder) {
    GtkWidget* dialog = gtk_file_chooser_dialog_new(title, NULL, GTK_FILE_CHOOSER_ACTION_OPEN,
        "_Cancel", GTK_RESPONSE_CANCEL,
        "_Open", GTK_RESPONSE_ACCEPT,
        NULL);
    if (initial_folder && initial_folder[0] != '\0') {
        gtk_file_chooser_set_current_folder(GTK_FILE_CHOOSER(dialog), initial_folder);
    }
    return dialog;
}

GtkWidget* crowngui_file_chooser_save(const char* title, const char* initial_folder) {
    GtkWidget* dialog = gtk_file_chooser_dialog_new(title, NULL, GTK_FILE_CHOOSER_ACTION_SAVE,
        "_Cancel", GTK_RESPONSE_CANCEL,
        "_Save", GTK_RESPONSE_ACCEPT,
        NULL);
    if (initial_folder && initial_folder[0] != '\0') {
        gtk_file_chooser_set_current_folder(GTK_FILE_CHOOSER(dialog), initial_folder);
    }
    return dialog;
}

GtkWidget* crowngui_file_chooser_dir(const char* title, const char* initial_folder) {
    GtkWidget* dialog = gtk_file_chooser_dialog_new(title, NULL, GTK_FILE_CHOOSER_ACTION_SELECT_FOLDER,
        "_Cancel", GTK_RESPONSE_CANCEL,
        "_Select", GTK_RESPONSE_ACCEPT,
        NULL);
    if (initial_folder && initial_folder[0] != '\0') {
        gtk_file_chooser_set_current_folder(GTK_FILE_CHOOSER(dialog), initial_folder);
    }
    return dialog;
}
