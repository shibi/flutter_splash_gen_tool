import 'package:flutter/material.dart';

/// Brand palette, darkest to lightest.
abstract final class Palette {
  static const navy = Color(0xFF355070);
  static const plum = Color(0xFF6D597A);
  static const rose = Color(0xFFB56576);
  static const coral = Color(0xFFE56B6F);
  static const peach = Color(0xFFEAAC8B);
}

/// Light and dark themes built from [Palette].
abstract final class AppTheme {
  static ThemeData get light {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: Palette.navy,
          brightness: Brightness.light,
        ).copyWith(
          primary: Palette.navy,
          onPrimary: Colors.white,
          secondary: Palette.plum,
          onSecondary: Colors.white,
          tertiary: Palette.rose,
          onTertiary: Colors.white,
          secondaryContainer: const Color(0xFFF7DDD0),
          onSecondaryContainer: Palette.navy,
          surface: const Color(0xFFFCF8F6),
        );
    return _build(scheme);
  }

  static ThemeData get dark {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: Palette.navy,
          brightness: Brightness.dark,
        ).copyWith(
          primary: Palette.peach,
          onPrimary: const Color(0xFF1E2F44),
          secondary: Palette.coral,
          onSecondary: const Color(0xFF2B1618),
          tertiary: Palette.rose,
          onTertiary: Colors.white,
          secondaryContainer: Palette.plum,
          onSecondaryContainer: Colors.white,
          surface: const Color(0xFF1A2433),
          surfaceContainerHighest: const Color(0xFF2A3A50),
        );
    return _build(scheme);
  }

  static ThemeData _build(ColorScheme scheme) {
    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.brightness == Brightness.light
            ? Palette.navy
            : const Color(0xFF223248),
        foregroundColor: Colors.white,
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: Palette.coral,
        thumbColor: Palette.coral,
      ),
    );
  }
}
