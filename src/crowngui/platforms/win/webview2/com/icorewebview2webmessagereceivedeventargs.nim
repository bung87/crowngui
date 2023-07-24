import winim/inc/windef
import ../com_wrapper

define_COM_interface:

  type
    # ICoreWebView2WebMessageReceivedEventArgs* {.pure.} = object
    #   lpVtbl*: ptr ICoreWebView2WebMessageReceivedEventArgsVTBL
    ICoreWebView2WebMessageReceivedEventArgs* {.pure.} = object
      QueryInterface*: proc(self;
        riid: REFIID; ppvObject: ptr pointer): HRESULT {.stdcall.}
      AddRef*: proc (self): ULONG {.stdcall.}
      Release*: proc (self): ULONG {.stdcall.}
      get_Source*: proc (self; source: ptr LPWSTR): HRESULT {.stdcall.}
      get_WebMessageAsJson*: proc (self; source: ptr LPWSTR): HRESULT {.stdcall.}
      TryGetWebMessageAsString*: proc (self; source: ptr LPWSTR): HRESULT {.stdcall.}
