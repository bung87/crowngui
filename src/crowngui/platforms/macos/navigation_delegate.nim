import objc_runtime
import darwin / [objc/blocks, web_kit]

const WKNavigationActionPolicyDownload = 2
const WKNavigationResponsePolicyAllow = 1

type MyWKNavigationDelegate* = ptr object of NSObject

proc setNavigationDelegate*(s: WKWebview, d: NSObject) {.objc: "setNavigationDelegate:".}

proc make_nav_policy_decision(self: Id; cmd: SEL; webView: Id; response: Id;
                                     decisionHandler: Block[proc (): void]) =
  objcr:
    if [response canShowMIMEType] == cast[Id](0):
      objc_msgSend(cast[Id](decisionHandler), $$"invoke", WKNavigationActionPolicyDownload)
    else:
      objc_msgSend(cast[Id](decisionHandler), $$"invoke", WKNavigationResponsePolicyAllow)

proc registerWKNavigationDelegate*(): ObjcClass =
  result = allocateClassPair(
      getClass("NSObject"), "MyWKNavigationDelegate", 0)
  discard addProtocol(result, getProtocol("WKNavigationDelegate"))
  discard addMethod(
      result,
      $$"webView:decidePolicyForNavigationResponse:decisionHandler:",
      make_nav_policy_decision)
  registerClassPair(result)
