class BarangBukti {
  final int id;
  final String code;
  final String? nomorPerkara;
  final String jenisKendaraan;
  final String jenisKendaraanLabel;
  final String? merek;
  final String? tipe;
  final String? warna;
  final int? tahunKendaraan;
  final String? nomorPolisi;
  final String? nomorRangka;
  final String? nomorMesin;
  final String namaPerlapor;
  final String? namaPemilikStnk;
  final DateTime? tanggalPenerimaan;
  final String? lokasiPenyimpanan;
  final String state;

  const BarangBukti({
    required this.id,
    required this.code,
    this.nomorPerkara,
    required this.jenisKendaraan,
    required this.jenisKendaraanLabel,
    this.merek,
    this.tipe,
    this.warna,
    this.tahunKendaraan,
    this.nomorPolisi,
    this.nomorRangka,
    this.nomorMesin,
    required this.namaPerlapor,
    this.namaPemilikStnk,
    this.tanggalPenerimaan,
    this.lokasiPenyimpanan,
    required this.state,
  });

  String get stateLabel => _stateLabels[state] ?? state;

  static const _stateLabels = <String, String>{
    'diterima':     'Diterima',
    'disimpan':     'Disimpan',
    'diproses':     'Diproses',
    'dikembalikan': 'Dikembalikan',
    'dimusnahkan':  'Dimusnahkan',
  };

  static const _jenisLabels = <String, String>{
    'roda_dua':   'Sepeda Motor',
    'roda_empat': 'Kendaraan Roda 4',
    'roda_tiga':  'Kendaraan Roda 3',
    'lainnya':    'Lainnya',
  };

  factory BarangBukti.fromJson(Map<String, dynamic> json) {
    final jenis = json['jenis_kendaraan'] as String? ?? 'lainnya';
    return BarangBukti(
      id:                 json['id'] as int,
      code:               json['code'] as String,
      nomorPerkara:       _str(json['nomor_perkara']),
      jenisKendaraan:     jenis,
      jenisKendaraanLabel: _jenisLabels[jenis] ?? jenis,
      merek:              _str(json['merek']),
      tipe:               _str(json['tipe']),
      warna:              _str(json['warna']),
      tahunKendaraan:     json['tahun_kendaraan'] is int && json['tahun_kendaraan'] != 0
                              ? json['tahun_kendaraan'] as int : null,
      nomorPolisi:        _str(json['nomor_polisi']),
      nomorRangka:        _str(json['nomor_rangka']),
      nomorMesin:         _str(json['nomor_mesin']),
      namaPerlapor:       json['nama_pelapor'] as String? ?? '-',
      namaPemilikStnk:    _str(json['nama_pemilik_stnk']),
      tanggalPenerimaan:  json['tanggal_penerimaan'] is String
                              ? DateTime.tryParse(json['tanggal_penerimaan'] as String) : null,
      lokasiPenyimpanan:  _str(json['lokasi_penyimpanan']),
      state:              json['state'] as String,
    );
  }

  static String? _str(dynamic v) => v is String && v.isNotEmpty ? v : null;
}
