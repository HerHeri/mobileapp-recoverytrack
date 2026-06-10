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
