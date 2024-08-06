when defined(macosx):
  switch("passC", "-Wno-incompatible-function-pointer-types")
  when defined(arm64):
    switch("passC", "-arch arm64")
    switch("passL", "-arch arm64")
  when defined(amd64):
    switch("passC", "-arch x86_64")
    switch("passL", "-arch x86_64")
    switch("passC", "-target x86_64-apple-macos10.12")
    switch("passL", "-target x86_64-apple-macos10.12")