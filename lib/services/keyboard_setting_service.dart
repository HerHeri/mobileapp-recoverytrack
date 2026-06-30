import 'package:shared_preferences/shared_preferences.dart';

class KeyboardSettingService {
  static const _keyType = 'selectedKeyboardType';
  static const _keyHeight = 'keyboardHeight';
  static const _keyTextSize = 'searchTextSize';
  static const _keyVibration = 'vibrationEnabled';
  static const _keyKeepScreenOn = 'keepScreenOn';

  // 0 = system, 1-5 = custom layouts
  static const int defaultType = 0;
  static const double defaultHeight = 280;
  static const double defaultTextSize = 32;
  static const bool defaultVibration = true;
  static const bool defaultKeepScreenOn = false;

  static Future<SharedPreferences> get _prefs =>
      SharedPreferences.getInstance();

  // --- Keyboard type ---
  static Future<int> getKeyboardType() async {
    final p = await _prefs;
    return p.getInt(_keyType) ?? defaultType;
  }

  static Future<void> setKeyboardType(int type) async {
    final p = await _prefs;
    await p.setInt(_keyType, type);
  }

  // --- Keyboard height ---
  static Future<double> getKeyboardHeight() async {
    final p = await _prefs;
    return p.getDouble(_keyHeight) ?? defaultHeight;
  }

  static Future<void> setKeyboardHeight(double height) async {
    final p = await _prefs;
    await p.setDouble(_keyHeight, height);
  }

  // --- Text size ---
  static Future<double> getTextSize() async {
    final p = await _prefs;
    return p.getDouble(_keyTextSize) ?? defaultTextSize;
  }

  static Future<void> setTextSize(double size) async {
    final p = await _prefs;
    await p.setDouble(_keyTextSize, size);
  }

  // --- Vibration ---
  static Future<bool> getVibrationEnabled() async {
    final p = await _prefs;
    return p.getBool(_keyVibration) ?? defaultVibration;
  }

  static Future<void> setVibrationEnabled(bool enabled) async {
    final p = await _prefs;
    await p.setBool(_keyVibration, enabled);
  }

  // --- Keep screen on ---
  static Future<bool> getKeepScreenOn() async {
    final p = await _prefs;
    return p.getBool(_keyKeepScreenOn) ?? defaultKeepScreenOn;
  }

  static Future<void> setKeepScreenOn(bool enabled) async {
    final p = await _prefs;
    await p.setBool(_keyKeepScreenOn, enabled);
  }
}
