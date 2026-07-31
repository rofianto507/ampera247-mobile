import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/eform_laka.dart';

// ── Daftar pilihan Yang Terlibat (master data) ─────────────────────────────
final yangTerlibatOptionsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final result = await api.callKw(
    model: 'digital_kamtibmas.yang_terlibat',
    method: 'search_read',
    args: [[]],
    kwargs: {
      'fields': ['id', 'nama', 'keterangan'],
      'order': 'nama asc',
    },
  );
  return (result as List).cast<Map<String, dynamic>>();
});

// ── Daftar laporan milik user ──────────────────────────────────────────────
final eformLakaListProvider =
    FutureProvider.autoDispose<List<EformLaka>>((ref) async {
  final api  = ref.watch(apiClientProvider);
  final user = ref.watch(authNotifierProvider).valueOrNull;
  if (user == null) return [];

  final result = await api.callKw(
    model: 'digital_kamtibmas.eform_laka',
    method: 'search_read',
    args: [
      [
        ['user_id', '=', user.id]
      ]
    ],
    kwargs: {
      'fields': [
        'code',
        'user_id',
        'yang_terlibat_id',
        'tanggal_kejadian',
        'jumlah_luka_luka',
        'jumlah_meninggal',
        'rumah_sakit',
        'keterangan',
        'state',
        'lat',
        'lng',
      ],
      'order': 'tanggal_kejadian desc',
    },
  );

  return (result as List)
      .map((e) => EformLaka.fromJson(e as Map<String, dynamic>))
      .toList();
});

// ── Foto satu laporan (lazy, hanya dimuat saat detail dibuka) ─────────────────
final lakaFotoProvider =
    FutureProvider.autoDispose.family<String?, int>((ref, id) async {
  final api = ref.watch(apiClientProvider);
  final result = await api.callKw(
    model: 'digital_kamtibmas.eform_laka',
    method: 'search_read',
    args: [
      [['id', '=', id]]
    ],
    kwargs: {
      'fields': ['foto'],
      'limit': 1,
    },
  );
  final list = result as List;
  if (list.isEmpty) return null;
  final foto = list[0]['foto'];
  return foto is String ? foto : null;
});

// ── Buat laporan baru ──────────────────────────────────────────────────────
Future<int> createEformLaka({
  required ApiClient api,
  required int yangTerlibatId,
  required DateTime tanggalKejadian,
  required int jumlahLukaLuka,
  required int jumlahMeninggal,
  String? rumahSakit,
  String? keterangan,
  String? fotoBase64,
  double? lat,
  double? lng,
}) async {
  final dt = tanggalKejadian.toUtc();
  final tanggal =
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';

  final id = await api.callKw(
    model: 'digital_kamtibmas.eform_laka',
    method: 'create',
    args: [
      {
        'yang_terlibat_id': yangTerlibatId,
        'tanggal_kejadian': tanggal,
        'jumlah_luka_luka': jumlahLukaLuka,
        'jumlah_meninggal': jumlahMeninggal,
        if (rumahSakit?.isNotEmpty ?? false) 'rumah_sakit': rumahSakit!,
        if (keterangan?.isNotEmpty ?? false) 'keterangan': keterangan!,
        if (fotoBase64 != null) 'foto': fotoBase64,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      }
    ],
  );
  return id as int;
}

// ── Hapus laporan ──────────────────────────────────────────────────────────────
Future<void> deleteEformLaka({
  required ApiClient api,
  required int id,
}) async {
  await api.callKw(
    model: 'digital_kamtibmas.eform_laka',
    method: 'unlink',
    args: [
      [id]
    ],
    kwargs: {},
  );
}
