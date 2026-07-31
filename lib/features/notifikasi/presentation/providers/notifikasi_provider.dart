import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/notifikasi.dart';

final notifikasiListProvider =
    FutureProvider.autoDispose<List<NotifikasiItem>>((ref) async {
  final api  = ref.watch(apiClientProvider);
  final user = ref.watch(authNotifierProvider).valueOrNull;
  if (user == null) return [];

  final result = await api.callKw(
    model: 'digital_kamtibmas.notifikasi',
    method: 'search_read',
    args: [
      [['user_id', '=', user.id]]
    ],
    kwargs: {
      'fields': ['id', 'judul', 'isi', 'tipe', 'is_read', 'created_at'],
      'order': 'created_at desc',
      'limit': 50,
    },
  );
  return (result as List)
      .map((e) => NotifikasiItem.fromJson(e as Map<String, dynamic>))
      .toList();
});

final unreadCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final api  = ref.watch(apiClientProvider);
  final user = ref.watch(authNotifierProvider).valueOrNull;
  if (user == null) return 0;

  final result = await api.callKw(
    model: 'digital_kamtibmas.notifikasi',
    method: 'search_count',
    args: [
      [
        ['user_id', '=', user.id],
        ['is_read', '=', false],
      ]
    ],
    kwargs: {},
  );
  return result as int? ?? 0;
});

Future<void> markAllRead({required ApiClient api, required int userId}) async {
  final ids = await api.callKw(
    model: 'digital_kamtibmas.notifikasi',
    method: 'search',
    args: [
      [
        ['user_id', '=', userId],
        ['is_read', '=', false],
      ]
    ],
    kwargs: {'limit': 200},
  );
  final list = ids as List;
  if (list.isEmpty) return;
  await api.callKw(
    model: 'digital_kamtibmas.notifikasi',
    method: 'write',
    args: [list.cast<int>(), {'is_read': true}],
    kwargs: {},
  );
}
