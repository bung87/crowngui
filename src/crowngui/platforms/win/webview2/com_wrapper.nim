# import macros

# macro define_COM_interface(type_decl: typedesc) =
#   ## Extract the interface name and method information from the type declaration
#   const interface_name = type_decl.ident()
#   const method_args = type_decl.fielddecls[0].type.params.map(proc (p: expr) : string = p.type.repr())

#   ## Define the interface and vtbl structs
#   type `$interface_name`* {.pure.} = object
#     lpVtbl*: ptr `$interface_name`Vtbl

#   type `$interface_name Vtbl`* = object
#     ## Define the entries of the vtbl struct
#     QueryInterface: proc(self: ptr `$interface_name`; riid: REFIID; ppvObject: ptr pointer): HRESULT {.stdcall.}
#     AddRef: proc(self: ptr `$interface_name`): ULONG {.stdcall.}
#     Release: proc(self: ptr `$interface_name`): ULONG {.stdcall.}
#     ## Add your other methods here
#   for i in countup(0, len(method_args), 3):
#     (`{method_args[i]}`)*: proc(self: `$interface_name`; `{method_args[i+1]}`): `{method_args[i+2]}` {.stdcall.}

#   ## Define the IID constant
#   const IID_`$interface_name` = IID_$interface_name

# define_COM_interface:
#   type MyInterface = object
#     get_Settings*: proc (self: ptr MyInterface;): HRESULT