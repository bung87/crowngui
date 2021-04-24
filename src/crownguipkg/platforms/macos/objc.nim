const OBJC_LIB_NAME* = "libobjc.A.dylib"
import macros, regex, sequtils, strutils
{.pragma: objcimport, cdecl, importc, dynlib: OBJC_LIB_NAME.}
{.pragma: objccallback, cdecl.}

when defined(cpu64):
  type
    CGFloat* = cdouble
    NSInteger* = clong
    NSUInteger* = culong
else:
  type
    CGFloat* = cfloat
    NSInteger* = cint
    NSUInteger* = cuint

type
  Class* = distinct pointer
  Method* = distinct pointer
  Ivar* = distinct pointer
  Category* = distinct pointer
  Protocol* = distinct pointer
  ID* = distinct pointer
  SEL* = distinct pointer
  STR* = ptr cchar
  arith_t* = cint
  uarith_t* = cuint
  ptrdiff_t* = int
  BOOL* = cchar

  objc_method_description = object
    name: SEL
    types: cstring

  MethodDescription* = object
    name*: SEL
    types*: string

  Property* = distinct pointer

  ObjcSuper* = object
    receiver*: ID
    superClass*: Class

  objc_property_attribute_t = object
    name: cstring
    value: cstring

  PropertyAttribute* = object
    name*: string
    value*: string

  objc_exception_functions_t* = object
    version: cint
    throw_exc: proc(id: ID) {.objccallback.}
    try_enter: proc(p: pointer) {.objccallback.}
    try_exit: proc(p: pointer) {.objccallback.}
    extract: proc(p: pointer): ID {.objccallback.}
    match: proc(class: Class, id: ID): cint {.objccallback.}

  IMP* = proc(id: ID, selector: SEL): ID {.cdecl, varargs.}

  objc_AssociationPolicy* {.size: sizeof(cuint).} = enum
    OBJC_ASSOCIATION_ASSIGN = 0
    OBJC_ASSOCIATION_RETAIN_NONATOMIC = 1
    OBJC_ASSOCIATION_COPY_NONATOMIC = 3
    OBJC_ASSOCIATION_RETAIN = 01401
    OBJC_ASSOCIATION_COPY = 01403

type
  NSObject* = object of RootObj
    id*: ID

  NSView* = object of NSObject

  NSTextView* = object of NSView

  NSString* = object of NSObject

  NSApplication* = object of NSObject
  NSURL* = object of NSObject

const
  YES* = cchar(1)
  NO* = cchar(0)

converter toId*(w: NSString): ID = w.id

proc isNil*(a: Class): bool =
  result = a.pointer == nil

proc isNil*(a: ID): bool =
  result = a.pointer == nil

proc c_free(p: pointer) {.importc: "free", header: "<stdlib.h>".}

proc class_getName(cls: Class): cstring {.objcimport.}
proc getName*(cls: Class): string =
  result = $class_getName(cls)

proc `$`*(cls: Class): string =
  getName(cls)

proc class_getSuperclass(cls: Class): Class {.objcimport.}
template getSuperclass*(cls: Class): untyped =
  class_getSuperClass(cls)

proc class_isMetaClass(cls: Class): BOOL {.objcimport.}
template isMetaClass*(cls: Class): untyped =
  class_isMetaClass(cls)

proc class_getInstanceSize(cls: Class): csize_t {.objcimport.}
proc getInstanceSize*(cls: Class): int = class_getInstanceSize(cls).int

proc class_getInstanceVariable(cls: Class; name: cstring): Ivar {.objcimport.}
template getIvar*(cls: Class, name: string): untyped =
  class_getInstanceVariable(cls, name.cstring)

proc class_getClassVariable(cls: Class; name: cstring): Ivar {.objcimport.}
template getClassVariable*(cls: Class; name: string): untyped =
  class_getClassVariable(cls, name.cstring)

proc class_addIvar(cls: Class; name: cstring; size: csize_t; alignment: uint8; types: cstring): BOOL {.objcimport.}
proc addIvar*(cls: Class; name: string; size: int; alignment: int; types: string): bool =
  class_addIvar(cls, name.cstring, size.csize_t, alignment.uint8, types.cstring) == YES

proc class_copyIvarList(cls: Class; outCount: var cuint): ptr Ivar {.objcimport.}
proc ivarList*(cls: Class): seq[Ivar] =
  var
    count = 0.cuint
    ivars = class_copyIvarList(cls, count)
  if count == 0:
    result = @[]
    return result
  result = newSeq[Ivar](count)
  copyMem(result[0].addr, ivars, sizeof(Ivar) * count.int)
  c_free(ivars)

proc class_getIvarLayout*(cls: Class): ptr uint8 {.objcimport.}
proc class_getWeakIvarLayout*(cls: Class): ptr uint8 {.objcimport.}
proc class_setIvarLayout*(cls: Class; layout: ptr uint8) {.objcimport.}
proc class_setWeakIvarLayout*(cls: Class; layout: ptr uint8) {.objcimport.}

proc class_getProperty(cls: Class; name: cstring): Property {.objcimport.}
template getProperty*(cls: Class; name: string): untyped =
  class_getProperty(cls, name.cstring)
# proc get_nsstring*(v: cstring): ID {.objcimport, discardable.}
proc class_copyPropertyList*(cls: Class, outCount: var cuint): ptr Property {.objcimport.}
proc propertyList*(cls: Class): seq[Property] =
  var
    count = 0.cuint
    props = class_copyPropertyList(cls, count)
  if count == 0:
    result = @[]
    return result
  result = newSeq[Property](count)
  copyMem(result[0].addr, props, sizeof(Property) * count.int)
  c_free(props)

proc class_addMethod(cls: Class; name: SEL; imp: IMP; types: cstring): BOOL {.objcimport.}
template addMethod*(cls: Class; name: SEL; imp: IMP; types: string): untyped =
  class_addMethod(cls, name, imp, types.cstring)

proc class_getInstanceMethod(cls: Class; name: SEL): Method {.objcimport.}
template getInstanceMethod*(cls: Class; name: SEL): untyped =
  class_getInstanceMethod(cls, name)

proc class_getClassMethod(cls: Class; name: SEL): Method {.objcimport.}
template getClassMethod*(cls: Class; name: SEL): untyped =
  class_getClassMethod(cls, name)

proc class_copyMethodList(cls: Class; outCount: var cuint): ptr Method {.objcimport.}
proc methodList*(cls: Class): seq[Method] =
  var
    count = 0.cuint
    procs = class_copyMethodList(cls, count)
  if count == 0:
    result = @[]
    return result
  result = newSeq[Method](count)
  copyMem(result[0].addr, procs, sizeof(Method) * count.int)
  c_free(procs)

proc class_replaceMethod(cls: Class; name: SEL; imp: IMP; types: cstring): IMP {.objcimport.}
template replaceMethod*(cls: Class; name: SEL; imp: IMP; types: string): untyped =
  class_replaceMethod(cls, name, imp, types.cstring)

proc class_getMethodImplementation(cls: Class; name: SEL): IMP {.objcimport.}
template getMethodImplementation*(cls: Class; name: SEL): untyped =
  class_getMethodImplementation(cls, name)

proc class_getMethodImplementation_stret*(cls: Class; name: SEL): IMP {.objcimport.}

proc class_respondsToSelector(cls: Class; sel: SEL): BOOL {.objcimport.}
template respondsToSelector*(cls: Class; sel: SEL): untyped =
  class_respondsToSelector(cls, sel)

proc class_addProtocol(cls: Class; protocol: Protocol): BOOL {.objcimport.}
template addProtocol*(cls: Class; protocol: Protocol): untyped =
  class_addProtocol(cls, protocol)

proc class_addProperty(cls: Class; name: cstring;
                       attributes: ptr objc_property_attribute_t;
                       attributeCount: cuint): BOOL {.objcimport.}

proc addProperty*(cls: Class; name: string; attributes: openArray[objc_property_attribute_t]): bool =
  class_addProperty(cls, name.cstring, attributes[0].unsafeAddr, attributes.len.cuint) == YES


proc class_replaceProperty(cls: Class; name: cstring;
                           attributes: ptr objc_property_attribute_t;
                           attributeCount: cuint) {.objcimport.}

proc replaceProperty*(cls: Class; name: string; attributes: openArray[objc_property_attribute_t]) =
  class_replaceProperty(cls, name.cstring, attributes[0].unsafeAddr, attributes.len.cuint)

proc class_conformsToProtocol(cls: Class; protocol: Protocol): BOOL {.objcimport.}
template conformsToProtocol*(cls: Class; protocol: Protocol): bool =
  class_conformsToProtocol(cls, protocol) == YES

proc class_copyProtocolList(cls: Class; outCount: var cuint): ptr Protocol {.objcimport.}
proc protocolList*(cls: Class): seq[Protocol] =
  var
    count = 0.cuint
    prots = class_copyProtocolList(cls, count)
  if count == 0:
    result = @[]
    return result
  result = newSeq[Protocol](count)
  copyMem(result[0].addr, prots, sizeof(Protocol) * count.int)
  c_free(prots)

proc class_getVersion(cls: Class): cint {.objcimport.}
template getVersion*(cls: Class): untyped =
  class_getVersion(cls).int

proc class_setVersion(cls: Class; version: cint) {.objcimport.}
template setVersion*(cls: Class; version: int) =
  class_setVersion(cls, version.cint)

proc objc_getFutureClass(name: cstring): Class {.objcimport.}
template getFutureClass*(name: string): untyped =
  objc_getFutureClass(name.cstring)

proc objc_allocateClassPair(superclass: Class, name: cstring, extraBytes: csize_t): Class {.objcimport.}
template allocateClassPair*(superclass: Class, name: string, extraBytes: int): untyped =
  objc_allocateClassPair(superclass, name.cstring, extrabytes.csize_t)

proc objc_disposeClassPair(cls: Class) {.objcimport.}
template disposeClassPair*(cls: Class) =
  objc_disposeClassPair(cls)

proc objc_registerClassPair(cls: Class) {.objcimport.}
template registerClassPair*(cls: Class) =
  objc_registerClassPair(cls)

proc objc_duplicateClass(original: Class; name: cstring; extraBytes: csize_t): Class {.objcimport.}
template duplicateClass*(original: Class; name: string; extraBytes: int): untyped =
  objc_duplicateClass(original, name.cstring, extraBytes.csize_t)

proc class_createInstance(cls: Class; extraBytes: csize_t): ID {.objcimport.}
template createInstance*(cls: Class; extraBytes: csize_t): untyped =
  class_createInstance(cls, extraBytes.csize_t)

proc objc_constructInstance(cls: Class; bytes: pointer): ID {.objcimport.}
template constructInstance*(cls: Class; bytes: pointer): untyped =
  objc_constructInstance(cls, bytes)

proc objc_destructInstance(obj: ID): pointer {.objcimport.}
template destructInstance*(obj: ID): untyped =
  objc_destructInstance(obj)

proc object_copy(obj: ID; size: csize_t): ID {.objcimport.}
template copy*(obj: ID; size: csize_t): untyped =
  object_copy(obj, size.csize_t)

proc object_dispose(obj: ID): ID {.objcimport.}
template dispose*(obj: ID): untyped =
  object_dispose(obj)

proc object_setInstanceVariable(obj: ID; name: cstring; value: pointer): Ivar {.objcimport.}
template setInstanceVariable*(obj: ID; name: string; value: pointer): untyped =
  object_setInstanceVariable(obj, name.cstring, value)

proc object_getInstanceVariable(obj: ID; name: cstring; outValue: var pointer): Ivar {.objcimport.}
template getInstanceVariable*(obj: ID; name: string; outValue: var pointer): untyped =
  object_getInstanceVariable(obj, name.cstring, outValue)

proc object_getIndexedIvars(obj: ID): pointer {.objcimport.}
template getIndexedIvars*(obj: ID): untyped =
  object_getIndexedIvars(obj)

proc object_getIvar(obj: ID; ivar: Ivar): ID {.objcimport.}
template getIvar*(obj: ID; ivar: Ivar): untyped =
  object_getIvar(obj, ivar)

proc object_setIvar(obj: ID; ivar: Ivar; value: ID) {.objcimport.}
template setIvar*(obj: ID; ivar: Ivar; value: ID) =
  object_setIvar(obj, ivar, value)

proc object_getClassName(obj: ID): cstring {.objcimport.}
proc getClassName*(obj: ID): string =
  result = $object_getClassName(obj)

proc objc_getClass(name: cstring): Class {.objcimport.}
template getClass*(name: string): untyped =
  objc_getClass(name.cstring)

proc object_setClass(obj: ID; cls: Class): Class {.objcimport.}
template setClass*(obj: ID; cls: Class): untyped =
  object_setClass(obj, cls)

proc objc_getClassList(buffer: ptr Class; bufferCount: cint): cint {.objcimport.}
proc getClassList*(): seq[Class] =
  let count = objc_getClassList(nil, 0.cint)
  if count == 0:
    result = @[]
    return result
  result = newSeq[Class](count)
  discard objc_getClassList(result[0].addr, result.len.cint)

proc objc_copyClassList(outCount: var cuint): ptr Class {.objcimport.}

proc copyClassList*(): seq[Class] =
  var
    count = 0.cuint
    classes = objc_copyClassList(count)
  if count == 0:
    result = @[]
    return result
  result = newSeq[Class](count)
  copyMem(result[0].addr, classes, sizeof(Class) * count.int)
  c_free(classes)

proc objc_lookUpClass(name: cstring): Class {.objcimport.}
template lookUpClass*(name: cstring): untyped =
  objc_lookUpClass(name.cstring)

proc object_getClass(obj: ID): Class {.objcimport.}
template getClass*(obj: ID): untyped =
  object_getClass(obj)

proc objc_getRequiredClass(name: cstring): Class {.objcimport.}
template getRequiredClass*(name: string): untyped =
  objc_getRequiredClass(name.cstring)

proc objc_getMetaClass(name: cstring): Class {.objcimport.}
template getMetaClass*(name: string): untyped =
  objc_getMetaClass(name.cstring)

proc ivar_getName(v: Ivar): cstring {.objcimport.}
template getName*(v: Ivar): untyped =
  $ivar_getName(v)

proc `$`*(v: Ivar): string =
  getName(v)

proc ivar_getTypeEncoding(v: Ivar): cstring {.objcimport.}
template getTypeEncoding*(v: Ivar): untyped =
  $ivar_getTypeEncoding(v)

proc ivar_getOffset(v: Ivar): ptrdiff_t {.objcimport.}
template getOffset*(v: Ivar): untyped =
  ivar_getOffset(v)

proc objc_setAssociatedObject(obj: ID; key: pointer; value: ID; policy: objc_AssociationPolicy) {.objcimport.}
template setAssociatedObject*(obj: ID; key: pointer; value: ID; policy: objc_AssociationPolicy) =
  objc_setAssociatedObject(obj, key, value, policy)

proc objc_getAssociatedObject(obj: ID; key: pointer): ID {.objcimport.}
template getAssociatedObject*(obj: ID; key: pointer): untyped =
  objc_getAssociatedObject(obj, key)

proc objc_removeAssociatedObjects(obj: ID) {.objcimport.}
template removeAssociatedObjects*(obj: ID) =
  objc_removeAssociatedObjects(obj)

proc objc_msgSend*(self: ID; op: SEL): ID {.objcimport, discardable, varargs.}


proc objc_msgSend_fpret*(self: ID; op: SEL): cdouble {.objcimport, varargs.}
proc objc_msgSend_stret*(self: ID; op: SEL) {.objcimport, varargs.}
proc objc_msgSendSuper*(super: var ObjcSuper; op: SEL): ID {.objcimport, varargs.}
proc objc_msgSendSuper_stret*(super: var ObjcSuper; op: SEL) {.objcimport, varargs.}
proc method_invoke*(receiver: ID; m: Method): ID {.objcimport, varargs.}
proc method_invoke_stret*(receiver: ID; m: Method) {.objcimport, varargs.}

proc sel_getName*(sel: SEL): cstring {.objcimport.}
template getName*(sel: SEL): untyped =
  $sel_getName(sel)

proc `$`*(sel: SEL): string =
  getName(sel)

proc sel_registerName*(str: cstring): SEL {.objcimport.}
template registerName*(str: string): untyped =
  sel_registerName(str.cstring)

proc `$$`*(str: string): SEL =
  sel_registerName(str.cstring)

proc sel_getUid(str: cstring): SEL {.objcimport.}
template getUid*(str: string): untyped =
  sel_getUid(str.cstring)

proc sel_isEqual(lhs: SEL; rhs: SEL): BOOL {.objcimport.}
template isEqual*(lhs, rhs: SEL): untyped =
  sel_isEqual(lhs, rhs)

proc method_getName(m: Method): SEL {.objcimport.}
template getName*(m: Method): untyped =
  $method_getName(m)

proc `$`*(m: Method): string =
  getName(m)

proc method_getImplementation(m: Method): IMP {.objcimport.}
template getImplementation*(m: Method): untyped =
  method_getImplementation(m)

proc method_getTypeEncoding(m: Method): cstring {.objcimport.}
template getTypeEncoding*(m: Method): untyped =
  $method_getTypeEncoding(m)

proc method_copyReturnType(m: Method): cstring {.objcimport.}
proc copyReturnType*(m: Method): string =
  var ret = method_copyReturnType(m)
  result = $ret
  c_free(ret)

proc method_copyArgumentType(m: Method; index: cuint): cstring {.objcimport.}
proc copyArgumentType*(m: Method; index: int): string =
  var ret = method_copyArgumentType(m, index.cuint)
  result = $ret
  c_free(ret)

proc method_getReturnType(m: Method; dst: cstring; dst_len: csize_t) {.objcimport.}
proc getReturnType*(m: Method): string =
  var ret: array[100, char]
  method_getReturnType(m, cast[cstring](ret[0].addr), sizeof(ret).csize_t)
  result = $(cast[cstring](ret[0].addr))

proc method_getNumberOfArguments(m: Method): cuint {.objcimport.}
template getNumberOfArguments*(m: Method): untyped =
  method_getNumberOfArguments(m).int

proc method_getArgumentType(m: Method; index: cuint; dst: cstring; dst_len: csize_t) {.objcimport.}
proc getArgumentType*(m: Method; index: int): string =
  var ret: array[100, char]
  method_getArgumentType(m, index.cuint, cast[cstring](ret[0].addr), sizeof(ret).csize_t)
  result = $(cast[cstring](ret[0].addr))

proc argumentTypes*(m: Method): seq[string] =
  let count = getNumberOfArguments(m)
  result = newSeq[string](count)
  if count == 0:
    result = @[]
    return result
  for i in 0 ..< count:
    result[i] = getArgumentType(m, i)

proc method_getDescription(m: Method): ptr objc_method_description {.objcimport.}
proc getDescription*(m: Method): MethodDescription =
  var p = method_getDescription(m)
  result.name = p.name
  result.types = $p.types

proc method_setImplementation(m: Method; imp: IMP): IMP {.objcimport.}
template setImplementation*(m: Method; imp: IMP): untyped =
  method_setImplementation(m, imp)

proc method_exchangeImplementations(m1: Method; m2: Method) {.objcimport.}
template exchangeImplementations*(m1: Method; m2: Method) =
  method_exchangeImplementations(m1, m2)

proc objc_copyImageNames(outCount: var cuint): cstringArray {.objcimport.}
proc imageNames*(): seq[string] =
  var
    count = 0.cuint
    images = objc_copyImageNames(count)
  if count == 0:
    result = @[]
    return result
  result = newSeq[string](count.int)
  for i in 0 ..< result.len:
    result[i] = $images[i]

proc class_getImageName(cls: Class): cstring {.objcimport.}
template getImageName*(cls: Class): untyped =
  $class_getImageName(cls)

proc objc_copyClassNamesForImage(image: cstring; outCount: var cuint): cstringArray {.objcimport.}
proc classNamesForImage*(image: string): seq[string] =
  var
    count = 0.cuint
    classes = objc_copyClassNamesForImage(image.cstring, count)
  if count == 0:
    result = @[]
    return result
  result = newSeq[string](count.int)
  for i in 0 ..< result.len:
    result[i] = $classes[i]

proc objc_getProtocol(name: cstring): Protocol {.objcimport.}
template getProtocol*(name: string): untyped =
  objc_getProtocol(name.cstring)

proc objc_copyProtocolList(outCount: var cuint): ptr Protocol {.objcimport.}
proc protocolList*(): seq[Protocol] =
  var
    count = 0.cuint
    prots = objc_copyProtocolList(count)
  if count == 0:
    result = @[]
    return result
  result = newSeq[Protocol](count.int)
  copyMem(result[0].addr, prots, result.len * sizeof(Protocol))
  c_free(prots)

proc objc_allocateProtocol(name: cstring): Protocol {.objcimport.}
template allocateProtocol*(name: string): untyped =
  objc_allocateProtocol(name.cstring)

proc objc_registerProtocol*(proto: Protocol) {.objcimport.}
template registerProtocol*(proto: Protocol) =
  objc_registerProtocol(proto)

proc protocol_addMethodDescription(proto: Protocol; name: SEL; types: cstring;
                                   isRequiredMethod, isInstanceMethod: BOOL) {.objcimport.}

template addMethodDescription*(proto: Protocol; name: SEL; types: string;
                                   isRequiredMethod, isInstanceMethod: BOOL) =
  protocol_addMethodDescription(proto, name, types.cstring, isRequiredMethod, isInstanceMethod)

proc protocol_addProtocol(proto, addition: Protocol) {.objcimport.}
template addProtocol*(proto, addition: Protocol) =
  protocol_addProtocol(proto, addition)

proc protocol_addProperty(proto: Protocol; name: cstring;
                          attributes: ptr objc_property_attribute_t;
                          attributeCount: cuint; isRequiredProperty: BOOL;
                          isInstanceProperty: BOOL) {.objcimport.}

proc addProperty*(proto: Protocol; name: string; attributes: openArray[objc_property_attribute_t],
                          isRequiredProperty, isInstanceProperty: BOOL) =
  protocol_addProperty(proto, name, attributes[0].unsafeAddr, attributes.len.cuint,
    isRequiredProperty, isInstanceProperty)

proc protocol_getName(p: Protocol): cstring {.objcimport.}
template getName*(p: Protocol): untyped =
  $protocol_getName(p)

proc `$`*(p: Protocol): string =
  getName(p)

proc protocol_isEqual(proto, other: Protocol): BOOL {.objcimport.}
template isEqual*(proto, other: Protocol): untyped =
  protocol_isEqual(proto, other)

proc protocol_copyMethodDescriptionList(p: Protocol; isRequiredMethod, isInstanceMethod: BOOL;
  outCount: var cuint): ptr objc_method_description {.objcimport.}

proc methodDescriptionList*(p: Protocol; isRequiredMethod, isInstanceMethod: BOOL): seq[MethodDescription] =
  type
    DescT = array[0..0, objc_method_description]
  var
    count = 0.cuint
    raw = protocol_copyMethodDescriptionList(p, isRequiredMethod, isInstanceMethod, count)
    descs = cast[DescT](raw)
  if count == 0:
    result = @[]
    return result
  result = newSeq[MethodDescription](count.int)
  for i in 0 ..< count.int:
    result[i] = MethodDescription(name: descs[i].name, types: $descs[i].types)
  c_free(raw)

proc protocol_getMethodDescription(p: Protocol; aSel: SEL;
  isRequiredMethod, isInstanceMethod: BOOL): objc_method_description {.objcimport.}

template getMethodDescription*(p: Protocol; aSel: SEL; isRequiredMethod, isInstanceMethod: BOOL): untyped =
  protocol_getMethodDescription(p, aSel, isRequiredMethod, isInstanceMethod)

proc protocol_copyPropertyList(proto: Protocol; outCount: var cuint): ptr Property {.objcimport.}
proc propertyList*(proto: Protocol): seq[Property] =
  var
    count = 0.cuint
    props = protocol_copyPropertyList(proto, count)
  if count == 0:
    result = @[]
    return result
  result = newSeq[Property](count.int)
  copyMem(result[0].addr, props, result.len * sizeof(Property))
  c_free(props)

proc protocol_getProperty(proto: Protocol; name: cstring; isRequiredProperty, isInstanceProperty: BOOL): Property {.objcimport.}
template getProperty*(proto: Protocol; name: string; isRequiredProperty, isInstanceProperty: BOOL): untyped =
  protocol_getProperty(proto, name.cstring, isRequiredProperty, isInstanceProperty)

proc protocol_copyProtocolList*(proto: Protocol, outCount: var cuint): ptr Protocol {.objcimport.}
proc protocolList*(proto: Protocol): seq[Protocol] =
  var
    count = 0.cuint
    prots = protocol_copyProtocolList(proto, count)
  if count == 0:
    result = @[]
    return result
  result = newSeq[Protocol](count.int)
  copyMem(result[0].addr, prots, result.len * sizeof(Protocol))
  c_free(prots)

proc protocol_conformsToProtocol(proto, other: Protocol): BOOL {.objcimport.}
template conformsToProtocol*(proto, other: Protocol): untyped =
  protocol_conformsToProtocol(proto, other)

proc property_getName(property: Property): cstring {.objcimport.}
template getName*(property: Property): untyped =
  $property_getName(property)

proc `$`*(property: Property): string =
  getName(property)

proc property_getAttributes(property: Property): cstring {.objcimport.}
template getAttributes*(property: Property): untyped =
  $property_getAttributes(property)

proc property_copyAttributeList(property: Property; outCount: var cuint): ptr objc_property_attribute_t {.objcimport.}
proc attributeList*(property: Property): seq[PropertyAttribute] =
  type AttrT = array[0..0, objc_property_attribute_t]
  var
    count = 0.cuint
    raw = property_copyAttributeList(property, count)
    attrs = cast[AttrT](raw)
  if count == 0:
    result = @[]
    return result
  result = newSeq[PropertyAttribute](count.int)
  for i in 0 ..< count.int:
    result[i] = PropertyAttribute(name: $attrs[i].name, value: $attrs[i].value)
  c_free(raw)

proc property_copyAttributeValue(property: Property; attributeName: cstring): cstring {.objcimport.}
proc attributeValue*(property: Property; attributeName: string): string =
  var res = property_copyAttributeValue(property, attributeName.cstring)
  result = $res
  c_free(res)

proc objc_enumerationMutation(obj: ID) {.objcimport.}
template enumerationMutation*(obj: ID) =
  objc_enumerationMutation(obj)

type
  EnumerationHandler = proc(a2: ID) {.objccallback.}

proc objc_setEnumerationMutationHandler(handler: EnumerationHandler) {.objcimport.}
template setEnumerationMutationHandler*(handler: EnumerationHandler) =
  objc_setEnumerationMutationHandler(handler)

proc imp_implementationWithBlock(blok: ID): IMP {.objcimport.}
template implementationWithBlock*(blok: ID): untyped =
  imp_implementationWithBlock(blok)

proc imp_getBlock(anImp: IMP): ID {.objcimport.}
template getBlock*(anImp: IMP): untyped =
  imp_getBlock(anImp)

proc imp_removeBlock(anImp: IMP): BOOL {.objcimport.}
template removeBlock*(anImp: IMP): untyped =
  imp_removeBlock(anImp)

proc objc_loadWeak(location: var ID): ID {.objcimport.}
template loadWeak*(location: var ID): untyped =
  objc_loadWeak(location)

proc objc_storeWeak(location: var ID; obj: ID): ID {.objcimport.}
template storeWeak*(location: var ID; obj: ID): untyped =
  objc_storeWeak(location, obj)

proc `@`*(a: string): NSString =
  result.id = objc_msgSend(getClass("NSString").ID, $$"stringWithUTF8String:", a.cstring)

proc transExprColonExpr(son: NimNode): NimNode =
  if son[0].kind == nnkCommand:
    var self = son[0][0]
    var sel = ident(son[0][1].strVal & ":")
    var v = son[1]
    var f = nnkCommand.newTree(self, sel, v)
    var cc = toSeq(son.children)
    for v in cc[2 .. ^1]:
      f.add v
    return f
  else:
    let c = nnkCall.newTree(ident"registerName", ident(son[0].strVal & ":").toStrLit)
    var f = nnkCommand.newTree(c, son[1])
    return f

proc replaceBracket(node: NimNode): NimNode

proc transformNode(node: NimNode): NimNode =
  if node.kind == nnkIdent:
    var m: RegexMatch
    if node.strVal.match(re"^[A-Z]+\w+", m):
      let declaredCall = nnkCall.newTree(ident("declared"), node)
      let isId = nnkInfix.newTree(ident("is"), node, ident("ID"))
      return nnkStmtListExpr.newTree(
        nnkWhenStmt.newTree(
          nnkElifExpr.newTree(
          nnkInfix.newTree(
            ident("and"),
            declaredCall,
            isId
        ),
        node
      ),
          nnkElseExpr.newTree(newCall(ident"ID", nnkCall.newTree(ident"getClass", node.toStrLit)))
        )
      )
    else:
      return node
  elif node.kind == nnkStrLit:
    return newCall(ident"get_nsstring", node)
  elif node.kind == nnkBracket:
    return replaceBracket(node)
  else:
    return node

proc extractSelf(self: NimNode, args: var seq[NimNode]): NimNode =
  case self.kind
  of nnkExprColonExpr:
    case self[0].kind
    of nnkCommand:
      let sel = self[0][1]
      let v = self[1]
      let ce = nnkExprColonExpr.newTree(sel, v)
      args.insert(ce)
      return self[0][0]
    else:
      discard
  of nnkCommand:
    if self[1].kind == nnkIdent:
      args.insert(nnkCall.newTree(ident"registerName", self[1].toStrLit))
    else:
      args.insert(self[1])
    return self[0]
  else:
    discard
  return self

proc replaceBracket(node: NimNode): NimNode =
  if node.kind != nnkBracket:
    return node
  var newnode = newCall(ident"objc_msgSend")
  var child = toSeq(node.children)
  var self = child[0]
  var args = child[1 .. ^1]
  self = extractSelf(self, args)
  newnode.add transformNode(self)
  var positionalArgs = args.filterIt(it.kind != nnkExprColonExpr)
  for pa in positionalArgs:
    newnode.add transformNode(pa)
  var namedArgs = args.filterIt(it.kind == nnkExprColonExpr)
  if namedArgs.len > 0:
    var names = namedArgs.mapIt(it[0].strVal()).join(":") & ":"
    # var values = namedArgs.mapIt( it[1] )
    newnode.add nnkCall.newTree(ident"registerName", newStrLitNode(names))
    for a in namedArgs:
      newnode.add transformNode(a[1])
  return newnode


macro objcr*(arg: untyped): untyped =
  if arg.kind == nnkStmtList:
    result = newStmtList()
    for one in arg:
      case one.kind
      of nnkLetSection:
        if one[^1][^1].kind == nnkBracket:
          var b = nnkLetSection.newTree()
          copyChildrenTo(one, b)
          b[^1][^1] = replaceBracket(one[^1][^1])
          result.add b
        else:
          result.add one
      of nnkVarSection:
        if one[^1][^1].kind == nnkBracket:
          var b = nnkVarSection.newTree()
          copyChildrenTo(one, b)
          b[^1][^1] = replaceBracket(one[^1][^1])
          result.add b
        else:
          result.add one
      of nnkAsgn:
        if one[1].kind == nnkBracket:
          var b = nnkAsgn.newTree()
          copyChildrenTo(one, b)
          b[1] = replaceBracket(one[1])
        else:
          result.add one
      of nnkBracket:
        result.add replaceBracket(one)
      else:
        result.add one
  else:
    result = replaceBracket(arg)

func get_nsstring*(c_str: string): ID =
  return objc_msgSend(getClass("NSString").ID, registerName("stringWithUTF8String:"), c_str.cstring)
