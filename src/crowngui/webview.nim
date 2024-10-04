include js_utils
import tables, strutils, macros, logging, json, os, strformat, std/exitprocs
import ./types
export types

var logger = newRollingFileLogger(expandTilde("~/crowngui.log"))
addHandler(logger)

when defined(linux):
  {.passc: "-DWEBVIEW_GTK=1 " & staticExec"pkg-config --cflags gtk+-3.0 webkit2gtk-4.0",
      passl: staticExec"pkg-config --libs gtk+-3.0 webkit2gtk-4.0".}
elif defined(windows):
  import platforms/win/webview2
  export webview2
  import winim
elif defined(macosx):
  import objc_runtime
  import darwin / [app_kit, foundation]
  import platforms/macos/menu
  import platforms/macos/webview
  import platforms/macos/app_delegate
  import platforms/macos/windowcontroller
  export webview

type
  DispatchFn* = proc()
  CallHook = proc (params: string): string # json -> proc -> json
  MethodInfo = object
    scope, name, args: string
  ExternalInvokeCb* = proc (w: Webview; arg: cstring) ## External CallBack Proc

const
  fileLocalHeader* = "file:///" ## Use Local File as URL

var
  eps = newTable[Webview, TableRef[string, TableRef[string, CallHook]]]()       # for bindProc
  cbs = newTable[Webview, ExternalInvokeCb]()                                   # easy callbacks
  dispatchTable = newTable[int, DispatchFn]()                                   # for dispatch

proc css*(w:Webview, css: string): void =
  when defined(windows): # FIXME: `addUserScriptAtDocumentStart` doesn't work with `NavigateToString`
    w.addUserScriptAtDocumentEnd(cssInjectFunction & "(\"" & css.jsEncode & "\")")
  else:
    w.addUserScriptAtDocumentStart(cssInjectFunction & "(\"" & css.jsEncode & "\")")

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
    cbs[w](w, arg)
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
  webview_dispatch(w, generalDispatchProc, cast[pointer](idx))

proc bindProc[P, R](w: Webview; scope, name: string; p: (proc(param: P): R)): string {.used.} =
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
  return jsTemplate % [name, scope]

proc bindProcNoArg(w: Webview; scope, name: string; p: proc()): string {.used.} =
  assert name.len > 0, "Name must not be empty string"
  proc hook(hookParam: string): string =
    p()
    return ""
  discard eps.hasKeyOrPut(w, newTable[string, TableRef[string, CallHook]]())
  discard hasKeyOrPut(eps[w], scope, newTable[string, CallHook]())
  eps[w][scope][name] = hook
  return jsTemplateNoArg % [name, scope]

proc bindProc[P](w: Webview; scope, name: string; p: proc(arg: P)): string {.used.} =
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
  return jsTemplateOnlyArg % [name, scope]

macro bindProcs*(w: Webview; scope: string; n: untyped): untyped =
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
  result = nnkStmtList.newTree()
  let body = n
  var jsIdent = genSym(nskVar)
  var jsStr = nnkVarSection.newTree(
    nnkIdentDefs.newTree(
      jsIdent,
      newIdentNode("string"),
      newLit("")
    )
  )
  result.add jsStr
  for def in n:
    expectKind(def, {nnkProcDef, nnkFuncDef, nnkLambda})
    let params = def.params()
    let fname = $def[0]
    # expectKind(params[0], nnkSym)
    if params.len() == 1 and params[0].kind() == nnkEmpty: # no args
      var bindCall = newCall(bindSym"bindProcNoArg", w, scope, newLit(fname), newIdentNode(fname))
      body.add(newCall("add", jsIdent, bindCall))
      continue
    if params.len > 2: error("Argument must be proc or func of 0 or 1 arguments", def)
    var bindCall = newCall(bindSym"bindProc", w, scope, newLit(fname), newIdentNode(fname))
    body.add(newCall("add", jsIdent, bindCall))
  result.add newBlockStmt(body)
  let w2 = w
  result.add(quote do:
    `w2`.dispatch(proc() = `w2`.addUserScriptAtDocumentEnd(`jsIdent`))
  )

proc run*(w: Webview; quitProc: proc () {.noconv.}; controlCProc: proc () {.noconv.}) {.inline.} =
  ## `run` starts the main UI loop until the user closes the window. Same as `run` but with extras.
  ## * `quitProc` is a function to run at exit, needs `{.noconv.}` pragma.
  ## * `controlCProc` is a function to run at CTRL+C, needs `{.noconv.}` pragma.
  ## * `autoClose` set to `true` to automatically run `exit()` at exit.
  exitprocs.addExitProc(quitProc)
  system.setControlCHook(controlCProc)
  w.run

proc webView(title = ""; url = "";entryType:EntryType; width: Positive = 1000; height: Positive = 700; resizable: static[bool] = true;
    debug: static[bool] = not defined(release); callback: ExternalInvokeCb = nil): Webview {.inline.} =
  result = create(WebviewObj)
  result.title = title
  result.url = url
  result.width = width
  result.height = height
  result.resizable = resizable
  result.debug = debug
  result.entryType = entryType
  result.invokeCb = generalExternalInvokeCallback
  if callback != nil: result.externalInvokeCB = callback
  if result.webview_init() != 0: return nil

proc newWebView*(path: static[string] = ""; entryType:static[EntryType]; title = ""; width: Positive = 1000; height: Positive = 700;
    resizable: static[bool] = true; debug: static[bool] = not defined(release); callback: ExternalInvokeCb = nil; 
    ): Webview =
  ## Create a new Window with given attributes, all arguments are optional.
  ## * `path` is the URL or Full Path to 1 HTML file, index of the Web GUI App.
  ## * `title` is the Title of the Window.
  ## * `width` is the Width of the Window.
  ## * `height` is the Height of the Window.
  ## * `resizable` set to `true` to allow Resize of the Window, defaults to `true`.
  ## * `debug` Debug mode, Debug is `true` when not built for Release.

  var entry = path
  var entryType1 = entryType
  when path.endsWith".js" or path.endsWith".nim":
    entry =  "<!DOCTYPE html><html><head><meta content='width=device-width,initial-scale=1' name=viewport></head><body id=body ><div id=ROOT ><div></body></html>" # Copied from Karax
    entryType1 = EntryType.html
  var webview = webView(title, entry, entryType1, width, height, resizable, debug, callback)
  when defined(macosx):
    let MyAppDelegateClass = registerAppDelegate()
    let MyWindowControllerClass = registerWindowController()

    objcr:
      var appDel = cast[MyAppDelegate](createInstance(MyAppDelegateClass, 0))
      var windowController = cast[MyWindowController](createInstance(MyWindowControllerClass, 0)) # [MyWindowController new]
      webview.priv.window.setDelegate(windowController)
      cast[NSApplication](NSApp).setDelegate(appDel)
      let ivar: Ivar = getIvar(MyAppDelegateClass, "webview")
      setIvar(appDel, ivar, cast[ID](webview))
      # createMenu()

  when not defined(macosx):
    if paramCount() > 0:
      let filepath = paramStr(1)
      if filepath.len > 0 and webview.onOpenFile != nil:
        discard webview.onOpenFile(webview, filepath)
  when path.endsWith".js": 
    const js = staticRead(path)
    webview.addUserScriptAtDocumentEnd(js)
  when path.endsWith".nim":
    doAssert fileExists(path)
    const compi = gorgeEx("nim js --out:" & path & ".js " & path & (when defined(release): " -d:release" else: "") & (
        when defined(danger): " -d:danger" else: ""))
    const jotaese = when compi.exitCode == 0: staticRead(path & ".js").strip else: ""
    when not defined(release): echo jotaese
    when compi.exitCode == 0: webview.addUserScriptAtDocumentEnd(jotaese)
  return webview
