import winim

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

  # https://learn.microsoft.com/en-us/microsoft-edge/webview2/reference/win32/icorewebview2?view=webview2-1.0.1823.32
  ICoreWebView2* {.pure.} = object
    lpVtbl*: ptr ICoreWebView2VTBL
  ICoreWebView2VTBL* = object
    QueryInterface*: proc(self: ptr ICoreWebView2;
        riid: REFIID; ppvObject: ptr pointer): HRESULT {.stdcall.}
    AddRef*: proc (self: ptr ICoreWebView2): ULONG {.stdcall.}
    Release*: proc (self: ptr ICoreWebView2): ULONG {.stdcall.}

    get_Settings*: proc (self: ptr ICoreWebView2;
        settings: ptr ptr ICoreWebView2Settings): HRESULT {.stdcall.}
    get_Source*: proc(): HRESULT {.stdcall.}
    Navigate*: proc (self: ptr ICoreWebView2; url: LPCWSTR): HRESULT {.stdcall.}
    NavigateToString*: proc (self: ptr ICoreWebView2;
        html_content: LPCWSTR): HRESULT {.stdcall.}
    add_NavigationStarting*: proc(): HRESULT {.stdcall.}
    remove_NavigationStarting*: proc(): HRESULT {.stdcall.}
    add_ContentLoading*: proc(): HRESULT {.stdcall.}
    remove_ContentLoading*: proc(): HRESULT {.stdcall.}
    add_SourceChanged*: proc(): HRESULT {.stdcall.}
    remove_SourceChanged*: proc(): HRESULT {.stdcall.}
    add_HistoryChanged*: proc(): HRESULT {.stdcall.}
    remove_HistoryChanged*: proc(): HRESULT {.stdcall.}
    add_NavigationCompleted*: proc(): HRESULT {.stdcall.}
    remove_NavigationCompleted*: proc(): HRESULT {.stdcall.}
    add_FrameNavigationStarting*: proc(): HRESULT {.stdcall.}
    remove_FrameNavigationStarting*: proc(): HRESULT {.stdcall.}
    add_FrameNavigationCompleted*: proc(): HRESULT {.stdcall.}
    remove_FrameNavigationCompleted*: proc(): HRESULT {.stdcall.}
    add_ScriptDialogOpening*: proc(): HRESULT {.stdcall.}
    remove_ScriptDialogOpening*: proc(): HRESULT {.stdcall.}
    add_PermissionRequested*: proc(): HRESULT {.stdcall.}
    remove_PermissionRequested*: proc(): HRESULT {.stdcall.}
    add_ProcessFailed*: proc(): HRESULT {.stdcall.}
    remove_ProcessFailed*: proc(): HRESULT {.stdcall.}
    AddScriptToExecuteOnDocumentCreated * : proc (self: ICoreWebView2;
        javaScript: LPCWSTR;
        handler: ptr ICoreWebView2AddScriptToExecuteOnDocumentCreatedCompletedHandler): HRESULT {.stdcall.}
    RemoveScriptToExecuteOnDocumentCreated*: proc(): HRESULT {.stdcall.}
    ExecuteScript*: proc (self: ptr ICoreWebView2; javaScript: LPCWSTR;
        handler: ptr ICoreWebView2ExecuteScriptCompletedHandler): HRESULT {.stdcall.}
    CapturePreview*: proc(): HRESULT {.stdcall.}
    Reload*: proc (self: ptr ICoreWebView2): HRESULT {.stdcall.}
    PostWebMessageAsJson*: proc(): HRESULT {.stdcall.}
    PostWebMessageAsString*: proc(): HRESULT {.stdcall.}
    add_WebMessageReceived*: proc(): HRESULT {.stdcall.}
    remove_WebMessageReceived*: proc(): HRESULT {.stdcall.}
    CallDevToolsProtocolMethod*: proc(): HRESULT {.stdcall.}
    get_BrowserProcessId*: proc(): HRESULT {.stdcall.}
    get_CanGoBack*: proc(): HRESULT {.stdcall.}
    get_CanGoForward*: proc(): HRESULT {.stdcall.}
    GoBack*: proc (self: ptr ICoreWebView2): HRESULT {.stdcall.}
    GoForward*: proc (self: ptr ICoreWebView2): HRESULT {.stdcall.}
    GetDevToolsProtocolEventReceiver*: proc(): HRESULT {.stdcall.}
    Stop*: proc (self: ptr ICoreWebView2): HRESULT {.stdcall.}
    add_NewWindowRequested*: proc(): HRESULT {.stdcall.}
    remove_NewWindowRequested*: proc(): HRESULT {.stdcall.}
    add_DocumentTitleChanged*: proc(): HRESULT {.stdcall.}
    remove_DocumentTitleChanged*: proc(): HRESULT {.stdcall.}
    get_DocumentTitle*: proc (self: ptr ICoreWebView2; title: LPWSTR): HRESULT {.stdcall.}
    AddHostObjectToScript*: proc(): HRESULT {.stdcall.}
    RemoveHostObjectFromScript*: proc(): HRESULT {.stdcall.}
    OpenDevToolsWindow*: proc (self: ptr ICoreWebView2): HRESULT {.stdcall.}
    add_ContainsFullScreenElementChanged*: proc(): HRESULT {.stdcall.}
    remove_ContainsFullScreenElementChanged*: proc(): HRESULT {.stdcall.}
    get_ContainsFullScreenElement*: proc(): HRESULT {.stdcall.}
    add_WebResourceRequested*: proc(): HRESULT {.stdcall.}
    remove_WebResourceRequested*: proc(): HRESULT {.stdcall.}
    AddWebResourceRequestedFilter*: proc(): HRESULT {.stdcall.}
    RemoveWebResourceRequestedFilter*: proc(): HRESULT {.stdcall.}
    add_WindowCloseRequested*: proc(): HRESULT {.stdcall.}
    remove_WindowCloseRequested*: proc(): HRESULT {.stdcall.}
    # ICoreWebView2_2
    add_WebResourceResponseReceived*: proc(): HRESULT {.stdcall.}
    remove_WebResourceResponseReceived*: proc(): HRESULT {.stdcall.}
    NavigateWithWebResourceRequest*: proc(): HRESULT {.stdcall.}
    add_DOMContentLoaded*: proc(): HRESULT {.stdcall.}
    remove_DOMContentLoaded*: proc(): HRESULT {.stdcall.}
    get_CookieManager*: proc(): HRESULT {.stdcall.}
    get_Environment*: proc(): HRESULT {.stdcall.}
    # ICoreWebView2_3
    TrySuspend*: proc(): HRESULT {.stdcall.}
    Resume*: proc(): HRESULT {.stdcall.}
    get_IsSuspended*: proc(): HRESULT {.stdcall.}
    SetVirtualHostNameToFolderMapping*: proc(): HRESULT {.stdcall.}
    ClearVirtualHostNameToFolderMapping*: proc(): HRESULT {.stdcall.}
    # ICoreWebView2_4
    add_FrameCreated*: proc(): HRESULT {.stdcall.}
    remove_FrameCreated*: proc(): HRESULT {.stdcall.}
    add_DownloadStarting*: proc(): HRESULT {.stdcall.}
    remove_DownloadStarting*: proc(): HRESULT {.stdcall.}
    # ICoreWebView2_5
    add_ClientCertificateRequested*: proc(): HRESULT {.stdcall.}
    remove_ClientCertificateRequested*: proc(): HRESULT {.stdcall.}
    # ICoreWebView2_6
    OpenTaskManagerWindow*: proc(): HRESULT {.stdcall.}
    # ICoreWebView2_7
    PrintToPdf*: proc(): HRESULT {.stdcall.}
    # ICoreWebView2_8
    add_IsMutedChanged*: proc(): HRESULT {.stdcall.}
    remove_IsMutedChanged*: proc(): HRESULT {.stdcall.}
    get_IsMuted*: proc(): HRESULT {.stdcall.}
    put_IsMuted*: proc(): HRESULT {.stdcall.}
    add_IsDocumentPlayingAudioChanged*: proc(): HRESULT {.stdcall.}
    remove_IsDocumentPlayingAudioChanged*: proc(): HRESULT {.stdcall.}
    get_IsDocumentPlayingAudio*: proc(): HRESULT {.stdcall.}
    # ICoreWebView2_9
    add_IsDefaultDownloadDialogOpenChanged*: proc(): HRESULT {.stdcall.}
    remove_IsDefaultDownloadDialogOpenChanged*: proc(): HRESULT {.stdcall.}
    get_IsDefaultDownloadDialogOpen*: proc(): HRESULT {.stdcall.}
    OpenDefaultDownloadDialog*: proc(): HRESULT {.stdcall.}
    CloseDefaultDownloadDialog*: proc(): HRESULT {.stdcall.}
    get_DefaultDownloadDialogCornerAlignment*: proc(): HRESULT {.stdcall.}
    put_DefaultDownloadDialogCornerAlignment*: proc(): HRESULT {.stdcall.}
    get_DefaultDownloadDialogMargin*: proc(): HRESULT {.stdcall.}
    put_DefaultDownloadDialogMargin*: proc(): HRESULT {.stdcall.}
    # ICoreWebView2_10
    add_BasicAuthenticationRequested*: proc(): HRESULT {.stdcall.}
    remove_BasicAuthenticationRequested*: proc(): HRESULT {.stdcall.}
    # ICoreWebView2_11
    CallDevToolsProtocolMethodForSession*: proc(): HRESULT {.stdcall.}
    add_ContextMenuRequested*: proc(): HRESULT {.stdcall.}
    remove_ContextMenuRequested*: proc(): HRESULT {.stdcall.}
    # ICoreWebView2_12
    add_StatusBarTextChanged*: proc(): HRESULT {.stdcall.}
    remove_StatusBarTextChanged*: proc(): HRESULT {.stdcall.}
    get_StatusBarText*: proc(): HRESULT {.stdcall.}
    # ICoreWebView2_13
    get_Profile*: proc(): HRESULT {.stdcall.}
    # ICoreWebView2_14
    add_ServerCertificateErrorDetected*: proc(): HRESULT {.stdcall.}
    remove_ServerCertificateErrorDetected*: proc(): HRESULT {.stdcall.}
    ClearServerCertificateErrorActions*: proc(): HRESULT {.stdcall.}
    # ICoreWebView2_15
    add_FaviconChanged*: proc(): HRESULT {.stdcall.}
    remove_FaviconChanged*: proc(): HRESULT {.stdcall.}
    get_FaviconUri*: proc(): HRESULT {.stdcall.}
    GetFavicon*: proc(): HRESULT {.stdcall.}
    # ICoreWebView2_16
    Print*: proc(): HRESULT {.stdcall.}
    ShowPrintUI*: proc(): HRESULT {.stdcall.}
    PrintToPdfStream*: proc(): HRESULT {.stdcall.}
    # ICoreWebView2_17
    PostSharedBufferToScript*: proc(): HRESULT {.stdcall.}
    # ICoreWebView2_18
    add_LaunchingExternalUriScheme*: proc(): HRESULT {.stdcall.}
    remove_LaunchingExternalUriScheme*: proc(): HRESULT {.stdcall.}
    # ICoreWebView2_19
    get_MemoryUsageTargetLevel*: proc(): HRESULT {.stdcall.}
    put_MemoryUsageTargetLevel*: proc(): HRESULT {.stdcall.}

  ICoreWebView2Environment* {.pure.} = object
    lpVtbl*: ptr ICoreWebView2EnvironmentVTBL

  ICoreWebView2EnvironmentVTBL* = object of IUnknownVtbl
    CreateCoreWebView2Controller*: proc (self: ptr ICoreWebView2Environment;
        parentWindow: HWND;
        handler: ptr ICoreWebView2CreateCoreWebView2ControllerCompletedHandler): HRESULT {.stdcall.}
    CreateWebResourceResponse*: HRESULT
    GetBrowserVersionString*: proc (self: ptr ICoreWebView2Environment;
        version_info: LPWSTR): HRESULT {.stdcall.}
    AddNewBrowserVersionAvailable*: HRESULT
    RemoveNewBrowserVersionAvailable*: HRESULT
    # ICoreWebView2Environment7
    get_UserDataFolder*: proc (self: ptr ICoreWebView2Environment;value: ptr LPWSTR): HRESULT {.stdcall.}
  ICoreWebView2Controller* {.pure.} = object
    lpVtbl*: ptr ICoreWebView2ControllerVTBL
  ICoreWebView2ControllerVTBL* = object
    QueryInterface*: proc(self: ptr ICoreWebView2Controller;
        riid: REFIID; ppvObject: ptr pointer): HRESULT {.stdcall.}
    AddRef*: proc (self: ptr ICoreWebView2Controller): ULONG {.stdcall.}
    Release*: proc (self: ptr ICoreWebView2Controller): ULONG {.stdcall.}

    get_IsVisible*: proc (self: ptr ICoreWebView2Controller;
        is_visible: ptr bool): HRESULT {.stdcall.}
    put_IsVisible*: proc (self: ptr ICoreWebView2Controller;
        is_visible: bool): HRESULT {.stdcall.}
    get_Bounds*: proc (self: ptr ICoreWebView2Controller;
        bounds: ptr RECT): HRESULT {.stdcall.}
    put_Bounds*: proc (self: ptr ICoreWebView2Controller; bounds: RECT): HRESULT {.stdcall.}
    get_ZoomFactor*: proc (self: ptr ICoreWebView2Controller;
        factor: ptr float64): HRESULT {.stdcall.}
    put_ZoomFactor*: proc (self: ptr ICoreWebView2Controller;
        factor: float64): HRESULT {.stdcall.}
    add_ZoomFactorChanged*: proc (): HRESULT {.stdcall.}
    remove_ZoomFactorChanged*: proc (): HRESULT {.stdcall.}
    SetBoundsAndZoomFactor*: proc (): HRESULT {.stdcall.}
    MoveFocus*: proc (): HRESULT {.stdcall.}
    add_MoveFocusRequested*: proc (): HRESULT {.stdcall.}
    remove_MoveFocusRequested*: proc (): HRESULT {.stdcall.}
    add_GotFocus*: proc (): HRESULT {.stdcall.}
    remove_GotFocus*: proc (): HRESULT {.stdcall.}
    add_LostFocus*: proc (): HRESULT {.stdcall.}
    remove_LostFocus*: proc (): HRESULT {.stdcall.}
    add_AcceleratorKeyPressed*: proc (): HRESULT {.stdcall.}
    remove_AcceleratorKeyPressed*: proc (): HRESULT {.stdcall.}
    get_ParentWindow*: proc (self: ptr ICoreWebView2Controller;
        parent: ptr HWND): HRESULT {.stdcall.}
    put_ParentWindow*: proc (self: ptr ICoreWebView2Controller;
        parent: HWND): HRESULT {.stdcall.}
    NotifyParentWindowPositionChanged*: proc (
        self: ptr ICoreWebView2Controller): HRESULT {.stdcall.}
    Close*: proc (self: ptr ICoreWebView2Controller): HRESULT {.stdcall.}
    get_CoreWebView2*: proc (self: ptr ICoreWebView2Controller;
        coreWebView2: ptr ptr ICoreWebView2): HRESULT {.stdcall.}
    # ICoreWebView2Controller2
    get_DefaultBackgroundColor*: proc (): HRESULT {.stdcall.}
    put_DefaultBackgroundColor*: proc (): HRESULT {.stdcall.}
    # ICoreWebView2Controller3
    add_RasterizationScaleChanged*: proc (): HRESULT {.stdcall.}
    get_BoundsMode*: proc (): HRESULT {.stdcall.}
    get_RasterizationScale*: proc (): HRESULT {.stdcall.}
    get_ShouldDetectMonitorScaleChanges*: proc (): HRESULT {.stdcall.}
    put_BoundsMode*: proc (): HRESULT {.stdcall.}
    put_RasterizationScale*: proc (): HRESULT {.stdcall.}
    put_ShouldDetectMonitorScaleChanges*: proc (): HRESULT {.stdcall.}
    # ICoreWebView2Controller4
    get_AllowExternalDrop*: proc (): HRESULT {.stdcall.}
    put_AllowExternalDrop*: proc (): HRESULT {.stdcall.}

  ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler* {.pure, inheritable.} = object
    lpVtbl*: ptr ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandlerVTBL
    windowHandle*: HWND
    controllerCompletedHandler*:ptr ICoreWebView2CreateCoreWebView2ControllerCompletedHandler

  ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandlerVTBL* {.pure, inheritable.} = object
    QueryInterface*: proc(self: ptr ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler;
        riid: REFIID; ppvObject: ptr pointer): HRESULT {.stdcall.}
    AddRef*: proc (self: ptr ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler): ULONG {.stdcall.}
    Release*: proc (self: ptr ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler): ULONG {.stdcall.}
    Invoke*: ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandlerInvoke

  ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandlerInvoke* = proc (
      self: ptr ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler;
      errorCode: HRESULT; createdEnvironment: ptr ICoreWebView2Environment): HRESULT {.stdcall.}
  ICoreWebView2CreateCoreWebView2ControllerCompletedHandler* {.pure.} = object
    lpVtbl*: ptr ICoreWebView2CreateCoreWebView2ControllerCompletedHandlerVTBL
    windowHandle*: HWND

  ICoreWebView2ExecuteScriptCompletedHandler* {.pure.} = object
    lpVtbl*: ptr ICoreWebView2ExecuteScriptCompletedHandlerVTBL
  ICoreWebView2AddScriptToExecuteOnDocumentCreatedCompletedHandler* {.pure.} = object
    lpVtbl*: ptr ICoreWebView2AddScriptToExecuteOnDocumentCreatedCompletedHandlerVTBL
  ICoreWebView2AddScriptToExecuteOnDocumentCreatedCompletedHandlerVTBL* = object of IUnknownVtbl
    Invoke*: proc (self: ptr ICoreWebView2AddScriptToExecuteOnDocumentCreatedCompletedHandler;
        errorCode: HRESULT; id: LPCWSTR) {.stdcall.}
  ICoreWebView2ExecuteScriptCompletedHandlerVTBL * = object of IUnknownVtbl
    Invoke*: proc (self: ICoreWebView2ExecuteScriptCompletedHandler;
        errorCode: HRESULT; resultObjectAsJson: LPCWSTR) {.stdcall.}

  ICoreWebView2CreateCoreWebView2ControllerCompletedHandlerVTBL* {.pure, inheritable.} = object
    QueryInterface*: proc(self: ptr ICoreWebView2CreateCoreWebView2ControllerCompletedHandler;
        riid: REFIID; ppvObject: ptr pointer): HRESULT {.stdcall.}
    AddRef*: proc (self: ptr ICoreWebView2CreateCoreWebView2ControllerCompletedHandler): ULONG {.stdcall.}
    Release*: proc (self: ptr ICoreWebView2CreateCoreWebView2ControllerCompletedHandler): ULONG {.stdcall.}
    Invoke*: ICoreWebView2CreateCoreWebView2ControllerCompletedHandlerInvoke

  ICoreWebView2CreateCoreWebView2ControllerCompletedHandlerInvoke* = proc (
      i: ptr ICoreWebView2CreateCoreWebView2ControllerCompletedHandler;
      errorCode: HRESULT; createdController: ptr ICoreWebView2Controller): HRESULT {.stdcall.}
  ICoreWebView2SettingsVTBL* = object of IUnknownVtbl
    GetIsScriptEnabled*: proc (self: ptr ICoreWebView2Settings;
        enabled: ptr bool): HRESULT {.stdcall.}
    PutIsScriptEnabled*: proc (self: ptr ICoreWebView2Settings;
        enabled: bool): HRESULT {.stdcall.}
    GetIsWebMessageEnabled*: proc (self: ptr ICoreWebView2Settings;
        enabled: ptr bool): HRESULT {.stdcall.}
    PutIsWebMessageEnabled*: proc (self: ptr ICoreWebView2Settings;
        enabled: bool): HRESULT {.stdcall.}
    GetAreDefaultScriptDialogsEnabled*: proc (self: ptr ICoreWebView2Settings;
        enabled: ptr bool): HRESULT {.stdcall.}
    PutAreDefaultScriptDialogsEnabled*: proc (self: ptr ICoreWebView2Settings;
        enabled: bool): HRESULT {.stdcall.}
    GetIsStatusBarEnabled*: proc (self: ptr ICoreWebView2Settings;
        enabled: ptr bool): HRESULT {.stdcall.}
    PutIsStatusBarEnabled*: proc (self: ptr ICoreWebView2Settings;
        enabled: bool): HRESULT {.stdcall.}
    GetAreDevToolsEnabled*: proc (self: ptr ICoreWebView2Settings;
        areDevToolsEnabled: ptr bool): HRESULT {.stdcall.}
    PutAreDevToolsEnabled*: proc (self: ptr ICoreWebView2Settings;
        areDevToolsEnabled: bool): HRESULT
    GetAreDefaultContextMenusEnabled*: proc (self: ptr ICoreWebView2Settings;
        enabled: ptr bool): HRESULT {.stdcall.}
    PutAreDefaultContextMenusEnabled*: proc (self: ptr ICoreWebView2Settings;
        enabled: bool): HRESULT {.stdcall.}
    GetAreHostObjectsAllowed*: proc (self: ptr ICoreWebView2Settings;
        allowed: ptr bool): HRESULT {.stdcall.}
    PutAreHostObjectsAllowed*: proc (self: ptr ICoreWebView2Settings;
        allowed: bool): HRESULT {.stdcall.}
    GetIsZoomControlEnabled*: proc (self: ptr ICoreWebView2Settings;
        enabled: ptr bool): HRESULT {.stdcall.}
    PutIsZoomControlEnabled*: proc (self: ptr ICoreWebView2Settings;
        enabled: bool): HRESULT {.stdcall.}
    GetIsBuiltInErrorPageEnabled*: proc (self: ptr ICoreWebView2Settings;
        enabled: ptr bool): HRESULT {.stdcall.}
    PutIsBuiltInErrorPageEnabled*: proc (self: ptr ICoreWebView2Settings;
        enabled: bool): HRESULT {.stdcall.}
  ICoreWebView2Settings* {.pure.} = object
    lpVtbl*: ptr ICoreWebView2SettingsVTBL
