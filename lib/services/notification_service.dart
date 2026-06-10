import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../storage/token_storage.dart';

class NotificationService {
  static String get _base => ApiConfig.baseUrl;

  /// POST /v1/send-notifikasi
  static Future<Map<String, dynamic>> sendNotification({
    required int logId,
    required String message,
  }) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse('$_base/send-notifikasi');
    final headers = ApiConfig.authHeaders(token);
    final body = jsonEncode({'log_id': logId, 'message': message});

    try {
      final response = await http.post(url, headers: headers, body: body);
      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return data;
      } else {
        throw Exception(
          data['message'] ??
              'Gagal mengirim notifikasi (${response.statusCode})',
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}
