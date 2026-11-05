# ZahraNet (Android, Irancell only)
Creator: فاطمه زهرا ساعي · Core: Aether by CluvexStudio (AGPL-3.0) — credit kept in the app.
UNTESTED scaffold: it was not compiled or run where it was written.

## Build
1. `flutter create --org ir.zahranet --project-name app --platforms=android .`
2. Copy `android_overlay/app/src/main/*` over `android/app/src/main/`
   (replace AndroidManifest.xml; delete the generated MainActivity.kt).
3. Put native files (arm64) here:
   - `android/app/src/main/jniLibs/arm64-v8a/libaether.so`  ← the Aether Linux/Android arm64 binary from the official
     releases (https://github.com/CluvexStudio/Aether), renamed, sha256 verified. Its `pt/` helpers need to be
     executable too (rename them lib*.so in the same folder, or point the core to them).
   - `android/app/src/main/jniLibs/arm64-v8a/libhev-socks5-tunnel.so` ← built from heiher/hev-socks5-tunnel
     (see Mrmmd2004/8vpn for a working reference).
4. In `android/app/build.gradle(.kts)` set `ndk { abiFilters += "arm64-v8a" }` and
   `packaging { jniLibs { useLegacyPackaging = true } }`; minSdk 26.
5. `flutter build apk --release --target-platform android-arm64`

## Irancell lock
`TelephonyManager.simOperator == "43235"` (MCC 432 / MNC 35). It is a client-side check and can be bypassed
by anyone who modifies the APK.
