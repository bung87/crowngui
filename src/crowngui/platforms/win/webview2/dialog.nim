import winim

proc info*(title: string, description: string) =
  discard messageBoxA(0, description, title, MB_OK or MB_ICONINFORMATION)

proc warning*(title: string, description: string) =
  discard messageBoxA(0, description, title, MB_OK or MB_ICONWARNING)

proc error*(title: string, description: string) =
  discard messageBoxA(0, description, title, MB_OK or MB_ICONERROR)

proc chooseFile*(root: string = "", description: string = ""): string =
  var
    opf: TOPENFILENAME
    buf: array[0..2047, char]
  opf.lStructSize = sizeof(opf).int32
  if root.len > 0:
    opf.lpstrInitialDir = root
  opf.lpstrFilter = "All Files\0*.*\0\0"
  opf.flags = OFN_FILEMUSTEXIST
  opf.lpstrFile = addr buf
  opf.nMaxFile = sizeof(buf).int32
  var res = getOpenFileName(addr(opf))
  if res != 0:
    result = $(addr buf)
  else:
    result = ""

proc chooseFiles*(root: string = "", description: string = ""): seq[string] =
  var
    opf: TOPENFILENAME
    buf: array[0..2047*4, char]
  opf.lStructSize = sizeof(opf).int32
  if root.len > 0:
    opf.lpstrInitialDir = root
  opf.lpstrFilter = "All Files\0*.*\0\0"
  opf.flags = OFN_FILEMUSTEXIST or OFN_ALLOWMULTISELECT or OFN_EXPLORER
  opf.lpstrFile = addr buf
  opf.nMaxFile = sizeof(buf).int32
  var res = getOpenFileName(addr(opf))
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

proc saveFile*(root: string = "", description: string = ""): string =
  var
    opf: TOPENFILENAME
    buf: array[0..2047, char]
  opf.lStructSize = sizeof(opf).int32
  if root.len > 0:
    opf.lpstrInitialDir = root
  opf.lpstrFilter = "All Files\0*.*\0\0"
  opf.flags = OFN_OVERWRITEPROMPT
  opf.lpstrFile = addr buf
  opf.nMaxFile = sizeof(buf).int32
  var res = getSaveFileName(addr(opf))
  if res != 0:
    result = $(addr buf)
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
