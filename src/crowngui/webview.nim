import tables, strutils, macros, logging, json, os, base64, strformat, std/exitprocs, math
var logger = newRollingFileLogger(expandTilde("~/crowngui.log"))
addHandler(logger)
const headerC = currentSourcePath().substr(0, high(currentSourcePath()) - 11) & "webview.h"
{.passc: "-DWEBVIEW_STATIC -DWEBVIEW_IMPLEMENTATION -I" & headerC.}
when defined(linux):
  {.passc: "-DWEBVIEW_GTK=1 " & staticExec"pkg-config --cflags gtk+-3.0 webkit2gtk-4.0",
      passl: staticExec"pkg-config --libs gtk+-3.0 webkit2gtk-4.0".}
elif defined(windows):
  {.passc: "-DWEBVIEW_WINAPI=1", passl: "-lole32 -lcomctl32 -loleaut32 -luuid -lgdi32".}
  import platforms/win/webview
  export webview
  import winim
elif defined(macosx):
  import objc_runtime
  import darwin / [app_kit, foundation]
  import platforms/macos/menu
  import platforms/macos/webview
  import platforms/macos/appdelegate
  import platforms/macos/windowcontroller
  export webview
  var NSApp {.importc.}: ID
  {.passc: "-DOBJC_OLD_DISPATCH_PROTOTYPES=1 -DWEBVIEW_COCOA -x objective-c",
      passl: "-framework Cocoa -framework WebKit".}

# type
#   ExternalInvokeCb* = proc (w: Webview; arg: string) ## External CallBack Proc
#   WebviewPrivObj {.importc: "struct webview_priv", header: headerC, bycopy.} = object
#     when defined(macosx):
#       pool: ID
#       window: ID
#       webview: ID
#       windowDelegate: ID
#       should_exit: int
#   WebviewObj* {.importc: "struct webview", header: headerC, bycopy.} = object ## WebView Type
#     url* {.importc: "url".}: cstring                                          ## Current URL
#     title* {.importc: "title".}: cstring                                      ## Window Title
#     width* {.importc: "width".}: cint                                         ## Window Width
#     height* {.importc: "height".}: cint                                       ## Window Height
#     resizable* {.importc: "resizable".}: cint ## `true` to Resize the Window, `false` for Fixed size Window
#     debug* {.importc: "debug".}: cint                                         ## Debug is `true` when not build for Release
#     external_invoke_cb {.importc: "external_invoke_cb".}: pointer                       ## Callback proc js:window.external.invoke
#     priv {.importc: "priv".}: WebviewPrivObj
#     userdata {.importc: "userdata".}: pointer
type
  OnOpenFile* = proc (view: Webview; filePath: string)
  # Webview* = ptr WebviewObj
  DispatchFn* = proc()
  DialogType {.size: sizeof(cint).} = enum
    dtOpen = 0, dtSave = 1, dtAlert = 2
  CallHook = proc (params: string): string # json -> proc -> json
  MethodInfo = object
    scope, name, args: string

template dataUriHtmlHeader*(s: string): string =
  ## Data URI for HTML UTF-8 header string. For Mac uses Base64, `import base64` to use.
  when defined(osx): "data:text/html;charset=utf-8;base64," & base64.encode(s)
  else: "data:text/html," & s

const
  fileLocalHeader* = "file:///" ## Use Local File as URL
  jsTemplate = """
    if (typeof $2 === 'undefined') {
      $2 = {};
    }
    $2.$1 = (arg) => {
      window.external.invoke(
        JSON.stringify(
          {scope: "$2", name: "$1", args: JSON.stringify(arg)}
        )
      );
    };
  """.strip.unindent
  jsTemplateOnlyArg = """
    if (typeof $2 === 'undefined') {
      $2 = {};
    }
    $2.$1 = (arg) => {
      window.external.invoke(
        JSON.stringify(
          {scope: "$2", name: "$1", args: JSON.stringify(arg)}
        )
      );
    };
  """.strip.unindent
  jsTemplateNoArg = """
    if (typeof $2 === 'undefined') {
      $2 = {};
    }
    $2.$1 = () => {
      window.external.invoke(
        JSON.stringify(
          {scope: "$2", name: "$1", args: ""}
        )
      );
    };
  """.strip.unindent

var
  eps = newTable[Webview, TableRef[string, TableRef[string, CallHook]]]()       # for bindProc
  cbs = newTable[Webview, ExternalInvokeCb]()                                   # easy callbacks
  dispatchTable = newTable[int, DispatchFn]()                                   # for dispatch

proc init(w: Webview): cint = webview_init(w)

func dispatch(w: Webview; fn: pointer; arg: pointer) = webview_dispatch(w, fn,
    arg) # dispatch nim func,function will be executed on the UI thread

func dialog(w: Webview; dlgtype: DialogType; flags: cint; title: cstring; arg: cstring; result: cstring;
    resultsz: system.csize_t) {.importc: "webview_dialog", header: headerC.}

proc dialog(w: Webview; dlgType: DialogType; dlgFlag: int; title, arg: string): string =
  ## dialog() opens a system dialog of the given type and title.
  ## String argument can be provided for certain dialogs, such as alert boxes.
  ## For alert boxes argument is a message inside the dialog box.
  const maxPath = 4096
  let resultPtr = cast[cstring](alloc0(maxPath))
  defer: dealloc(resultPtr)
  w.dialog(dlgType, dlgFlag.cint, title.cstring, arg.cstring, resultPtr, system.csize_t(maxPath))
  return $resultPtr

template msg*(w: Webview; title, msg: string) =
  ## Show one message box
  discard w.dialog(dtAlert, 0, title, msg)

template info*(w: Webview; title, msg: string) =
  ## Show one alert box
  discard w.dialog(dtAlert, 1 shl 1, title, msg)

template warn*(w: Webview; title, msg: string) =
  ## Show one warn box
  discard w.dialog(dtAlert, 2 shl 1, title, msg)

template error*(w: Webview; title, msg: string) =
  ## Show one error box
  discard w.dialog(dtAlert, 3 shl 1, title, msg)

template dialogOpen*(w: Webview; title = ""): string =
  ## Opens a dialog that requests filenames from the user. Returns ""
  ## if the user closed the dialog without selecting a file.
  w.dialog(dtOpen, 0.cint, title, "")

template dialogSave*(w: Webview; title = ""): string =
  ## Opens a dialog that requests a filename to save to from the user.
  ## Returns "" if the user closed the dialog without selecting a file.
  w.dialog(dtSave, 0.cint, title, "")

template dialogOpenDir*(w: Webview; title = ""): string =
  ## Opens a dialog that requests a Directory from the user.
  w.dialog(dtOpen, 1.cint, title, "")

proc generalExternalInvokeCallback(w: Webview; arg: cstring) {.exportc.} =
  # assign to webview.external_invoke_cb using eps,cbs store user defined proc
  var handled = false
  if eps.hasKey(w):
    try:
      var mi = parseJson($arg).to(MethodInfo)
      if hasKey(eps[w], mi.scope) and hasKey(eps[w][mi.scope], mi.name):
        discard eps[w][mi.scope][mi.name](mi.args)
        handled = true
    except:
      when defined(release): discard else: echo getCurrentExceptionMsg()
  elif cbs.hasKey(w):
    cbs[w](w, $arg)
    handled = true
  when not defined(release):
    if unlikely(handled == false): echo "Error on External invoke: ", arg

proc `externalInvokeCB=`*(w: Webview; callback: ExternalInvokeCb) {.inline.} =
  ## Set the external invoke callback for webview, for Advanced users only
  cbs[w] = callback

proc generalDispatchProc(w: Webview; arg: pointer) {.exportc.} =
  let idx = cast[int](arg)
  let fn = dispatchTable[idx]
  fn()

proc dispatch*(w: Webview; fn: DispatchFn) {.inline.} =
  ## Explicitly force dispatch a function, for advanced users only
  let idx = dispatchTable.len() + 1
  dispatchTable[idx] = fn
  dispatch(w, generalDispatchProc, cast[pointer](idx))

proc bindProc*[P, R](w: Webview; scope, name: string; p: (proc(param: P): R)) {.used.} =
  ## Do NOT use directly, see `bindProcs` macro.
  assert name.len > 0, "Name must not be empty string"
  proc hook(hookParam: string): string =
    var paramVal: P
    var retVal: R
    try:
      let jnode = parseJson(hookParam)
      when not defined(release): echo jnode
      paramVal = jnode.to(P)
    except:
      when defined(release): discard else: return getCurrentExceptionMsg()
    retVal = p(paramVal)
    return $(%*retVal) # ==> json
  discard eps.hasKeyOrPut(w, newTable[string, TableRef[string, CallHook]]())
  discard hasKeyOrPut(eps[w], scope, newTable[string, CallHook]())
  eps[w][scope][name] = hook
  w.dispatch(proc() = discard w.js(jsTemplate % [name, scope]))

proc bindProcNoArg*(w: Webview; scope, name: string; p: proc()) {.used.} =
  ## Do NOT use directly, see `bindProcs` macro.
  assert name.len > 0, "Name must not be empty string"
  proc hook(hookParam: string): string =
    p()
    return ""
  discard eps.hasKeyOrPut(w, newTable[string, TableRef[string, CallHook]]())
  discard hasKeyOrPut(eps[w], scope, newTable[string, CallHook]())
  eps[w][scope][name] = hook
  w.dispatch(proc() = w.eval(jsTemplateNoArg % [name, scope]))

proc bindProc*[P](w: Webview; scope, name: string; p: proc(arg: P)) {.used.} =
  ## Do NOT use directly, see `bindProcs` macro.
  assert name.len > 0, "Name must not be empty string"
  proc hook(hookParam: string): string =
    var paramVal: P
    try:
      let jnode = parseJson(hookParam)
      paramVal = jnode.to(P)
    except:
      when defined(release): discard else: return getCurrentExceptionMsg()
    p(paramVal)
    return ""
  discard eps.hasKeyOrPut(w, newTable[string, TableRef[string, CallHook]]())
  discard hasKeyOrPut(eps[w], scope, newTable[string, CallHook]())
  eps[w][scope][name] = hook
  w.dispatch(proc() = discard w.js(jsTemplateOnlyArg % [name, scope]))

macro bindProcs*(w: Webview; scope: string; n: untyped): untyped =
  ## * Functions must be `proc` or `func`; No `template` nor `macro`.
  ## * Functions must NOT have return Type, must NOT return anything, use the API.
  ## * To pass return data to the Frontend use the JavaScript API and WebGui API.
  ## * Functions do NOT need the `*` Star to work. Functions must NOT have Pragmas.
  ##
  ## You can bind functions with the signature like:
  ##
  ## .. code-block:: nim
  ##    proc functionName[T, U](argumentString: T): U
  ##    proc functionName[T](argumentString: T)
  ##    proc functionName()
  ##
  ## Then you can call the function in JavaScript side, like this:
  ##
  ## .. code-block:: js
  ##    scope.functionName(argumentString)
  ##
  ## Example:
  ##
  ## .. code-block:: js
  ##    let app = newWebView()
  ##    app.bindProcs("api"):
  ##      proc changeTitle(title: string) = app.setTitle(title) ## You can call code on the right-side,
  ##      proc changeCss(stylesh: string) = app.css(stylesh)    ## from JavaScript Web Frontend GUI,
  ##      proc injectJs(jsScript: string) = app.js(jsScript)    ## by the function name on the left-side.
  ##      ## (JS) JavaScript Frontend <-- = --> Nim Backend (Native Code, C Speed)
  ##
  ## The only limitation is `1` string argument only, but you can just use JSON.
  expectKind(n, nnkStmtList)
  let body = n
  for def in n:
    expectKind(def, {nnkProcDef, nnkFuncDef, nnkLambda})
    let params = def.params()
    let fname = $def[0]
    # expectKind(params[0], nnkSym)
    if params.len() == 1 and params[0].kind() == nnkEmpty: # no args
      body.add(newCall("bindProcNoArg", w, scope, newLit(fname), newIdentNode(fname)))
      continue
    if params.len > 2: error("Argument must be proc or func of 0 or 1 arguments", def)
    body.add(newCall("bindProc", w, scope, newLit(fname), newIdentNode(fname)))
  result = newBlockStmt(body)
  when not defined(release): echo repr(result)

# proc run*(w: Webview) {.inline.} =
#   ## `run` starts the main UI loop until the user closes the window or `exit()` is called.
#   while w.loop(1) == 0: discard

proc run*(w: Webview; quitProc: proc () {.noconv.}; controlCProc: proc () {.noconv.}) {.inline.} =
  ## `run` starts the main UI loop until the user closes the window. Same as `run` but with extras.
  ## * `quitProc` is a function to run at exit, needs `{.noconv.}` pragma.
  ## * `controlCProc` is a function to run at CTRL+C, needs `{.noconv.}` pragma.
  ## * `autoClose` set to `true` to automatically run `exit()` at exit.
  exitprocs.addExitProc(quitProc)
  system.setControlCHook(controlCProc)
  w.run

proc webView(title = ""; url = ""; width: Positive = 1000; height: Positive = 700; resizable: static[bool] = true;
    debug: static[bool] = not defined(release); callback: ExternalInvokeCb = nil): Webview {.inline.} =
  result = cast[Webview](alloc0(sizeof(WebviewObj)))
  
  result.title = title.cstring
  result.url = url.cstring
  result.width = width.cint
  result.height = height.cint
  result.resizable = when resizable: 1 else: 0
  result.debug = when debug: 1 else: 0
  result.external_invoke_cb = generalExternalInvokeCallback
  if callback != nil: result.externalInvokeCB = callback
  if result.init() != 0: return nil

proc newWebView*(path: static[string] = ""; title = ""; width: Positive = 1000; height: Positive = 700;
    resizable: static[bool] = true; debug: static[bool] = not defined(release); callback: ExternalInvokeCb = nil;
        skipTaskbar: static[bool] = false; windowBorders: static[bool] = true; focus: static[bool] = false;
            keepOnTop: static[bool] = false;
    minimized: static[bool] = false; cssPath: static[string] = ""; trayIcon: static[cstring] = ""; fullscreen: static[
        bool] = false): Webview =
  ## Create a new Window with given attributes, all arguments are optional.
  ## * `path` is the URL or Full Path to 1 HTML file, index of the Web GUI App.
  ## * `title` is the Title of the Window.
  ## * `width` is the Width of the Window.
  ## * `height` is the Height of the Window.
  ## * `resizable` set to `true` to allow Resize of the Window, defaults to `true`.
  ## * `debug` Debug mode, Debug is `true` when not built for Release.
  ## * `skipTaskbar` if set to `true` the Window will not be visible on the desktop Taskbar.
  ## * `windowBorders` if set to `false` the Window will have no Borders, no Close button, no Minimize button.
  ## * `focus` if set to `true` the Window will force Focus.
  ## * `keepOnTop` if set to `true` the Window will keep on top of all other windows on the desktop.
  ## * `minimized` if set the `true` the Window will be Minimized, Iconified.
  ## * `cssPath` Full Path or URL of a CSS file to use as Style, defaults to `"dark.css"` for Dark theme, can be `"light.css"` for Light theme.
  ## * `trayIcon` Path to a local PNG Image Icon file.
  ## * `fullscreen` if set to `true` the Window will be forced Fullscreen.
  ## * If `--light-theme` on `commandLineParams()` then it will use Light Theme automatically.
  ## * CSS is embedded, if your app is used Offline, it will display Ok.
  ## * For templates that do CSS, remember that CSS must be injected *after DOM Ready*.
  ## * Is up to the developer to guarantee access to the HTML URL or File of the GUI.

  result = webView(title, path, width, height, resizable, debug, callback)
  when defined(macosx):
    let webview = result
    let MyAppDelegateClass = initAppDelegate()
    MyAppDelegateClass.registerClassPair()

    let WindowControllerClass = initWindowControlelr()
    WindowControllerClass.registerClassPair()
    objcr:
      var appDel = [AppDelegate alloc]
      [appDel init]
      # var windowController = [[WindowController alloc] init]
      # [webview.priv.window setDelegate: windowController]
      [NSApplication sharedApplication]
      [NSApp setDelegate: appDel]
      let ivar: Ivar = getIvar(MyAppDelegateClass, "webview")
      setIvar(appDel, ivar, cast[ID](webview))
      createMenu()
      [NSApp finishLaunching]
      [NSApp activateIgnoringOtherApps: true]

  when not defined(macosx) and compiles(onOpenFile(webview, "")):
    let filepath = paramStr(1)
    if filepath.len > 0:
      onOpenFile(filepath)
  when skipTaskbar: result.setSkipTaskbar(skipTaskbar)
  when not windowBorders: result.setBorderlessWindow(windowBorders)
  when focus: result.setFocus()
  when keepOnTop: result.setOnTop(keepOnTop)
  when minimized: webviewindow.setIconify(minimized)
  when trayIcon.len > 0: result.setTrayIcon(trayIcon, title.cstring, visible = true)
  when fullscreen: result.setFullscreen(fullscreen)

  when path.endsWith".js": result.eval(readFile(path))
  when path.endsWith".nim":
    const compi = gorgeEx("nim js --out:" & path & ".js " & path & (when defined(release): " -d:release" else: "") & (
        when defined(danger): " -d:danger" else: ""))
    const jotaese = when compi.exitCode == 0: staticRead(path & ".js").strip.cstring else: "".cstring
    when not defined(release): echo jotaese
    when compi.exitCode == 0: echo result.eval(jotaese)
