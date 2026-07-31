import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../constants/app_constants.dart';

class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;

  AuthInterceptor(this._storage);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Web: browser sends session cookie automatically via withCredentials.
    // Native: manually attach session_id cookie from secure storage.
    if (!kIsWeb) {
      final token = await _storage.read(key: AppConstants.tokenKey);
      if (token != null) {
        options.headers['Cookie'] = 'session_id=$token';
      }
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 401 is handled at the repository level to trigger re-login
    handler.next(err);
  }
}
