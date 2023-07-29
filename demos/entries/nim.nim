import os, strutils, crowngui

when isMainModule:
  const nim = currentSourcePath.parentDir / "nim2js.nim"
  let app = newApplication(nim)
  app.run()
  app.destroy()