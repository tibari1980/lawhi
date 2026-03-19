import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/quran_models.dart';

class AppSettings {
  final double fontSize;
  final double scrollSpeed;
  final Color backgroundColor;
  final String language;
  final bool showTranslation;
  final String translationLanguage; // 'Français', 'English', 'None'
  final bool showPhonetics;
  final Riwaya riwaya;

  AppSettings({
    required this.fontSize,
    required this.scrollSpeed,
    required this.backgroundColor,
    required this.language,
    required this.showTranslation,
    required this.translationLanguage,
    required this.showPhonetics,
    required this.riwaya,
  });

  AppSettings copyWith({
    double? fontSize,
    double? scrollSpeed,
    Color? backgroundColor,
    String? language,
    bool? showTranslation,
    String? translationLanguage,
    bool? showPhonetics,
    Riwaya? riwaya,
  }) {
    return AppSettings(
      fontSize: fontSize ?? this.fontSize,
      scrollSpeed: scrollSpeed ?? this.scrollSpeed,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      language: language ?? this.language,
      showTranslation: showTranslation ?? this.showTranslation,
      translationLanguage: translationLanguage ?? this.translationLanguage,
      showPhonetics: showPhonetics ?? this.showPhonetics,
      riwaya: riwaya ?? this.riwaya,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier()
      : super(AppSettings(
          fontSize: 30.0,
          scrollSpeed: 10.0,
          backgroundColor: const Color(0xFF0F172A),
          language: 'العربية',
          showTranslation: false,
          translationLanguage: 'None',
          showPhonetics: false,
          riwaya: Riwaya.warsh,
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

  void setLanguage(String lang) {
    state = state.copyWith(language: lang);
  }

  void setShowTranslation(bool show) {
    state = state.copyWith(showTranslation: show);
  }

  void setTranslationLanguage(String lang) {
    state = state.copyWith(
      translationLanguage: lang,
      showTranslation: lang != 'None',
    );
  }

  void setShowPhonetics(bool show) {
    state = state.copyWith(showPhonetics: show);
  }

  void setRiwaya(Riwaya riwaya) {
    state = state.copyWith(riwaya: riwaya);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});
