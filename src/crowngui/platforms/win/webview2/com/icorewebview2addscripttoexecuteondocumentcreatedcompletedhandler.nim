import winim/inc/windef
import ../com_wrapper
import ./icorewebview2settings

define_COM_interface:
  type 
    ICoreWebView2AddScriptToExecuteOnDocumentCreatedCompletedHandler* {.pure.} = object
      QueryInterface*: proc(self;riid: REFIID; ppvObject: ptr pointer): HRESULT {.stdcall.}
      AddRef*: proc (self): ULONG {.stdcall.}
      Release*: proc (self): ULONG {.stdcall.}
      Invoke*: proc (self;errorCode: HRESULT; id: LPCWSTR) {.stdcall.}