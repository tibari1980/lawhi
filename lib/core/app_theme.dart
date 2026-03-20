import 'package:flutter/material.dart';

class AppTheme {
  // Design: Al-Quran As-Siraj
  // Font: Inter (Local)
  // Font: Amiri (Local)

  static const Color premiumGold = Color(0xFFC5A022); // Satin Gold
  static const Color emeraldGreen = Color(0xFF064E3B);
  static const Color richGold = Color(0xFFD97706);
  static const Color creamWhite = Color(0xFFFFFBEB);
  static const double borderRadius = 16.0;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      colorScheme: ColorScheme.fromSeed(
        seedColor: emeraldGreen,
        primary: emeraldGreen,
        secondary: premiumGold,
        onPrimary: Colors.white,
        surface: creamWhite,
        onSurface: const Color(0xFF1F2937),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFF1F2937),
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: const BorderSide(color: Colors.black12),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: emeraldGreen,
        primary: emeraldGreen,
        secondary: premiumGold,
        surface: const Color(0xFF020617),
        onSurface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: const BorderSide(color: Colors.white10),
        ),
      ),
    );
  }

  // Preset background colors for the "Lawh"
  static const Color creamBackground = Color(0xFFFFFDD0);
  static const Color pastelGreenBackground = Color(0xFFE8F5E9);
  static const Color pastelBlueBackground = Color(0xFFE3F2FD);
}
