import os, strutils, crowngui

when isMainModule:

  const
    cssDark = staticRead"assets/dark.css".strip.unindent
    cssLight = staticRead"assets/light.css".strip.unindent

  let app = newApplication(staticRead("assets/demo.html"))
  when not defined(bundle):
    let theme = if "--light-theme" in commandLineParams(): cssLight else: cssDark
    app.css(theme)

  app.run()
  app.destroy()