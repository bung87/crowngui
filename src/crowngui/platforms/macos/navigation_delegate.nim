import objc_runtime
import darwin / [objc/blocks]

const WKNavigationActionPolicyDownload = 2
const WKNavigationResponsePolicyAllow = 1

proc make_nav_policy_decision(self: Id; cmd: SEL; webView: Id; response: Id;
                                     decisionHandler: Block[proc (): void]) =
  objcr:
    if [response canShowMIMEType] == cast[Id](0):
      objc_msgSend(cast[Id](decisionHandler), $$"invoke", WKNavigationActionPolicyDownload)
    else:
      objc_msgSend(cast[Id](decisionHandler), $$"invoke", WKNavigationResponsePolicyAllow)

proc registerWKNavigationDelegate*(): ObjcClass =
  result = allocateClassPair(
      getClass("NSObject"), "PrivWKNavigationDelegate", 0)
  discard addProtocol(result, getProtocol("WKNavigationDelegate"))
  discard addMethod(
      result,
      $$"webView:decidePolicyForNavigationResponse:decisionHandler:",
      make_nav_policy_decision)
  registerClassPair(result)
