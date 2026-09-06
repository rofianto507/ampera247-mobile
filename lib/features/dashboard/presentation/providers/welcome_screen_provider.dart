import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/config/app_config.dart';

class WelcomeScreenData {
  final int id;
  final String name;
  final String imageUrl;
  final String keterangan;
  const WelcomeScreenData({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.keterangan,
  });
}

final welcomeScreenProvider = FutureProvider<WelcomeScreenData?>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final resp = await api.dio
        .get('${AppConfig.baseUrl}/api/mobile/welcome-screen');
    final result = resp.data?['result'];
    if (result == null) return null;
    return WelcomeScreenData(
      id: result['id'] as int,
      name: result['name'] as String,
      imageUrl: '${AppConfig.baseUrl}${result['image_url'] as String}',
      keterangan: (result['keterangan'] as String?) ?? '',
    );
  } catch (_) {
    return null;
  }
});
