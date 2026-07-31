class Konseling {
  final int id;
  final String code;
  final String nama;
  final String? nik;
  final String? noHp;
  final String? jenisKelamin;
  final String? tempatLahir;
  final String? tanggalLahir;
  final String? alamat;
  final String? keterangan;
  final String? tanggalPengajuan;
  final String? tanggalJadwal;
  final String? konselorNama;
  final String state;
  final int? channelId;

  const Konseling({
    required this.id,
    required this.code,
    required this.nama,
    this.nik,
    this.noHp,
    this.jenisKelamin,
    this.tempatLahir,
    this.tanggalLahir,
    this.alamat,
    this.keterangan,
    this.tanggalPengajuan,
    this.tanggalJadwal,
    this.konselorNama,
    required this.state,
    this.channelId,
  });

  String get stateLabel => const {
        'menunggu':   'Menunggu',
        'konfirmasi': 'Dikonfirmasi',
        'proses':     'Sedang Diproses',
        'selesai':    'Selesai',
      }[state] ??
      state;

  factory Konseling.fromJson(Map<String, dynamic> j) => Konseling(
        id:               j['id'] as int,
        code:             j['code'] as String? ?? '-',
        nama:             j['nama'] as String? ?? '-',
        nik:              _str(j['nik']),
        noHp:             _str(j['no_hp']),
        jenisKelamin:     _str(j['jenis_kelamin']),
        tempatLahir:      _str(j['tempat_lahir']),
        tanggalLahir:     _str(j['tanggal_lahir']),
        alamat:           _str(j['alamat']),
        keterangan:       _str(j['keterangan']),
        tanggalPengajuan: _str(j['tanggal_pengajuan']),
        tanggalJadwal:    _str(j['tanggal_jadwal']),
        konselorNama:     j['konselor_id'] is List
            ? (j['konselor_id'] as List)[1] as String?
            : null,
        state:            j['state'] as String? ?? 'menunggu',
        channelId:        j['channel_id'] is List
            ? (j['channel_id'] as List)[0] as int?
            : null,
      );

  static String? _str(dynamic v) => v is String && v.isNotEmpty ? v : null;
}
