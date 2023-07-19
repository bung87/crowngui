import std/[strutils]

const
  jsTemplate = """
    if (typeof $2 === 'undefined') {
      $2 = {};
    }
    $2.$1 = (arg) => {
      window.external.invoke(
        JSON.stringify(
          {scope: "$2", name: "$1", args: JSON.stringify(arg)}
        )
      );
    };
  """.strip
  jsTemplateOnlyArg = """
    if (typeof $2 === 'undefined') {
      $2 = {};
    }
    $2.$1 = (arg) => {
      window.external.invoke(
        JSON.stringify(
          {scope: "$2", name: "$1", args: JSON.stringify(arg)}
        )
      );
    };
  """.strip
  jsTemplateNoArg = """
    if (typeof $2 === 'undefined') {
      $2 = {};
    }
    $2.$1 = () => {
      window.external.invoke(
        JSON.stringify(
          {scope: "$2", name: "$1", args: ""}
        )
      );
    };
  """.strip
  cssInjectFunction = """
  (function(e){window.onload = function(){
  var t=document.createElement('style'),d=document.head||document.getElementsByTagName('head')[0];
  t.setAttribute('type','text/css');
  t.styleSheet?t.styleSheet.cssText=e:t.appendChild(document.createTextNode(e)),d.appendChild(t);
  }})
  """.strip.unindent

func jsEncode(s: string): string =
  result = newStringOfCap(s.len * 4) # Allocate reasonable buffer size
  var n = s.len * 4
  var r = 1 # At least one byte for trailing zero
  for c in s:
    let byte = c.uint8
    if byte >= 0x20 and byte < 0x80 and c notin {'<', '>', '\\', '\'', '"'}:
      if n > 0:
        result.add c
        dec(n)
      r += 1
    else:
      if n > 0:
        result.add "\\x" & byte.toHex(2)
        n -= 4 # We add 4 bytes, so we want to subtract 4 from remaining space
      r += 4