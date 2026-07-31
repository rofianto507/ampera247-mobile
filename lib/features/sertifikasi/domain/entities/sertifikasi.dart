class Sertifikasi {
  final int id;
  final String name;
  final DateTime? tanggalAktif;
  final DateTime? tanggalExpired;
  final int jumlahSoal;
  final int waktuMenit;
  final int nilaiKelulusan;
  final String? notes;
  final String urlPublic;
  final int totalPeserta;
  final int totalLulus;

  const Sertifikasi({
    required this.id,
    required this.name,
    this.tanggalAktif,
    this.tanggalExpired,
    required this.jumlahSoal,
    required this.waktuMenit,
    required this.nilaiKelulusan,
    this.notes,
    required this.urlPublic,
    required this.totalPeserta,
    required this.totalLulus,
  });

  factory Sertifikasi.fromJson(Map<String, dynamic> json) {
    return Sertifikasi(
      id:             json['id'] as int,
      name:           json['name'] as String,
      tanggalAktif:   json['tanggal_aktif'] != null
          ? DateTime.tryParse(json['tanggal_aktif'] as String)
          : null,
      tanggalExpired: json['tanggal_expired'] != null
          ? DateTime.tryParse(json['tanggal_expired'] as String)
          : null,
      jumlahSoal:     json['jumlah_soal'] as int,
      waktuMenit:     json['waktu_menit'] as int,
      nilaiKelulusan: json['nilai_kelulusan'] as int,
      notes:          json['notes'] as String?,
      urlPublic:      json['url_public'] as String? ?? '',
      totalPeserta:   json['total_peserta'] as int,
      totalLulus:     json['total_lulus'] as int,
    );
  }
}
