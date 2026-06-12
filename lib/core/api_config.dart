class ApiConfig {
  ApiConfig._();

  static const String apiOrigin = 'https://api.suntikradar.com';

  /// Base URL for desktop & mobile API (Bearer token, non-cookie)
  static const String baseUrl = '$apiOrigin/v1';

  static const String websiteSettingsUrl =
      '$apiOrigin/api/admin/website-settings';

  /// Auth sub-path
  static const String authPath = '$baseUrl/auth';

  /// Admin sub-path
  static const String adminPath = '$baseUrl/admin';

  /// Common request headers
  static Map<String, String> get baseHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Build Authorization header from a token (can be null for public endpoints)
  static Map<String, String> authHeaders(String? token) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }
}
