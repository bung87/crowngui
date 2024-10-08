import darwin / [objc/runtime]
import darwin/foundation/[nsarray,nsurl]

type OpenCompletionHandler* = proc (self: ID;urls: NSArray[NSURL];): void

type SaveCompletionHandler* = proc (self: ID;allowOverwrite: BOOL; destination: NSString): void

type ConfirmCompletionHandler* = proc (self: ID;b: bool): void

type AlertCompletionHandler* = proc (self: ID;): void
