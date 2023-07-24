import winim/inc/windef
import ../com_wrapper

define_COM_interface:
  type
    ICoreWebView2Settings* {.pure.} = object
        QueryInterface*: proc(self;
            riid: REFIID; ppvObject: ptr pointer): HRESULT {.stdcall.}
        AddRef*: proc (self;): ULONG {.stdcall.}
        Release*: proc (self;): ULONG {.stdcall.}
        GetIsScriptEnabled*: proc (self;
            enabled: ptr bool): HRESULT {.stdcall.}
        PutIsScriptEnabled*: proc (self;
            enabled: bool): HRESULT {.stdcall.}
        GetIsWebMessageEnabled*: proc (self;
            enabled: ptr bool): HRESULT {.stdcall.}
        PutIsWebMessageEnabled*: proc (self;
            enabled: bool): HRESULT {.stdcall.}
        GetAreDefaultScriptDialogsEnabled*: proc (self;
            enabled: ptr bool): HRESULT {.stdcall.}
        PutAreDefaultScriptDialogsEnabled*: proc (self;
            enabled: bool): HRESULT {.stdcall.}
        GetIsStatusBarEnabled*: proc (self;
            enabled: ptr bool): HRESULT {.stdcall.}
        PutIsStatusBarEnabled*: proc (self;
            enabled: bool): HRESULT {.stdcall.}
        GetAreDevToolsEnabled*: proc (self;
            areDevToolsEnabled: ptr bool): HRESULT {.stdcall.}
        PutAreDevToolsEnabled*: proc (self;
            areDevToolsEnabled: bool): HRESULT
        GetAreDefaultContextMenusEnabled*: proc (self;
            enabled: ptr bool): HRESULT {.stdcall.}
        PutAreDefaultContextMenusEnabled*: proc (self;
            enabled: bool): HRESULT {.stdcall.}
        GetAreHostObjectsAllowed*: proc (self;
            allowed: ptr bool): HRESULT {.stdcall.}
        PutAreHostObjectsAllowed*: proc (self;
            allowed: bool): HRESULT {.stdcall.}
        GetIsZoomControlEnabled*: proc (self;
            enabled: ptr bool): HRESULT {.stdcall.}
        PutIsZoomControlEnabled*: proc (self;
            enabled: bool): HRESULT {.stdcall.}
        GetIsBuiltInErrorPageEnabled*: proc (self;
            enabled: ptr bool): HRESULT {.stdcall.}
        PutIsBuiltInErrorPageEnabled*: proc (self;
            enabled: bool): HRESULT {.stdcall.}