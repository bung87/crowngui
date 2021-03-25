
type PackageInfo* = object
  name*: string
  ## The version specified in the .nimble file.Assuming info is non-minimal,
  ## it will always be a non-special version such as '0.1.4'.
  ## If in doubt, use `getConcreteVersion` instead.
  version*: string
  author*: string
  # description*: string
  # license*: string
  # skipDirs*: seq[string]
  # skipFiles*: seq[string]
  # skipExt*: seq[string]
  # installDirs*: seq[string]
  # installFiles*: seq[string]
  # installExt*: seq[string]
  # # requires*: seq[PkgTuple]
  # # bin*: Table[string, string]
  # binDir*: string
  # srcDir*: string
  # backend*: string
  # foreignDeps*: seq[string]
