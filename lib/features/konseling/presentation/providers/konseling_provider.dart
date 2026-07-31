import '../../../../core/network/api_client.dart';
import '../../domain/entities/konseling.dart';

Future<List<Konseling>> fetchMyKonseling({
  required ApiClient api,
  required int userId,
}) async {
  final result = await api.callKw(
    model: 'digital_kamtibmas.konseling',
    method: 'search_read',
    args: [
      [
        ['user_id', '=', userId],
      ]
    ],
    kwargs: {
      'fields': [
        'code', 'nama', 'tanggal_pengajuan', 'tanggal_jadwal',
        'konselor_id', 'keterangan', 'state', 'channel_id',
      ],
      'order': 'id desc',
      'limit': 50,
    },
  );
  return (result as List)
      .map((e) => Konseling.fromJson(e as Map<String, dynamic>))
      .toList();
}

Future<int> createKonseling({
  required ApiClient api,
  required Map<String, dynamic> data,
}) async {
  final result = await api.callKw(
    model: 'digital_kamtibmas.konseling',
    method: 'create',
    args: [data],
    kwargs: {},
  );
  return result as int;
}
