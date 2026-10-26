import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Versi aplikasi apa adanya dari pubspec (versionName+versionCode), mis.
/// "Versi 1.4.0 (8)". Dibaca saat runtime sehingga selalu cocok dengan build.
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  final build = info.buildNumber.isEmpty ? '' : ' (${info.buildNumber})';
  return 'Versi ${info.version}$build';
});
