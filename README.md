# Android Nougat APK Patcher
Patches Nougat APKs to use User Certificate Authorities so you can setup tools like mitmproxy


      nimble install cligen
      nim c patcher.nim

# Usage

	patcher <path to APK>

### Dependencies

- apktool
- java >= 1.8
- keytool
- zipalign
- apksigner
