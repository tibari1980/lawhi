import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/quran_models.dart';

class AppSettings {
  final double fontSize;
  final double scrollSpeed;
  final Color backgroundColor;
  final String language;
  final bool showPhonetics;
  final Riwaya riwaya;

  AppSettings({
    required this.fontSize,
    required this.scrollSpeed,
    required this.backgroundColor,
    required this.language,
    required this.showPhonetics,
    required this.riwaya,
  });

  AppSettings copyWith({
    double? fontSize,
    double? scrollSpeed,
    Color? backgroundColor,
    String? language,
    bool? showPhonetics,
    Riwaya? riwaya,
  }) {
    return AppSettings(
      fontSize: fontSize ?? this.fontSize,
      scrollSpeed: scrollSpeed ?? this.scrollSpeed,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      language: language ?? this.language,
      showPhonetics: showPhonetics ?? this.showPhonetics,
      riwaya: riwaya ?? this.riwaya,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  final SharedPreferences _prefs;

  static const String _keyFontSize = 'fontSize';
  static const String _keyScrollSpeed = 'scrollSpeed';
  static const String _keyBackgroundColor = 'backgroundColor';
  static const String _keyLanguage = 'language';
  static const String _keyShowPhonetics = 'showPhonetics';
  static const String _keyRiwaya = 'riwaya';

  SettingsNotifier(this._prefs)
      : super(AppSettings(
          fontSize: _prefs.getDouble(_keyFontSize) ?? 30.0,
          scrollSpeed: _prefs.getDouble(_keyScrollSpeed) ?? 10.0,
          backgroundColor: Color(_prefs.getInt(_keyBackgroundColor) ?? 0xFF0F172A),
          language: _prefs.getString(_keyLanguage) ?? 'العربية',
          showPhonetics: _prefs.getBool(_keyShowPhonetics) ?? false,
          riwaya: Riwaya.values.firstWhere(
            (r) => r.name == _prefs.getString(_keyRiwaya),
            orElse: () => Riwaya.warsh,
          ),
        ));

  void setFontSize(double size) {
    state = state.copyWith(fontSize: size);
    _prefs.setDouble(_keyFontSize, size);
  }

  void setScrollSpeed(double speed) {
    state = state.copyWith(scrollSpeed: speed);
    _prefs.setDouble(_keyScrollSpeed, speed);
  }

  void setBackgroundColor(Color color) {
    state = state.copyWith(backgroundColor: color);
    _prefs.setInt(_keyBackgroundColor, color.toARGB32());
  }

  void setLanguage(String lang) {
    state = state.copyWith(language: lang);
    _prefs.setString(_keyLanguage, lang);
  }


  void setShowPhonetics(bool show) {
    state = state.copyWith(showPhonetics: show);
    _prefs.setBool(_keyShowPhonetics, show);
  }

  void setRiwaya(Riwaya riwaya) {
    state = state.copyWith(riwaya: riwaya);
    _prefs.setString(_keyRiwaya, riwaya.name);
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsNotifier(prefs);
});
