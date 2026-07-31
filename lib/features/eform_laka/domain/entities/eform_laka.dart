class EformLaka {
  final int id;
  final String code;
  final int? yangTerlibatId;
  final String? yangTerlibatNama;
  final String? rumahSakit;
  final String? keterangan;
  final int jumlahLukaLuka;
  final int jumlahMeninggal;
  final DateTime tanggalKejadian;
  final String state;
  final double? lat;
  final double? lng;

  const EformLaka({
    required this.id,
    required this.code,
    this.yangTerlibatId,
    this.yangTerlibatNama,
    this.rumahSakit,
    this.keterangan,
    required this.jumlahLukaLuka,
    required this.jumlahMeninggal,
    required this.tanggalKejadian,
    required this.state,
    this.lat,
    this.lng,
  });

  factory EformLaka.fromJson(Map<String, dynamic> json) {
    final yt = json['yang_terlibat_id'];
    return EformLaka(
      id: json['id'] as int,
      code: json['code'] as String? ?? '-',
      yangTerlibatId: yt is List ? yt[0] as int : null,
      yangTerlibatNama: yt is List ? yt[1] as String : null,
      rumahSakit:
          json['rumah_sakit'] is String ? json['rumah_sakit'] as String : null,
      keterangan:
          json['keterangan'] is String ? json['keterangan'] as String : null,
      jumlahLukaLuka: (json['jumlah_luka_luka'] as int?) ?? 0,
      jumlahMeninggal: (json['jumlah_meninggal'] as int?) ?? 0,
      tanggalKejadian: json['tanggal_kejadian'] != null
          ? DateTime.parse('${json['tanggal_kejadian']}Z').toLocal()
          : DateTime.now(),
      state: json['state'] as String? ?? 'BARU',
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
    );
  }
}
