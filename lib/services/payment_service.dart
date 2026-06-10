import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../storage/token_storage.dart';

class PaymentService {
  static String get _base => ApiConfig.baseUrl;

  /// GET /v1/paket
  static Future<List<dynamic>> getPackages() async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse('$_base/paket');
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
          data['message'] ??
              'Gagal mengambil daftar paket (${response.statusCode})',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// POST /v1/paket/beli/{paketId}
  static Future<Map<String, dynamic>> buyPackage(int paketId) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse('$_base/paket/beli/$paketId');
    final headers = ApiConfig.authHeaders(token);

    try {
      final response = await http.post(url, headers: headers);
      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(
          data['message'] ??
              'Gagal memproses pembelian paket (${response.statusCode})',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// POST /v1/paket/free — activate free package
  static Future<Map<String, dynamic>> activateFreePackage() async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse('$_base/paket/free');
    final headers = ApiConfig.authHeaders(token);

    try {
      final response = await http.post(url, headers: headers);
      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(
          data['message'] ??
              'Gagal mengaktifkan paket gratis (${response.statusCode})',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// GET /v1/transaksi
  static Future<List<dynamic>> getTransactions() async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse('$_base/transaksi');
    final headers = ApiConfig.authHeaders(token);

    try {
      final response = await http.get(url, headers: headers);
      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data['data'] ?? [];
      } else {
        throw Exception(
          data['message'] ??
              'Gagal mengambil riwayat transaksi (${response.statusCode})',
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}
