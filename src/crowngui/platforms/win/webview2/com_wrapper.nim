import macros
import winim/inc/windef
import sequtils

macro define_COM_interface*(stmts: untyped) =
  result = stmts
  var vtbls = newSeq[NimNode]()
  var ignoreLens = newSeq[int]()
  var originLen: int
  var methods = newSeq[NimNode]()
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
      var fields = t[^1][^1]
      expectKind(fields, nnkRecList)
      var ignoreLen = 0
      for d in fields:
        expectKind(d, nnkIdentDefs)
        if d[^2].kind != nnkProcTy:
          inc ignoreLen
          continue
        expectKind(d[^2][0], nnkFormalParams)
        var formalParams = d[^2][0]

        expectKind(formalParams[1], nnkIdentDefs)
        # self type
        formalParams[1][1] = nnkPtrTy.newTree(newIdentNode(name))
        # wrap vtbl methods to ptr type
        var procName = d[0][^1].copy
        if procName.strVal == "Invoke":
          # Invoke called from com side, by passing handler, no need wrap
          continue
        var params  = d[^2].params.copy
        var pragma = d[^2].pragma.copy
        
        var call = nnkCall.newTree(
            nnkDotExpr.newTree(
              nnkDotExpr.newTree(
                newIdentNode("self"),
                newIdentNode("lpVtbl")
              ),
              procName
            ),
          )
        let fpLen = formalParams.len
        for i in 1 ..< fpLen:
          call.add(formalParams[i][0].copy)
        var body = nnkStmtList.newTree(call)
        expectKind d[0], nnkPostfix
        methods.add newProc(d[0].copy, toSeq(params.children), body, pragmas = pragma)
      ignoreLens.add ignoreLen
      vtbl = t.copy
      vtbl[0][0][^1] = newIdentNode(name & "VTBL")
      vtbls.add vtbl
      fields.insert(0, lpVtblField)
  for i in 0 ..< vtbls.len:
    var fields = vtbls[i][^1][^1]
    fields.del(fields.len - ignoreLens[i], ignoreLens[i])
    result[0].add vtbls[i]
  
  for i in 0 ..< originLen:
    if result[0][i][^1].kind != nnkObjectTy:
      continue
    var fields = result[0][i][^1][^1]
    var ignoreLen = 0
    for d in fields:
      if d[^2].kind != nnkProcTy:
        inc ignoreLen
    expectKind fields,nnkRecList
    let ll = fields.len
    fields.del(1, ll - (ignoreLen))
  for m in methods:
    result.add m

when isMainModule:

  expandMacros:
    define_COM_interface:
      type
        AA* {.pure.} = object
          get_Settings*: proc (self;): HRESULT