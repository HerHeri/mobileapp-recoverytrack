import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const _tokenKey = "auth_token";
  static const _lastUpdateVersionCodeKey = "last_update_version_code";
  static String? _cachedToken;
  static bool _tokenLoaded = false;

  static Future<void> saveToken(String token) async {
    _cachedToken = token;
    _tokenLoaded = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    if (_tokenLoaded) return _cachedToken;

    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString(_tokenKey);
    _tokenLoaded = true;
    return _cachedToken;
  }

  static Future<void> clearToken() async {
    _cachedToken = null;
    _tokenLoaded = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove("user_photo");
  }

  static Future<void> savePhoto(String photo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("user_photo", photo);
  }

  static Future<String?> getPhoto() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("user_photo");
  }

  /// Save the version code that user has already installed
  static Future<void> saveLastUpdateVersionCode(int versionCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastUpdateVersionCodeKey, versionCode);
  }

  /// Get the last installed update version code, or null if never installed
  static Future<int?> getLastUpdateVersionCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastUpdateVersionCodeKey);
  }
}
