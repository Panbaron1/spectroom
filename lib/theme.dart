import 'package:flutter/material.dart';

import 'models/challenge.dart';

/// Spectroom palette — calming, low-saturation, warm. The visual quiet is part
/// of the product: predictable, soft, no overstimulation.
class Palette {
  static const bg = Color(0xFFF3F6F4); // warm off-white with a hint of mint
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF2E3A40); // deep slate, softer than black
  static const inkSoft = Color(0xFF6B7A80);

  static const teal = Color(0xFF5FA89E); // hygiene / primary
  static const lavender = Color(0xFF9B8FD4); // medical
  static const peach = Color(0xFFE8A87C); // routine

  // Soft background tints per category (for cards / runner backdrops)
  static const tealTint = Color(0xFFE3F1EE);
  static const lavenderTint = Color(0xFFECE8F7);
  static const peachTint = Color(0xFFFBEADF);

  static Color of(ChallengeCategory c) => switch (c) {
        ChallengeCategory.hygiene => teal,
        ChallengeCategory.medical => lavender,
        ChallengeCategory.routine => peach,
      };

  static Color tintOf(ChallengeCategory c) => switch (c) {
        ChallengeCategory.hygiene => tealTint,
        ChallengeCategory.medical => lavenderTint,
        ChallengeCategory.routine => peachTint,
      };
}

ThemeData buildSpectroomTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: Palette.teal,
    brightness: Brightness.light,
  ).copyWith(
    surface: Palette.surface,
    primary: Palette.teal,
    onSurface: Palette.ink,
  );

  TextTheme nun(TextTheme base) => base
      .apply(fontFamily: 'Nunito', bodyColor: Palette.ink, displayColor: Palette.ink);

  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Nunito',
    colorScheme: scheme,
    scaffoldBackgroundColor: Palette.bg,
    textTheme: nun(ThemeData.light().textTheme),
    appBarTheme: const AppBarTheme(
      backgroundColor: Palette.bg,
      foregroundColor: Palette.ink,
      centerTitle: true,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'Nunito',
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: Palette.ink,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Palette.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Palette.teal,
        foregroundColor: Colors.white,
        minimumSize: const Size(64, 58),
        textStyle: const TextStyle(
            fontFamily: 'Nunito', fontSize: 19, fontWeight: FontWeight.w800),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: UnderlineInputBorder(),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Palette.teal, width: 2),
      ),
    ),
  );
}
