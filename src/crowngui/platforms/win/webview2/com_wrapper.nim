import macros
import winim/inc/windef

macro define_COM_interface*(stmts: untyped) =
  result = stmts
  var vtbls = newSeq[NimNode]()
  var originLen: int
  for st in result:
    expectKind(st,nnkTypeSection)
    originLen = st.len
    for t in st:
      var vtbl: NimNode
      expectKind(t, nnkTypeDef)
      if t[^1].kind != nnkObjectTy:
        continue
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
        if d[^2].kind == nnkIdent:
          continue
        expectKind(d[^2][0], nnkFormalParams)
        var formalParams = d[^2][0]

        expectKind(formalParams[1], nnkIdentDefs)
        # self type
        formalParams[1][1] = nnkPtrTy.newTree(newIdentNode(name))

      vtbl = t.copy
      vtbl[0][0][^1] = newIdentNode(name & "VTBL")
      vtbls.add vtbl
      t[^1][^1].insert(0, lpVtblField)
  for vtbl in vtbls:
    result[0].add vtbl
  
  for i in 0 ..< originLen:
    if result[0][i][^1].kind != nnkObjectTy:
      continue
    expectKind result[0][i][^1][^1],nnkRecList
    let ll = result[0][i][^1][^1].len
    result[0][i][^1][^1].del(1, ll - 1)

when isMainModule:
  expandMacros:
    #   define_COM_interface:
    define_COM_interface:
      type
        AA* {.pure.} = object
          get_Settings*: proc (self;): HRESULT