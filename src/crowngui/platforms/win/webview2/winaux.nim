
import winim

type
  LPITEMIDLIST* = ptr ITEMIDLIST
  LPCITEMIDLIST* = ptr ITEMIDLIST
  TITEMIDLIST* = ITEMIDLIST
  PITEMIDLIST* = ptr ITEMIDLIST

proc globalLock*(hMem: HGLOBAL): pointer{.stdcall, dynlib: "kernel32",
    importc: "GlobalLock".}
proc globalHandle*(pMem: pointer): HGLOBAL{.stdcall, dynlib: "kernel32",
    importc: "GlobalHandle".}
proc globalUnlock*(hMem: HGLOBAL): WINBOOL{.stdcall, dynlib: "kernel32",
    importc: "GlobalUnlock".}
proc globalFree*(hMem: HGLOBAL): HGLOBAL{.stdcall, dynlib: "kernel32",
    importc: "GlobalFree".}

proc globalUnlockPtr(lp: pointer): pointer =
  discard globalUnlock(globalHandle(lp))
  result = lp

proc globalFreePtr*(lp: pointer): pointer =
  result = cast[pointer](globalFree(cast[HWND](globalUnlockPtr(lp))))
