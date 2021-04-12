import jsonschema
import json
import tables
import options
# https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/AboutInformationPropertyListFiles.html#//apple_ref/doc/uid/TP40009254-SW4

jsonSchema:
  Domain:
    NSIncludesSubdomains ?: bool
    NSExceptionAllowsInsecureHTTPLoads ?: bool
    NSExceptionMinimumTLSVersion ?: bool
    NSExceptionRequiresForwardSecrecy ?: bool
    NSRequiresCertificateTransparency ?: bool

  NSAppTransportSecurity:
    NSAllowsArbitraryLoads?:bool
    NSAllowsLocalNetworking?:bool
    NSExceptionDomains ?: any
  DocumentType:
    CFBundleTypeExtensions?:string[]
    CFBundleTypeMIMETypes?:string[]
    CFBundleTypeRole?:string
  CocoaAppInfo:
    CFBundleDisplayName: string
    CFBundleVersion: string
    CFBundleExecutable: string
    CFBundleIdentifier?:string
    CFBundlePackageType ?: string
    NSAppTransportSecurity ?: NSAppTransportSecurity
    NSHighResolutionCapable ?: bool
    CFBundleIconName ?: string
    CFBundleDocumentTypes ?: DocumentType[]
