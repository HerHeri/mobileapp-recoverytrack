class Kendaraan {
  final String noPolisi;
  final String? noMesin;
  final String? noRangka;
  final String? typeMotor;
  final String? namaStnk;
  final String? leasing;
  final String? cabang;
  final String? tahun;
  final String? noHp;
  final String? warna;

  Kendaraan({
    required this.noPolisi,
    this.noMesin,
    this.noRangka,
    this.typeMotor,
    this.namaStnk,
    this.leasing,
    this.cabang,
    this.tahun,
    this.noHp,
    this.warna,
  });

  factory Kendaraan.fromJson(Map<String, dynamic> json) {
    return Kendaraan(
      noPolisi: json['no_polisi'] ?? '',
      noMesin: json['no_mesin'],
      noRangka: json['no_rangka'],
      typeMotor: json['type_motor'],
      namaStnk: json['nama_stnk'],
      leasing: json['nama_leasing'] ?? json['leasing'],
      cabang: json['nama_cabang'] ?? json['cabang'],
      tahun: _firstValue(json, const [
        'tahun',
        'tahun_kendaraan',
        'tahun_motor',
        'year',
      ]),
      noHp: _firstValue(json, const [
        'no_hp',
        'nomor_hp',
        'phone',
        'no_handphone',
        'contact_person',
      ]),
      warna: _firstValue(json, const [
        'warna',
        'warna_kendaraan',
        'warna_motor',
        'color',
      ]),
    );
  }

  Map<String, dynamic> toDetailJson() {
    return {
      'no_polisi': noPolisi,
      'no_mesin': noMesin,
      'no_rangka': noRangka,
      'type_motor': typeMotor,
      'nama_stnk': namaStnk,
      'nama_leasing': leasing,
      'nama_cabang': cabang,
      'tahun': tahun,
      'no_hp': noHp,
      'warna': warna,
    };
  }

  static String? _firstValue(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }
}

class SearchMeta {
  final String query;
  final String field;
  final String source;
  final double responseTimeMs;
  final int count;
  final int limit;

  SearchMeta({
    required this.query,
    required this.field,
    required this.source,
    required this.responseTimeMs,
    required this.count,
    required this.limit,
  });

  factory SearchMeta.fromJson(Map<String, dynamic> json) {
    return SearchMeta(
      query: json['query'] ?? '',
      field: json['field'] ?? '',
      source: json['source'] ?? '',
      responseTimeMs: (json['response_time_ms'] ?? 0).toDouble(),
      count: json['count'] ?? 0,
      limit: json['limit'] ?? 0,
    );
  }
}

/// Model kendaraan untuk Admin Panel (extended dengan field admin)
class KendaraanAdmin {
  final int id;
  final String noPolisi;
  final String? noMesin;
  final String? noRangka;
  final String? typeMotor;
  final String? namaStnk;
  final String? warna;
  final String? tahun;
  final String? noHp;
  final String? nomorKontrak;
  final int? leasingId;
  final String? namaLeasing;
  final int? cabangId;
  final String? namaCabang;
  final int? narasumberId;
  final String? ovd;

  KendaraanAdmin({
    required this.id,
    required this.noPolisi,
    this.noMesin,
    this.noRangka,
    this.typeMotor,
    this.namaStnk,
    this.warna,
    this.tahun,
    this.noHp,
    this.nomorKontrak,
    this.leasingId,
    this.namaLeasing,
    this.cabangId,
    this.namaCabang,
    this.narasumberId,
    this.ovd,
  });

  factory KendaraanAdmin.fromJson(Map<String, dynamic> json) {
    final leasing = json['leasing'] as Map<String, dynamic>?;
    final cabang = json['cabang'] as Map<String, dynamic>?;

    return KendaraanAdmin(
      id: json['id'] ?? 0,
      noPolisi: json['no_polisi'] ?? '',
      noMesin: json['no_mesin']?.toString(),
      noRangka: json['no_rangka']?.toString(),
      typeMotor: json['type_motor']?.toString(),
      namaStnk: json['nama_stnk']?.toString(),
      warna: json['warna']?.toString(),
      tahun: json['tahun']?.toString(),
      noHp: json['no_hp']?.toString(),
      nomorKontrak: json['nomor_kontrak']?.toString(),
      leasingId: leasing != null
          ? (leasing['id'] as int?)
          : (json['leasing_id'] as int?),
      namaLeasing: leasing != null
          ? leasing['nama_leasing']?.toString()
          : json['nama_leasing']?.toString(),
      cabangId: cabang != null
          ? (cabang['id'] as int?)
          : (json['cabang_id'] as int?),
      namaCabang: cabang != null
          ? cabang['nama_cabang']?.toString()
          : json['nama_cabang']?.toString(),
      narasumberId: json['narasumber_id'] as int?,
      ovd: json['ovd']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'no_polisi': noPolisi,
      if (noMesin != null) 'no_mesin': noMesin,
      if (noRangka != null) 'no_rangka': noRangka,
      if (typeMotor != null) 'type_motor': typeMotor,
      if (namaStnk != null) 'nama_stnk': namaStnk,
      if (warna != null) 'warna': warna,
      if (tahun != null) 'tahun': tahun,
      if (noHp != null) 'no_hp': noHp,
      if (nomorKontrak != null) 'nomor_kontrak': nomorKontrak,
      if (leasingId != null) 'leasing_id': leasingId,
      if (cabangId != null) 'cabang_id': cabangId,
      if (narasumberId != null) 'narasumber_id': narasumberId,
      if (ovd != null) 'ovd': ovd,
    };
  }
}

/// Response paginasi dari GET /v1/admin/kendaraan
class PaginatedKendaraan {
  final List<KendaraanAdmin> data;
  final int currentPage;
  final int lastPage;
  final int total;
  final int perPage;

  PaginatedKendaraan({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.perPage,
  });

  factory PaginatedKendaraan.fromJson(Map<String, dynamic> json) {
    final root = json['data'] as Map<String, dynamic>? ?? {};

    List<dynamic> rawItems = [];
    Map<String, dynamic> meta = {};

    if (root.containsKey('items')) {
      // Format baru
      rawItems = root['items'] as List<dynamic>? ?? [];
      meta = root['meta'] as Map<String, dynamic>? ?? {};
    } else {
      // Format paginator Laravel
      rawItems = root['data'] as List<dynamic>? ?? [];
      meta = root;
    }

    return PaginatedKendaraan(
      data: rawItems
          .map((e) => KendaraanAdmin.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentPage: meta['current_page'] ?? 1,
      lastPage: meta['last_page'] ?? 1,
      total: meta['total'] ?? rawItems.length,
      perPage: meta['per_page'] ?? 20,
    );
  }

  bool get hasMore => currentPage < lastPage;
}

/// Status progress import kendaraan
class ImportProgress {
  final String status; // 'pending' | 'processing' | 'done' | 'error'
  final int processed;
  final int total;
  final String? message;
  final List<String> errors;

  ImportProgress({
    required this.status,
    required this.processed,
    required this.total,
    this.message,
    this.errors = const [],
  });

  factory ImportProgress.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] is Map)
        ? json['data'] as Map<String, dynamic>
        : json;
    final rawErrors = data['errors'];
    final errorList = rawErrors is List
        ? rawErrors.map((e) => e.toString()).toList()
        : <String>[];
    return ImportProgress(
      status: data['status']?.toString() ?? 'pending',
      processed: (data['processed'] as int?) ?? 0,
      total: (data['total'] as int?) ?? 0,
      message: data['message']?.toString(),
      errors: errorList,
    );
  }

  double get progress => total > 0 ? processed / total : 0.0;
  String get normalizedStatus => status.toLowerCase().trim();
  bool get isDone =>
      const ['done', 'completed', 'success'].contains(normalizedStatus);
  bool get isError => const ['error', 'failed'].contains(normalizedStatus);
  bool get isFinished => isDone || isError;
}
