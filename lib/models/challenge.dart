import 'pictogram_ref.dart';

/// What a single step does in the live runner.
enum StepKind {
  /// Just show the pictogram + label. Tap Next to advance.
  info,

  /// Count down [count] → 1, one tap per tick. Rides the kid's love of numbers.
  countdown,

  /// Run a [durationSec] visual timer. "2 minutes in the chair."
  timer,
}

/// Broad bucket for the library grid + color coding.
enum ChallengeCategory { hygiene, medical, routine }

extension ChallengeCategoryX on ChallengeCategory {
  String get labelCs => switch (this) {
        ChallengeCategory.hygiene => 'Hygiena',
        ChallengeCategory.medical => 'Doktor',
        ChallengeCategory.routine => 'Rutina',
      };
  String get labelEn => switch (this) {
        ChallengeCategory.hygiene => 'Hygiene',
        ChallengeCategory.medical => 'Medical',
        ChallengeCategory.routine => 'Routine',
      };
  String label(String lang) => lang == 'en' ? labelEn : labelCs;
}

class ChallengeStep {
  final String id;
  final StepKind kind;
  final PictogramRef pictogram;
  final String labelCs; // primary (he can read short Czech words)
  final String labelEn; // secondary channel
  final int? count; // countdown only
  final int? durationSec; // timer only
  final String? audioPath; // parent voice recording — absolute device path

  const ChallengeStep({
    required this.id,
    required this.kind,
    required this.pictogram,
    required this.labelCs,
    this.labelEn = '',
    this.count,
    this.durationSec,
    this.audioPath,
  });

  String label(String lang) =>
      lang == 'en' && labelEn.isNotEmpty ? labelEn : labelCs;

  ChallengeStep copyWith({
    StepKind? kind,
    PictogramRef? pictogram,
    String? labelCs,
    String? labelEn,
    int? count,
    int? durationSec,
    String? audioPath,
  }) =>
      ChallengeStep(
        id: id,
        kind: kind ?? this.kind,
        pictogram: pictogram ?? this.pictogram,
        labelCs: labelCs ?? this.labelCs,
        labelEn: labelEn ?? this.labelEn,
        count: count ?? this.count,
        durationSec: durationSec ?? this.durationSec,
        audioPath: audioPath ?? this.audioPath,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'pictogram': pictogram.toJson(),
        'labelCs': labelCs,
        'labelEn': labelEn,
        'count': count,
        'durationSec': durationSec,
        'audioPath': audioPath,
      };

  factory ChallengeStep.fromJson(Map<String, dynamic> j) => ChallengeStep(
        id: j['id'] as String,
        kind: StepKind.values.firstWhere(
          (k) => k.name == j['kind'],
          orElse: () => StepKind.info,
        ),
        pictogram:
            PictogramRef.fromJson(j['pictogram'] as Map<String, dynamic>),
        labelCs: j['labelCs'] as String? ?? '',
        labelEn: j['labelEn'] as String? ?? '',
        count: j['count'] as int?,
        durationSec: j['durationSec'] as int?,
        audioPath: j['audioPath'] as String?,
      );
}

class Challenge {
  final String id;
  final String titleCs;
  final String titleEn;
  final ChallengeCategory category;
  final PictogramRef cover;
  final List<ChallengeStep> steps;

  /// Built-in seed (read-only in v1) vs parent-created.
  final bool builtIn;

  const Challenge({
    required this.id,
    required this.titleCs,
    required this.titleEn,
    required this.category,
    required this.cover,
    required this.steps,
    this.builtIn = false,
  });

  String title(String lang) =>
      lang == 'en' && titleEn.isNotEmpty ? titleEn : titleCs;

  Challenge copyWith({
    String? titleCs,
    String? titleEn,
    ChallengeCategory? category,
    PictogramRef? cover,
    List<ChallengeStep>? steps,
  }) =>
      Challenge(
        id: id,
        titleCs: titleCs ?? this.titleCs,
        titleEn: titleEn ?? this.titleEn,
        category: category ?? this.category,
        cover: cover ?? this.cover,
        steps: steps ?? this.steps,
        builtIn: builtIn,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'titleCs': titleCs,
        'titleEn': titleEn,
        'category': category.name,
        'cover': cover.toJson(),
        'steps': steps.map((s) => s.toJson()).toList(),
        'builtIn': builtIn,
      };

  factory Challenge.fromJson(Map<String, dynamic> j) => Challenge(
        id: j['id'] as String,
        titleCs: j['titleCs'] as String,
        titleEn: j['titleEn'] as String? ?? '',
        category: ChallengeCategory.values.firstWhere(
          (c) => c.name == j['category'],
          orElse: () => ChallengeCategory.routine,
        ),
        cover: PictogramRef.fromJson(j['cover'] as Map<String, dynamic>),
        steps: (j['steps'] as List)
            .map((s) => ChallengeStep.fromJson(s as Map<String, dynamic>))
            .toList(),
        builtIn: j['builtIn'] as bool? ?? false,
      );
}
