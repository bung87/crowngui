import winim/inc/windef
import ../com_wrapper
import ./icorewebview2settings
import ./icorewebview2addscripttoexecuteondocumentcreatedcompletedhandler
import ./icorewebview2executescriptcompletedhandler
import ./icorewebview2webmessagereceivedeventargs
import ./icorewebview2domcontentloadedeventargs

type
  EventRegistrationToken* {.pure.} = object
    value*: int64

define_COM_interface:
    type
      ICoreWebView2* {.pure.} = object
        #   https://learn.microsoft.com/en-us/microsoft-edge/webview2/reference/win32/icorewebview2?view=webview2-1.0.1823.32
        QueryInterface*: proc(self: ptr ICoreWebView2;
            riid: REFIID; ppvObject: ptr pointer): HRESULT {.stdcall.}
        AddRef*: proc (self: ptr ICoreWebView2): ULONG {.stdcall.}
        Release*: proc (self: ptr ICoreWebView2): ULONG {.stdcall.}

        get_Settings*: proc (self: ptr ICoreWebView2;
            settings: ptr ptr ICoreWebView2Settings): HRESULT {.stdcall.}
        get_Source*: proc(self): HRESULT {.stdcall.}
        Navigate*: proc (self: ptr ICoreWebView2; url: LPCWSTR): HRESULT {.stdcall.}
        NavigateToString*: proc (self: ptr ICoreWebView2;
            html_content: LPCWSTR): HRESULT {.stdcall.}
        add_NavigationStarting*: proc(self): HRESULT {.stdcall.}
        remove_NavigationStarting*: proc(self): HRESULT {.stdcall.}
        add_ContentLoading*: proc(self): HRESULT {.stdcall.}
        remove_ContentLoading*: proc(self): HRESULT {.stdcall.}
        add_SourceChanged*: proc(self): HRESULT {.stdcall.}
        remove_SourceChanged*: proc(self): HRESULT {.stdcall.}
        add_HistoryChanged*: proc(self): HRESULT {.stdcall.}
        remove_HistoryChanged*: proc(self): HRESULT {.stdcall.}
        add_NavigationCompleted*: proc(self): HRESULT {.stdcall.}
        remove_NavigationCompleted*: proc(self): HRESULT {.stdcall.}
        add_FrameNavigationStarting*: proc(self): HRESULT {.stdcall.}
        remove_FrameNavigationStarting*: proc(self): HRESULT {.stdcall.}
        add_FrameNavigationCompleted*: proc(self): HRESULT {.stdcall.}
        remove_FrameNavigationCompleted*: proc(self): HRESULT {.stdcall.}
        add_ScriptDialogOpening*: proc(self): HRESULT {.stdcall.}
        remove_ScriptDialogOpening*: proc(self): HRESULT {.stdcall.}
        add_PermissionRequested*: proc(self): HRESULT {.stdcall.}
        remove_PermissionRequested*: proc(self): HRESULT {.stdcall.}
        add_ProcessFailed*: proc(self): HRESULT {.stdcall.}
        remove_ProcessFailed*: proc(self): HRESULT {.stdcall.}
        AddScriptToExecuteOnDocumentCreated * : proc (self: ptr ICoreWebView2;
            javaScript: LPCWSTR;
            handler: ptr ICoreWebView2AddScriptToExecuteOnDocumentCreatedCompletedHandler): HRESULT {.stdcall.}
        RemoveScriptToExecuteOnDocumentCreated*: proc(self): HRESULT {.stdcall.}
        ExecuteScript*: proc (self: ptr ICoreWebView2; javaScript: LPCWSTR;
            handler: ptr ICoreWebView2ExecuteScriptCompletedHandler): HRESULT {.stdcall.}
        CapturePreview*: proc(self): HRESULT {.stdcall.}
        Reload*: proc (self: ptr ICoreWebView2): HRESULT {.stdcall.}
        PostWebMessageAsJson*: proc(self): HRESULT {.stdcall.}
        PostWebMessageAsString*: proc(self): HRESULT {.stdcall.}
        add_WebMessageReceived*: proc(self: ptr ICoreWebView2; handler: ptr ICoreWebView2WebMessageReceivedEventHandler; token: ptr EventRegistrationToken): HRESULT {.stdcall.}
        remove_WebMessageReceived*: proc(self): HRESULT {.stdcall.}
        CallDevToolsProtocolMethod*: proc(self): HRESULT {.stdcall.}
        get_BrowserProcessId*: proc(self: ptr ICoreWebView2; value: var uint32): HRESULT {.stdcall.}
        get_CanGoBack*: proc(self: ptr ICoreWebView2; value: var BOOL): HRESULT {.stdcall.}
        get_CanGoForward*: proc(self): HRESULT {.stdcall.}
        GoBack*: proc (self: ptr ICoreWebView2): HRESULT {.stdcall.}
        GoForward*: proc (self: ptr ICoreWebView2): HRESULT {.stdcall.}
        GetDevToolsProtocolEventReceiver*: proc(self): HRESULT {.stdcall.}
        Stop*: proc (self: ptr ICoreWebView2): HRESULT {.stdcall.}
        add_NewWindowRequested*: proc(self): HRESULT {.stdcall.}
        remove_NewWindowRequested*: proc(self): HRESULT {.stdcall.}
        add_DocumentTitleChanged*: proc(self): HRESULT {.stdcall.}
        remove_DocumentTitleChanged*: proc(self): HRESULT {.stdcall.}
        get_DocumentTitle*: proc (self: ptr ICoreWebView2; title: LPWSTR): HRESULT {.stdcall.}
        AddHostObjectToScript*: proc(self): HRESULT {.stdcall.}
        RemoveHostObjectFromScript*: proc(self): HRESULT {.stdcall.}
        OpenDevToolsWindow*: proc (self: ptr ICoreWebView2): HRESULT {.stdcall.}
        add_ContainsFullScreenElementChanged*: proc(self): HRESULT {.stdcall.}
        remove_ContainsFullScreenElementChanged*: proc(self): HRESULT {.stdcall.}
        get_ContainsFullScreenElement*: proc(self): HRESULT {.stdcall.}
        add_WebResourceRequested*: proc(self): HRESULT {.stdcall.}
        remove_WebResourceRequested*: proc(self): HRESULT {.stdcall.}
        AddWebResourceRequestedFilter*: proc(self): HRESULT {.stdcall.}
        RemoveWebResourceRequestedFilter*: proc(self): HRESULT {.stdcall.}
        add_WindowCloseRequested*: proc(self): HRESULT {.stdcall.}
        remove_WindowCloseRequested*: proc(self): HRESULT {.stdcall.}
        # ICoreWebView2_2
        add_WebResourceResponseReceived*: proc(self): HRESULT {.stdcall.}
        remove_WebResourceResponseReceived*: proc(self): HRESULT {.stdcall.}
        NavigateWithWebResourceRequest*: proc(self): HRESULT {.stdcall.}
        add_DOMContentLoaded*: proc(self; eventHandler: ptr ICoreWebView2DOMContentLoadedEventHandler; token: ptr EventRegistrationToken): HRESULT {.stdcall.}
        remove_DOMContentLoaded*: proc(self): HRESULT {.stdcall.}
        get_CookieManager*: proc(self): HRESULT {.stdcall.}
        get_Environment*: proc(self): HRESULT {.stdcall.}
        # ICoreWebView2_3
        TrySuspend*: proc(self): HRESULT {.stdcall.}
        Resume*: proc(self): HRESULT {.stdcall.}
        get_IsSuspended*: proc(self): HRESULT {.stdcall.}
        SetVirtualHostNameToFolderMapping*: proc(self): HRESULT {.stdcall.}
        ClearVirtualHostNameToFolderMapping*: proc(self): HRESULT {.stdcall.}
        # ICoreWebView2_4
        add_FrameCreated*: proc(self): HRESULT {.stdcall.}
        remove_FrameCreated*: proc(self): HRESULT {.stdcall.}
        add_DownloadStarting*: proc(self): HRESULT {.stdcall.}
        remove_DownloadStarting*: proc(self): HRESULT {.stdcall.}
        # ICoreWebView2_5
        add_ClientCertificateRequested*: proc(self): HRESULT {.stdcall.}
        remove_ClientCertificateRequested*: proc(self): HRESULT {.stdcall.}
        # ICoreWebView2_6
        OpenTaskManagerWindow*: proc(self): HRESULT {.stdcall.}
        # ICoreWebView2_7
        PrintToPdf*: proc(self): HRESULT {.stdcall.}
        # ICoreWebView2_8
        add_IsMutedChanged*: proc(self): HRESULT {.stdcall.}
        remove_IsMutedChanged*: proc(self): HRESULT {.stdcall.}
        get_IsMuted*: proc(self): HRESULT {.stdcall.}
        put_IsMuted*: proc(self): HRESULT {.stdcall.}
        add_IsDocumentPlayingAudioChanged*: proc(self): HRESULT {.stdcall.}
        remove_IsDocumentPlayingAudioChanged*: proc(self): HRESULT {.stdcall.}
        get_IsDocumentPlayingAudio*: proc(self): HRESULT {.stdcall.}
        # ICoreWebView2_9
        add_IsDefaultDownloadDialogOpenChanged*: proc(self): HRESULT {.stdcall.}
        remove_IsDefaultDownloadDialogOpenChanged*: proc(self): HRESULT {.stdcall.}
        get_IsDefaultDownloadDialogOpen*: proc(self): HRESULT {.stdcall.}
        OpenDefaultDownloadDialog*: proc(self): HRESULT {.stdcall.}
        CloseDefaultDownloadDialog*: proc(self): HRESULT {.stdcall.}
        get_DefaultDownloadDialogCornerAlignment*: proc(self): HRESULT {.stdcall.}
        put_DefaultDownloadDialogCornerAlignment*: proc(self): HRESULT {.stdcall.}
        get_DefaultDownloadDialogMargin*: proc(self): HRESULT {.stdcall.}
        put_DefaultDownloadDialogMargin*: proc(self): HRESULT {.stdcall.}
        # ICoreWebView2_10
        add_BasicAuthenticationRequested*: proc(self): HRESULT {.stdcall.}
        remove_BasicAuthenticationRequested*: proc(self): HRESULT {.stdcall.}
        # ICoreWebView2_11
        CallDevToolsProtocolMethodForSession*: proc(self): HRESULT {.stdcall.}
        add_ContextMenuRequested*: proc(self): HRESULT {.stdcall.}
        remove_ContextMenuRequested*: proc(self): HRESULT {.stdcall.}
        # ICoreWebView2_12
        add_StatusBarTextChanged*: proc(self): HRESULT {.stdcall.}
        remove_StatusBarTextChanged*: proc(self): HRESULT {.stdcall.}
        get_StatusBarText*: proc(self): HRESULT {.stdcall.}
        # ICoreWebView2_13
        get_Profile*: proc(self): HRESULT {.stdcall.}
        # ICoreWebView2_14
        add_ServerCertificateErrorDetected*: proc(self): HRESULT {.stdcall.}
        remove_ServerCertificateErrorDetected*: proc(self): HRESULT {.stdcall.}
        ClearServerCertificateErrorActions*: proc(self): HRESULT {.stdcall.}
        # ICoreWebView2_15
        add_FaviconChanged*: proc(self): HRESULT {.stdcall.}
        remove_FaviconChanged*: proc(self): HRESULT {.stdcall.}
        get_FaviconUri*: proc(self): HRESULT {.stdcall.}
        GetFavicon*: proc(self): HRESULT {.stdcall.}
        # ICoreWebView2_16
        Print*: proc(self): HRESULT {.stdcall.}
        ShowPrintUI*: proc(self): HRESULT {.stdcall.}
        PrintToPdfStream*: proc(self): HRESULT {.stdcall.}
        # ICoreWebView2_17
        PostSharedBufferToScript*: proc(self): HRESULT {.stdcall.}
        # ICoreWebView2_18
        add_LaunchingExternalUriScheme*: proc(self): HRESULT {.stdcall.}
        remove_LaunchingExternalUriScheme*: proc(self): HRESULT {.stdcall.}
        # ICoreWebView2_19
        get_MemoryUsageTargetLevel*: proc(self): HRESULT {.stdcall.}
        put_MemoryUsageTargetLevel*: proc(self): HRESULT {.stdcall.}

      ICoreWebView2WebMessageReceivedEventHandler* {.pure.} = object
        QueryInterface*: proc(self;riid: REFIID; ppvObject: ptr pointer): HRESULT {.stdcall.}
        AddRef*: proc (self): ULONG {.stdcall.}
        Release*: proc (self): ULONG {.stdcall.}
        Invoke*: proc (self; sender: ptr ICoreWebView2; args: ptr ICoreWebView2WebMessageReceivedEventArgs) {.stdcall.}
        windowHandle*: HWND

      ICoreWebView2DOMContentLoadedEventHandler* {.pure.} = object
        QueryInterface*: proc(self; riid: REFIID; ppvObject: ptr pointer): HRESULT {.stdcall.}
        AddRef*: proc (self): ULONG {.stdcall.}
        Release*: proc (self): ULONG {.stdcall.}
        Invoke*: proc (self; sender: ptr ICoreWebView2; args: ptr ICoreWebView2DOMContentLoadedEventArgs): HRESULT {.stdcall.}
        script*: string
