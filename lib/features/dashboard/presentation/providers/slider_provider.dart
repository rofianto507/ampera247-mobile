import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/config/app_config.dart';

class SliderItem {
  final int id;
  final String name;
  final String imageUrl;
  const SliderItem({required this.id, required this.name, required this.imageUrl});
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
            ))
        .toList();
  } catch (_) {
    return [];
  }
});
