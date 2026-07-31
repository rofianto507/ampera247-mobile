import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/antrian.dart';

// ── Jenis Layanan aktif (untuk dropdown form) ────────────────────────────────
final jenisLayananOptionsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final result = await api.callKw(
    model: 'digital_kamtibmas.jenis_layanan',
    method: 'search_read',
    args: [[['active', '=', true]]],
    kwargs: {
      'fields': ['id', 'name', 'code'],
      'order': 'name asc',
    },
  );
  return (result as List).cast<Map<String, dynamic>>();
});

// ── Loket aktif per jenis layanan (untuk dropdown form) ──────────────────────
final loketOptionsProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, int>(
        (ref, layananId) async {
  final api = ref.watch(apiClientProvider);
  final result = await api.callKw(
    model: 'digital_kamtibmas.loket',
    method: 'search_read',
    args: [
      [
        ['layanan_id', '=', layananId],
        ['state', '=', 'aktif'],
      ]
    ],
    kwargs: {
      'fields': ['id', 'name', 'kuota'],
      'order': 'name asc',
    },
  );
  return (result as List).cast<Map<String, dynamic>>();
});

// ── Daftar antrian milik user ─────────────────────────────────────────────────
final antrianListProvider =
    FutureProvider.autoDispose<List<Antrian>>((ref) async {
  final api  = ref.watch(apiClientProvider);
  final user = ref.watch(authNotifierProvider).valueOrNull;
  if (user == null) return [];

  final result = await api.callKw(
    model: 'digital_kamtibmas.antrian',
    method: 'search_read',
    args: [
      [['user_id', '=', user.id]]
    ],
    kwargs: {
      'fields': [
        'nomor_antrian', 'nomor_urut', 'atas_nama',
        'tanggal_booking', 'loket_id', 'layanan_id',
        'state', 'catatan',
      ],
      'order': 'id desc',
    },
  );
  return (result as List)
      .map((e) => Antrian.fromJson(e as Map<String, dynamic>))
      .toList();
});

// ── Buat antrian baru ─────────────────────────────────────────────────────────
Future<String> createAntrian({
  required ApiClient api,
  required int userId,
  required String atasNama,
  required int loketId,
  required DateTime tanggalBooking,
  String? catatan,
}) async {
  final tgl =
      '${tanggalBooking.year}-${tanggalBooking.month.toString().padLeft(2, '0')}-${tanggalBooking.day.toString().padLeft(2, '0')}';

  final id = await api.callKw(
    model: 'digital_kamtibmas.antrian',
    method: 'create',
    args: [
      {
        'user_id': userId,
        'atas_nama': atasNama,
        'loket_id': loketId,
        'tanggal_booking': tgl,
        if (catatan?.isNotEmpty ?? false) 'catatan': catatan!,
      }
    ],
  );

  // Ambil nomor antrian yang di-generate server
  final result = await api.callKw(
    model: 'digital_kamtibmas.antrian',
    method: 'search_read',
    args: [
      [['id', '=', id]]
    ],
    kwargs: {
      'fields': ['nomor_antrian'],
      'limit': 1,
    },
  );
  final list = result as List;
  return list.isNotEmpty ? list[0]['nomor_antrian'] as String : '-';
}

// ── Batalkan antrian ──────────────────────────────────────────────────────────
Future<void> batalAntrian({
  required ApiClient api,
  required int id,
}) async {
  await api.callKw(
    model: 'digital_kamtibmas.antrian',
    method: 'action_batal',
    args: [[id]],
    kwargs: {},
  );
}
