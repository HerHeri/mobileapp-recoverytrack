// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../core/api_config.dart';
import '../storage/token_storage.dart';

class AuthService {
  static String get _base => ApiConfig.baseUrl;
  static String get _authBase => ApiConfig.authPath;

  /// POST /v1/auth/register
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String nik,
    required String password,
    required String passwordConfirmation,
    required String alamat,
    required String domisili,
    required XFile ktpPhoto,
    required XFile selfieKtpPhoto,
    required XFile suratTugasPhoto,
    required XFile sppiPhoto,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_authBase/register'),
    );
    request.headers['Accept'] = 'application/json';
    request.fields.addAll({
      'name': name,
      'email': email,
      'phone': phone,
      'nik': nik,
      'password': password,
      'password_confirmation': passwordConfirmation,
      'alamat': alamat,
      'domisili': domisili,
    });

    Future<http.MultipartFile> filePart(String field, XFile file) async {
      return http.MultipartFile.fromBytes(
        field,
        await file.readAsBytes(),
        filename: file.name,
      );
    }

    request.files.addAll([
      await filePart('ktp_photo', ktpPhoto),
      await filePart('selfie_ktp_photo', selfieKtpPhoto),
      await filePart('surat_tugas_photo', suratTugasPhoto),
      await filePart('sppi_photo', sppiPhoto),
    ]);

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final dynamic decoded = jsonDecode(response.body);
      final data = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{};

      if (response.statusCode == 201 || response.statusCode == 200) {
        return data;
      }

      final validationErrors = data['errors'];
      if (validationErrors is Map) {
        final messages = validationErrors.values
            .expand(
              (value) => value is List
                  ? value.map((item) => item.toString())
                  : [value.toString()],
            )
            .toList();
        if (messages.isNotEmpty) {
          throw Exception(messages.join('\n'));
        }
      }

      throw Exception(
        data['message'] ?? 'Registrasi gagal diproses (${response.statusCode})',
      );
    } on http.ClientException {
      throw Exception('Masalah koneksi jaringan. Pastikan internet aktif.');
    } on FormatException {
      throw Exception('Respon server bukan format JSON yang valid.');
    }
  }

  /// POST /v1/auth/login
  static Future<Map<String, dynamic>> login(
    String email,
    String password, {
    String? deviceName,
    String? deviceType,
  }) async {
    final url = Uri.parse('$_authBase/login');
    final headers = ApiConfig.baseHeaders;
    final body = jsonEncode({
      'email': email,
      'password': password,
      'device_name': deviceName,
      'device_type': deviceType,
    });

    print('>>> HTTP REQUEST: POST $url');
    print('>>> HEADERS: $headers');
    print('>>> BODY: $body');

    try {
      final response = await http.post(url, headers: headers, body: body);

      print('<<< HTTP RESPONSE [${response.statusCode}]: ${response.body}');

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        final hasToken = data['data'] is Map && data['data']['token'] != null;
        final userData = hasToken ? data['data']['user'] : null;
        final isPending = userData is Map && userData['status'] == 'Pending';
        final statusTerms = userData is Map ? userData['status_terms'] : null;
        if (hasToken && isPending && (statusTerms == null || statusTerms == 'No')) {
          return data;
        }

        throw Exception(
          data['message'] ??
              'Terjadi kesalahan pada server (Status: ${response.statusCode})',
        );
      }
    } catch (e) {
      print('!!! ERROR DALAM AUTH_SERVICE: $e');
      if (e is http.ClientException) {
        throw Exception('Masalah koneksi jaringan. Pastikan internet aktif.');
      } else if (e is FormatException) {
        throw Exception('Respon server bukan format JSON yang valid.');
      }
      rethrow;
    }
  }

  /// POST /v1/auth/logout
  static Future<void> logout() async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse('$_authBase/logout');
    final headers = ApiConfig.authHeaders(token);

    try {
      final response = await http.post(url, headers: headers);
      if (response.statusCode != 200) {
        print('!!! GAGAL LOGOUT SERVER: ${response.body}');
      }
    } catch (e) {
      print('!!! ERROR LOGOUT SERVER: $e');
    }
  }

  /// GET /v1/auth/me
  static Future<Map<String, dynamic>> getMe() async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse('$_authBase/me');
    final headers = ApiConfig.authHeaders(token);

    try {
      final response = await http.get(url, headers: headers);
      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(
          data['message'] ??
              'Gagal mengambil data user (${response.statusCode})',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// GET /v1/profile
  static Future<Map<String, dynamic>> getProfile() async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse('$_base/profile');
    final headers = ApiConfig.authHeaders(token);

    try {
      final response = await http.get(url, headers: headers);
      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(
          data['message'] ??
              'Gagal mengambil data profil (${response.statusCode})',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// POST /v1/profile/update
  static Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> body, {
    List<int>? photoBytes,
    String? photoFileName,

    List<int>? ktpPhotoBytes,
    String? ktpPhotoFileName,

    List<int>? selfieKtpPhotoBytes,
    String? selfieKtpPhotoFileName,

    List<int>? suratTugasPhotoBytes,
    String? suratTugasPhotoFileName,

    List<int>? sppiPhotoBytes,
    String? sppiPhotoFileName,
  }) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse('$_base/profile/update');
    final headers = <String, String>{
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    try {
      final request = http.MultipartRequest('POST', url);
      request.headers.addAll(headers);

      body.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });

      if (photoBytes != null && photoFileName != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'photo',
            photoBytes,
            filename: photoFileName,
          ),
        );
      }

      if (ktpPhotoBytes != null && ktpPhotoFileName != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'ktp_photo',
            ktpPhotoBytes,
            filename: ktpPhotoFileName,
          ),
        );
      }

      if (selfieKtpPhotoBytes != null && selfieKtpPhotoFileName != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'selfie_ktp_photo',
            selfieKtpPhotoBytes,
            filename: selfieKtpPhotoFileName,
          ),
        );
      }

      if (suratTugasPhotoBytes != null && suratTugasPhotoFileName != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'surat_tugas_photo',
            suratTugasPhotoBytes,
            filename: suratTugasPhotoFileName,
          ),
        );
      }

      if (sppiPhotoBytes != null && sppiPhotoFileName != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'sppi_photo',
            sppiPhotoBytes,
            filename: sppiPhotoFileName,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(
          data['message'] ??
              'Gagal memperbarui profil (${response.statusCode})',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// POST /v1/auth/reset-password
  static Future<Map<String, dynamic>> resetPassword(String email) async {
    final url = Uri.parse('$_authBase/reset-password');
    final headers = ApiConfig.baseHeaders;
    final body = jsonEncode({'email': email});

    try {
      final response = await http.post(url, headers: headers, body: body);
      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(
          data['message'] ?? 'Gagal mengirim OTP (${response.statusCode})',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// POST /v1/auth/verify-otp
  static Future<Map<String, dynamic>> verifyOtp(
    String email,
    String otp,
  ) async {
    final url = Uri.parse('$_authBase/verify-otp');
    final headers = ApiConfig.baseHeaders;
    final body = jsonEncode({'email': email, 'otp': otp});

    try {
      final response = await http.post(url, headers: headers, body: body);
      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(
          data['message'] ??
              'OTP salah atau tidak valid (${response.statusCode})',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// POST /v1/auth/change-password
  static Future<Map<String, dynamic>> changePassword(
    String email,
    String otp,
    String password,
  ) async {
    final url = Uri.parse('$_authBase/change-password');
    final headers = ApiConfig.baseHeaders;
    final body = jsonEncode({'email': email, 'otp': otp, 'password': password});

    try {
      final response = await http.post(url, headers: headers, body: body);
      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(
          data['message'] ?? 'Gagal mengubah password (${response.statusCode})',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// POST /v1/terms/update (menu persetujuan syarat & ketentuan)
  static Future<Map<String, dynamic>> updateTerms(String status) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse('$_base/terms/update');
    final headers = ApiConfig.authHeaders(token);
    final body = jsonEncode({'terms_conditions': status});

    try {
      final response = await http.post(url, headers: headers, body: body);
      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(
          data['message'] ?? 'Gagal mengupdate terms (${response.statusCode})',
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}
