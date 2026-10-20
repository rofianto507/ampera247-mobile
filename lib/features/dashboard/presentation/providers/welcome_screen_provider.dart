import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/config/app_config.dart';

class WelcomeScreenData {
  final int id;
  final String name;
  final String imageUrl;
  final String keterangan;
  final String buttonLabel;
  final String buttonUrl;
  const WelcomeScreenData({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.keterangan,
    required this.buttonLabel,
    required this.buttonUrl,
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
      buttonLabel: (result['button_label'] as String?) ?? 'Lihat detail',
      buttonUrl: (result['button_url'] as String?) ?? '',
    );
  } catch (_) {
    return null;
  }
});
