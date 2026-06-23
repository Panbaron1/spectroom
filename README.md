# Spectroom

Visual routine and social story app for children with atypical development. Built for parents, used on Android.

Repo: https://github.com/Panbaron1/spectroom

## What it does

- **Step-by-step visual schedules** with pictures and voice recordings
- **Rehearsal mode** — preview the routine before doing it
- **Live guided mode** — step through with a timer and celebration at the end
- **Builder** — create fully custom routines with your own photos and audio
- **Daily reminders** — scheduled notifications to start routines at the right time
- **Bilingual** — English and Czech

## Seeded routines

Brushing teeth · Haircut · Dentist · Clip nails · Bath time · Bedtime · Vaccination · Wash hands · Meal time · Potty

## Stack

Flutter 3.44 · Dart 3.12 · Android · `flutter_local_notifications` · `audioplayers` · `record`

## Build from source

### Run it (any platform with the matching device)

```bash
flutter pub get
flutter run          # debug build to a connected device/emulator
```

The repo contains no signing keys or credentials, so a debug build works out of the box.

### Android release

```bash
flutter build apk --release        # sideloadable APK
flutter build appbundle --release  # Play Store AAB
```

A release build is debug-signed and installs anywhere. A Play Store upload needs your own
`android/key.properties` + keystore (not in repo — bring your own).

### iOS — needs a Mac

iOS can only be compiled on macOS with Xcode (Apple toolchain, no exceptions).

```bash
flutter pub get
flutter run          # with your iPhone connected
```

Before it builds, open `ios/Runner.xcworkspace` in Xcode → **Signing & Capabilities** and:

1. Set **Team** to your own Apple ID (the repo intentionally ships no signing config).
2. Change the **bundle identifier** to something unique to you (e.g. `com.yourname.spectroom`) —
   `com.spectroom.app` is already registered to the original developer.

A **free** Apple ID works but the install expires after 7 days (re-run `flutter run` over cable
to renew). A paid Apple Developer account ($99/yr) is needed for TestFlight / a permanent install.
A `codemagic.yaml` is included for cloud (macOS CI) builds straight to TestFlight.

## Privacy

Privacy policy: https://panbaron1.github.io/spectroom-legal/privacy-policy

All data stored on-device. No analytics, no accounts, no network requests.

## Docs

- [Architecture](docs/architecture.md)
- [Adding seed challenges](docs/adding-seeds.md)
- [Building and releasing](docs/building-and-releasing.md)

## License

MIT
