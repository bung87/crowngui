import cligen,os
import nimblepkg/[packageinfo,packageparser,options,common,cli]
import json
import plists
import tables
import osproc
import sequtils,sugar
import zip/zipfiles
import strformat

# https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/AboutInformationPropertyListFiles.html#//apple_ref/doc/uid/TP40009254-SW4
type
  CocoaAppInfo = object
    CFBundleDisplayName:string
    CFBundleVersion:string
    CFBundleExecutable:string
    # CFBundleIdentifier:string
    NSAppTransportSecurity:JsonNode
    NSHighResolutionCapable:string

proc zipBundle(dir:string):string = 
    var zip:ZipArchive
    let p = getTempDir() / "zipBundle.zip"
    let openSuccess =  zip.open(p,fmWrite)
    if not openSuccess:
        raise newException(OSError,fmt"can't open {p}")
    if not dirExists(dir):
            raise newException(OSError,fmt"dir {dir} not existed.")
    for path in os.walkDirRec(dir):
        zip.addFile( relativePath(path,dir),path)
    zip.close()
    return p

proc buildMacos(wwwroot="",flags: seq[string]) =
    let pwd:string = getCurrentDir()
    var nimbleFile = ""
    try:
        nimbleFile = findNimbleFile(getCurrentDir(), true)
    except: discard
    # PackageInfos are cached so we can read them as many times as we want.
    let options = Options(
        action: Action(typ: actionNil),
        pkgInfoCache: newTable[string, PackageInfo](),
        verbosity: HighPriority
    )
    let pkgInfo = getPkgInfoFromFile(nimbleFile, options)
    let buildDir = pwd / "build" / "macos"
    discard existsOrCreateDir(buildDir)
    let subDir = if "-d:release" in flags: "Release" else: "Debug"
    removeDir( buildDir )
    let appDir = buildDir / subDir / pkgInfo.name & ".app"
    createDir(appDir)
    let NSAppTransportSecurity = %* {"NSAllowsArbitraryLoads":true,
        "NSAllowsLocalNetworking":true,
        "NSExceptionDomains":[
            {"localhost":{"NSExceptionAllowsInsecureHTTPLoads":true}}
            ]
        }
    let plist = %* CocoaAppInfo(NSHighResolutionCapable:"True",CFBundleExecutable:pkgInfo.name,CFBundleDisplayName:pkgInfo.name,CFBundleVersion:pkgInfo.version)
    if len(wwwroot) > 0:
        plist["NSAppTransportSecurity"] = NSAppTransportSecurity
    
    writePlist(plist,appDir / "Info.plist")
    var zip:string
    if len(wwwroot) > 0:
        let path = absolutePath wwwroot
        if not dirExists(path):
            raise newException(OSError,fmt"dir {path} not existed.")
        debugEcho absolutePath wwwroot
        zip = zipBundle(path)
        debugEcho zip
    let cmd = ["nimble","build"].map((x: string) => x.quoteShell).join(" ")
    var rcmd = cmd & " " &  flags.join(" ") 
    let rrcmd = when declared(zip): rcmd & fmt" -d:bundle='{zip}' --threads:on " else:rcmd
    debugEcho rrcmd
    
    let (output,exitCode) = execCmdEx( rrcmd )
    if exitCode == 0:
        debugEcho output
        moveFile(pwd / pkgInfo.name,appDir / pkgInfo.name  )
    else:
        debugEcho output

proc build(target:string,wwwroot="",flags: seq[string]):int = 
    case target:
        of "macos":
            buildMacos(wwwroot,flags)
dispatchMulti([build])