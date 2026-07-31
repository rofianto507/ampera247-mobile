import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/open_url.dart';

const _kBlue0 = Color(0xFF0D1526);
const _kBlue1 = Color(0xFF1D2A44);

class KonselingChatScreen extends StatefulWidget {
  final int channelId;
  final String title;

  const KonselingChatScreen({
    super.key,
    required this.channelId,
    required this.title,
  });

  @override
  State<KonselingChatScreen> createState() => _KonselingChatScreenState();
}

class _KonselingChatScreenState extends State<KonselingChatScreen> {
  WebViewController? _controller;
  bool _loading = true;

  String get _chatUrl =>
      '${AppConfig.baseUrl}/odoo/discuss/channel-${widget.channelId}';

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await openUrlExternal(_chatUrl);
        if (mounted) setState(() => _loading = false);
      });
    } else {
      _requestPermissionsAndInit();
    }
  }

  Future<void> _requestPermissionsAndInit() async {
    await [Permission.camera, Permission.microphone].request();
    _initWebView();
  }

  Future<void> _initWebView() async {
    const storage = FlutterSecureStorage();
    final sessionId = await storage.read(key: AppConstants.tokenKey);

    if (sessionId != null && sessionId.isNotEmpty) {
      final host = Uri.parse(AppConfig.baseUrl).host;
      await WebViewCookieManager().setCookie(
        WebViewCookie(
          name: 'session_id',
          value: sessionId,
          domain: host,
          path: '/',
        ),
      );
    }

    if (!kIsWeb && Platform.isIOS && sessionId != null && sessionId.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 300));
    }

    final reqHeaders = sessionId != null && sessionId.isNotEmpty
        ? <String, String>{'Cookie': 'session_id=$sessionId'}
        : <String, String>{};

    final ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
          'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36')
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) {
          if (mounted) setState(() => _loading = true);
          _injectPolyfills();
        },
        onPageFinished: (url) {
          if (mounted) setState(() => _loading = false);
          if (!url.contains('/web/login') && !url.contains('/odoo/login')) {
            _injectHideNavbarStyle();
          }
        },
        onWebResourceError: (_) {
          if (mounted) setState(() => _loading = false);
        },
        onNavigationRequest: (request) {
          final url = request.url;
          if (url.contains('/web/login') || url.contains('/odoo/login')) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sesi telah berakhir, silakan login ulang.'),
                  backgroundColor: Colors.redAccent,
                  duration: Duration(seconds: 4),
                ),
              );
            }
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(_chatUrl), headers: reqHeaders);

    if (ctrl.platform is AndroidWebViewController) {
      final androidCtrl = ctrl.platform as AndroidWebViewController;
      await androidCtrl.setOnPlatformPermissionRequest(
        (request) async => request.grant(),
      );
      androidCtrl.setOnConsoleMessage((msg) {
        // ignore: avoid_print
        print('WV[${msg.level.name}]: ${msg.message}');
      });
    }

    if (mounted) setState(() => _controller = ctrl);
  }

  void _injectPolyfills() {
    _controller?.runJavaScript(r'''
      (function() {
        if (!Object.groupBy) {
          Object.groupBy = function(items, fn) {
            return Array.from(items).reduce(function(acc, item) {
              var key = fn(item);
              if (!acc[key]) acc[key] = [];
              acc[key].push(item);
              return acc;
            }, Object.create(null));
          };
        }
        if (!Map.groupBy) {
          Map.groupBy = function(items, fn) {
            var m = new Map();
            for (var item of items) {
              var k = fn(item);
              if (!m.has(k)) m.set(k, []);
              m.get(k).push(item);
            }
            return m;
          };
        }
        if (!Set.prototype.difference) {
          Set.prototype.difference = function(other) {
            var r = new Set();
            this.forEach(function(v) { if (!other.has(v)) r.add(v); });
            return r;
          };
        }
        if (!Set.prototype.intersection) {
          Set.prototype.intersection = function(other) {
            var r = new Set();
            this.forEach(function(v) { if (other.has(v)) r.add(v); });
            return r;
          };
        }
        if (!Set.prototype.union) {
          Set.prototype.union = function(other) {
            var r = new Set(this);
            other.forEach(function(v) { r.add(v); });
            return r;
          };
        }
        if (!Set.prototype.symmetricDifference) {
          Set.prototype.symmetricDifference = function(other) {
            var r = new Set();
            this.forEach(function(v) { if (!other.has(v)) r.add(v); });
            other.forEach(function(v) { if (!this.has(v)) r.add(v); }.bind(this));
            return r;
          };
        }
        if (!Set.prototype.isSubsetOf) {
          Set.prototype.isSubsetOf = function(other) {
            for (var v of this) { if (!other.has(v)) return false; }
            return true;
          };
        }
        if (!Set.prototype.isSupersetOf) {
          Set.prototype.isSupersetOf = function(other) {
            return other.isSubsetOf(this);
          };
        }
        if (!Set.prototype.isDisjointFrom) {
          Set.prototype.isDisjointFrom = function(other) {
            for (var v of this) { if (other.has(v)) return false; }
            return true;
          };
        }
      })();
    ''');
  }

  void _injectHideNavbarStyle() {
    _controller?.runJavaScript(r'''
      (function() {
        var styleId = '_dk_hide';
        if (document.getElementById(styleId)) return;
        var s = document.createElement('style');
        s.id = styleId;
        s.textContent =
          'header.o_navbar, .o_main_navbar { display: none !important; }' +
          '.o_web_client { padding-top: 0 !important; }' +
          '.o_action_manager { top: 0 !important; }' +
          '.o-mail-DiscussSidebar { display: none !important; }' +
          '.o-mail-Discuss > .o-mail-Thread { flex: 1 !important; min-width: 0 !important; }';
        (document.head || document.documentElement).appendChild(s);
      })();
    ''');
  }

  Future<bool> _onWillPop() async {
    if (_controller != null && await _controller!.canGoBack()) {
      await _controller!.goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = GoRouter.of(context);
        if (await _onWillPop()) {
          nav.pop();
        }
      },
      child: Scaffold(
        backgroundColor: _kBlue0,
        appBar: AppBar(
          backgroundColor: _kBlue0,
          foregroundColor: Colors.white,
          title: Text(
            widget.title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          elevation: 0,
        ),
        body: kIsWeb ? _buildWebFallback() : _buildMobileWebView(),
      ),
    );
  }

  Widget _buildMobileWebView() {
    return Stack(
      children: [
        if (_controller != null) WebViewWidget(controller: _controller!),
        if (_loading || _controller == null)
          Container(
            color: _kBlue0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Colors.white54),
                  const SizedBox(height: 16),
                  Text(
                    'Memuat konsultasi...',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWebFallback() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_rounded,
                  size: 36, color: Colors.white70),
            ),
            const SizedBox(height: 24),
            const Text(
              'Konsultasi Dibuka',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Sesi konsultasi telah dibuka di tab baru. Kembali ke halaman ini setelah selesai.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 13,
                  height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _kBlue1,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => openUrlExternal(_chatUrl),
                icon: const Icon(Icons.open_in_new_rounded, size: 20),
                label: const Text(
                  'Buka Ulang',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
