import winim/inc/windef

import ./com/[
  icorewebview2environmentoptions,
  icorewebview2settings,icorewebview2,
  icorewebview2environment,icorewebview2controller,
icorewebview2createcorewebview2controllercompletedhandler,
  icorewebview2webmessagereceivedeventargs
  ]
export
  icorewebview2,
  icorewebview2controller,
  icorewebview2environmentoptions,icorewebview2settings,
  icorewebview2environment,
  icorewebview2createcorewebview2controllercompletedhandler,
  icorewebview2webmessagereceivedeventargs

type

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
#   ICoreWebView2CreateCoreWebView2ControllerCompletedHandler* {.pure.} = object
#     lpVtbl*: ptr ICoreWebView2CreateCoreWebView2ControllerCompletedHandlerVTBL
#     windowHandle*: HWND





