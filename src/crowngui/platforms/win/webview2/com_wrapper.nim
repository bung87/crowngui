import macros
import winim/inc/windef

macro define_COM_interface*(stmts: untyped) =
  result = stmts
  var vtbl: NimNode
  for st in result:
    expectKind(st,nnkTypeSection)
    for t in st:
      expectKind(t, nnkTypeDef)
      expectKind(t[0], nnkPragmaExpr)
      expectKind(t[0][0], nnkPostfix)
      let nameNode = t[0][0][^1]
      let name = nameNode.strVal
      var lpVtblField = nnkIdentDefs.newTree(
            nnkPostfix.newTree(
              newIdentNode("*"),
              newIdentNode("lpVtbl")
            ),
            nnkPtrTy.newTree(
              newIdentNode(name & "VTBL")
            ),
            newEmptyNode()
      )
      expectKind(t[^1], nnkObjectTy)
      expectKind(t[^1][^1], nnkRecList)
      for d in t[^1][^1]:
        expectKind(d, nnkIdentDefs)
        # expectKind(d[^2], nnkProcTy)
        expectKind(d[^2][0], nnkFormalParams)
        var formalParams = d[^2][0]

        expectKind(formalParams[1], nnkIdentDefs)
        # self type
        formalParams[1][1] = nnkPtrTy.newTree(newIdentNode(name))

      vtbl = t.copy
      vtbl[0][0][^1] = newIdentNode(name & "VTBL")
      t[^1][^1].insert(0, lpVtblField)

  result[0].add vtbl
  expectKind result[0][0][^1][^1],nnkRecList
  let ll = result[0][0][^1][^1].len
  result[0][0][^1][^1].del(1, ll - 1)

when isMainModule:
  expandMacros:
    #   define_COM_interface:
    define_COM_interface:
      type
        AA* {.pure.} = object
          get_Settings*: proc (self;): HRESULT