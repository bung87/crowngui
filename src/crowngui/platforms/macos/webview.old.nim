import objc_runtime
import darwin / [app_kit, foundation, objc/runtime, objc/blocks, core_graphics/cggeometry]
import menu
import types

proc webview_loop*(w: Webview; blocking: cint): cint =
  objcr:
    var until = if blocking > 0: [NSDate distantFuture] else: [NSDate distantPast]
    [NSApplication sharedApplication]
    var event = [NSApp nextEventMatchingMask: culong.high, untilDate: until, inMode: "kCFRunLoopDefaultMode", dequeue: true]
    if cast[pointer](event) != nil:
      [NSApp sendEvent: event]
    return w.priv.should_exit


proc webview_reload*(w: Webview) =
  objcr: [w.priv.webview $$"reload"]

proc webview_show*(w: Webview) =
  objcr:
    [w.priv.window reload]
    if cast[bool]([w.priv.window isMiniaturized]):
      [w.priv.window deminiaturize: nil]
    [w.priv.window makeKeyAndOrderFront: nil]

proc webview_hide*(w: Webview) =
  objcr: [w.priv.window orderOut: nil]

proc webview_minimize*(w: Webview) =
  objcr: [w.priv.window miniaturize: nil]

proc webview_close*(w: Webview) =
  objcr: [w.priv.window close]

proc webview_set_fullscreen*(w: Webview; fullscreen: int) =
  objcr:
    var windowStyleMask = cast[NSWindowStyleMask]([w.priv.window styleMask])
    var b: int = if (windowStyleMask.uint and NSWindowStyleMaskFullScreen.uint) == NSWindowStyleMaskFullScreen.uint: 1 else: 0
    if b != fullscreen:
      [w.priv.window toggleFullScreen: nil]

proc webview_set_iconify*(w: Webview; iconify: int) {.objcr.}  =
  if iconify > 0:
    [w.priv.window miniaturize: nil]
  else:
    [w.priv.window deminiaturize: nil]

proc webview_launch_external_URL*(w: Webview; uri: string) {.objcr.} =
  var url = [NSURL URLWithString: @uri]
  [[NSWorkspace sharedWorkspace]openURL: url]

proc webview_set_color*(w: Webview; r, g, b, a: uint8) {.objcr.} =
  var color = [NSColor colorWithRed: r.float64 / 255.0, green: g.float64 / 255.0, blue: b.float64 / 255.0,
      alpha: a.float64 / 255.0]
  [w.priv.window setBackgroundColor: color]

  if (0.5 >= ((r.float64 / 255.0 * 299.0) + (g.float64 / 255.0 * 587.0) + (b.float64 / 255.0 * 114.0)) /
                1000.0):
    [w.priv.window setAppearance: [NSAppearance appearanceNamed: "NSAppearanceNameVibrantDark"]]
  else:
    [w.priv.window setAppearance: [NSAppearance appearanceNamed: "NSAppearanceNameVibrantLight"]]
    [w.priv.window setOpaque: 0]
    [w.priv.window setTitlebarAppearsTransparent: 1]
    [w.priv.window "_setDrawsBackground": 0]

proc webview_set_developer_tools_enabled*(w: Webview; enabled: bool) =
  objcr: [[w.priv.window configuration]"_setDeveloperExtrasEnabled": enabled]
