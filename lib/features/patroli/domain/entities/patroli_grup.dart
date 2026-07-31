class PatroliGrup {
  final int id;
  final String name;
  final String? noPol;
  final String jenisKendaraan;
  final String? keterangan;

  const PatroliGrup({
    required this.id,
    required this.name,
    this.noPol,
    required this.jenisKendaraan,
    this.keterangan,
  });

  factory PatroliGrup.fromJson(Map<String, dynamic> json) {
    return PatroliGrup(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      noPol: json['no_pol'] is String ? json['no_pol'] as String : null,
      jenisKendaraan: json['jenis_kendaraan'] as String? ?? 'mobil',
      keterangan: json['keterangan'] is String ? json['keterangan'] as String : null,
    );
  }

  String get jenisLabel => switch (jenisKendaraan) {
        'mobil' => 'Mobil',
        'motor' => 'Motor',
        _ => 'Lainnya',
      };

  String get jenisIcon => switch (jenisKendaraan) {
        'motor' => '🏍️',
        _ => '🚔',
      };
}
