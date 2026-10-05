# Published APK installation audit — October 5

User reports that the new APK shows “File unsupported” on an ARM64 device while a previous APK installed. Device model, Android version, exact downloaded bytes, and PackageInstaller error code remain unavailable; failure cannot yet be reproduced on the user's device.

Downloaded GitHub build-4-1 APK matches the release SHA-256 `6ba62f56ed7e3184606e30bcf970c9c316ad11d5997f7772e9f6bb22b92a3b83`. ZIP CRC integrity passes, AndroidManifest parses, native ABI is only arm64-v8a, minSdk is 24 (Android 7.0), targetSdk 36. Repository asset filename ends `.apk` and Content-Type is application/vnd.android.package-archive.

Build 2 versionCode 2002 and build 4 versionCode 2004 use the identical RSA signing certificate SHA-256 `ebf23f916209024051497d810821b79ae9b7cf233fc020bfe760eb8b1471a8db`; apksigner verifies v2 signatures. No signer change or version downgrade was found.

On retained Android 14/API34 Google Play emulator, `ro.product.cpu.abilist` reports x86_64,arm64-v8a. Normal `adb install` of build 2 and `adb install -r` of build 4 both returned Success, without ABI override or manifest changes. Build 4 launched and rendered Home. This is ARM64-translated emulator validation, not a claim of testing the user's physical ARM64 phone. The original app package/data were untouched.

Workflow now checks APK ZIP integrity, manifest presence, ARM64-only libraries, and Android signing before publication. README provides a direct APK download rather than a source archive. These checks prevent publishing damaged/unsigned artifacts; they do not establish the cause of the reported file-handler rejection. A package-manager error or the rejected file's hash is needed to distinguish download/file-handler problems from a device-specific rejection. No user record reset or instruction to uninstall was used.
