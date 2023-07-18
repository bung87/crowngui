import winim
import com
import types

const GUID = DEFINE_GUID"2FDE08A8-1E9A-4766-8C05-95A9CEB9D1C5"

using
  self: ptr ICoreWebView2EnvironmentOptions


proc QueryInterface*(self; riid: REFIID; ppvObject: ptr pointer): HRESULT {.stdcall.} =
  if ppvObject == nil:
    return E_NOINTERFACE
  if riid[] == GUID or riid[] == IID_IUnknown:
    ppvObject[] = self
    return S_OK
  else:
    ppvObject[] = nil
    return E_NOINTERFACE

proc AddRef*(self): ULONG {.stdcall.} =
  return 1

proc Release*(self): ULONG {.stdcall.} =
  return 0

proc get_AdditionalBrowserArguments*(self;value: ptr LPWSTR): HRESULT {.stdcall.} =
  # value[] = self.lpVtbl.AdditionalBrowserArguments
  return S_OK

proc put_AdditionalBrowserArguments*(self;value:LPCWSTR ): HRESULT {.stdcall.} =
  # self.lpVtbl.AdditionalBrowserArguments = value
  return S_OK

proc get_Language*(self;value: ptr LPWSTR): HRESULT {.stdcall.} =
  # value[] = self.lpVtbl.Language
  let ws = L"en-US"
  value[] = cast[LPOLESTR](CoTaskMemAlloc(SIZE_T (ws.len + 2) * 2))
  value[] <<< ws
  return S_OK

proc put_Language*(self;value:LPCWSTR ): HRESULT {.stdcall.} =
  # self.lpVtbl.Language = value
  return S_OK

proc get_TargetCompatibleBrowserVersion*(self; value: ptr LPWSTR ): HRESULT {.stdcall.} =
  let ws = L"97.0.1072.69"
  value[] = cast[LPOLESTR](CoTaskMemAlloc(SIZE_T (ws.len + 2) * 2))
  value[] <<< ws
  return S_OK

proc put_TargetCompatibleBrowserVersion*(self; value:LPCWSTR ): HRESULT {.stdcall.} =
  # self.lpVtbl.TargetCompatibleBrowserVersion = value
  return S_OK

proc get_AllowSingleSignOnUsingOSPrimaryAccount*(self;allow: ptr BOOL): HRESULT {.stdcall.} =
  allow[] = TRUE
  return S_OK

proc put_AllowSingleSignOnUsingOSPrimaryAccount*(self;allow: BOOL ): HRESULT {.stdcall.} =
  # self.lpVtbl.AllowSingleSignOnUsingOSPrimaryAccount = allow
  return S_OK

proc get_ExclusiveUserDataFolderAccess*(self;value:ptr BOOL): HRESULT {.stdcall.} =
  # value[] = self.lpVtbl.ExclusiveUserDataFolderAccess
  return S_OK

proc put_ExclusiveUserDataFolderAccess*(self;value: BOOL): HRESULT {.stdcall.} =
  # self.lpVtbl.ExclusiveUserDataFolderAccess = value
  return S_OK
