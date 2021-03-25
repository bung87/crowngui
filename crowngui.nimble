# Package

version       = "0.2.0"
author        = "bung87"
description   = "Web Technologies based Crossplatform GUI Framework"
license       = "MIT"
srcDir        = "src"
installExt    = @["nim"]
bin           = @["crowngui"]



# Dependencies

requires "nim >= 1.1.1"
requires "nimble >= 0.11.4"
requires "plists"
requires "cligen"
requires "https://github.com/bung87/nimhttpd#c5e20a9"
requires "https://github.com/bung87/icon"
