import winim/inc/windef
import ../com_wrapper
import ./icorewebview2
import ./icorewebview2webmessagereceivedeventargs

# define_COM_interface:
#   ICoreWebView2WebMessageReceivedEventHandler* {.pure.} = object
#     lpVtbl*VTBL
#     windowHandle*: HWND
