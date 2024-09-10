import winim
import com
# import std/[atomics]

type

  WebviewPrivObj* = object
    windowHandle*: HWND
    view*: ptr ICoreWebView2
    controller*: ptr ICoreWebView2Controller
    settings*: ptr ICoreWebView2Settings

