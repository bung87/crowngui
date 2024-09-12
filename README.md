# crowngui  ![Build Status](https://github.com/bung87/crowngui/workflows/build/badge.svg)  

Web Technologies based Crossplatform GUI Framework  

It uses Cocoa/WebKit on macOS, gtk-webkit2 on Linux and webview2 on Windows  

crowngui contains managed code only, no native code.

crowngui uses [nimpacker](https://github.com/nimpacker/nimpacker) for bundling application easier.


## Architecture

### how bindProcs works?  

figure generated via asciiflow  

```

┌─────────────┐         ┌──────────────────────────────┐       ┌─────────────────────────┐
│             │         │                              │       │                         │
│             │         │store hook function in `eps`  │       │when trigger js function │
│             │         │hook accept one string param  │       │internally it use browser│
│  bindProcs  ├────────►│and returns string that wraps ├──────►│`postMessage` api send   │
│             │         │nim proc call.                │       │json string with scope,  │
│             │         │And generate js function and  │       │name, argument.          │
│             │         │dispatch to main queue.       │       │                         │
└─────────────┘         └──────────────────────────────┘       └────────────┬────────────┘
                                                                            │
                                                                            ▼
                        ┌────────────────────────────────────────────────────┐
                        │browser add callback when received message          │
                        │it calls Webview's `invokeCb` which implements      │
                        │as `generalExternalInvokeCallback`                  │
                        │it parse argument as json retrieve scope,           │
                        │name, argument,then call the hook stored.           │
                        │                                                    │
                        └────────────────────────────────────────────────────┘

```

## Usage  
file: yourexecutable.nim  
``` nim
import crowngui

when isMainModule:
  const   
    cssDark = staticRead"assets/dark.css".strip.unindent.cstring
    cssLight = staticRead"assets/light.css".strip.unindent.cstring

  let app = newApplication( staticRead("assets/demo.html") )
  let theme = if "--light-theme" in commandLineParams(): cssLight else: cssDark
  app.css(theme)
  app.run()
  app.exit()
```
Your project `.nimble` file  
``` nim
bin           = @["yourexecutable"]
```

`nimpacker` will bundle your executable to `exe` on windows, `.app` on mac  

Your project root can have `"logo.png"` which will generate as icon of application.  

### CLI usage  
`nimpacker [build,run] --help`  

```
Usage:
  [build,run] [required&optional-params] [flags: string...]
Options:
  -h, --help                         print this cligen-erated help
  --help-syntax                      advanced: prepend,plurals,..
  -t=, --target=   string  REQUIRED  set target
  -r, --release    bool    false     set release

```

## Examples  

[crown_excel](https://github.com/bung87/crown_excel) excel viewer  

[gamode](https://github.com/bung87/gamode) windows optimization tool for game  

## Development  

run  
`nimpacker run --target macos`  

build  
`nimpacker build --target macos`


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

## References  

[Distribute your app and the WebView2 Runtime](https://learn.microsoft.com/en-us/microsoft-edge/webview2/concepts/distribution)

[WebView2 Win32 Reference](https://learn.microsoft.com/en-us/microsoft-edge/webview2/reference/win32/)  
