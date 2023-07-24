import winim/inc/windef
import ../com_wrapper

define_COM_interface:
  type 
      ICoreWebView2ExecuteScriptCompletedHandler* {.pure.} = object
        QueryInterface*: proc(self;
            riid: REFIID; ppvObject: ptr pointer): HRESULT {.stdcall.}
        AddRef*: proc (self): ULONG {.stdcall.}
        Release*: proc (self): ULONG {.stdcall.}
        Invoke*: proc (self;
            errorCode: HRESULT; resultObjectAsJson: LPCWSTR) {.stdcall.}