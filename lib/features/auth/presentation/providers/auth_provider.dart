import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/session_expired_notifier.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (_) => const FlutterSecureStorage(),
);

final sessionExpiredProvider = ChangeNotifierProvider<SessionExpiredNotifier>(
  (_) => SessionExpiredNotifier(),
);

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(
    storage: ref.watch(secureStorageProvider),
    // read, bukan watch: ApiClient hanya perlu instance notifier-nya. Dengan
    // watch, tiap notifyListeners() membangun ulang Dio + seluruh provider
    // turunannya sehingga satu session expired memicu badai request.
    sessionExpired: ref.read(sessionExpiredProvider),
  ),
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final api     = ref.watch(apiClientProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthRepositoryImpl(AuthRemoteDatasource(api, storage), storage);
});

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, User?>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    return ref.read(authRepositoryProvider).getCurrentUser();
  }

  Future<void> login({
    required String username,
    required String password,
    required String db,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).login(
            username: username,
            password: password,
            db: db,
          ),
    );
    if (state.valueOrNull != null) {
      ref.read(sessionExpiredProvider).reset();
    }
  }

  /// Perbarui nama di sesi aktif setelah server menyimpan perubahan profil.
  Future<void> updateName(String name) async {
    final user = state.valueOrNull;
    if (user == null) return;
    await ref
        .read(secureStorageProvider)
        .write(key: AppConstants.nameKey, value: name);
    state = AsyncData(User(
      id: user.id,
      name: name,
      login: user.login,
      imageUrl: user.imageUrl,
      isPatroli: user.isPatroli,
    ));
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }
}
