# crowngui  

Web Technologies based Crossplatform GUI Framework  

## Usage  

``` nim
import crowngui

when isMainModule:
  const   
    cssDark = staticRead"assets/dark.css".strip.unindent.cstring
    cssLight = staticRead"assets/light.css".strip.unindent.cstring

  let app = newApplication( staticRead("assets/demo.html") )
  when not defined(bundle):
    let theme = if "--light-theme" in commandLineParams(): cssLight else: cssDark
    app.css(theme)
  app.run()
  app.exit()
```


## Development  

run  
`nim c -r -f src/crownguipkg/cli.nim run --target macos --wwwroot ./docs`  

build  
`nim c -r -f src/crownguipkg/cli.nim build --target macos --wwwroot ./docs`


## Cross compilation for Windows  

To cross compile for Windows from Linux or macOS using the MinGW-w64 toolchain:  

`nim c -d:mingw myproject.nim`  

Use `--cpu:i386` or `--cpu:amd64` to switch the CPU architecture.

The MinGW-w64 toolchain can be installed as follows:  

```
Ubuntu: apt install mingw-w64
CentOS: yum install mingw32-gcc | mingw64-gcc - requires EPEL
OSX: brew install mingw-w64
```