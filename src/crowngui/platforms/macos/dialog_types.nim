import darwin / [objc/runtime]

type OpenCompletionHandler* = proc (self: ID;urls: seq[string];): void

type SaveCompletionHandler* = proc (self: ID;allowOverwrite: int; destination: Id): void

type ConfirmCompletionHandler* = proc (self: ID;b: bool): void

type AlertCompletionHandler* = proc (self: ID;): void

type
  NSSavePanel* {.importobjc: "NSSavePanel*", header: "<AppKit/AppKit.h>",
        incompleteStruct.} = object
  NSOpenPanel* {.importobjc: "NSOpenPanel*", header: "<AppKit/AppKit.h>",
    incompleteStruct.} = object