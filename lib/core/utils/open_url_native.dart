import 'package:url_launcher/url_launcher.dart';

Future<void> openUrlExternal(String url) async {
  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}
