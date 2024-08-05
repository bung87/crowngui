import std/[math]
import objc_runtime
import darwin / [app_kit, foundation, objc/runtime]
import types
import ./internal_dialogs

proc registerDownloadDelegate*(): ObjcClass =
  var result = allocateClassPair(getClass("NSObject"), "PrivWKDownloadDelegate", 0)
  discard addMethod(
      result,
      $$"_download:decideDestinationWithSuggestedFilename:completionHandler:",
      run_save_panel)
  # discard addMethod(result,registerName("_download:didFailWithError:"),cast[IMP](download_failed), "v@:@@")
  registerClassPair(result)