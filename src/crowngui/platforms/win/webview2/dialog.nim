import winim
import winaux
import os

const bufferSize = MAX_PATH

proc info*(title: string, description: string) =
  discard MessageBoxA(0, description, title, MB_OK or MB_ICONINFORMATION)

proc warning*(title: string, description: string) =
  discard MessageBoxA(0, description, title, MB_OK or MB_ICONWARNING)

proc error*(title: string, description: string) =
  discard MessageBoxA(0, description, title, MB_OK or MB_ICONERROR)

proc chooseFile*(root: string = "", description: string = ""): string =
  var
    opf: OPENFILENAMEW
    buf = newWString(bufferSize)
  opf.lStructSize = sizeof(opf).int32
  if root.len > 0:
    opf.lpstrInitialDir = root
  opf.lpstrFilter = "All Files\0*.*\0\0"
  opf.Flags = OFN_FILEMUSTEXIST
  opf.lpstrFile = &buf
  opf.nMaxFile = sizeof(buf).int32
  var res = GetOpenFileName(addr(opf))
  if res != 0:
    result = $(&buf)
  else:
    result = ""

proc chooseFiles*(root: string = "", description: string = ""): seq[string] =
  var
    opf: OPENFILENAMEW
    buf = newWString(bufferSize)
  opf.lStructSize = sizeof(opf).int32
  if root.len > 0:
    opf.lpstrInitialDir = root
  opf.lpstrFilter = "All Files\0*.*\0\0"
  opf.Flags = OFN_FILEMUSTEXIST or OFN_ALLOWMULTISELECT or OFN_EXPLORER
  opf.lpstrFile = &buf
  opf.nMaxFile = sizeof(buf).int32
  var res = GetOpenFileName(addr(opf))
  result = @[]
  if res != 0:
    var
      i = 0
      s: string
      path = ""
    while buf[i] != '\0'.WCHAR:
      add(path, buf[i])
      inc(i)
    inc(i)
    if buf[i] != '\0'.WCHAR:
      while true:
        s = ""
        while buf[i] != '\0'.WCHAR:
          add(s, buf[i])
          inc(i)
        add(result, s)
        inc(i)
        if buf[i] == '\0'.WCHAR: break
      for i in 0..result.len-1: result[i] = os.joinPath(path, result[i])
    else:
      add(result, path)

proc saveFile*(root: string = "", description: string = ""): string =
  var
    opf: OPENFILENAMEW
    buf = newWString(bufferSize)
  opf.lStructSize = sizeof(opf).int32
  if root.len > 0:
    opf.lpstrInitialDir = root
  opf.lpstrFilter = "All Files\0*.*\0\0"
  opf.Flags = OFN_OVERWRITEPROMPT
  opf.lpstrFile = &buf
  opf.nMaxFile = sizeof(buf).int32
  var res = getSaveFileName(addr(opf))
  if res != 0:
    result = $(&buf)
  else:
    result = ""

proc chooseDir*(root: string = "", description: string = ""): string =
  var
    lpItemID: PItemIDList
    browseInfo: BrowseInfo
    displayName: array[0..MAX_PATH, char]
    tempPath: array[0..MAX_PATH, char]
  result = ""
  browseInfo.pszDisplayName = addr displayName
  browseInfo.ulFlags = 1 #BIF_RETURNONLYFSDIRS
  lpItemID = shBrowseForFolder(addr(browseInfo))
  if lpItemId != nil:
    discard shGetPathFromIDList(lpItemID, addr tempPath)
    result = $(addr tempPath)
    discard globalFreePtr(lpItemID)
