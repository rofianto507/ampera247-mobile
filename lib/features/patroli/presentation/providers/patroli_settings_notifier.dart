import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

const _kDefaultInterval = 30;
const _kIntervalKey = 'patroli_interval_seconds';

class PatroliSettingsNotifier extends StateNotifier<int> {
  final FlutterSecureStorage _storage;

  PatroliSettingsNotifier(this._storage) : super(_kDefaultInterval) {
    _load();
  }

  Future<void> _load() async {
    final raw = await _storage.read(key: _kIntervalKey);
    if (raw != null) state = int.tryParse(raw) ?? _kDefaultInterval;
  }

  Future<void> setInterval(int seconds) async {
    state = seconds;
    await _storage.write(key: _kIntervalKey, value: seconds.toString());
  }
}

final patroliSettingsProvider =
    StateNotifierProvider<PatroliSettingsNotifier, int>((ref) {
  return PatroliSettingsNotifier(ref.watch(secureStorageProvider));
});
