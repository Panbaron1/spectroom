import '../models/challenge.dart';
import '../models/pictogram_ref.dart';

/// The 6 built-in challenges, now using Mulberry Symbols (CC BY-SA) bundled in
/// assets/pictograms/. Parents can still add custom challenges with their own
/// photos or other Mulberry symbols via the builder.
final List<Challenge> seedChallenges = [
  // ── HYGIENE ────────────────────────────────────────────────
  Challenge(
    id: 'seed.nails',
    titleCs: 'Stříhání nehtů',
    titleEn: 'Clip nails',
    category: ChallengeCategory.hygiene,
    cover: const PictogramRef.mulberry('clip_nails'),
    steps: [
      const ChallengeStep(id: 'nails.1', kind: StepKind.info, pictogram: PictogramRef.mulberry('sit'), labelCs: 'Sedneme si', labelEn: 'Sit down'),
      const ChallengeStep(id: 'nails.2', kind: StepKind.info, pictogram: PictogramRef.mulberry('hands'), labelCs: 'Ukážeme ruce', labelEn: 'Show hands'),
      const ChallengeStep(id: 'nails.3', kind: StepKind.countdown, pictogram: PictogramRef.mulberry('clip_nails'), labelCs: 'Deset nehtů', labelEn: 'Ten nails', count: 10),
      const ChallengeStep(id: 'nails.4', kind: StepKind.info, pictogram: PictogramRef.mulberry('star'), labelCs: 'Hotovo!', labelEn: 'All done!'),
    ],
  ),
  Challenge(
    id: 'seed.teeth',
    titleCs: 'Čištění zubů',
    titleEn: 'Brush teeth',
    category: ChallengeCategory.hygiene,
    cover: const PictogramRef.mulberry('brush_teeth'),
    steps: [
      const ChallengeStep(id: 'teeth.1', kind: StepKind.info, pictogram: PictogramRef.mulberry('toothpaste'), labelCs: 'Pasta na kartáček', labelEn: 'Paste on brush'),
      const ChallengeStep(id: 'teeth.2', kind: StepKind.timer, pictogram: PictogramRef.mulberry('toothbrush'), labelCs: 'Čistíme dvě minuty', labelEn: 'Brush two minutes', durationSec: 120),
      const ChallengeStep(id: 'teeth.3', kind: StepKind.info, pictogram: PictogramRef.mulberry('rinse'), labelCs: 'Vyplácháme pusu', labelEn: 'Rinse'),
      const ChallengeStep(id: 'teeth.4', kind: StepKind.info, pictogram: PictogramRef.mulberry('star'), labelCs: 'Hotovo!', labelEn: 'All done!'),
    ],
  ),
  Challenge(
    id: 'seed.haircut',
    titleCs: 'Stříhání vlasů',
    titleEn: 'Cut hair',
    category: ChallengeCategory.hygiene,
    cover: const PictogramRef.mulberry('haircut'),
    steps: [
      const ChallengeStep(id: 'haircut.1', kind: StepKind.info, pictogram: PictogramRef.mulberry('sit'), labelCs: 'Sedneme si', labelEn: 'Sit down'),
      const ChallengeStep(id: 'haircut.2', kind: StepKind.info, pictogram: PictogramRef.mulberry('gown'), labelCs: 'Dáme pláštěnku', labelEn: 'Put on cape'),
      const ChallengeStep(id: 'haircut.3', kind: StepKind.timer, pictogram: PictogramRef.mulberry('cut_hair'), labelCs: 'Stříháme', labelEn: 'Cutting', durationSec: 180),
      const ChallengeStep(id: 'haircut.4', kind: StepKind.info, pictogram: PictogramRef.mulberry('star'), labelCs: 'Hotovo!', labelEn: 'All done!'),
    ],
  ),
  // ── ROUTINE ────────────────────────────────────────────────
  Challenge(
    id: 'seed.dressed',
    titleCs: 'Oblékání',
    titleEn: 'Get dressed',
    category: ChallengeCategory.routine,
    cover: const PictogramRef.mulberry('get_dressed'),
    steps: [
      const ChallengeStep(id: 'dressed.1', kind: StepKind.info, pictogram: PictogramRef.mulberry('pants'), labelCs: 'Spodní prádlo', labelEn: 'Underwear'),
      const ChallengeStep(id: 'dressed.2', kind: StepKind.info, pictogram: PictogramRef.mulberry('tshirt'), labelCs: 'Tričko', labelEn: 'Shirt'),
      const ChallengeStep(id: 'dressed.3', kind: StepKind.info, pictogram: PictogramRef.mulberry('trousers'), labelCs: 'Kalhoty', labelEn: 'Trousers'),
      const ChallengeStep(id: 'dressed.4', kind: StepKind.info, pictogram: PictogramRef.mulberry('socks'), labelCs: 'Ponožky', labelEn: 'Socks'),
      const ChallengeStep(id: 'dressed.5', kind: StepKind.info, pictogram: PictogramRef.mulberry('shoes'), labelCs: 'Boty', labelEn: 'Shoes'),
      const ChallengeStep(id: 'dressed.6', kind: StepKind.info, pictogram: PictogramRef.mulberry('star'), labelCs: 'Hotovo!', labelEn: 'All done!'),
    ],
  ),
  // ── MEDICAL ────────────────────────────────────────────────
  Challenge(
    id: 'seed.dentist',
    titleCs: 'U zubaře',
    titleEn: 'Dentist',
    category: ChallengeCategory.medical,
    cover: const PictogramRef.mulberry('dentist'),
    steps: [
      const ChallengeStep(id: 'dentist.1', kind: StepKind.info, pictogram: PictogramRef.mulberry('door'), labelCs: 'Přijdeme do ordinace', labelEn: 'Arrive at clinic'),
      const ChallengeStep(id: 'dentist.2', kind: StepKind.info, pictogram: PictogramRef.mulberry('chair'), labelCs: 'Sedneme do křesla', labelEn: 'Sit in the chair'),
      const ChallengeStep(id: 'dentist.3', kind: StepKind.timer, pictogram: PictogramRef.mulberry('dentist_look'), labelCs: 'Pan doktor se podívá', labelEn: 'Dentist looks', durationSec: 120),
      const ChallengeStep(id: 'dentist.4', kind: StepKind.info, pictogram: PictogramRef.mulberry('stickers'), labelCs: 'Dostaneme samolepku', labelEn: 'Get a sticker'),
      const ChallengeStep(id: 'dentist.5', kind: StepKind.info, pictogram: PictogramRef.mulberry('star'), labelCs: 'Hotovo!', labelEn: 'All done!'),
    ],
  ),
  Challenge(
    id: 'seed.doctor',
    titleCs: 'U doktora',
    titleEn: 'Doctor',
    category: ChallengeCategory.medical,
    cover: const PictogramRef.mulberry('doctor'),
    steps: [
      const ChallengeStep(id: 'doctor.1', kind: StepKind.info, pictogram: PictogramRef.mulberry('door'), labelCs: 'Přijdeme k doktorovi', labelEn: 'Arrive at doctor'),
      const ChallengeStep(id: 'doctor.2', kind: StepKind.info, pictogram: PictogramRef.mulberry('weigh'), labelCs: 'Zvážíme a změříme', labelEn: 'Weigh and measure'),
      const ChallengeStep(id: 'doctor.3', kind: StepKind.timer, pictogram: PictogramRef.mulberry('stethoscope'), labelCs: 'Doktor poslechne', labelEn: 'Doctor listens', durationSec: 90),
      const ChallengeStep(id: 'doctor.4', kind: StepKind.info, pictogram: PictogramRef.mulberry('star'), labelCs: 'Byli jsme statečný', labelEn: 'We were brave'),
      const ChallengeStep(id: 'doctor.5', kind: StepKind.info, pictogram: PictogramRef.mulberry('finish'), labelCs: 'Hotovo!', labelEn: 'All done!'),
    ],
  ),
];
