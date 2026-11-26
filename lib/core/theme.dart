import 'package:flutter/material.dart';

// One place for the app look. Remote Config will switch to the holiday theme later.
class AppTheme {
  static const Color brand = Color(0xFF00796B);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: brand);
    return ThemeData(
      colorScheme: scheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      ),
      cardTheme: const CardThemeData(clipBehavior: Clip.antiAlias),
    );
  }
}
