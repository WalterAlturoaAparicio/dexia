import 'package:flutter/material.dart';

/// DexIA design tokens – all colors, radii and text styles live here.
/// Never hardcode colors elsewhere; always reference AppTheme.
abstract class AppTheme {
  // ── Brand colors ──────────────────────────────────────────────────────────
  static const Color green = Color(0xFF80BA27);
  static const Color greenDark = Color(0xFF5F8F1A);
  static const Color greenLight = Color(0xFFE8F5D0);
  static const Color navy = Color(0xFF2C3E50);
  static const Color bg = Color(0xFFF4F6F7);
  static const Color white = Color(0xFFFFFFFF);
  static const Color grayLight = Color(0xFFBDC3C7);

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF27AE60);
  static const Color warning = Color(0xFFF39C12);
  static const Color error = Color(0xFFE74C3C);

  // ── Confidence thresholds ─────────────────────────────────────────────────
  static Color confidenceColor(double conf) {
    if (conf >= 0.85) return success;
    if (conf >= 0.60) return warning;
    return grayLight;
  }

  static String confidenceLabel(double conf) {
    if (conf >= 0.85) return '¡Muy probable!';
    if (conf >= 0.60) return 'Posible';
    return 'Incierto';
  }

  static IconData confidenceIcon(double conf) {
    if (conf >= 0.85) return Icons.check_circle_rounded;
    if (conf >= 0.60) return Icons.help_rounded;
    return Icons.remove_circle_outline;
  }

  // ── Border radius ─────────────────────────────────────────────────────────
  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 20;
  static const double radiusXl = 24;

  // ── Elevation ─────────────────────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  // ── MaterialApp theme ─────────────────────────────────────────────────────
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: green,
          primary: green,
          secondary: navy,
          surface: bg,
          onPrimary: white,
          onSecondary: white,
        ),
        scaffoldBackgroundColor: bg,
        fontFamily: 'Nunito',
        appBarTheme: const AppBarTheme(
          backgroundColor: navy,
          foregroundColor: white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: white,
          ),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
              fontSize: 28, fontWeight: FontWeight.w800, color: navy),
          titleLarge: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w800, color: navy),
          titleMedium: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: navy),
          bodyLarge: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600, color: navy),
          bodyMedium: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: navy),
          bodySmall: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: green,
            foregroundColor: white,
            textStyle: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMd),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: navy,
            side: const BorderSide(color: navy, width: 1.5),
            textStyle: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMd),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      );
}