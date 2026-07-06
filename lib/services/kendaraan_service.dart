import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../models/kendaraan.dart';
import '../storage/token_storage.dart';

class KendaraanService {
  static String get _base => ApiConfig.baseUrl;
  static const _requestTimeout = Duration(seconds: 6);
  static const _searchCacheLifetime = Duration(seconds: 45);
  static const _detailCacheLifetime = Duration(minutes: 2);

  static final http.Client _client = http.Client();
  static final Map<String, _CacheEntry<Map<String, dynamic>>> _searchCache = {};
  static final Map<int, _CacheEntry<Map<String, dynamic>>> _detailCache = {};
  static int _requestSeq = 0;

  /// GET /v1/cari/kendaraan?q=...&field=...&limit=...
  static Future<Map<String, dynamic>> search(
    String query, {
    String field = 'no_polisi',
    int limit = 20,
  }) async {
    final normalizedQuery = query.trim().toUpperCase();
    final cacheKey = '$field|$normalizedQuery|$limit';
    final cached = _searchCache[cacheKey];
    if (cached != null && cached.isFresh(_searchCacheLifetime)) {
      return cached.value;
    }

    final requestId = ++_requestSeq;
    final token = await TokenStorage.getToken();
    final url = Uri.parse('$_base/cari/kendaraan').replace(
      queryParameters: {
        'q': normalizedQuery,
        'field': field,
        'limit': limit.toString(),
      },
    );
    final headers = ApiConfig.authHeaders(token);

    try {
      final response = await _client
          .get(url, headers: headers)
          .timeout(_requestTimeout);
      if (requestId != _requestSeq) {
        throw const SearchCancelledException();
      }
      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data['success'] == true) {
          final List<dynamic> results = data['data'] ?? [];
          final Map<String, dynamic> metaJson = data['meta'] ?? {};

          final parsed = <String, dynamic>{
            'data': results.map((j) => Kendaraan.fromJson(j)).toList(),
            'meta': SearchMeta.fromJson(metaJson),
          };
          _searchCache[cacheKey] = _CacheEntry(parsed);
          _removeExpiredSearchCache();
          return parsed;
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
    } on TimeoutException {
      throw Exception('Pencarian terlalu lama. Silakan coba lagi.');
    } on http.ClientException {
      throw Exception('Tidak dapat terhubung ke server. Periksa koneksi Anda.');
    }
  }

  static void cancelSearch() {
    _requestSeq++;
  }

  static void _removeExpiredSearchCache() {
    _searchCache.removeWhere(
      (_, entry) => !entry.isFresh(_searchCacheLifetime),
    );
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
      final response = await _client
          .post(url, headers: headers, body: body)
          .timeout(_requestTimeout);
      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return data;
      } else {
        throw Exception(
          data['message'] ?? 'Gagal mengirim log (${response.statusCode})',
        );
      }
    } on TimeoutException {
      throw Exception('Permintaan detail terlalu lama. Silakan coba lagi.');
    }
  }

  /// GET /v1/history-log
  static Future<List<dynamic>> getHistoryLog() async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse('$_base/history-log');
    final headers = ApiConfig.authHeaders(token);

    try {
      final response = await _client.get(url, headers: headers);
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
    final cached = _detailCache[id];
    if (cached != null && cached.isFresh(_detailCacheLifetime)) {
      return normalizeHistoryDetail(cached.value);
    }

    final token = await TokenStorage.getToken();
    final url = Uri.parse('$_base/history-log/detail/$id');
    final headers = ApiConfig.authHeaders(token);

    try {
      final response = await _client
          .get(url, headers: headers)
          .timeout(_requestTimeout);
      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final detail = normalizeHistoryDetail(data);
        _detailCache[id] = _CacheEntry(detail);
        return detail;
      } else {
        throw Exception(
          data['message'] ??
              'Gagal mengambil detail riwayat (${response.statusCode})',
        );
      }
    } on TimeoutException {
      throw Exception('Detail terlalu lama dimuat. Silakan coba lagi.');
    }
  }

  static Map<String, dynamic> normalizeHistoryDetail(
    Map<dynamic, dynamic> response,
  ) {
    final normalized = <String, dynamic>{};
    const nestedKeys = [
      'data',
      'detail',
      'history',
      'log',
      'result',
      'search_result',
      'response_data',
      'vehicle_data',
      'hasil',
      'kendaraan',
      'vehicle',
    ];

    void merge(Map<dynamic, dynamic> source) {
      for (final entry in source.entries) {
        if (entry.value is! Map && entry.value is! List) {
          normalized[entry.key.toString()] = entry.value;
        }
      }

      for (final key in nestedKeys) {
        final value = source[key];
        if (value is Map) {
          merge(value);
        } else if (value is List && value.isNotEmpty && value.first is Map) {
          merge(value.first as Map);
        }
      }
    }

    merge(response);
    return normalized;
  }
}

class SearchCancelledException implements Exception {
  const SearchCancelledException();
}

class _CacheEntry<T> {
  final T value;
  final DateTime createdAt;

  _CacheEntry(this.value) : createdAt = DateTime.now();

  bool isFresh(Duration lifetime) {
    return DateTime.now().difference(createdAt) < lifetime;
  }
}
