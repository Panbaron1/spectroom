import 'package:flutter/material.dart';

import 'design/spectrum.dart';
import 'models/challenge.dart';

/// Back-compat palette facade — existing screens reference Palette.*, now backed
/// by the Spectrum brand. New work should use Spectrum directly.
class Palette {
  static const bg = Spectrum.bg;
  static const surface = Spectrum.surface;
  static const ink = Spectrum.ink;
  static const inkSoft = Spectrum.inkSoft;

  static const teal = Spectrum.primary;
  static const lavender = Spectrum.lavender;
  static const peach = Spectrum.amber;

  static final tealTint = Spectrum.tint(Spectrum.mint);
  static final lavenderTint = Spectrum.tint(Spectrum.lavender);
  static final peachTint = Spectrum.tint(Spectrum.amber);

  static Color of(ChallengeCategory c) => Spectrum.accent(c);
  static Color tintOf(ChallengeCategory c) => Spectrum.accentTint(c);
}

/// Spacing / radius tokens — never eyeball values.
class Gap {
  static const xs = 6.0, sm = 10.0, md = 16.0, lg = 24.0, xl = 36.0;
}

class Radii {
  static const sm = 14.0, md = 20.0, lg = 28.0, xl = 36.0;
}

ThemeData buildSpectroomTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: Spectrum.primary,
    brightness: Brightness.light,
  ).copyWith(surface: Spectrum.surface, onSurface: Spectrum.ink);

  TextTheme geist(TextTheme b) => b.apply(
      fontFamily: 'Geist',
      bodyColor: Spectrum.ink,
      displayColor: Spectrum.ink);

  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Geist',
    colorScheme: scheme,
    scaffoldBackgroundColor: Spectrum.bg,
    textTheme: geist(ThemeData.light().textTheme),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Spectrum.ink,
      centerTitle: true,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'Geist',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: Spectrum.ink,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Spectrum.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Spectrum.ink,
        foregroundColor: Colors.white,
        minimumSize: const Size(64, 56),
        textStyle: const TextStyle(
            fontFamily: 'Geist',
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md)),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: UnderlineInputBorder(),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Spectrum.primary, width: 2),
      ),
    ),
  );
}
