# Package

version       = "0.2.12"
author        = "bung87"
description   = "Web Technologies based Crossplatform GUI Framework"
license       = "MIT"
srcDir        = "src"
installExt    = @["nim"]

# Dependencies

requires "nim >= 1.1.1"
# requires "nimble >= 0.11.4"

requires "regex"
requires "static_server >= 2.2.1"
requires "jsonschema"
requires "objc_runtime >= 0.1.5"
requires "darwin"
requires "winim"

task docs,"a":
  exec "nim doc --project src/crowngui.nim"
  exec "mv src/htmldocs/theindex.html src/htmldocs/index.html"

task ghpage,"gh page":
  cd "src/htmldocs" 
  exec "git init"
  exec "git add ."
  exec "git config user.name \"bung87\""
  exec "git config user.email \"crc32@qq.com\""
  exec "git commit -m \"docs(docs): update gh-pages\" -n"
  let url = "\"https://bung87@github.com/bung87/crowngui.git\""
  exec "git push --force --quiet " & url & " master:gh-pages"