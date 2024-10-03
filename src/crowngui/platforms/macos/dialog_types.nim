import darwin / [objc/runtime]

type OpenCompletionHandler* = proc (self: ID;urls: seq[string];): void

type SaveCompletionHandler* = proc (self: ID;allowOverwrite: BOOL; destination: NSString): void

type ConfirmCompletionHandler* = proc (self: ID;b: bool): void

type AlertCompletionHandler* = proc (self: ID;): void
