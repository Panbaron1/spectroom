import 'package:flutter/material.dart';

import '../models/challenge.dart';

/// The Spectroom brand: a calm, desaturated pastel **spectrum**. The name is a
/// spectrum wordplay, so the spectrum is the identity — categories are points
/// along it, and the signature timer ring literally sweeps through it.
class Spectrum {
  // Calm pastel spectrum stops
  static const coral = Color(0xFFEFA79E);
  static const amber = Color(0xFFF1C889);
  static const mint = Color(0xFF8FD3B6);
  static const sky = Color(0xFF93C2E6);
  static const lavender = Color(0xFFBCACE4);

  /// Ordered stops for a left→right spectrum.
  static const stops = [coral, amber, mint, sky, lavender];

  /// Looped stops for a seamless sweep (ring).
  static const sweep = [coral, amber, mint, sky, lavender, coral];

  // Neutrals — near-white, minimal, lots of air
  static const ink = Color(0xFF21262B);
  static const inkSoft = Color(0xFF79838C);
  static const bg = Color(0xFFFBFBFC);
  static const surface = Colors.white;

  /// Primary action — a deep spectrum-teal that reads premium on buttons.
  static const primary = Color(0xFF3FA98F);

  /// Light tint of any color (for card backdrops).
  static Color tint(Color c, [double t = 0.86]) =>
      Color.lerp(c, Colors.white, t)!;

  /// A soft horizontal spectrum gradient (brand wordmark, hero accents).
  static const LinearGradient brand = LinearGradient(
    colors: [coral, amber, mint, sky, lavender],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Category → a distinct point on the spectrum
  static Color accent(ChallengeCategory c) => switch (c) {
        ChallengeCategory.hygiene => mint,
        ChallengeCategory.routine => amber,
        ChallengeCategory.medical => lavender,
      };

  static Color accentTint(ChallengeCategory c) => tint(accent(c));
}
