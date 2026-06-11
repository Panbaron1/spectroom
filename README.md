# Spectroom

Visual routine and social story app for children with atypical development. Built for parents, used on Android.

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

## Build

```bash
flutter build appbundle --release
```

Requires `android/key.properties` and `android/spectroom-release.keystore` (not in repo).

## Privacy

Privacy policy: https://panbaron1.github.io/spectroom-legal/privacy-policy

All data stored on-device. No analytics, no accounts, no network requests.

## License

MIT
