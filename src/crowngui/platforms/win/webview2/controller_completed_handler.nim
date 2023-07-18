import winim
import com

const GUID = DEFINE_GUID"6C4819F3-C9B7-4260-8127-C9F5BDE7F68C"

using
  self: ptr ICoreWebView2CreateCoreWebView2ControllerCompletedHandler



proc AddRef*(self): ULONG {.stdcall.} =
  return 1

proc Release*(self): ULONG {.stdcall.} =
  return 0

proc QueryInterface*(self; riid: REFIID; ppvObject: ptr pointer): HRESULT {.stdcall.} =
  if ppvObject == nil:
    return E_NOINTERFACE
  if riid[] == GUID or riid[] == IID_IUnknown:
    ppvObject[] = self
    return S_OK
  else:
    ppvObject[] = nil
    return E_NOINTERFACE
