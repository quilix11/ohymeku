// lib/services/settings_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { light, dark }
enum AccentColor { green, blue, purple, orange }

class SettingsService extends ChangeNotifier {
  static const _keyTheme = 'theme_mode';
  static const _keyAccent = 'accent_color';
  static const _keyTtsSpeed = 'tts_speed';
  static const _keyTtsEnabled = 'tts_enabled';
  static const _keySfxEnabled = 'sfx_enabled';
  static const _keyAutoSend = 'auto_send';
  static const _keyTtsVoice = 'tts_voice'; // 0=male,1=female
  static const _keyUiLang = 'ui_lang'; // 'uk','en'

  AppThemeMode _themeMode = AppThemeMode.light;
  AccentColor _accentColor = AccentColor.green;
  double _ttsSpeed = 1.0;
  bool _ttsEnabled = true;
  bool _sfxEnabled = true;
  bool _autoSend = true;
  int _ttsVoice = 0;
  String _uiLang = 'uk';

  AppThemeMode get themeMode => _themeMode;
  AccentColor get accentColor => _accentColor;
  double get ttsSpeed => _ttsSpeed;
  bool get ttsEnabled => _ttsEnabled;
  bool get sfxEnabled => _sfxEnabled;
  bool get autoSend => _autoSend;
  int get ttsVoice => _ttsVoice;
  String get uiLang => _uiLang;

  bool get isDark => _themeMode == AppThemeMode.dark;

  Color get primaryColor {
    switch (_accentColor) {
      case AccentColor.green: return const Color(0xFF58CC02);
      case AccentColor.blue: return const Color(0xFF1CB0F6);
      case AccentColor.purple: return const Color(0xFF9B59B6);
      case AccentColor.orange: return const Color(0xFFFF9600);
    }
  }

  Color get primaryDarkColor {
    switch (_accentColor) {
      case AccentColor.green: return const Color(0xFF46A302);
      case AccentColor.blue: return const Color(0xFF0E8FCC);
      case AccentColor.purple: return const Color(0xFF7D3C98);
      case AccentColor.orange: return const Color(0xFFCC7A00);
    }
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = AppThemeMode.values[prefs.getInt(_keyTheme) ?? 0];
    _accentColor = AccentColor.values[prefs.getInt(_keyAccent) ?? 0];
    _ttsSpeed = prefs.getDouble(_keyTtsSpeed) ?? 1.0;
    _ttsEnabled = prefs.getBool(_keyTtsEnabled) ?? true;
    _sfxEnabled = prefs.getBool(_keySfxEnabled) ?? true;
    _autoSend = prefs.getBool(_keyAutoSend) ?? true;
    _ttsVoice = prefs.getInt(_keyTtsVoice) ?? 0;
    _uiLang = prefs.getString(_keyUiLang) ?? 'uk';
    notifyListeners();
  }

  Future<void> setTheme(AppThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyTheme, mode.index);
    notifyListeners();
  }

  Future<void> setAccent(AccentColor color) async {
    _accentColor = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyAccent, color.index);
    notifyListeners();
  }

  Future<void> setTtsSpeed(double speed) async {
    _ttsSpeed = speed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyTtsSpeed, speed);
    notifyListeners();
  }

  Future<void> setTtsEnabled(bool v) async {
    _ttsEnabled = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyTtsEnabled, v);
    notifyListeners();
  }

  Future<void> setSfxEnabled(bool v) async {
    _sfxEnabled = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySfxEnabled, v);
    notifyListeners();
  }

  Future<void> setAutoSend(bool v) async {
    _autoSend = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoSend, v);
    notifyListeners();
  }

  Future<void> setTtsVoice(int v) async {
    _ttsVoice = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyTtsVoice, v);
    notifyListeners();
  }

  Future<void> setUiLang(String lang) async {
    _uiLang = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUiLang, lang);
    notifyListeners();
  }
}
