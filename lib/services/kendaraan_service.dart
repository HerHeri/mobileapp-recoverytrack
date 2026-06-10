// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../models/kendaraan.dart';
import '../storage/token_storage.dart';

class KendaraanService {
  static String get _base => ApiConfig.baseUrl;

  /// GET /v1/cari/kendaraan?q=...&field=...&limit=...
  static Future<Map<String, dynamic>> search(
    String query, {
    String field = 'no_polisi',
    int limit = 50,
  }) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse(
      '$_base/cari/kendaraan?q=$query&field=$field&limit=$limit',
    );
    final headers = ApiConfig.authHeaders(token);

    print(url);
    print(headers);

    try {
      final response = await http.get(url, headers: headers);
      print(response.body);
      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data['success'] == true) {
          final List<dynamic> results = data['data'] ?? [];
          final Map<String, dynamic> metaJson = data['meta'] ?? {};

          return {
            'data': results.map((j) => Kendaraan.fromJson(j)).toList(),
            'meta': SearchMeta.fromJson(metaJson),
          };
        } else {
          throw Exception(
            data['error'] ?? data['message'] ?? 'Terjadi kesalahan',
          );
        }
      } else {
        throw Exception(
          data['error'] ??
              data['message'] ??
              'Terjadi kesalahan pada server (${response.statusCode})',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// POST /v1/log-lokasi
  static Future<Map<String, dynamic>> logLokasi({
    required String query,
    required int resultsCount,
    required String source,
    required double responseTimeMs,
    String channel = 'mobile',
    double? latitude,
    double? longitude,
  }) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse('$_base/log-lokasi');
    final headers = ApiConfig.authHeaders(token);
    final body = jsonEncode({
      'query': query,
      'results_count': resultsCount,
      'source': 'database',
      'response_time_ms': responseTimeMs.round(),
      'channel': 'api',
      'latitude': latitude,
      'longitude': longitude,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return data;
      } else {
        throw Exception(
          data['message'] ?? 'Gagal mengirim log (${response.statusCode})',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// GET /v1/history-log
  static Future<List<dynamic>> getHistoryLog() async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse('$_base/history-log');
    final headers = ApiConfig.authHeaders(token);

    try {
      final response = await http.get(url, headers: headers);
      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data['data'] ?? [];
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception(
          data['message'] ?? 'Gagal mengambil riwayat (${response.statusCode})',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// GET /v1/history-log/detail/{id}
  static Future<Map<String, dynamic>> getHistoryLogDetail(int id) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse('$_base/history-log/detail/$id');
    final headers = ApiConfig.authHeaders(token);

    try {
      final response = await http.get(url, headers: headers);
      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(
          data['message'] ??
              'Gagal mengambil detail riwayat (${response.statusCode})',
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}
