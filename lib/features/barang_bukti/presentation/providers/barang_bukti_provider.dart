import '../../../../core/network/api_client.dart';
import '../../domain/entities/barang_bukti.dart';

Future<List<BarangBukti>> searchBarangBukti({
  required ApiClient api,
  required String filterType, // 'nopol' | 'rangka' | 'mesin'
  required String query,
}) async {
  final response = await api.dio.post(
    '/api/dkm/barang-bukti/cari',
    data: {
      'jsonrpc': '2.0',
      'method': 'call',
      'params': {
        'filter_type': filterType,
        'query': query,
      },
    },
  );

  final body = response.data as Map<String, dynamic>;
  if (body.containsKey('error')) {
    final err = body['error'] as Map;
    throw Exception(err['data']?['message'] ?? err['message'] ?? 'Server error');
  }

  final result = body['result'] as Map<String, dynamic>;
  if (result['ok'] != true) {
    throw Exception(result['error'] ?? 'Pencarian gagal');
  }

  return (result['data'] as List)
      .map((e) => BarangBukti.fromJson(e as Map<String, dynamic>))
      .toList();
}
