# crowngui  

## Background story  

contained `webview.h` base on [zserge/webview](https://github.com/zserge/webview/tree/0.1.0) which latest commit on 9 May 2018. and [juancarlospaco/webgui](https://github.com/juancarlospaco/webgui) juancarlospaco translate macos objc code to objc runtime.  

some issues I fixed:  

* [fix webview_eval on macos replace original simple solution](https://github.com/juancarlospaco/webgui/commit/c177d73e68f21b3163217841e2e0ffd4dd991272)  

* [add edit menu and works fine first launch through addLocalMonitorForEventsMatchingMask](https://github.com/bung87/crowngui/commit/8ab16c04c50401fdc145db991eb51e0e3f522fca)

contained `webview.nim` base on [juancarlospaco/webgui](https://github.com/juancarlospaco/webgui)

some issues I fixed:  

* [dataUriHtmlHeader as template,using base64 follow w3c rules make it actually works on macos without side effect](https://github.com/juancarlospaco/webgui/commit/e48d4373e74f1eb8c0002cfb5357b924dd4655a3)

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