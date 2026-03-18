import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Stitch Design: Lawhi-app
  // Custom Color: #F2B90D (Gold)
  // Roundness: 12.0 (ROUND_TWELVE)
  // Font: Inter

  static const Color goldAccent = Color(0xFFF2B90D);
  static const Color brandRed = Color(0xFFC62828);
  static const Color brandGreen = Color(0xFF2E7D32);
  static const double borderRadius = 12.0;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: goldAccent,
        primary: goldAccent,
        secondary: brandGreen,
        tertiary: brandRed,
        surface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: brandRed,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      textTheme: GoogleFonts.interTextTheme(),
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: goldAccent,
        primary: goldAccent,
        secondary: brandGreen,
        tertiary: brandRed,
        surface: const Color(0xFF121212),
        onSurface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: brandRed,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  // Preset background colors for the "Lawh"
  static const Color creamBackground = Color(0xFFFFFDD0);
  static const Color pastelGreenBackground = Color(0xFFE8F5E9);
  static const Color pastelBlueBackground = Color(0xFFE3F2FD);
}
