import 'package:flutter/material.dart';

/// Calm, predictable theme. No high-saturation noise, large touch targets,
/// generous spacing — the visual quiet is part of the product, not polish.
ThemeData buildSpectroomTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF5B8DEF), // soft blue
    brightness: Brightness.light,
  ).copyWith(surface: const Color(0xFFF7F9FC));

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      centerTitle: true,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 56),
        textStyle:
            const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );
}
