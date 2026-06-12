import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../storage/token_storage.dart';

class SettingsService {
  static String get _base => ApiConfig.adminPath;

  /// GET /v1/admin/settings
  static Future<Map<String, dynamic>> getAdminSettings() async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse('$_base/settings');
    final headers = ApiConfig.authHeaders(token);

    try {
      final response = await http.get(url, headers: headers);
      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data['data'] ?? data;
      } else {
        throw Exception(
          data['message'] ??
              'Gagal mengambil data pengaturan (${response.statusCode})',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<String?> getWhatsAppShareTemplate() async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse(ApiConfig.websiteSettingsUrl);
    final headers = ApiConfig.authHeaders(token);
    final response = await http
        .get(url, headers: headers)
        .timeout(const Duration(seconds: 15));
    final decoded = jsonDecode(response.body);

    if (response.statusCode != 200) {
      final message = decoded is Map ? decoded['message'] : null;
      throw Exception(
        message ?? 'Gagal mengambil website settings (${response.statusCode})',
      );
    }

    final template = _findSettingValue(decoded, 'whatsapp_share_template');
    final value = template?.toString().trim();
    if (value == null || value.isEmpty) return null;

    return value;
  }

  static dynamic _findSettingValue(dynamic node, String key) {
    if (node is Map) {
      final directValue = node[key];
      if (directValue != null) return directValue;

      if (node['key'] == key || node['name'] == key) {
        return node['value'] ?? node['setting_value'];
      }

      for (final value in node.values) {
        final found = _findSettingValue(value, key);
        if (found != null) return found;
      }
    } else if (node is List) {
      for (final value in node) {
        final found = _findSettingValue(value, key);
        if (found != null) return found;
      }
    }
    return null;
  }

  /// GET /api/admin/website-settings
  static Future<Map<String, dynamic>> getWebsiteSettings() async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse(ApiConfig.websiteSettingsUrl);
    final headers = ApiConfig.authHeaders(token);

    final response = await http.get(url, headers: headers);
    final decoded = jsonDecode(response.body);
    final data = decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{};

    if (response.statusCode == 200) {
      final responseData = data['data'];
      return responseData is Map<String, dynamic> ? responseData : data;
    }

    throw Exception(
      data['message'] ??
          'Gagal mengambil website settings (${response.statusCode})',
    );
  }

  /// POST /api/admin/website-settings
  static Future<Map<String, dynamic>> updateWebsiteSettings(
    Map<String, dynamic> body,
  ) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse(ApiConfig.websiteSettingsUrl);
    final headers = ApiConfig.authHeaders(token);

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );
    final decoded = jsonDecode(response.body);
    final data = decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{};

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = data['data'];
      return responseData is Map<String, dynamic> ? responseData : data;
    }

    throw Exception(
      data['message'] ??
          'Gagal menyimpan website settings (${response.statusCode})',
    );
  }

  /// POST /v1/admin/settings
  static Future<Map<String, dynamic>> updateAdminSettings(
    Map<String, dynamic> body,
  ) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse('$_base/settings');
    final headers = ApiConfig.authHeaders(token);

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data['data'] ?? data;
      } else {
        throw Exception(
          data['message'] ??
              'Gagal menyimpan pengaturan (${response.statusCode})',
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}
