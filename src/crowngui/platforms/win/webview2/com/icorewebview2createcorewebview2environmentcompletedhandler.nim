import winim/inc/windef
import ../com_wrapper
import ./icorewebview2controller
import ./icorewebview2createcorewebview2controllercompletedhandler
import ./icorewebview2environment

define_COM_interface:
  type
    ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler* {.pure.} = object
      QueryInterface*: proc(self; riid: REFIID; ppvObject: ptr pointer): HRESULT {.stdcall.}
      AddRef*: proc (self): ULONG {.stdcall.}
      Release*: proc (self): ULONG {.stdcall.}
      Invoke*: proc (self;errorCode: HRESULT; createdEnvironment: ptr ICoreWebView2Environment): HRESULT {.stdcall.}
      windowHandle*: HWND
      controllerCompletedHandler*:ptr ICoreWebView2CreateCoreWebView2ControllerCompletedHandler
