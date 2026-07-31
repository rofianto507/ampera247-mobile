class Patroli {
  final int id;
  final String code;
  final String state;
  final DateTime tanggalPatroli;
  final DateTime? tanggalSelesai;
  final int? grupId;
  final String? grupName;
  final int? kecamatanId;
  final String? kecamatanName;
  final int? desaId;
  final String? desaName;
  final String? keterangan;

  const Patroli({
    required this.id,
    required this.code,
    required this.state,
    required this.tanggalPatroli,
    this.tanggalSelesai,
    this.grupId,
    this.grupName,
    this.kecamatanId,
    this.kecamatanName,
    this.desaId,
    this.desaName,
    this.keterangan,
  });

  factory Patroli.fromJson(Map<String, dynamic> json) {
    final grup = json['grup_id'];
    final kec  = json['kecamatan_id'];
    final desa = json['desa_id'];
    return Patroli(
      id:   json['id'] as int,
      code: json['code'] as String? ?? '-',
      state: json['state'] as String? ?? 'menunggu',
      tanggalPatroli: json['tanggal_patroli'] != null
          ? DateTime.parse('${json['tanggal_patroli']}Z').toLocal()
          : DateTime.now(),
      tanggalSelesai: json['tanggal_selesai'] is String
          ? DateTime.parse('${json['tanggal_selesai']}Z').toLocal()
          : null,
      grupId:       grup is List ? grup[0] as int    : null,
      grupName:     grup is List ? grup[1] as String : null,
      kecamatanId:  kec  is List ? kec[0]  as int    : null,
      kecamatanName: kec is List ? kec[1]  as String : null,
      desaId:       desa is List ? desa[0] as int    : null,
      desaName:     desa is List ? desa[1] as String : null,
      keterangan:   json['keterangan'] is String ? json['keterangan'] as String : null,
    );
  }

  String get stateLabel => switch (state) {
        'menunggu' => 'Menunggu',
        'berjalan' => 'Berjalan',
        'selesai'  => 'Selesai',
        _ => state,
      };

  Duration? get durasi {
    if (tanggalSelesai == null) return null;
    return tanggalSelesai!.difference(tanggalPatroli);
  }
}
