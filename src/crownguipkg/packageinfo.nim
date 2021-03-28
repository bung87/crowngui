
import jsonschema
import json
type PackageInfo* = object
  name: string
  version: string
  author: string
  desc: string
  license: string
jsonSchema:
  PackageInfoSchema:
    name: string
    version: string
    author: string
    desc: string
    license: string
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


