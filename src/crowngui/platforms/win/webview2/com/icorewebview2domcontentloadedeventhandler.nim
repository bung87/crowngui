import winim
import ../com_wrapper
import ./icorewebview2


const GUID = DEFINE_GUID"59e1c3f0-8476-4f4b-b01f-42faa38a1951"

using
  self: ptr ICoreWebView2DOMContentLoadedEventHandler

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