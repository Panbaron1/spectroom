/// Pictogram abstraction — the swappable image layer.
///
/// Challenges reference a pictogram by [kind] + [value], never by a hardcoded
/// library path. This is the seam that lets us test with emoji/ARASAAC now and
/// ship Mulberry Symbols (CC BY-SA, commercial-safe) later with zero content
/// rework. Rendering lives in widgets/pictogram_view.dart.
enum PictogramKind {
  /// Unicode emoji char(s) — zero-asset placeholder, always renders.
  emoji,

  /// Mulberry Symbol asset name (no extension), under assets/pictograms/.
  mulberry,

  /// AI-generated kawaii icon name (no extension), under assets/icons/.
  asset,

  /// Absolute file path to a parent-supplied photo in the app docs dir.
  photo,
}

class PictogramRef {
  final PictogramKind kind;

  /// emoji char | mulberry asset basename | absolute photo path.
  final String value;

  const PictogramRef.emoji(this.value) : kind = PictogramKind.emoji;
  const PictogramRef.mulberry(this.value) : kind = PictogramKind.mulberry;
  const PictogramRef.asset(this.value) : kind = PictogramKind.asset;
  const PictogramRef.photo(this.value) : kind = PictogramKind.photo;

  const PictogramRef._(this.kind, this.value);

  Map<String, dynamic> toJson() => {'kind': kind.name, 'value': value};

  factory PictogramRef.fromJson(Map<String, dynamic> j) => PictogramRef._(
        PictogramKind.values.firstWhere(
          (k) => k.name == j['kind'],
          orElse: () => PictogramKind.emoji,
        ),
        j['value'] as String,
      );
}
