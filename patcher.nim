import os, strutils

proc checkTool(cmd: string) =
    var res = execShellCmd(cmd)
    if res > 0 and res != 2:
        raise newException(LibraryError, "Missing tool (" & $res & ") " & cmd)

proc decodeApk(apk: string) =
    copyFile(apk, "_aux.apk")
    if execShellCmd("apktool d _aux.apk") > 0:
        raise newException(LibraryError, "Decode APK failed")

proc rebuildApk() =
    if execShellCmd("apktool b _aux") > 0:
        raise newException(LibraryError, "Rebuild APK failed")
    removeFile("_aux.apk")
    moveFile("_aux/dist/_aux.apk", "_aux.apk")

proc injectSecurityXml() =
    writeFile("_aux/res/xml/network_security_config.xml", """
<network-security-config>    
   <base-config>  
      <trust-anchors>
          <certificates src="system" />
          <certificates src="user" />
      </trust-anchors>
   </base-config>
</network-security-config>
    """)
    var manifest = readFile("_aux/AndroidManifest.xml")
    var smanifest = manifest.split("<application ")
    manifest = smanifest[0] & """<application android:networkSecurityConfig="@xml/network_security_config" """ & smanifest[1]
    writeFile("_aux/AndroidManifest.xml", manifest)

proc generateKeystore() =
    if execShellCmd("""keytool -genkey -noprompt -alias random-alias -keyalg RSA -dname "CN=any.com, OU=ID, O=IBM, L=Hursley, S=Hants, C=SP" -keypass changeit -storepass changeit -keystore keystore.jks""") > 0:
        raise newException(LibraryError, "Generate Keystore failed")

proc alignApk() =
    if execShellCmd("zipalign -v -p 4 _aux.apk aligned.apk") > 0:
        raise newException(LibraryError, "Align APK failed")

proc signApk() =
    if execShellCmd("apksigner sign --ks keystore.jks --ks-pass pass:changeit --out release-patched.apk aligned.apk") > 0:
        raise newException(LibraryError, "Sign APK failed")

proc clean() =
    removeDir("_aux")
    removeFile("_aux.apk")
    removeFile("aligned.apk")
    removeFile("keystore.jks")

proc patchapk(path: seq[string]): int =
    checkTool "apktool"
    checkTool "java -version"
    checkTool "keytool"
    checkTool "zipalign"
    checkTool "apksigner"
    
    if len(path) > 0:
        decodeApk(path[0])
        injectSecurityXml()
        rebuildApk()
        generateKeystore()
        alignApk()
        signApk()
        clean()
    else:
        echo "You must specify the APK"
    return 0

when isMainModule: import cligen; dispatch patchapk


