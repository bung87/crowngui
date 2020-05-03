import cligen,os
import nimblepkg/[packageinfo,packageparser,options,common,cli]
import json
import plists
import tables
import osproc
import sequtils
import zip/zipfiles
import strformat
import icon

const DEBUG_OPTS = " --verbose --debug "
const RELEASE_OPTS = " -d:release -d:noSignalHandler --exceptions:quirky"
# https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/AboutInformationPropertyListFiles.html#//apple_ref/doc/uid/TP40009254-SW4
type
  CocoaAppInfo = object
    CFBundleDisplayName:string
    CFBundleVersion:string
    CFBundleExecutable:string
    # CFBundleIdentifier:string
    NSAppTransportSecurity:JsonNode
    NSHighResolutionCapable:string

proc getPkgInfo():PackageInfo = 
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
    return pkgInfo

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

proc handleBundle(wwwroot:string):string = 
    var zip:string
    if len(wwwroot) > 0:
        let path = absolutePath wwwroot
        if not dirExists(path):
            raise newException(OSError,fmt"dir {path} not existed.")
        debugEcho path
        zip = zipBundle(path)
        debugEcho zip
    return zip

proc baseCmd(base:seq[string],wwwroot:string,release:bool,flags:seq[string]):seq[string] = 
    let zip = handleBundle(wwwroot)
    if len(wwwroot) > 0:
        result.add fmt" -d:bundle='{zip}'"
    result.add "--threads:on"
    discard result.concat flags
    let opts = if not release: DEBUG_OPTS  else: RELEASE_OPTS
    result.add opts

proc buildMacos(wwwroot="",release=false,flags: seq[string]) =
    let pwd:string = getCurrentDir()
    let pkgInfo = getPkgInfo()
    let buildDir = pwd / "build" / "macos"
    discard existsOrCreateDir(buildDir)
    let subDir = if release: "Release" else: "Debug"
    removeDir( buildDir )
    let appDir = buildDir / subDir / pkgInfo.name & ".app"
    createDir(appDir)
    let NSAppTransportSecurity = %* {"NSAllowsArbitraryLoads":true,
        "NSAllowsLocalNetworking":true,
        "NSExceptionDomains":[
            {"localhost":{"NSExceptionAllowsInsecureHTTPLoads":true}}
            ]
        }
    var plist = %* CocoaAppInfo(NSHighResolutionCapable:"True",CFBundleExecutable:pkgInfo.name,CFBundleDisplayName:pkgInfo.name,CFBundleVersion:pkgInfo.version)
    if len(wwwroot) > 0:
        plist["NSAppTransportSecurity"] = NSAppTransportSecurity
    let app_logo = getCurrentDir() / "logo.png"
    if existsFile(app_logo):
        let img = ImageInfo(size:32,filePath:app_logo)
        let opts = ICNSOptions()
        let path = generateICNS(@[img],appDir,opts)
        plist["CFBundleIconFile"] =  newJString(extractFilename path)
    writePlist(plist,appDir / "Info.plist")
    var cmd = baseCmd(@["nimble","build"],wwwroot,release,flags)
    let finalCMD = cmd.join(" ")
    debugEcho finalCMD
    let (output,exitCode) = execCmdEx( finalCMD )
    if exitCode == 0:
        debugEcho output
        moveFile(pwd / pkgInfo.name,appDir / pkgInfo.name  )
    else:
        debugEcho output

proc runMacos(wwwroot="",release=false,flags: seq[string]) =
    let pkgInfo = getPkgInfo()
    var cmd = baseCmd(@["nimble"],wwwroot,release,flags)
    let finalCMD = cmd.concat(@["run",pkgInfo.name]).join(" ")
    debugEcho finalCMD
    let (output,exitCode) = execCmdEx( finalCMD )
    if exitCode == 0:
        debugEcho output
    else:
        debugEcho output

proc buildWindows(wwwroot="",release=false,flags: seq[string]) = 
    let app_logo = getCurrentDir() / "logo.png"
    let logoExists = existsFile(app_logo)
    var res:string
    var output:string
    var exitCode:int
    if logoExists:
        let img = ImageInfo(size:32,filePath:app_logo)
        let opts = ICOOptions()
        let path = generateICO(@[img],getTempDir(),opts)
        let content = &"id ICON \"{path}\""
        let rc = getTempDir() / "my.rc"
        writeFile(rc,content)
        res = getTempDir() / "my.res"
        let resCmd = &"windres {rc} -O coff -o {res}"
        (output,exitCode) = execCmdEx( resCmd )
    var myflags = @["-d:mingw"]
    var cmd = baseCmd(@["nimble","build"],wwwroot,release,myflags.concat flags)
    if logoExists and exitCode == 0:
        discard cmd.concat @[&"--passL:{res}"]
        debugEcho output
    else:
        debugEcho output
    
    let finalCMD = cmd.join(" ")
    debugEcho finalCMD
    let (o,e) = execCmdEx( finalCMD )
    if e == 0:
        debugEcho o
    else:
        debugEcho o

proc build(target:string,wwwroot="",release=false,flags: seq[string]):int = 
    case target:
        of "macos":
            # nim c -r -f src/crownguipkg/cli.nim build --target macos --wwwroot ./docs 
            buildMacos(wwwroot,release,flags)
        of "windows":
            buildWindows(wwwroot,release,flags)

proc run(target:string,wwwroot="",release=false,flags: seq[string]):int = 
    case target:
        of "macos":
            # nim c -r -f src/crownguipkg/cli.nim run --target macos --wwwroot ./docs 
            runMacos(wwwroot,release,flags)

dispatchMulti([build],[run])