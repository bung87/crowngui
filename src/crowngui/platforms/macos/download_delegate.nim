import darwin / [foundation, objc/runtime]
import ./internal_dialogs

proc registerDownloadDelegate*(): ObjcClass =
  result = allocateClassPair(getClass("NSObject"), "PrivWKDownloadDelegate", 0)
  discard addMethod(
      result,
      $$"_download:decideDestinationWithSuggestedFilename:completionHandler:",
      run_save_panel)
  # discard addMethod(result,registerName("_download:didFailWithError:"),cast[IMP](download_failed), "v@:@@")
  registerClassPair(result)