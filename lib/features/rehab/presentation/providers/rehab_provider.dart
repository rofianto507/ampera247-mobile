import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/rehab.dart';

// ── Master data tempat rehabilitasi ───────────────────────────────────────────
final rehabTempatOptionsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final result = await api.callKw(
    model: 'digital_kamtibmas.rehab.tempat',
    method: 'search_read',
    args: [[]],
    kwargs: {
      'fields': ['id', 'name', 'alamat'],
      'order': 'name asc',
    },
  );
  return (result as List).cast<Map<String, dynamic>>();
});

// ── Daftar permohonan milik user ──────────────────────────────────────────────
final rehabListProvider =
    FutureProvider.autoDispose<List<Rehab>>((ref) async {
  final api  = ref.watch(apiClientProvider);
  final user = ref.watch(authNotifierProvider).valueOrNull;
  if (user == null) return [];

  final result = await api.callKw(
    model: 'digital_kamtibmas.rehab',
    method: 'search_read',
    args: [
      [['user_id', '=', user.id]]
    ],
    kwargs: {
      'fields': [
        'code', 'user_id', 'nama', 'jenis_kelamin',
        'tempat_rehab_id', 'keterangan', 'tanggal_pengajuan',
        'tanggal_jadwal', 'state',
      ],
      'order': 'id desc',
    },
  );
  return (result as List)
      .map((e) => Rehab.fromJson(e as Map<String, dynamic>))
      .toList();
});

// ── Foto pemohon — lazy ────────────────────────────────────────────────────────
final rehabFotoProvider =
    FutureProvider.autoDispose.family<String?, int>((ref, id) async {
  final api = ref.watch(apiClientProvider);
  final result = await api.callKw(
    model: 'digital_kamtibmas.rehab',
    method: 'search_read',
    args: [
      [['id', '=', id]]
    ],
    kwargs: {'fields': ['foto_pemohon'], 'limit': 1},
  );
  final list = result as List;
  if (list.isEmpty) return null;
  final foto = list[0]['foto_pemohon'];
  return foto is String ? foto : null;
});

// ── Buat permohonan baru ───────────────────────────────────────────────────────
Future<int> createRehab({
  required ApiClient api,
  required int userId,
  required String nama,
  String? jenisKelamin,
  String? tempatLahir,
  DateTime? tanggalLahir,
  String? alamat,
  int? tempatRehabId,
  String? keterangan,
  String? fotoPemohonBase64,
}) async {
  final id = await api.callKw(
    model: 'digital_kamtibmas.rehab',
    method: 'create',
    args: [
      {
        'user_id': userId,
        'nama': nama,
        if (jenisKelamin != null) 'jenis_kelamin': jenisKelamin,
        if (tempatLahir?.isNotEmpty ?? false) 'tempat_lahir': tempatLahir!,
        if (tanggalLahir != null)
          'tanggal_lahir':
              '${tanggalLahir.year}-${tanggalLahir.month.toString().padLeft(2, '0')}-${tanggalLahir.day.toString().padLeft(2, '0')}',
        if (alamat?.isNotEmpty ?? false) 'alamat': alamat!,
        if (tempatRehabId != null) 'tempat_rehab_id': tempatRehabId,
        if (keterangan?.isNotEmpty ?? false) 'keterangan': keterangan!,
        if (fotoPemohonBase64 != null) 'foto_pemohon': fotoPemohonBase64,
      }
    ],
  );
  return id as int;
}

// ── Hapus permohonan ──────────────────────────────────────────────────────────
Future<void> deleteRehab({
  required ApiClient api,
  required int id,
}) async {
  await api.callKw(
    model: 'digital_kamtibmas.rehab',
    method: 'unlink',
    args: [
      [id]
    ],
    kwargs: {},
  );
}
