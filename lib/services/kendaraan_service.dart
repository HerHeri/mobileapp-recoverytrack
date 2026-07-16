import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../models/kendaraan.dart';
import '../storage/token_storage.dart';

class KendaraanService {
  static String get _base => ApiConfig.baseUrl;
  static const _requestTimeout = Duration(seconds: 8);
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
    final selectedField = _validateSearchField(field);
    final normalizedQuery = query.trim().toUpperCase();
    final cacheKey = '$selectedField|$normalizedQuery|$limit';
    final cached = _searchCache[cacheKey];
    if (cached != null && cached.isFresh(_searchCacheLifetime)) {
      return cached.value;
    }

    final requestId = ++_requestSeq;
    final token = await TokenStorage.getToken();
    final url = Uri.parse('$_base/cari/kendaraan').replace(
      queryParameters: {
        'q': normalizedQuery,
        'field': selectedField,
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
          final vehicles = results
              .map((j) => Kendaraan.fromJson(j))
              .where(
                (item) =>
                    _matchesSelectedField(item, selectedField, normalizedQuery),
              )
              .toList();
          final serverMeta = SearchMeta.fromJson(metaJson);

          final parsed = <String, dynamic>{
            'data': vehicles,
            'meta': SearchMeta(
              query: normalizedQuery,
              field: selectedField,
              source: serverMeta.source,
              responseTimeMs: serverMeta.responseTimeMs,
              count: vehicles.length,
              limit: limit,
            ),
          };

          _searchCache[cacheKey] = _CacheEntry(parsed);
          _removeExpiredSearchCache();
          return parsed;
        } else {
          throw SearchAccessException.fromJson(data, response.statusCode);
        }
      } else {
        throw SearchAccessException.fromJson(data, response.statusCode);
      }
    } on TimeoutException {
      final parsed = <String, dynamic>{
        'data': <Kendaraan>[],
        'meta': SearchMeta(
          query: normalizedQuery,
          field: selectedField,
          source: 'timeout',
          responseTimeMs: _requestTimeout.inMilliseconds.toDouble(),
          count: 0,
          limit: limit,
        ),
      };
      _searchCache[cacheKey] = _CacheEntry(parsed);
      _removeExpiredSearchCache();
      return parsed;
    } on http.ClientException {
      throw Exception('Tidak dapat terhubung ke server. Periksa koneksi Anda.');
    }
  }

  static void cancelSearch() {
    _requestSeq++;
  }

  static String _validateSearchField(String field) {
    const allowedFields = {'no_polisi', 'no_mesin', 'no_rangka'};
    final normalized = field.trim().toLowerCase();

    if (!allowedFields.contains(normalized)) {
      throw ArgumentError.value(field, 'field', 'Field pencarian tidak valid');
    }

    return normalized;
  }

  static bool _matchesSelectedField(
    Kendaraan item,
    String field,
    String query,
  ) {
    final normalizedQuery = _normalizeIdentifier(query);
    final value = switch (field) {
      'no_polisi' => item.noPolisi,
      'no_mesin' => item.noMesin ?? '',
      'no_rangka' => item.noRangka ?? '',
      _ => '',
    };
    final normalizedValue = _normalizeIdentifier(value);

    if (normalizedQuery.isEmpty || normalizedValue.isEmpty) return false;
    return normalizedValue.contains(normalizedQuery);
  }

  static String _normalizeIdentifier(String value) {
    return value.trim().toUpperCase().replaceAll(RegExp(r'[\s_-]+'), '');
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

class SearchAccessException implements Exception {
  final String title;
  final String message;
  final String status;
  final int statusCode;

  const SearchAccessException({
    required this.title,
    required this.message,
    required this.status,
    required this.statusCode,
  });

  factory SearchAccessException.fromJson(
    Map<String, dynamic> data,
    int statusCode,
  ) {
    final status = (data['access_status'] ?? '').toString();
    final rawMessage = (data['error'] ?? data['message'] ?? '').toString();
    final titleFromServer = _friendlyTitle(data['title']?.toString());
    final isUnauthenticated =
        statusCode == 401 ||
        rawMessage.toLowerCase().contains('unauthenticated');

    if (isUnauthenticated) {
      return SearchAccessException(
        title: 'Sesi Login Berakhir',
        message: 'Silakan login kembali untuk melanjutkan pencarian.',
        status: status.isEmpty ? 'unauthenticated' : status,
        statusCode: statusCode,
      );
    }

    final isAccessRestriction =
        status == 'package_pending' ||
        status == 'package_inactive' ||
        status == 'pending' ||
        status == 'inactive';

    final title =
        titleFromServer ??
        (status == 'schedule_restricted'
            ? 'Di luar jam operasional'
            : isAccessRestriction
            ? 'Akses Dibatasi'
            : 'Pencarian Belum Tersedia');

    return SearchAccessException(
      title: title,
      message: rawMessage.isEmpty
          ? 'Pencarian belum dapat diproses. Silakan coba lagi.'
          : _friendlyMessage(rawMessage),
      status: status,
      statusCode: statusCode,
    );
  }

  static String? _friendlyTitle(String? title) {
    final value = title?.trim();
    if (value == null || value.isEmpty) return null;

    final lowerValue = value.toLowerCase();
    if (lowerValue.contains('error') ||
        lowerValue.contains('exception') ||
        lowerValue.contains('bermasalah')) {
      return null;
    }

    return value;
  }

  static String _friendlyMessage(String message) {
    final value = message.trim();
    final lowerValue = value.toLowerCase();

    if (lowerValue.contains('error') ||
        lowerValue.contains('exception') ||
        lowerValue.contains('bermasalah')) {
      return 'Pencarian belum dapat diproses. Silakan coba lagi.';
    }

    return value;
  }

  @override
  String toString() => message;
}

class _CacheEntry<T> {
  final T value;
  final DateTime createdAt;

  _CacheEntry(this.value) : createdAt = DateTime.now();

  bool isFresh(Duration lifetime) {
    return DateTime.now().difference(createdAt) < lifetime;
  }
}
