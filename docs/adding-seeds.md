# Adding seed challenges

Seed challenges are defined in `lib/data/seeds.dart` as compile-time constants.

## Step-by-step

### 1. Add icon assets (if needed)

Place PNG files in `assets/icons/`. Register the name in `lib/data/asset_icons.dart`:

```dart
'my_icon': 'assets/icons/my_icon.png',
```

### 2. Define the challenge in `seeds.dart`

```dart
Challenge(
  id: 'seed.my_challenge',          // must be unique, never change after shipping
  titleCs: 'Můj rozvrh',
  titleEn: 'My routine',
  category: ChallengeCategory.routine,  // hygiene | medical | routine
  cover: const PictogramRef.asset('my_icon'),
  builtIn: true,
  steps: [
    const ChallengeStep(
      id: 'my_challenge.1',          // must be unique within challenge
      kind: StepKind.info,           // info | countdown | timer
      pictogram: PictogramRef.asset('sit'),
      labelCs: 'Sedneme si',
      labelEn: 'Sit down',
    ),
    const ChallengeStep(
      id: 'my_challenge.wait',
      kind: StepKind.timer,
      pictogram: PictogramRef.asset('wait'),
      labelCs: 'Čekáme',
      labelEn: 'Wait',
      durationSec: 120,              // timer only
    ),
    const ChallengeStep(
      id: 'my_challenge.count',
      kind: StepKind.countdown,
      pictogram: PictogramRef.asset('clip_nails'),
      labelCs: 'Počítáme',
      labelEn: 'Count',
      count: 10,                     // countdown only
    ),
  ],
),
```

### 3. Register asset in `pubspec.yaml`

If the icon is new, add it to the `flutter > assets` section (or ensure the `assets/icons/` glob covers it).

### 4. Healing

If you add new steps to an **existing** seed (steps the user already has stored), the `ChallengeStore` healing logic will append them automatically on next load. Existing user customisations are preserved.

**Never change a step `id` after shipping** — the healing logic uses step IDs as stable keys. Changing an ID makes the step appear as new and the old stored version becomes an orphan.

## Step kind reference

| Kind | Required fields | Behaviour |
|------|----------------|-----------|
| `info` | `labelCs`, `pictogram` | Tap Next to advance |
| `timer` | `durationSec` | Arc timer, auto-advance on expiry |
| `countdown` | `count` | Count from N down to 1, one tap per tick |
