import winim/inc/windef
import ../com_wrapper

define_COM_interface:
  type
    ICoreWebView2DOMContentLoadedEventArgs* {.pure.} = object
      QueryInterface*: proc(self; riid: REFIID; ppvObject: ptr pointer): HRESULT {.stdcall.}
      AddRef*: proc (self): ULONG {.stdcall.}
      Release*: proc (self): ULONG {.stdcall.}
      get_NavigationId*: proc (self; navigationId: ptr uint64): HRESULT {.stdcall.}
