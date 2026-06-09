import '../models/challenge.dart';
import '../models/pictogram_ref.dart';

final List<Challenge> seedChallenges = [
  // ── MEDICAL (shown first — top row) ───────────────────────
  Challenge(
    id: 'seed.doctor',
    titleCs: 'U doktora',
    titleEn: 'Doctor',
    category: ChallengeCategory.medical,
    cover: const PictogramRef.asset('doctor'),
    steps: [
      const ChallengeStep(id: 'doctor.1', kind: StepKind.info, pictogram: PictogramRef.asset('door'), labelCs: 'Přijdeme k doktorovi', labelEn: 'Arrive at doctor'),
      const ChallengeStep(id: 'doctor.2', kind: StepKind.info, pictogram: PictogramRef.asset('weigh'), labelCs: 'Zvážíme a změříme', labelEn: 'Weigh and measure'),
      const ChallengeStep(id: 'doctor.3', kind: StepKind.timer, pictogram: PictogramRef.asset('stethoscope'), labelCs: 'Doktor poslechne', labelEn: 'Doctor listens', durationSec: 90),
      const ChallengeStep(id: 'doctor.4', kind: StepKind.info, pictogram: PictogramRef.asset('star'), labelCs: 'Byli jsme stateční', labelEn: 'We were brave'),
    ],
  ),
  Challenge(
    id: 'seed.dentist',
    titleCs: 'U zubaře',
    titleEn: 'Dentist',
    category: ChallengeCategory.medical,
    cover: const PictogramRef.asset('dentist'),
    steps: [
      const ChallengeStep(id: 'dentist.1', kind: StepKind.info, pictogram: PictogramRef.asset('door'), labelCs: 'Jdeme do ordinace', labelEn: 'Going to the clinic'),
      const ChallengeStep(id: 'dentist.2', kind: StepKind.info, pictogram: PictogramRef.asset('chair'), labelCs: 'Kouzelné křeslo jezdí nahoru a dolů', labelEn: 'Magic chair goes up and down'),
      const ChallengeStep(id: 'dentist.3', kind: StepKind.info, pictogram: PictogramRef.asset('sit'), labelCs: 'Sedíš u maminky na klíně', labelEn: 'You sit on mummy\'s lap'),
      const ChallengeStep(id: 'dentist.4', kind: StepKind.info, pictogram: PictogramRef.asset('dentist'), labelCs: 'Sloní chobot pije vodu, foukátko fouká', labelEn: 'Elephant trunk drinks water, blower blows air'),
      const ChallengeStep(id: 'dentist.5', kind: StepKind.countdown, pictogram: PictogramRef.asset('dentist_look'), labelCs: 'Spočítáme všechny zoubky!', labelEn: 'Let\'s count all your teeth!', count: 20),
      const ChallengeStep(id: 'dentist.6', kind: StepKind.info, pictogram: PictogramRef.asset('reward_box'), labelCs: 'Vyber si odměnu z krabičky!', labelEn: 'Pick a reward from the box!'),
      const ChallengeStep(id: 'dentist.7', kind: StepKind.info, pictogram: PictogramRef.asset('star'), labelCs: 'Byl jsi skvělý!', labelEn: 'You were amazing!'),
    ],
  ),
  // ── HYGIENE ────────────────────────────────────────────────
  Challenge(
    id: 'seed.nails',
    titleCs: 'Stříhání nehtů',
    titleEn: 'Clip nails',
    category: ChallengeCategory.hygiene,
    cover: const PictogramRef.asset('clip_nails'),
    steps: [
      const ChallengeStep(id: 'nails.1', kind: StepKind.info, pictogram: PictogramRef.asset('sit'), labelCs: 'Sedneme si', labelEn: 'Sit down'),
      const ChallengeStep(id: 'nails.2', kind: StepKind.info, pictogram: PictogramRef.asset('hands'), labelCs: 'Ukážeme ruce', labelEn: 'Show hands'),
      const ChallengeStep(id: 'nails.3', kind: StepKind.countdown, pictogram: PictogramRef.asset('clip_nails'), labelCs: 'Deset nehtů', labelEn: 'Ten nails', count: 10),
    ],
  ),
  Challenge(
    id: 'seed.teeth',
    titleCs: 'Čištění zubů',
    titleEn: 'Brush teeth',
    category: ChallengeCategory.hygiene,
    cover: const PictogramRef.asset('brush_teeth'),
    steps: [
      const ChallengeStep(id: 'teeth.1', kind: StepKind.info, pictogram: PictogramRef.asset('toothpaste'), labelCs: 'Pasta na kartáček', labelEn: 'Paste on brush'),
      const ChallengeStep(id: 'teeth.2', kind: StepKind.timer, pictogram: PictogramRef.asset('toothbrush'), labelCs: 'Čistíme dvě minuty', labelEn: 'Brush two minutes', durationSec: 120),
      const ChallengeStep(id: 'teeth.3', kind: StepKind.info, pictogram: PictogramRef.asset('rinse'), labelCs: 'Vyplácháme pusu', labelEn: 'Rinse'),
    ],
  ),
  Challenge(
    id: 'seed.haircut',
    titleCs: 'Stříhání vlasů',
    titleEn: 'Cut hair',
    category: ChallengeCategory.hygiene,
    cover: const PictogramRef.asset('haircut'),
    steps: [
      const ChallengeStep(id: 'haircut.1', kind: StepKind.info, pictogram: PictogramRef.asset('sit'), labelCs: 'Sedneme si', labelEn: 'Sit down'),
      const ChallengeStep(id: 'haircut.2', kind: StepKind.info, pictogram: PictogramRef.asset('gown'), labelCs: 'Dáme pláštěnku', labelEn: 'Put on cape'),
      const ChallengeStep(id: 'haircut.3', kind: StepKind.timer, pictogram: PictogramRef.asset('cut_hair'), labelCs: 'Stříháme', labelEn: 'Cutting', durationSec: 180),
    ],
  ),
  // ── ROUTINE ────────────────────────────────────────────────
  Challenge(
    id: 'seed.dressed',
    titleCs: 'Oblékání',
    titleEn: 'Get dressed',
    category: ChallengeCategory.routine,
    cover: const PictogramRef.asset('get_dressed'),
    steps: [
      const ChallengeStep(id: 'dressed.1', kind: StepKind.info, pictogram: PictogramRef.asset('pants'), labelCs: 'Spodní prádlo', labelEn: 'Underwear'),
      const ChallengeStep(id: 'dressed.2', kind: StepKind.info, pictogram: PictogramRef.asset('tshirt'), labelCs: 'Tričko', labelEn: 'Shirt'),
      const ChallengeStep(id: 'dressed.3', kind: StepKind.info, pictogram: PictogramRef.asset('trousers'), labelCs: 'Kalhoty', labelEn: 'Trousers'),
      const ChallengeStep(id: 'dressed.4', kind: StepKind.info, pictogram: PictogramRef.asset('socks'), labelCs: 'Ponožky', labelEn: 'Socks'),
      const ChallengeStep(id: 'dressed.5', kind: StepKind.info, pictogram: PictogramRef.asset('shoes'), labelCs: 'Boty', labelEn: 'Shoes'),
    ],
  ),
  Challenge(
    id: 'seed.handwash',
    titleCs: 'Mytí rukou',
    titleEn: 'Wash hands',
    category: ChallengeCategory.hygiene,
    cover: const PictogramRef.asset('faucet'),
    steps: [
      const ChallengeStep(id: 'handwash.1', kind: StepKind.info, pictogram: PictogramRef.asset('faucet'), labelCs: 'Pustíme vodu', labelEn: 'Turn on water'),
      const ChallengeStep(id: 'handwash.2', kind: StepKind.info, pictogram: PictogramRef.asset('hands'), labelCs: 'Namočíme ruce', labelEn: 'Wet hands'),
      const ChallengeStep(id: 'handwash.3', kind: StepKind.info, pictogram: PictogramRef.asset('soap'), labelCs: 'Mýdlo', labelEn: 'Soap'),
      const ChallengeStep(id: 'handwash.4', kind: StepKind.timer, pictogram: PictogramRef.asset('hands'), labelCs: 'Myjeme ruce', labelEn: 'Wash hands', durationSec: 20),
      const ChallengeStep(id: 'handwash.5', kind: StepKind.info, pictogram: PictogramRef.asset('rinse'), labelCs: 'Opláchnutí', labelEn: 'Rinse'),
      const ChallengeStep(id: 'handwash.6', kind: StepKind.info, pictogram: PictogramRef.asset('towel'), labelCs: 'Utřeme ruce', labelEn: 'Dry hands'),
    ],
  ),
  Challenge(
    id: 'seed.bath',
    titleCs: 'Koupání',
    titleEn: 'Bath time',
    category: ChallengeCategory.hygiene,
    cover: const PictogramRef.asset('bathtub'),
    steps: [
      const ChallengeStep(id: 'bath.1', kind: StepKind.info, pictogram: PictogramRef.asset('bathtub'), labelCs: 'Jdeme se koupat', labelEn: 'Time for a bath'),
      const ChallengeStep(id: 'bath.2', kind: StepKind.info, pictogram: PictogramRef.asset('soap'), labelCs: 'Umyjeme se mýdlem', labelEn: 'Wash with soap'),
      const ChallengeStep(id: 'bath.3', kind: StepKind.timer, pictogram: PictogramRef.asset('bathtub'), labelCs: 'Ve vaně', labelEn: 'In the tub', durationSec: 120),
      const ChallengeStep(id: 'bath.4', kind: StepKind.countdown, pictogram: PictogramRef.asset('rinse'), labelCs: 'Oplácháme vlasy', labelEn: 'Rinse hair', count: 5),
      const ChallengeStep(id: 'bath.5', kind: StepKind.info, pictogram: PictogramRef.asset('pajamas'), labelCs: 'Pyžamo', labelEn: 'Pyjamas'),
    ],
  ),
  Challenge(
    id: 'seed.bedtime',
    titleCs: 'Dobrou noc',
    titleEn: 'Bedtime',
    category: ChallengeCategory.routine,
    cover: const PictogramRef.asset('moon'),
    steps: [
      const ChallengeStep(id: 'bedtime.1', kind: StepKind.info, pictogram: PictogramRef.asset('pajamas'), labelCs: 'Pyžamo', labelEn: 'Pyjamas'),
      const ChallengeStep(id: 'bedtime.2', kind: StepKind.info, pictogram: PictogramRef.asset('toothbrush'), labelCs: 'Zuby', labelEn: 'Brush teeth'),
      const ChallengeStep(id: 'bedtime.3', kind: StepKind.timer, pictogram: PictogramRef.asset('book'), labelCs: 'Pohádka', labelEn: 'Story time', durationSec: 600),
      const ChallengeStep(id: 'bedtime.4', kind: StepKind.info, pictogram: PictogramRef.asset('moon'), labelCs: 'Dobrou noc', labelEn: 'Goodnight'),
    ],
  ),
  Challenge(
    id: 'seed.vaccination',
    titleCs: 'Očkování',
    titleEn: 'Vaccination',
    category: ChallengeCategory.medical,
    cover: const PictogramRef.asset('syringe'),
    steps: [
      const ChallengeStep(id: 'vaccination.1', kind: StepKind.info, pictogram: PictogramRef.asset('door'), labelCs: 'Přijdeme k doktorovi', labelEn: 'Arrive at doctor'),
      const ChallengeStep(id: 'vaccination.2', kind: StepKind.info, pictogram: PictogramRef.asset('sit'), labelCs: 'Sedíš u maminky', labelEn: 'Sit with mummy'),
      const ChallengeStep(id: 'vaccination.3', kind: StepKind.timer, pictogram: PictogramRef.asset('syringe'), labelCs: 'Rychlé pípnutí', labelEn: 'Quick pinch', durationSec: 5),
      const ChallengeStep(id: 'vaccination.4', kind: StepKind.info, pictogram: PictogramRef.asset('plaster'), labelCs: 'Náplast', labelEn: 'Plaster'),
      const ChallengeStep(id: 'vaccination.5', kind: StepKind.info, pictogram: PictogramRef.asset('reward_box'), labelCs: 'Odměna!', labelEn: 'Reward!'),
    ],
  ),
];
