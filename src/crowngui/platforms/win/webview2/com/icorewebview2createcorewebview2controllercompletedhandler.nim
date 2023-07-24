import winim/inc/windef
import ../com_wrapper
import ./icorewebview2controller

define_COM_interface:
  type
    ICoreWebView2CreateCoreWebView2ControllerCompletedHandler* {.pure.} = object
      QueryInterface*: proc(self; riid: REFIID; ppvObject: ptr pointer): HRESULT {.stdcall.}
      AddRef*: proc (self): ULONG {.stdcall.}
      Release*: proc (self): ULONG {.stdcall.}
      Invoke*: proc (self; errorCode: HRESULT; createdController: ptr ICoreWebView2Controller): HRESULT {.stdcall.}
      windowHandle*: HWND
