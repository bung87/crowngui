import os, strutils, crowngui

when isMainModule:
  const js = currentSourcePath.parentDir / "assets" / "main.js"
  let app = newApplication(js)
  app.run()
  app.destroy()