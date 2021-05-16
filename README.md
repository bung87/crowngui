# crowngui  

Web Technologies based Crossplatform GUI Framework  

It uses Cocoa/WebKit on macOS, gtk-webkit2 on Linux and IE on Windows  

Notice: I mainly work on macOS, also it has well document of Cocoa/WebKit,
 contribute to Linux and Windows are welcome, the windows binding will change to Edge and webview2 api in the future.

CLI tool:  
[crowncli](https://github.com/bung87/crowncli) for build application.   

## Usage  
file: yourexecutable.nim  
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
Your project `.nimble` file  
``` nim
bin           = @["yourexecutable"]
```

`crowncli` will bundle your executable to `exe` on windows, `.app` on mac  

Your project root can have `"logo.png"` which will generate as icon of application.  

### CLI usage  
`crowncli [build,run] --help`  

```
Usage:
  [build,run] [required&optional-params] [flags: string...]
Options:
  -h, --help                         print this cligen-erated help
  --help-syntax                      advanced: prepend,plurals,..
  -t=, --target=   string  REQUIRED  set target
  -w=, --wwwroot=  string  ""        set wwwroot
  -r, --release    bool    false     set release

```

## Examples  
[crown_excel](https://github.com/bung87/crown_excel)  crowngui based excel viewer
## Prerequires  
  
`rcedit` for windows exe icon on non-windows platform requires `wine`  

## Development  

run  
`crowncli run --target macos`  

build  
`crowncli build --target macos`


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