import winim/inc/windef
import ../com_wrapper
import ./icorewebview2createcorewebview2controllercompletedhandler

define_COM_interface:

  type
    ICoreWebView2Environment* {.pure.} = object
      QueryInterface*: proc(self; riid: REFIID;
          ppvObject: ptr pointer): HRESULT {.stdcall.}
      AddRef*: proc (self): ULONG {.stdcall.}
      Release*: proc (self): ULONG {.stdcall.}

      CreateCoreWebView2Controller*: proc (self;
        parentWindow: HWND;
        handler: ptr ICoreWebView2CreateCoreWebView2ControllerCompletedHandler): HRESULT {.stdcall.}
      CreateWebResourceResponse*: proc (self): HRESULT {.stdcall.}
      GetBrowserVersionString*: proc (self;
        version_info: LPWSTR): HRESULT {.stdcall.}
      AddNewBrowserVersionAvailable*: proc (self): HRESULT {.stdcall.}
      RemoveNewBrowserVersionAvailable*: proc (self): HRESULT {.stdcall.}
      # ICoreWebView2Environment7
      get_UserDataFolder*: proc (self; value: ptr LPWSTR): HRESULT {.stdcall.}
