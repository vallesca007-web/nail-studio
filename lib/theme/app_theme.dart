import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const background = Color(0xFFFBF7F6);
  static const surface = Colors.white;
  static const accent = Color(0xFF8E3F5A);
  static const button = Color(0xFF1F1B1C);
  static const softPink = Color(0xFFFCE4EA);
  static const heroPink = Color(0xFFFFC2D1);
  static const field = Color(0xFFF5F1F0);
  static const text = Color(0xFF292526);
  static const muted = Color(0xFF81777A);
  static const disabled = Color(0xFFD8D1D1);

  static TextStyle get labelStyle => GoogleFonts.plusJakartaSans(
    color: accent,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.4,
  );

  static TextStyle get titleStyle =>
      GoogleFonts.playfairDisplay(color: text, fontWeight: FontWeight.w600);

  static ThemeData get theme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        primary: accent,
        secondary: softPink,
        surface: surface,
      ),
      scaffoldBackgroundColor: background,
      textTheme: ThemeData.light().textTheme.apply(
        fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
        bodyColor: text,
        displayColor: text,
      ),
    );
    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: field,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: accent, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
