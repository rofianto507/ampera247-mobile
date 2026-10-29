import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/config/app_config.dart';

class SliderItem {
  final int id;
  final String name;
  final String imageUrl;

  /// Tujuan saat banner diketuk. Kosong = banner tidak bisa diketuk.
  final String url;

  const SliderItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.url = '',
  });

  /// URL aman untuk dibuka: hanya http/https dengan host yang valid.
  /// null bila kosong atau tidak valid (mis. javascript:, file:, intent:).
  Uri? get actionUri {
    final u = Uri.tryParse(url.trim());
    if (u == null || !u.hasAuthority || u.host.isEmpty) return null;
    final scheme = u.scheme.toLowerCase();
    return (scheme == 'http' || scheme == 'https') ? u : null;
  }
}

final sliderProvider = FutureProvider<List<SliderItem>>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final resp = await api.dio.get('${AppConfig.baseUrl}/api/mobile/slider');
    final result = resp.data?['result'] as List?;
    if (result == null) return [];
    return result
        .map((e) => SliderItem(
              id: e['id'] as int,
              name: e['name'] as String,
              imageUrl: '${AppConfig.baseUrl}${e['image_url'] as String}',
              // Server lama belum mengirim field ini -> default kosong.
              url: (e['url'] as String?) ?? '',
            ))
        .toList();
  } catch (_) {
    return [];
  }
});
