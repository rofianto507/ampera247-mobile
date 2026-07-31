class Rehab {
  final int id;
  final String code;
  final String nama;
  final String? jenisKelamin;
  final String? tempatLahir;
  final DateTime? tanggalLahir;
  final String? alamat;
  final int? tempatRehabId;
  final String? tempatRehabNama;
  final String? keterangan;
  final DateTime tanggalPengajuan;
  final DateTime? tanggalJadwal;
  final String state;

  const Rehab({
    required this.id,
    required this.code,
    required this.nama,
    this.jenisKelamin,
    this.tempatLahir,
    this.tanggalLahir,
    this.alamat,
    this.tempatRehabId,
    this.tempatRehabNama,
    this.keterangan,
    required this.tanggalPengajuan,
    this.tanggalJadwal,
    required this.state,
  });

  factory Rehab.fromJson(Map<String, dynamic> json) {
    final tempat = json['tempat_rehab_id'];
    return Rehab(
      id: json['id'] as int,
      code: json['code'] as String? ?? '-',
      nama: json['nama'] as String? ?? '-',
      jenisKelamin: json['jenis_kelamin'] is String ? json['jenis_kelamin'] as String : null,
      tempatLahir: json['tempat_lahir'] is String ? json['tempat_lahir'] as String : null,
      tanggalLahir: json['tanggal_lahir'] is String
          ? DateTime.tryParse(json['tanggal_lahir'] as String)
          : null,
      alamat: json['alamat'] is String ? json['alamat'] as String : null,
      tempatRehabId: tempat is List ? tempat[0] as int : null,
      tempatRehabNama: tempat is List ? tempat[1] as String : null,
      keterangan: json['keterangan'] is String ? json['keterangan'] as String : null,
      tanggalPengajuan: json['tanggal_pengajuan'] is String
          ? DateTime.parse(json['tanggal_pengajuan'] as String)
          : DateTime.now(),
      tanggalJadwal: json['tanggal_jadwal'] is String
          ? DateTime.parse('${json['tanggal_jadwal']}Z').toLocal()
          : null,
      state: json['state'] as String? ?? 'menunggu',
    );
  }
}
