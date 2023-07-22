

## Some stuff that used to be in Windows.nim.

import winim

# type
#   HGLOBAL* = HANDLE
#   HLOCAL* = HANDLE
#   HWND* = HANDLE
#   HINST* = HANDLE

#   TOPENFILENAME* = object
#     lStructSize*: DWORD
#     hwndOwner*: HWND
#     hInstance*: HINST
#     lpstrFilter*: cstring
#     lpstrCustomFilter*: cstring
#     nMaxCustFilter*: DWORD
#     nFilterIndex*: DWORD
#     lpstrFile*: cstring
#     nMaxFile*: DWORD
#     lpstrFileTitle*: cstring
#     nMaxFileTitle*: DWORD
#     lpstrInitialDir*: cstring
#     lpstrTitle*: cstring
#     flags*: DWORD
#     nFileOffset*: int16
#     nFileExtension*: int16
#     lpstrDefExt*: cstring
#     lCustData*: ByteAddress
#     lpfnHook*: pointer
#     lpTemplateName*: cstring
#     pvReserved*: pointer
#     dwreserved*: DWORD
#     FlagsEx*: DWORD

#   SHITEMID* = object
#     cb*: uint16
#     abID*: array[0..0, int8]

#   LPSHITEMID* = ptr SHITEMID
#   LPCSHITEMID* = ptr SHITEMID
#   TSHITEMID* = SHITEMID
#   PSHITEMID* = ptr SHITEMID
#   ITEMIDLIST* = object
#     mkid*: SHITEMID

#   LPITEMIDLIST* = ptr ITEMIDLIST
#   LPCITEMIDLIST* = ptr ITEMIDLIST
#   TITEMIDLIST* = ITEMIDLIST
#   PITEMIDLIST* = ptr ITEMIDLIST



# proc messageBoxA*(wnd: Handle, lpText, lpCaption: cstring, uType: int): int32{.
#     stdcall, dynlib: "user32", importc: "MessageBoxA".}

# proc getOpenFileName*(para1: ptr TOPENFILENAME): WINBOOL{.stdcall,
#     dynlib: "comdlg32", importc: "GetOpenFileNameA".}

# proc getSaveFileName*(para1: ptr TOPENFILENAME): WINBOOL{.stdcall,
#     dynlib: "comdlg32", importc: "GetSaveFileNameA".}


# proc globalLock*(hMem: HGLOBAL): pointer{.stdcall, dynlib: "kernel32",
#     importc: "GlobalLock".}
# proc globalHandle*(pMem: pointer): HGLOBAL{.stdcall, dynlib: "kernel32",
#     importc: "GlobalHandle".}
# proc globalUnlock*(hMem: HGLOBAL): WINBOOL{.stdcall, dynlib: "kernel32",
#     importc: "GlobalUnlock".}
# proc globalFree*(hMem: HGLOBAL): HGLOBAL{.stdcall, dynlib: "kernel32",
#     importc: "GlobalFree".}

# proc globalUnlockPtr(lp: pointer): pointer =
#   discard globalUnlock(globalHandle(lp))
#   result = lp

# proc globalFreePtr*(lp: pointer): pointer =
#   result = cast[pointer](globalFree(cast[HWND](globalUnlockPtr(lp))))

# proc shBrowseForFolder*(para1: ptr BROWSEINFO): LPITEMIDLIST{.stdcall,
#     dynlib: "shell32", importc: "SHBrowseForFolder".}

# proc shGetPathFromIDList*(para1: LPCITEMIDLIST, para2: cstring): WINBOOL{.
#     stdcall, dynlib: "shell32", importc: "SHGetPathFromIDList".}