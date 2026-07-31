class Antrian {
  final int id;
  final String nomorAntrian;
  final int nomorUrut;
  final String atasNama;
  final DateTime tanggalBooking;
  final int loketId;
  final String loketNama;
  final String? layananNama;
  final String state; // menunggu|konfirmasi|dipanggil|selesai|batal
  final String? catatan;

  const Antrian({
    required this.id,
    required this.nomorAntrian,
    required this.nomorUrut,
    required this.atasNama,
    required this.tanggalBooking,
    required this.loketId,
    required this.loketNama,
    this.layananNama,
    required this.state,
    this.catatan,
  });

  factory Antrian.fromJson(Map<String, dynamic> json) {
    final loket   = json['loket_id']   as List;
    final layanan = json['layanan_id'];

    return Antrian(
      id:             json['id'] as int,
      nomorAntrian:   json['nomor_antrian'] as String,
      nomorUrut:      json['nomor_urut'] as int,
      atasNama:       json['atas_nama'] as String,
      tanggalBooking: DateTime.parse(json['tanggal_booking'] as String),
      loketId:        loket[0] as int,
      loketNama:      loket[1] as String,
      layananNama:    layanan is List ? layanan[1] as String : null,
      state:          json['state'] as String,
      catatan:        json['catatan'] is String ? json['catatan'] as String : null,
    );
  }
}
