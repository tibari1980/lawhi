import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppSettings {
  final double fontSize;
  final double scrollSpeed;
  final Color backgroundColor;

  AppSettings({
    required this.fontSize,
    required this.scrollSpeed,
    required this.backgroundColor,
  });

  AppSettings copyWith({
    double? fontSize,
    double? scrollSpeed,
    Color? backgroundColor,
  }) {
    return AppSettings(
      fontSize: fontSize ?? this.fontSize,
      scrollSpeed: scrollSpeed ?? this.scrollSpeed,
      backgroundColor: backgroundColor ?? this.backgroundColor,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier()
      : super(AppSettings(
          fontSize: 30.0,
          scrollSpeed: 10.0,
          backgroundColor: const Color(0xFF0F172A),
        ));

  void setFontSize(double size) {
    state = state.copyWith(fontSize: size);
  }

  void setScrollSpeed(double speed) {
    state = state.copyWith(scrollSpeed: speed);
  }

  void setBackgroundColor(Color color) {
    state = state.copyWith(backgroundColor: color);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});
