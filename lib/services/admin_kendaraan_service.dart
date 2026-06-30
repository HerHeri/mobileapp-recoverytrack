import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:downloadsfolder/downloadsfolder.dart';
import '../core/api_config.dart';
import '../models/kendaraan.dart';
import '../storage/token_storage.dart';

class AdminKendaraanService {
  static String get _base => ApiConfig.adminPath;
  static const _timeout = Duration(seconds: 30);

  // ─── LIST ────────────────────────────────────────────────────────────────

  /// GET /v1/admin/kendaraan
  /// [q] search query, [page] halaman, [perPage] items per halaman
  static Future<PaginatedKendaraan> getKendaraan({
    String? q,
    int page = 1,
    int perPage = 20,
  }) async {
    final token = await TokenStorage.getToken();
    final params = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
      if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
    };
    final url = Uri.parse('$_base/kendaraan').replace(queryParameters: params);
    final headers = ApiConfig.authHeaders(token);
    try {
      final response = await http.get(url, headers: headers).timeout(_timeout);
      print('STATUS: ${response.statusCode}');
      print('BODY: ${response.body}');
      // Parse response body, handle non-JSON responses
      Map<String, dynamic> data = {};
      try {
        if (response.body.isNotEmpty) {
          data = jsonDecode(response.body) as Map<String, dynamic>;
        }
      } catch (e) {
        // Ignore JSON decode errors, use empty data
      }

      if (response.statusCode == 200) {
        return PaginatedKendaraan.fromJson(data);
      } else {
        // Get error message from server if available
        final errorMessage =
            data['message'] ?? 'Gagal mengambil data (${response.statusCode})';
        throw Exception(errorMessage);
      }
    } on TimeoutException {
      throw Exception('Koneksi timeout. Coba lagi.');
    } on SocketException {
      throw Exception('Tidak dapat terhubung ke server.');
    } catch (e) {
      // Catch any other unexpected errors
      throw Exception('Terjadi kesalahan: ${e.toString()}');
    }
  }

  // ─── SAVE (CREATE / UPDATE) ───────────────────────────────────────────────

  /// POST /v1/admin/kendaraan
  /// Untuk tambah data baru. Backend menentukan update jika no_polisi sama.
  static Future<Map<String, dynamic>> saveKendaraan(
    Map<String, dynamic> body,
  ) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse('$_base/kendaraan');
    final headers = ApiConfig.authHeaders(token);

    try {
      final response = await http
          .post(url, headers: headers, body: jsonEncode(body))
          .timeout(_timeout);

      print(response.statusCode);
      print(response.body);

      // Parse response body, handle non-JSON responses
      Map<String, dynamic> data = {};
      try {
        if (response.body.isNotEmpty) {
          data = jsonDecode(response.body) as Map<String, dynamic>;
        }
      } catch (e) {
        // Ignore JSON decode errors, use empty data
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return data;
      }
      // Validation errors
      if (response.statusCode == 422) {
        final errors = data['errors'] as Map?;
        if (errors != null) {
          final messages = errors.values
              .expand(
                (v) => v is List ? v.map((e) => e.toString()) : [v.toString()],
              )
              .join('\n');
          throw Exception(messages);
        }
      }
      throw Exception(
        data['message'] ?? 'Gagal menyimpan data (${response.statusCode})',
      );
    } on TimeoutException {
      throw Exception('Koneksi timeout. Coba lagi.');
    } on SocketException {
      throw Exception('Tidak dapat terhubung ke server.');
    } catch (e) {
      // Catch any other unexpected errors
      throw Exception('Terjadi kesalahan: ${e.toString()}');
    }
  }

  // ─── DELETE ───────────────────────────────────────────────────────────────

  /// DELETE /v1/admin/kendaraan/{id}
  static Future<void> deleteKendaraan(int id) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse('$_base/kendaraan/$id');
    final headers = ApiConfig.authHeaders(token);

    try {
      final response = await http
          .delete(url, headers: headers)
          .timeout(_timeout);
      if (response.statusCode == 200 || response.statusCode == 204) return;

      // Parse response body, handle non-JSON responses
      Map<String, dynamic> data = {};
      try {
        if (response.body.isNotEmpty) {
          data = jsonDecode(response.body) as Map<String, dynamic>;
        }
      } catch (e) {
        // Ignore JSON decode errors, use empty data
      }

      throw Exception(
        data['message'] ?? 'Gagal menghapus data (${response.statusCode})',
      );
    } on TimeoutException {
      throw Exception('Koneksi timeout. Coba lagi.');
    } on SocketException {
      throw Exception('Tidak dapat terhubung ke server.');
    } catch (e) {
      // Catch any other unexpected errors
      throw Exception('Terjadi kesalahan: ${e.toString()}');
    }
  }

  // ─── IMPORT EXCEL ─────────────────────────────────────────────────────────

  /// POST /v1/admin/kendaraan/import
  /// [filePath] path file lokal, [uploadType] 'replace' | 'tambah'
  /// [narasumberId] diisi dengan user_id (untuk Admin Leasing, otomatis dari caller)
  static Future<Map<String, dynamic>> importKendaraan({
    required String filePath,
    required String uploadType,
    int? narasumberId,
    int? leasingId,
    int? cabangId,
  }) async {
    print("narasumberId = $narasumberId");
    print("leasingId = $leasingId");
    print("cabangId = $cabangId");
    final token = await TokenStorage.getToken();
    final url = Uri.parse('$_base/kendaraan/import');

    final request = http.MultipartRequest('POST', url);
    request.headers.addAll({
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });

    request.fields['upload_type'] = uploadType;
    if (narasumberId != null) {
      request.fields['narasumber_id'] = narasumberId.toString();
    }
    if (leasingId != null) request.fields['leasing_id'] = leasingId.toString();
    if (cabangId != null) request.fields['cabang_id'] = cabangId.toString();

    final fileName = filePath.split('/').last.split('\\').last;
    request.files.add(
      await http.MultipartFile.fromPath('file', filePath, filename: fileName),
    );

    try {
      final streamed = await request.send().timeout(
        const Duration(seconds: 60),
      );
      final response = await http.Response.fromStream(streamed);

      // Parse response body, handle non-JSON responses
      Map<String, dynamic> data = {};
      try {
        if (response.body.isNotEmpty) {
          data = jsonDecode(response.body) as Map<String, dynamic>;
        }
      } catch (e) {
        // Ignore JSON decode errors, use empty data
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return data;
      }
      if (response.statusCode == 422) {
        final errors = data['errors'] as Map?;
        if (errors != null) {
          final messages = errors.values
              .expand(
                (v) => v is List ? v.map((e) => e.toString()) : [v.toString()],
              )
              .join('\n');
          throw Exception(messages);
        }
      }
      throw Exception(
        data['message'] ?? 'Gagal mengimpor file (${response.statusCode})',
      );
    } on TimeoutException {
      throw Exception('Koneksi timeout saat upload. Coba lagi.');
    } on SocketException {
      throw Exception('Tidak dapat terhubung ke server.');
    } catch (e) {
      // Catch any other unexpected errors
      throw Exception('Terjadi kesalahan: ${e.toString()}');
    }
  }

  // ─── IMPORT PROGRESS ─────────────────────────────────────────────────────

  /// GET /v1/admin/kendaraan/import-progress/{id}
  static Future<ImportProgress> getImportProgress(String importId) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse('$_base/kendaraan/import-progress/$importId');
    final headers = ApiConfig.authHeaders(token);

    try {
      final response = await http.get(url, headers: headers).timeout(_timeout);

      // Parse response body, handle non-JSON responses
      Map<String, dynamic> data = {};
      try {
        if (response.body.isNotEmpty) {
          data = jsonDecode(response.body) as Map<String, dynamic>;
        }
      } catch (e) {
        // Ignore JSON decode errors, use empty data
      }

      if (response.statusCode == 200) {
        return ImportProgress.fromJson(data);
      }
      throw Exception(
        data['message'] ?? 'Gagal mengambil progress (${response.statusCode})',
      );
    } on TimeoutException {
      throw Exception('Koneksi timeout. Coba lagi.');
    } on SocketException {
      throw Exception('Tidak dapat terhubung ke server.');
    } catch (e) {
      // Catch any other unexpected errors
      throw Exception('Terjadi kesalahan: ${e.toString()}');
    }
  }

  // ─── DOWNLOAD TEMPLATE ────────────────────────────────────────────────────

  /// GET /v1/admin/kendaraan/template
  /// Mengembalikan URL download template Excel
  static String get templateDownloadUrl =>
      '${ApiConfig.adminPath}/kendaraan/template';

  /// Download template Excel dan simpan ke direktori download.
  /// Mengembalikan path file yang disimpan.
  static Future<String> downloadTemplate() async {
    final token = await TokenStorage.getToken();

    final response = await http.get(
      Uri.parse(templateDownloadUrl),
      headers: {if (token != null) "Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) {
      throw Exception("Download gagal (${response.statusCode})");
    }

    if (response.bodyBytes.isEmpty) {
      throw Exception("Template kosong.");
    }

    // Folder temporary aplikasi
    final tempDir = await getTemporaryDirectory();

    final tempFile = File("${tempDir.path}/template-import-kendaraan.csv");

    await tempFile.writeAsBytes(response.bodyBytes);

    print("Temp file : ${tempFile.path}");
    print("Exists    : ${await tempFile.exists()}");

    final success = await copyFileIntoDownloadFolder(
      tempFile.path,
      "template-import-kendaraan.csv",
    );

    print("Copy Result : $success");

    if (success != true) {
      throw Exception("Gagal menyalin file ke folder Download.");
    }

    final downloadDir = await getDownloadDirectory();

    return "${downloadDir.path}/template-import-kendaraan.csv";
  }
}
