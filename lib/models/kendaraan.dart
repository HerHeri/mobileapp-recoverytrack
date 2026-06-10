class Kendaraan {
  final String noPolisi;
  final String? noMesin;
  final String? noRangka;
  final String? typeMotor;
  final String? namaStnk;
  final String? cabang;

  Kendaraan({
    required this.noPolisi,
    this.noMesin,
    this.noRangka,
    this.typeMotor,
    this.namaStnk,
    this.cabang,
  });

  factory Kendaraan.fromJson(Map<String, dynamic> json) {
    return Kendaraan(
      noPolisi: json['no_polisi'] ?? '',
      noMesin: json['no_mesin'],
      noRangka: json['no_rangka'],
      typeMotor: json['type_motor'],
      namaStnk: json['nama_stnk'],
      cabang: json['cabang'],
    );
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
