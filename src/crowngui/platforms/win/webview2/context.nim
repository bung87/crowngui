import std/[locks, tables]
import winim
import types

type
  WebviewContextStoreObj = object
    mu: Lock
    store: Table[HWND, WebView]
  WebviewContextStore = ref WebviewContextStoreObj

# var webviewContext* = new WebviewContextStore
# webviewContext.mu.initLock()

proc set*(wcs: WebviewContextStore; hwnd: HWND;wv: WebView) = 
  wcs.mu.acquire
  defer: wcs.mu.release
  wcs.store[hwnd] = wv

proc get*(wcs: WebviewContextStore;hwnd: HWND;):WebView =
  wcs.mu.acquire
  defer: wcs.mu.release
  return wcs.store[hwnd]