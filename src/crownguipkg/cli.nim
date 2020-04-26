import cligen,os
import nimblepkg/[packageinfo,packageparser,options,common,cli]
import json
import plists
import tables
import osproc
import sequtils,sugar


# https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/AboutInformationPropertyListFiles.html#//apple_ref/doc/uid/TP40009254-SW4
type
  CocoaAppInfo = object
    CFBundleDisplayName:string
    CFBundleVersion:string
    CFBundleExecutable:string
    # CFBundleIdentifier:string
    NSHighResolutionCapable:string

proc buildMacos(flags: seq[string]) =
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
    let plist = %* CocoaAppInfo(NSHighResolutionCapable:"True",CFBundleExecutable:pkgInfo.name,CFBundleDisplayName:pkgInfo.name,CFBundleVersion:pkgInfo.version)
    writePlist(plist,appDir / "Info.plist")
    let bin = pkgInfo.bin[0]
    let cmd = ["nimble","build"].map((x: string) => x.quoteShell).join(" ")
    let (output,exitCode) = execCmdEx(cmd & " " &  flags.join(" "))
    if exitCode == 0:
        moveFile(pwd / bin,appDir / bin )
    else:
        echo output

proc build(target:string,flags: seq[string]):int = 
    case target:
        of "macos":
            buildMacos(flags)
dispatchMulti([build])