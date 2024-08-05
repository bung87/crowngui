import std/[math]
import objc_runtime
import darwin / [ objc/runtime]


proc registerWKPreferences*(): ObjcClass =
  result = allocateClassPair(getClass("WKPreferences"), "PrivWKPreferences", 0)
  var typ = objc_property_attribute_t(name: "T".cstring, value: "c".cstring)
  var ownership = objc_property_attribute_t(name: "N".cstring, value: "".cstring)
  replaceProperty(result, "developerExtrasEnabled", [typ, ownership])
  registerClassPair(result)