import darwin / [objc/runtime]

type OpenCompletionHandler* = proc (Id: Id): void

type SaveCompletionHandler* = proc (allowOverwrite: int; destination: Id): void

type ConfirmCompletionHandler* = proc (b: bool): void

type AlertCompletionHandler* = proc (): void
