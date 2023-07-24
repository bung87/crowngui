import winim/inc/windef
import ../com_wrapper
import ./icorewebview2

define_COM_interface:
  type 
    ICoreWebView2Controller* {.pure.} = object
      QueryInterface*: proc(self;riid: REFIID; ppvObject: ptr pointer): HRESULT {.stdcall.}
      AddRef*: proc (self): ULONG {.stdcall.}
      Release*: proc (self): ULONG {.stdcall.}

      get_IsVisible*: proc (self;is_visible: ptr bool): HRESULT {.stdcall.}
      put_IsVisible*: proc (self;is_visible: bool): HRESULT {.stdcall.}
      get_Bounds*: proc (self;bounds: ptr RECT): HRESULT {.stdcall.}
      put_Bounds*: proc (self; bounds: RECT): HRESULT {.stdcall.}
      get_ZoomFactor*: proc (self;factor: ptr float64): HRESULT {.stdcall.}
      put_ZoomFactor*: proc (self;factor: float64): HRESULT {.stdcall.}
      add_ZoomFactorChanged*: proc (self): HRESULT {.stdcall.}
      remove_ZoomFactorChanged*: proc (self): HRESULT {.stdcall.}
      SetBoundsAndZoomFactor*: proc (self): HRESULT {.stdcall.}
      MoveFocus*: proc (self): HRESULT {.stdcall.}
      add_MoveFocusRequested*: proc (self): HRESULT {.stdcall.}
      remove_MoveFocusRequested*: proc (self): HRESULT {.stdcall.}
      add_GotFocus*: proc (self): HRESULT {.stdcall.}
      remove_GotFocus*: proc (self): HRESULT {.stdcall.}
      add_LostFocus*: proc (self): HRESULT {.stdcall.}
      remove_LostFocus*: proc (self): HRESULT {.stdcall.}
      add_AcceleratorKeyPressed*: proc (self): HRESULT {.stdcall.}
      remove_AcceleratorKeyPressed*: proc (self): HRESULT {.stdcall.}
      get_ParentWindow*: proc (self;parent: ptr HWND): HRESULT {.stdcall.}
      put_ParentWindow*: proc (self;parent: HWND): HRESULT {.stdcall.}
      NotifyParentWindowPositionChanged*: proc (self): HRESULT {.stdcall.}
      Close*: proc (self): HRESULT {.stdcall.}
      get_CoreWebView2*: proc (self;coreWebView2: ptr ptr ICoreWebView2): HRESULT {.stdcall.}
      # ICoreWebView2Controller2
      get_DefaultBackgroundColor*: proc (self): HRESULT {.stdcall.}
      put_DefaultBackgroundColor*: proc (self): HRESULT {.stdcall.}
      # ICoreWebView2Controller3
      add_RasterizationScaleChanged*: proc (self): HRESULT {.stdcall.}
      get_BoundsMode*: proc (self): HRESULT {.stdcall.}
      get_RasterizationScale*: proc (self): HRESULT {.stdcall.}
      get_ShouldDetectMonitorScaleChanges*: proc (self): HRESULT {.stdcall.}
      put_BoundsMode*: proc (self): HRESULT {.stdcall.}
      put_RasterizationScale*: proc (self): HRESULT {.stdcall.}
      put_ShouldDetectMonitorScaleChanges*: proc (self): HRESULT {.stdcall.}
      # ICoreWebView2Controller4
      get_AllowExternalDrop*: proc (self): HRESULT {.stdcall.}
      put_AllowExternalDrop*: proc (self): HRESULT {.stdcall.}
