import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/error/exceptions.dart';
import '../providers/auth_provider.dart';

const _kPrivacyPolicyUrl = 'https://palembang.polisibaik.id/kebijakan-privasi';

// ── Palette (Biru Prabowo) ────────────────────────────────────────────────────
const _kBlue0 = Color(0xFF0D1526); // gradient start — very dark navy
const _kBlue1 = Color(0xFF1D2A44); // main navy (secondary color)
const _kBlue2 = Color(0xFF243356); // gradient end — medium navy
const _kSky   = Color(0xFFA2CFFE); // biru langit — primary brand / button
const _kRed   = Color(0xFFFF0000); // merah — accent color
const _kDark  = Color(0xFF1D2A44); // text on card

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _usernameCtrl.addListener(_clearError);
    _passwordCtrl.addListener(_clearError);
  }

  void _clearError() {
    if (_errorMsg != null) setState(() => _errorMsg = null);
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _errorMsg = null);
    await ref.read(authNotifierProvider.notifier).login(
      username: _usernameCtrl.text.trim(),
      password: _passwordCtrl.text,
      db: AppConfig.dbName,
    );
    if (!mounted) return;
    ref.read(authNotifierProvider).whenOrNull(
      error: (e, _) {
        final msg = e is AuthException
            ? 'Username atau password salah.'
            : 'Terjadi kesalahan koneksi.';
        setState(() => _errorMsg = msg);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider).isLoading;
    final screenH   = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // ── Background gradient ──────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_kBlue0, _kBlue1, _kBlue2],
                stops: [0.0, 0.45, 1.0],
              ),
            ),
          ),

          // ── Ampera bridge silhouette ─────────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: CustomPaint(
              size: Size(double.infinity, screenH * 0.30),
              painter: const _AmperaBridgePainter(),
            ),
          ),

          // ── Gold accent line top ──────────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(height: 3, color: _kSky),
          ),

          // ── Scrollable content ───────────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo circle
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: _kSky, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 24,
                              spreadRadius: 2,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.shield_rounded,
                              size: 52,
                              color: _kSky,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Brand
                      const Text(
                        'AMPERA247',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                        ),
                      ),

                      // Gold divider
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 40, height: 1, color: _kSky.withValues(alpha: 0.5)),
                            const SizedBox(width: 8),
                            const Icon(Icons.star, color: _kRed, size: 10),
                            const SizedBox(width: 8),
                            Container(width: 40, height: 1, color: _kSky.withValues(alpha: 0.5)),
                          ],
                        ),
                      ),

                      const Text(
                        'AMPERA247',
                        style: TextStyle(
                          color: Color(0xFFC5D5E8),
                          fontSize: 12,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                      const SizedBox(height: 36),

                      // ── Login card ────────────────────────────────────────
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.45),
                              blurRadius: 48,
                              offset: const Offset(0, 20),
                            ),
                            BoxShadow(
                              color: _kSky.withValues(alpha: 0.10),
                              blurRadius: 0,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Card header strip
                            Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [_kBlue1, _kBlue2],
                                ),
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 14),
                              child: Row(
                                children: [
                                  
                                  Text(
                                    'Sign In',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.92),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Card body
                            Padding(
                              padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _buildField(
                                      controller: _usernameCtrl,
                                      label: 'Username',
                                      icon: Icons.person_outline_rounded,
                                      enabled: !isLoading,
                                      action: TextInputAction.next,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildField(
                                      controller: _passwordCtrl,
                                      label: 'Password',
                                      icon: Icons.lock_outline_rounded,
                                      enabled: !isLoading,
                                      obscure: _obscure,
                                      action: TextInputAction.done,
                                      onSubmit: (_) => isLoading ? null : _submit(),
                                      suffix: IconButton(
                                        icon: Icon(
                                          _obscure
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          size: 20,
                                          color: Colors.grey.shade600,
                                        ),
                                        onPressed: () =>
                                            setState(() => _obscure = !_obscure),
                                      ),
                                    ),
                                    if (_errorMsg != null) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          border: Border.all(
                                              color: Colors.red.shade300),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.error_outline,
                                                color: Colors.red.shade700,
                                                size: 18),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                _errorMsg!,
                                                style: TextStyle(
                                                  color: Colors.red.shade800,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 28),
                                    SizedBox(
                                      height: 50,
                                      child: FilledButton(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: _kSky,
                                          foregroundColor: _kBlue1,
                                          disabledBackgroundColor:
                                              _kSky.withValues(alpha: 0.5),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          elevation: 2,
                                        ),
                                        onPressed: isLoading ? null : _submit,
                                        child: isLoading
                                            ? const SizedBox(
                                                height: 22,
                                                width: 22,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : const Text(
                                                'Masuk',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => context.push('/register'),
                        child: Text(
                          'Belum punya akun? Daftar',
                          style: TextStyle(
                            color: _kSky.withValues(alpha: 0.85),
                            fontSize: 13,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.45),
                              fontSize: 11,
                              height: 1.6,
                            ),
                            children: [
                              const TextSpan(
                                  text: 'Dengan masuk, Anda menyetujui '),
                              TextSpan(
                                text: 'Kebijakan Privasi',
                                style: const TextStyle(
                                  color: _kSky,
                                  decoration: TextDecoration.underline,
                                  decorationColor: _kSky,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () async {
                                    final uri =
                                        Uri.parse(_kPrivacyPolicyUrl);
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri,
                                          mode: LaunchMode
                                              .externalApplication);
                                    }
                                  },
                              ),
                              const TextSpan(text: ' kami.'),
                            ],
                          ),
                        ),
                      ),

                      // Space agar card tidak tertutup bridge
                      SizedBox(height: screenH * 0.10),
                    ],
                  ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool enabled,
    bool obscure = false,
    TextInputAction action = TextInputAction.next,
    ValueChanged<String>? onSubmit,
    Widget? suffix,
  }) {
    const border = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Color(0xFFE0D0D0)),
    );
    const focusBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: _kSky, width: 2),
    );

    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: obscure,
      textInputAction: action,
      onFieldSubmitted: onSubmit,
      style: const TextStyle(color: _kDark, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF888888), fontSize: 14),
        prefixIcon: Icon(icon, color: _kSky, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFFAF7F7),
        border: border,
        enabledBorder: border,
        focusedBorder: focusBorder,
        errorBorder: border.copyWith(
          borderSide: const BorderSide(color: Colors.red)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
    );
  }
}

// ── Ampera Bridge Silhouette ──────────────────────────────────────────────────

class _AmperaBridgePainter extends CustomPainter {
  const _AmperaBridgePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final fill = Paint()
      ..color = const Color(0xFF001020)
      ..style = PaintingStyle.fill;

    final cable = Paint()
      ..color = const Color(0xFF001830)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // ── River / base ─────────────────────────────────────────────────────
    final riverY = h * 0.62;
    canvas.drawRect(Rect.fromLTWH(0, riverY, w, h - riverY), fill);

    // ── Road deck ────────────────────────────────────────────────────────
    final deckY = h * 0.52;
    final deckH = h * 0.10;
    canvas.drawRect(Rect.fromLTWH(0, deckY, w, deckH), fill);

    // ── Truss work on deck (simplified) ──────────────────────────────────
    final truss = Paint()
      ..color = const Color(0xFF001530)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final segW = w / 12;
    for (int i = 0; i < 12; i++) {
      final x = i * segW;
      if (i % 2 == 0) {
        canvas.drawLine(Offset(x, deckY), Offset(x + segW, deckY + deckH), truss);
      } else {
        canvas.drawLine(Offset(x, deckY + deckH), Offset(x + segW, deckY), truss);
      }
    }

    // ── Two pylons ───────────────────────────────────────────────────────
    final t1x = w * 0.30;
    final t2x = w * 0.70;
    final tW   = w * 0.032;
    final tTop = h * 0.0;
    final tBot = deckY + deckH;

    // Shaft
    canvas.drawRect(
        Rect.fromLTWH(t1x - tW / 2, tTop, tW, tBot - tTop), fill);
    canvas.drawRect(
        Rect.fromLTWH(t2x - tW / 2, tTop, tW, tBot - tTop), fill);

    // Crossbeam near top (horizontal bar)
    final crossY1 = h * 0.08;
    final crossY2 = h * 0.20;
    canvas.drawRect(
        Rect.fromLTWH(t1x - tW * 1.5, crossY1, tW * 3, h * 0.05), fill);
    canvas.drawRect(
        Rect.fromLTWH(t2x - tW * 1.5, crossY1, tW * 3, h * 0.05), fill);
    canvas.drawRect(
        Rect.fromLTWH(t1x - tW * 1.2, crossY2, tW * 2.4, h * 0.04), fill);
    canvas.drawRect(
        Rect.fromLTWH(t2x - tW * 1.2, crossY2, tW * 2.4, h * 0.04), fill);

    // Pylon cap
    canvas.drawRect(
        Rect.fromLTWH(t1x - tW * 2, tTop, tW * 4, h * 0.065), fill);
    canvas.drawRect(
        Rect.fromLTWH(t2x - tW * 2, tTop, tW * 4, h * 0.065), fill);

    // ── Cables ───────────────────────────────────────────────────────────
    final anchorY = h * 0.06;
    const steps = 8;

    for (int i = 0; i <= steps; i++) {
      final t = i / steps.toDouble();
      // Left tower → left
      canvas.drawLine(
        Offset(t1x, anchorY),
        Offset(t1x - w * 0.28 * t, deckY),
        cable,
      );
      // Left tower → right (toward center)
      canvas.drawLine(
        Offset(t1x, anchorY),
        Offset(t1x + w * 0.16 * t, deckY),
        cable,
      );
      // Right tower → right
      canvas.drawLine(
        Offset(t2x, anchorY),
        Offset(t2x + w * 0.28 * t, deckY),
        cable,
      );
      // Right tower → left (toward center)
      canvas.drawLine(
        Offset(t2x, anchorY),
        Offset(t2x - w * 0.16 * t, deckY),
        cable,
      );
    }

    // ── River shimmer (very subtle lighter strip) ─────────────────────────
    final shimmer = Paint()
      ..color = const Color(0xFF001228)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
        Rect.fromLTWH(0, riverY, w, h * 0.06), shimmer);

  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
