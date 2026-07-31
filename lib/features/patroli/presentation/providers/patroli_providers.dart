import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/patroli_grup.dart';
import '../../domain/entities/patroli.dart';

final patroliGrupProvider = FutureProvider.autoDispose<PatroliGrup?>((ref) async {
  final api  = ref.watch(apiClientProvider);
  final user = ref.watch(authNotifierProvider).valueOrNull;
  if (user == null) return null;

  final result = await api.callKw(
    model: 'digital_kamtibmas.patroli_grup',
    method: 'search_read',
    args: [[['user_id', '=', user.id]]],
    kwargs: {
      'fields': ['id', 'name', 'no_pol', 'jenis_kendaraan', 'keterangan'],
      'limit': 1,
    },
  );
  final list = result as List;
  if (list.isEmpty) return null;
  return PatroliGrup.fromJson(list[0] as Map<String, dynamic>);
});

final activePatroliProvider = FutureProvider.autoDispose<Patroli?>((ref) async {
  final grup = await ref.watch(patroliGrupProvider.future);
  if (grup == null) return null;
  final api = ref.watch(apiClientProvider);

  final result = await api.callKw(
    model: 'digital_kamtibmas.patroli',
    method: 'search_read',
    args: [[['grup_id', '=', grup.id], ['state', '=', 'berjalan']]],
    kwargs: {
      'fields': ['id', 'code', 'state', 'tanggal_patroli', 'grup_id', 'kecamatan_id', 'desa_id'],
      'limit': 1,
    },
  );
  final list = result as List;
  if (list.isEmpty) return null;
  return Patroli.fromJson(list[0] as Map<String, dynamic>);
});

final patroliHistoryProvider = FutureProvider.autoDispose<List<Patroli>>((ref) async {
  final grup = await ref.watch(patroliGrupProvider.future);
  if (grup == null) return [];
  final api = ref.watch(apiClientProvider);

  final result = await api.callKw(
    model: 'digital_kamtibmas.patroli',
    method: 'search_read',
    args: [[['grup_id', '=', grup.id], ['state', '!=', 'berjalan']]],
    kwargs: {
      'fields': [
        'id', 'code', 'state', 'tanggal_patroli', 'tanggal_selesai',
        'kecamatan_id', 'desa_id',
      ],
      'order': 'id desc',
      'limit': 20,
    },
  );
  return (result as List)
      .map((e) => Patroli.fromJson(e as Map<String, dynamic>))
      .toList();
});

final kecamatanOptionsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final result = await api.callKw(
    model: 'digital_kamtibmas.kecamatan',
    method: 'search_read',
    args: [[]],
    kwargs: {'fields': ['id', 'name'], 'order': 'name asc'},
  );
  return (result as List).cast<Map<String, dynamic>>();
});

final desaByKecamatanProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, int>(
  (ref, kecId) async {
    final api = ref.watch(apiClientProvider);
    final result = await api.callKw(
      model: 'digital_kamtibmas.desa',
      method: 'search_read',
      args: [[['kecamatan_id', '=', kecId]]],
      kwargs: {'fields': ['id', 'name'], 'order': 'name asc'},
    );
    return (result as List).cast<Map<String, dynamic>>();
  },
);

final patroliPersonelProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, int>(
  (ref, patroliId) async {
    final api = ref.watch(apiClientProvider);
    final result = await api.callKw(
      model: 'digital_kamtibmas.patroli_personel',
      method: 'search_read',
      args: [[['patroli_id', '=', patroliId]]],
      kwargs: {
        'fields': ['nama', 'pangkat', 'sequence'],
        'order': 'sequence asc, id asc',
      },
    );
    return (result as List).cast<Map<String, dynamic>>();
  },
);

final patroliDetailProvider =
    FutureProvider.autoDispose.family<Patroli?, int>((ref, id) async {
  final api = ref.watch(apiClientProvider);
  final result = await api.callKw(
    model: 'digital_kamtibmas.patroli',
    method: 'search_read',
    args: [[['id', '=', id]]],
    kwargs: {
      'fields': [
        'id', 'code', 'state', 'tanggal_patroli', 'tanggal_selesai',
        'grup_id', 'kecamatan_id', 'desa_id', 'keterangan',
      ],
      'limit': 1,
    },
  );
  final list = result as List;
  if (list.isEmpty) return null;
  return Patroli.fromJson(list[0] as Map<String, dynamic>);
});

final patroliTitikProvider =
    FutureProvider.autoDispose.family<List<LatLng>, int>((ref, patroliId) async {
  final api = ref.watch(apiClientProvider);
  final result = await api.callKw(
    model: 'digital_kamtibmas.patroli_titik',
    method: 'search_read',
    args: [[['patroli_id', '=', patroliId]]],
    kwargs: {
      'fields': ['latitude', 'longitude', 'waktu_rekam'],
      'order': 'waktu_rekam asc, id asc',
    },
  );
  return (result as List).map((e) {
    final m = e as Map<String, dynamic>;
    return LatLng(
      (m['latitude'] as num).toDouble(),
      (m['longitude'] as num).toDouble(),
    );
  }).toList();
});
