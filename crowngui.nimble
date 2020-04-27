# Package

version       = "0.1.0"
author        = "bung87"
description   = "A new awesome nimble package"
license       = "MIT"
srcDir        = "src"
installExt    = @["nim"]
bin           = @["crowngui"]



# Dependencies

requires "nim >= 1.1.1"
requires "plists"
requires "cligen"
requires "nimhttpd"
# requires "https://github.com/mjendrusch/objc"
