import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../domain/entities/sertifikasi.dart';

final sertifikasiListProvider =
    FutureProvider.autoDispose<List<Sertifikasi>>((ref) async {
  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.baseUrl,
    contentType: 'application/json',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'X-Odoo-Database': AppConfig.dbName},
  ));

  final response = await dio.post(
    '/mobile/dkm/sertifikasi/list',
    data: {'jsonrpc': '2.0', 'method': 'call', 'params': {}},
  );

  final body = response.data as Map<String, dynamic>;
  if (body.containsKey('error')) {
    throw Exception(
      (body['error'] as Map)['message'] ?? 'Gagal memuat data sertifikasi',
    );
  }

  final result = body['result'] as Map<String, dynamic>;
  if (result['success'] != true) {
    throw Exception('Gagal memuat data sertifikasi');
  }

  return (result['data'] as List)
      .map((e) => Sertifikasi.fromJson(e as Map<String, dynamic>))
      .toList();
});
