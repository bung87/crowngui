import winim

proc info*(title: string, description: string) =
  discard messageBoxA(0, description, title, MB_OK or MB_ICONINFORMATION)

proc warning*(title: string, description: string) =
  discard messageBoxA(0, description, title, MB_OK or MB_ICONWARNING)

proc error*(title: string, description: string) =
  discard messageBoxA(0, description, title, MB_OK or MB_ICONERROR)
