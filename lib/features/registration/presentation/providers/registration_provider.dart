import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';

enum RegStatus { idle, loading, success, error }

class RegState {
  final RegStatus status;
  final String? error;
  final String? login;
  const RegState({this.status = RegStatus.idle, this.error, this.login});
}

/// Hasil pengecekan ketersediaan username. [error] berisi alasan bila
/// [available] false; null + false berarti pengecekan gagal (jaringan).
class UsernameCheck {
  final bool available;
  final String? error;
  const UsernameCheck({required this.available, this.error});
}

class RegNotifier extends Notifier<RegState> {
  @override
  RegState build() => const RegState();

  // Endpoint v2 (username + password). Endpoint lama /mobile/dkm/register
  // (login = nomor WA) masih dipakai app versi lama, jangan diubah.
  Dio _dio() => Dio(BaseOptions(
        baseUrl: AppConfig.baseUrl,
        contentType: 'application/json',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'X-Odoo-Database': AppConfig.dbName},
      ));

  Future<UsernameCheck> checkUsername(String username) async {
    try {
      final response = await _dio().post(
        '/mobile/dkm/v2/check-username',
        data: {
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {'username': username},
        },
      );
      final body = response.data as Map<String, dynamic>;
      if (body.containsKey('error')) {
        return const UsernameCheck(
            available: false, error: 'Gagal memeriksa username');
      }
      final result = body['result'] as Map<String, dynamic>;
      return UsernameCheck(
        available: result['available'] == true,
        error: result['error'] as String?,
      );
    } on DioException {
      return const UsernameCheck(
          available: false, error: 'Koneksi gagal. Periksa jaringan Anda.');
    } catch (_) {
      return const UsernameCheck(
          available: false, error: 'Gagal memeriksa username');
    }
  }

  Future<void> register({
    required String username,
    required String nama,
    required String password,
    String? fotoBase64,
  }) async {
    state = const RegState(status: RegStatus.loading);
    try {
      final payload = <String, dynamic>{
        'username': username,
        'nama': nama,
        'password': password,
      };
      if (fotoBase64 != null && fotoBase64.isNotEmpty) {
        payload['foto'] = fotoBase64;
      }

      final response = await _dio().post(
        '/mobile/dkm/v2/register',
        data: {
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {'data': payload},
        },
      );

      final body = response.data as Map<String, dynamic>;
      if (body.containsKey('error')) {
        final errData = body['error'] as Map;
        final msg = errData['data']?['message'] as String? ??
            errData['message'] as String? ??
            'Terjadi kesalahan server';
        state = RegState(status: RegStatus.error, error: msg);
        return;
      }

      final result = body['result'] as Map<String, dynamic>;
      if (result['success'] == true) {
        state = RegState(
          status: RegStatus.success,
          login: result['login'] as String?,
        );
      } else {
        state = RegState(
          status: RegStatus.error,
          error: result['error'] as String? ?? 'Registrasi gagal',
        );
      }
    } on DioException {
      state = const RegState(
        status: RegStatus.error,
        error: 'Koneksi gagal. Periksa jaringan Anda.',
      );
    } catch (e) {
      state = RegState(status: RegStatus.error, error: 'Terjadi kesalahan: $e');
    }
  }

  void reset() => state = const RegState();
}

final registrationProvider =
    NotifierProvider<RegNotifier, RegState>(RegNotifier.new);
