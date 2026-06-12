# Architecture

## Overview

Spectroom is a single-process Flutter app. All state lives in-memory via `ChangeNotifier` singletons. All persistence is `SharedPreferences` (JSON strings). No network, no backend, no accounts.

```
lib/
├── main.dart               # App entry, init sequence
├── theme.dart              # MaterialTheme + Spectrum colors
├── models/
│   ├── challenge.dart      # Challenge, ChallengeStep, StepKind, ChallengeCategory
│   └── pictogram_ref.dart  # PictogramRef (asset name or device file path)
├── data/
│   ├── challenge_store.dart # ChangeNotifier — owns all challenges + healing logic
│   ├── schedule_store.dart  # ChangeNotifier — reminder entries
│   ├── lang_store.dart      # ChangeNotifier — 'en' | 'cs'
│   ├── seeds.dart           # Const seed challenge definitions
│   ├── asset_icons.dart     # Icon name → asset path mapping
│   ├── mulberry.dart        # Legacy Mulberry SVG refs (unused in v1)
│   └── prefs.dart           # SharedPreferences helpers
├── screens/
│   ├── onboarding_screen.dart
│   ├── home_screen.dart     # Challenge grid + settings drawer
│   ├── runner_screen.dart   # Rehearsal + live modes
│   ├── builder_screen.dart  # Create/edit challenges
│   └── schedule_screen.dart # Daily reminder management
├── services/
│   ├── notification_service.dart # flutter_local_notifications wrapper
│   └── audio_service.dart        # audioplayers wrapper
├── widgets/
│   ├── pictogram_view.dart  # Renders PictogramRef (asset or file)
│   ├── pin_dialog.dart      # 4-digit PIN for builder lock
│   └── spectrum_mesh.dart   # Animated gradient mesh background
└── design/
    └── spectrum.dart        # Palette constants + gradient helpers
```

## Data flow

```
seedChallenges (const)
       │
       ▼
ChallengeStore.load()   ←── SharedPreferences JSON
  • merges seeds + stored
  • heals corrupt labelEn
  • appends new seed steps
       │
       ▼
ChallengeStore (ChangeNotifier)
  ┌────┴──────────────┐
  │                   │
HomeScreen        BuilderScreen
  │
  ▼
RunnerScreen
  • Rehearsal: shows schedule strip, navigates to Live
  • Live: steps through, plays audio, fires celebration
```

## State singletons

| Store | Key | What it holds |
|-------|-----|---------------|
| `ChallengeStore.instance` | `challenges_v1` | All challenges (seeds + custom) |
| `ScheduleStore.instance` | `schedule_entries_v1` | Reminder entries |
| `LangStore.instance` | `lang` | `'en'` or `'cs'` |

## Step kinds

| Kind | Behaviour |
|------|-----------|
| `info` | Show pictogram + label. Tap Next. |
| `countdown` | Count down from N, one tap per tick. |
| `timer` | Visual arc timer for N seconds. Auto-advance on expiry. |

## Healing logic

On every `ChallengeStore.load()`, built-in seeds are reconciled against stored data:

1. Iterate stored steps (preserves user edits)
2. Detect corrupt `labelEn` — either empty or equal to `labelCs` when seed has distinct EN text
3. Restore correct `labelEn` from seed definition
4. Append any new seed steps not yet in stored data

This lets seeds be updated across app versions without overwriting parent customisations.

## Notification scheduling

`ScheduleStore` calls `NotificationService.scheduleDaily()` which wraps `flutter_local_notifications` `zonedSchedule` with `DateTimeComponents.time` for daily repeat. `notifyListeners()` is always called **before** the scheduling/cancel side-effect so UI never blocks on a thrown exception.

## Pictogram system

`PictogramRef` is a sealed-like class with two variants:

- `PictogramRef.asset(name)` — bundled kawaii icon from `assets/icons/`
- `PictogramRef.file(path)` — absolute device path (parent-taken photo)

`PictogramView` renders either via `Image.asset` or `Image.file` with a fallback placeholder.
