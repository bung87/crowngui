import winim/inc/windef

type
  ICoreWebView2EnvironmentOptions* {.pure.} = object
    lpVtbl*: ptr ICoreWebView2EnvironmentOptionsVTBL

  ICoreWebView2EnvironmentOptionsVTBL* {.pure.} = object
    QueryInterface*: proc(self: ptr ICoreWebView2EnvironmentOptions;
        riid: REFIID; ppvObject: ptr pointer): HRESULT {.stdcall.}
    AddRef*: proc (self: ptr ICoreWebView2EnvironmentOptions): ULONG {.stdcall.}
    Release*: proc (self: ptr ICoreWebView2EnvironmentOptions): ULONG {.stdcall.}
    get_AdditionalBrowserArguments*: proc (
        self: ptr ICoreWebView2EnvironmentOptions;
        value: ptr LPWSTR): HRESULT {.stdcall.}
    put_AdditionalBrowserArguments*: proc (
        self: ptr ICoreWebView2EnvironmentOptions;
        value: LPCWSTR): HRESULT {.stdcall.}
    get_Language*: proc(self: ptr ICoreWebView2EnvironmentOptions;
        value: ptr LPWSTR): HRESULT {.stdcall.}
    put_Language*: proc (self: ptr ICoreWebView2EnvironmentOptions;
        value: LPCWSTR): HRESULT {.stdcall.}
    get_TargetCompatibleBrowserVersion* : proc (
        self: ptr ICoreWebView2EnvironmentOptions;
        value: ptr LPWSTR): HRESULT {.stdcall.}
    put_TargetCompatibleBrowserVersion* : proc (
        self: ptr ICoreWebView2EnvironmentOptions;
        value: LPCWSTR): HRESULT {.stdcall.}
    get_AllowSingleSignOnUsingOSPrimaryAccount* : proc(
        self: ptr ICoreWebView2EnvironmentOptions;
        allow: ptr BOOL): HRESULT {.stdcall.}
    put_AllowSingleSignOnUsingOSPrimaryAccount* : proc(
        self: ptr ICoreWebView2EnvironmentOptions;
        allow: BOOL): HRESULT {.stdcall.}
    # ICoreWebView2EnvironmentOptions2
    get_ExclusiveUserDataFolderAccess*: proc (self: ptr ICoreWebView2EnvironmentOptions;value: ptr BOOL): HRESULT {.stdcall.}
    put_ExclusiveUserDataFolderAccess*: proc (self: ptr ICoreWebView2EnvironmentOptions;value: BOOL): HRESULT {.stdcall.}
    # ICoreWebView2EnvironmentOptions3
    get_IsCustomCrashReportingEnabled*: proc(): HRESULT {.stdcall.}
    put_IsCustomCrashReportingEnabled*: proc(): HRESULT {.stdcall.}
    # ICoreWebView2EnvironmentOptions4
    GetCustomSchemeRegistrations*: proc(): HRESULT {.stdcall.}
    SetCustomSchemeRegistrations*: proc(): HRESULT {.stdcall.}
    # ICoreWebView2EnvironmentOptions5
    get_EnableTrackingPrevention*: proc(): HRESULT {.stdcall.}
    put_EnableTrackingPrevention*: proc(): HRESULT {.stdcall.}

using self: ptr ICoreWebView2EnvironmentOptions
