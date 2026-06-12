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
