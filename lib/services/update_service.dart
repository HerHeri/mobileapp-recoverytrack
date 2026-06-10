import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';

import '../storage/token_storage.dart';

class UpdateService {
  UpdateService._();

  /// Check latest version from server
  /// Returns null if no update available, or Map with version data if update exists
  static Future<Map<String, dynamic>?> checkUpdate({
    required String currentVersion,
    required int currentVersionCode,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/version'),
            headers: ApiConfig.baseHeaders,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final body = json.decode(response.body);
      if (body['success'] != true) return null;

      final data = body['data'];
      if (data == null) return null;

      final serverVersionCode =
          int.tryParse(data['version_code']?.toString() ?? '0') ?? 0;

      // Check if user already installed this update (prevents loop)
      final lastInstalled = await TokenStorage.getLastUpdateVersionCode();
      if (lastInstalled != null && serverVersionCode <= lastInstalled) {
        return null; // Already installed this version or newer
      }

      if (serverVersionCode > currentVersionCode) {
        return {
          'version': data['version']?.toString() ?? '',
          'version_code': serverVersionCode,
          'filename': data['filename']?.toString() ?? '',
          'download_url': data['download_url']?.toString() ?? '',
          'file_size': data['file_size'],
          'changelog': data['changelog']?.toString() ?? '',
          'force_update':
              data['force_update'] == true || data['force_update'] == 1,
        };
      }

      return null; // No update needed
    } catch (_) {
      return null; // Network error → skip update check gracefully
    }
  }
}
