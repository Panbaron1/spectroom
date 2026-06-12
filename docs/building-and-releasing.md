# Building and releasing

## Prerequisites

- Flutter 3.44+ / Dart 3.12+
- Android SDK (API 21+)
- Java 17+

## Debug build

```bash
flutter run
```

Connects to the first available device/emulator.

## Release build (APK — sideload)

```bash
flutter build apk --release
# output: build/app/outputs/flutter-apk/app-release.apk
```

## Release build (AAB — Play Store)

```bash
flutter build appbundle --release
# output: build/app/outputs/bundle/release/app-release.aab
```

## Signing

Signing config is in `android/app/build.gradle.kts`. It reads from `android/key.properties`:

```
storePassword=...
keyPassword=...
keyAlias=spectroom
storeFile=../spectroom-release.keystore
```

Both `key.properties` and `spectroom-release.keystore` are gitignored. Keep them backed up separately — losing the keystore means you cannot update the Play Store listing.

## Versioning

Version is in `pubspec.yaml`:

```yaml
version: 1.0.0+1   # name+code
```

Bump `+1` (build number / versionCode) on every Play Store upload. Bump the semantic version for user-visible releases.

## Play Store

- Package: `com.spectroom.app`
- Track: closed testing → production
- Privacy policy: https://panbaron1.github.io/spectroom-legal/privacy-policy
- Min SDK: 21 (Android 5.0)
- Target SDK: 35
