import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFF5F5DC), // Beige/Cream base
        primary: const Color(0xFF2E7D32), // Deep Green
        secondary: const Color(0xFFFFCC80), // Pastel Orange
        surface: const Color(0xFFF9FBE7), // Light Pastel Green
      ),
      textTheme: GoogleFonts.interTextTheme(),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: const Color(0xFF1B5E20),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    );
  }

  // Preset background colors for the "Lawh"
  static const Color creamBackground = Color(0xFFFFFDD0);
  static const Color pastelGreenBackground = Color(0xFFE8F5E9);
  static const Color pastelBlueBackground = Color(0xFFE3F2FD);
}
