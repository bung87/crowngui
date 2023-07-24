import winim/inc/windef
import ../com_wrapper

define_COM_interface:
  type
    ICoreWebView2EnvironmentOptions* {.pure.} = object
      QueryInterface*: proc(self;riid: REFIID; ppvObject: ptr pointer): HRESULT {.stdcall.}
      AddRef*: proc (self;): ULONG {.stdcall.}
      Release*: proc (self;): ULONG {.stdcall.}
      get_AdditionalBrowserArguments*: proc (self; value: ptr LPWSTR): HRESULT {.stdcall.}
      put_AdditionalBrowserArguments*: proc (self; value: LPCWSTR): HRESULT {.stdcall.}
      get_Language*: proc(self; value: ptr LPWSTR): HRESULT {.stdcall.}
      put_Language*: proc (self; value: LPCWSTR): HRESULT {.stdcall.}
      get_TargetCompatibleBrowserVersion*: proc (self; value: ptr LPWSTR): HRESULT {.stdcall.}
      put_TargetCompatibleBrowserVersion*: proc (self; value: LPCWSTR): HRESULT {.stdcall.}
      get_AllowSingleSignOnUsingOSPrimaryAccount*: proc(self; allow: ptr BOOL): HRESULT {.stdcall.}
      put_AllowSingleSignOnUsingOSPrimaryAccount*: proc(self; allow: BOOL): HRESULT {.stdcall.}
      # ICoreWebView2EnvironmentOptions2
      get_ExclusiveUserDataFolderAccess*: proc (self; value: ptr BOOL): HRESULT {.stdcall.}
      put_ExclusiveUserDataFolderAccess*: proc (self; value: BOOL): HRESULT {.stdcall.}
      # ICoreWebView2EnvironmentOptions3
      get_IsCustomCrashReportingEnabled*: proc(self;): HRESULT {.stdcall.}
      put_IsCustomCrashReportingEnabled*: proc(self;): HRESULT {.stdcall.}
      # ICoreWebView2EnvironmentOptions4
      GetCustomSchemeRegistrations*: proc(self;): HRESULT {.stdcall.}
      SetCustomSchemeRegistrations*: proc(self;): HRESULT {.stdcall.}
      # ICoreWebView2EnvironmentOptions5
      get_EnableTrackingPrevention*: proc(self;): HRESULT {.stdcall.}
      put_EnableTrackingPrevention*: proc(self;): HRESULT {.stdcall.}
