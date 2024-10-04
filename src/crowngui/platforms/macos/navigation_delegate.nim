import darwin/objc/runtime
import darwin / [objc/blocks, web_kit]

type MyWKNavigationDelegate* = ptr object of NSObject

proc make_nav_policy_decision(self: Id; cmd: SEL; webView: WKWebView; response: WKNavigationResponse;
                                     decisionHandler: Block[proc (a: WKNavigationActionPolicy): void]) =
  let send = cast[proc(a: ID, b: SEL, c: WKNavigationActionPolicy){.cdecl,gcsafe.}](objc_msgSend)
  if response.canShowMIMEType == NO:
    send(cast[Id](decisionHandler), $$"invoke", WKNavigationActionPolicy.WKNavigationActionPolicyDownload)
  else:
    send(cast[Id](decisionHandler), $$"invoke", WKNavigationActionPolicy.WKNavigationActionPolicyAllow)

proc registerWKNavigationDelegate*(): ObjcClass =
  result = allocateClassPair(
      getClass("NSObject"), "MyWKNavigationDelegate", 0)
  discard addProtocol(result, getProtocol("WKNavigationDelegate"))
  discard addMethod(
      result,
      $$"webView:decidePolicyForNavigationResponse:decisionHandler:",
      make_nav_policy_decision)
  registerClassPair(result)
