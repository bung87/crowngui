import winim
import winaux
import os

const bufferSize = 2048

proc info*(title: string, description: string) =
  discard MessageBoxA(0, description, title, MB_OK or MB_ICONINFORMATION)

proc warning*(title: string, description: string) =
  discard MessageBoxA(0, description, title, MB_OK or MB_ICONWARNING)

proc error*(title: string, description: string) =
  discard MessageBoxA(0, description, title, MB_OK or MB_ICONERROR)

proc chooseFile*(root: string = "", description: string = ""): string {.discardable.} =
  var
    opf: OPENFILENAMEW
    buf = newString(bufferSize)
  opf.lStructSize = sizeof(opf).int32
  if root.len > 0:
    opf.lpstrInitialDir = root
  opf.lpstrFilter = "All Files\0*.*\0\0"
  opf.Flags = OFN_FILEMUSTEXIST
  opf.lpstrFile = buf
  opf.nMaxFile = sizeof(buf).int32
  var res = GetOpenFileName(addr(opf))
  if res != 0:
    result = $(&buf)
  else:
    result = ""

proc chooseFiles*(root: string = "", description: string = ""): seq[string] {.discardable.}  =
  var
    opf: OPENFILENAMEW
    buf = newString(bufferSize)
  opf.lStructSize = sizeof(opf).int32
  if root.len > 0:
    opf.lpstrInitialDir = root
  opf.lpstrFilter = "All Files\0*.*\0\0"
  opf.Flags = OFN_FILEMUSTEXIST or OFN_ALLOWMULTISELECT or OFN_EXPLORER
  opf.lpstrFile = buf
  opf.nMaxFile = sizeof(buf).int32
  var res = GetOpenFileName(addr(opf))
  result = @[]
  if res != 0:
    var
      i = 0
      s: string
      path = ""
    while buf[i] != '\0':
      add(path, buf[i])
      inc(i)
    inc(i)
    if buf[i] != '\0':
      while true:
        s = ""
        while buf[i] != '\0':
          add(s, buf[i])
          inc(i)
        add(result, s)
        inc(i)
        if buf[i] == '\0': break
      for i in 0..result.len-1: result[i] = os.joinPath(path, result[i])
    else:
      add(result, path)

proc chooseFile*(cb: proc (a: seq[string]); root = "") =
  let files = chooseFiles(root, "")
  cb(files)

proc saveFile*(root: string = "", description: string = ""): string {.discardable.} =
  var
    opf: OPENFILENAMEW
    buf = newString(bufferSize)
  opf.lStructSize = sizeof(opf).int32
  if root.len > 0:
    opf.lpstrInitialDir = root
  opf.lpstrFilter = "All Files\0*.*\0\0"
  opf.Flags = OFN_OVERWRITEPROMPT
  opf.lpstrFile = buf
  opf.nMaxFile = sizeof(buf).int32
  var res = GetSaveFileName(addr(opf))
  if res != 0:
    result = $(&buf)
  else:
    result = ""

proc saveFile*(cb: proc (a: string); root = ""; filename = "") =
  let path = saveFile(root)
  cb(path)

proc chooseDir*(root: string = "", description: string = ""): string {.discardable.} =
  var
    lpItemID: PItemIDList
    browseInfo: BrowseInfo
    displayName = T(MAX_PATH)
    tempPath = T(MAX_PATH)
  result = ""
  browseInfo.pszDisplayName = &displayName
  browseInfo.ulFlags = 1 #BIF_RETURNONLYFSDIRS
  lpItemID = SHBrowseForFolder(addr(browseInfo))
  if lpItemId != nil:
    discard SHGetPathFromIDList(lpItemID, &tempPath)
    result = $tempPath
    discard globalFreePtr(lpItemID)
