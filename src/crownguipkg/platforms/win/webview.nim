import wNim / [wWebView]
# webview_init
# webview_eval
# webview_fix_ie_compat_mode
# webview_set_title
# webview_set_fullscreen
# webview_set_iconify
# webview_launch_external_URL
# webview_dialog
# webview_terminate
# webview_exit
# webview_print_log
struct webview {
  const char *url;
  const char *title;
  int width;
  int height;
  int resizable;
  int debug;
  webview_external_invoke_cb_t external_invoke_cb;
  struct webview_priv priv;
  void *userdata;
};
# struct webview_priv {
#   HWND hwnd;// window
#   IOleObject **browser;
#   BOOL is_fullscreen;
#   DWORD saved_style;
#   DWORD saved_ex_style;
#   RECT saved_rect;
# };

proc  webview_init(struct webview *w):cint =
  var wc:WNDCLASSEX
  var hInstance:HINSTANCE
  var style:DWORD
  var clientRect:RECT
  var rect:RECT

  if (webview_fix_ie_compat_mode() < 0) :
    return -1;

  hInstance = GetModuleHandle(NULL);
  if (hInstance == NULL) {
    return -1;
  }
  if (OleInitialize(NULL) != S_OK) {
    return -1;
  }
  ZeroMemory(&wc, sizeof(WNDCLASSEX));
  wc.cbSize = sizeof(WNDCLASSEX);
  wc.hInstance = hInstance;
  wc.lpfnWndProc = wndproc;
  wc.lpszClassName = classname;
  RegisterClassEx(&wc);

  style = WS_OVERLAPPEDWINDOW;
  if (not w.resizable) :
    style = WS_OVERLAPPED or WS_CAPTION or WS_MINIMIZEBOX or WS_SYSMENU;

  rect.left = 0;
  rect.top = 0;
  rect.right = w.width;
  rect.bottom = w.height;
  AdjustWindowRect(&rect, WS_OVERLAPPEDWINDOW, 0);

  GetClientRect(GetDesktopWindow(), &clientRect);
  int left = (clientRect.right / 2) - ((rect.right - rect.left) / 2);
  int top = (clientRect.bottom / 2) - ((rect.bottom - rect.top) / 2);
  rect.right = rect.right - rect.left + left;
  rect.left = left;
  rect.bottom = rect.bottom - rect.top + top;
  rect.top = top;

  w.priv.hwnd =
      CreateWindowEx(0, classname, w.title, style, rect.left, rect.top,
                     rect.right - rect.left, rect.bottom - rect.top,
                     HWND_DESKTOP, NULL, hInstance, (void *)w);
  if (w.priv.hwnd == 0):
    OleUninitialize();
    return -1;

  SetWindowLongPtr(w.priv.hwnd, GWLP_USERDATA, (LONG_PTR)w)

  DisplayHTMLPage(w)

  SetWindowText(w.priv.hwnd, w.title)
  ShowWindow(w.priv.hwnd, SW_SHOWDEFAULT)
  UpdateWindow(w.priv.hwnd)
  SetFocus(w.priv.hwnd)

  return 0;

proc  webview_loop(struct webview *w, int blocking):cint =
  var msg: MSG
  if blocking) :
    if (GetMessage(&msg, 0, 0, 0)<0): return 0;
  else :
    if (!PeekMessage(&msg, 0, 0, 0, PM_REMOVE)): return 0;
  
  case msg.message:
  of WM_QUIT:
    return -1;
  of WM_COMMAND:
  of WM_KEYDOWN:
  of WM_KEYUP: 
    HRESULT r = S_OK;
    IWebBrowser2 *webBrowser2;
    IOleObject *browser = *w.priv.browser;
    if (browser.lpVtbl.QueryInterface(browser, iid_unref(&IID_IWebBrowser2),
                                        (void **)&webBrowser2) == S_OK) :
      IOleInPlaceActiveObject *pIOIPAO;
      if (browser.lpVtbl.QueryInterface(
              browser, iid_unref(&IID_IOleInPlaceActiveObject),
              (void **)&pIOIPAO) == S_OK) :
        r = pIOIPAO.lpVtbl.TranslateAccelerator(pIOIPAO, &msg);
        pIOIPAO.lpVtbl.Release(pIOIPAO);
      
      webBrowser2.lpVtbl.Release(webBrowser2);
    
    if (r != S_FALSE) :
      break;
  
  else:
    TranslateMessage(&msg);
    DispatchMessage(&msg);
  
  return 0;
