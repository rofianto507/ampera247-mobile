import 'dart:js_interop';

@JS('window.open')
external void _windowOpen(String url, String target);

Future<void> openUrlExternal(String url) async {
  _windowOpen(url, '_blank');
}
