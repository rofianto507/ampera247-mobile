import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/registration_provider.dart';

// ── Palette (sama dengan login) ──────────────────────────────────────────────
const _kBlue0 = Color(0xFF0D1526);
const _kBlue1 = Color(0xFF1D2A44);
const _kBlue2 = Color(0xFF243356);
const _kSky   = Color(0xFFA2CFFE);
const _kDark  = Color(0xFF1D2A44);

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _namaCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _alamatCtrl = TextEditingController();

  String? _fotoBase64;
  String? _fotoFileName;

  @override
  void dispose() {
    _namaCtrl.dispose();
    _phoneCtrl.dispose();
    _alamatCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _fotoBase64   = base64Encode(result.files.single.bytes!);
        _fotoFileName = result.files.single.name;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(registrationProvider.notifier).register(
      nama:       _namaCtrl.text.trim(),
      phone:      _phoneCtrl.text.trim(),
      alamat:     _alamatCtrl.text.trim(),
      fotoBase64: kIsWeb ? null : _fotoBase64,
    );
  }

  @override
  Widget build(BuildContext context) {
    final regState = ref.watch(registrationProvider);
    final isLoading = regState.status == RegStatus.loading;
    final isSuccess = regState.status == RegStatus.success;
    final screenH   = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // ── Background gradient ────────────────────────────────────────
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

          // ── Ampera bridge silhouette ───────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: CustomPaint(
              size: Size(double.infinity, screenH * 0.22),
              painter: const _AmperaBridgePainter(),
            ),
          ),

          // ── Blue accent top ────────────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(height: 3, color: _kSky),
          ),

          // ── Content ───────────────────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: isSuccess ? _buildSuccess(context) : _buildForm(isLoading),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Form registrasi ───────────────────────────────────────────────────────

  Widget _buildForm(bool isLoading) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Back + title + subtitle
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white70, size: 20),
              onPressed: () => context.pop(),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  const Text(
                    'Daftar Akun',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Isi data berikut untuk mendaftar.\nPassword akan dikirim ke WhatsApp Anda.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.60),
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // ── Card ──────────────────────────────────────────────────────
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
              // Card header
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [_kBlue1, _kBlue2]),
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                child: const Text(
                  'Data Pendaftaran',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
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
                        controller: _namaCtrl,
                        label: 'Nama Lengkap',
                        icon: Icons.person_outline_rounded,
                        enabled: !isLoading,
                        action: TextInputAction.next,
                      ),
                      const SizedBox(height: 14),
                      _buildField(
                        controller: _phoneCtrl,
                        label: 'Nomor WhatsApp',
                        hint: 'Contoh: 08123456789',
                        icon: Icons.phone_outlined,
                        enabled: !isLoading,
                        keyboardType: TextInputType.phone,
                        action: TextInputAction.next,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                          final digits = v.replaceAll(RegExp(r'\D'), '');
                          if (digits.length < 9) return 'Nomor tidak valid';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _buildField(
                        controller: _alamatCtrl,
                        label: 'Alamat (opsional)',
                        icon: Icons.home_outlined,
                        enabled: !isLoading,
                        maxLines: 3,
                        action: TextInputAction.done,
                        validator: (_) => null,
                      ),
                      if (!kIsWeb) ...[
                        const SizedBox(height: 14),
                        _buildFotoPicker(isLoading),
                      ],

                      // Error message
                      if (ref.watch(registrationProvider).status == RegStatus.error) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            ref.watch(registrationProvider).error ?? '',
                            style: TextStyle(
                                color: Colors.red.shade700, fontSize: 13),
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),
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
                                  'Daftar',
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
          onPressed: () => context.pop(),
          child: Text(
            'Sudah punya akun? Login',
            style: TextStyle(
              color: _kSky.withValues(alpha: 0.85),
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFotoPicker(bool isLoading) {
    return GestureDetector(
      onTap: isLoading ? null : _pickFoto,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF7F7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0D0D0)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kSky.withValues(alpha: 0.12),
                border: Border.all(color: _kSky.withValues(alpha: 0.4)),
              ),
              child: _fotoBase64 != null
                  ? ClipOval(
                      child: Image.memory(
                        base64Decode(_fotoBase64!),
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Icon(Icons.camera_alt_outlined, color: _kSky, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _fotoFileName ?? 'Foto',
                    style: TextStyle(
                      color: _fotoBase64 != null ? _kDark : const Color(0xFF888888),
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_fotoFileName == null)
                    Text(
                      'Ketuk untuk memilih foto',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                    ),
                ],
              ),
            ),
            if (_fotoBase64 != null)
              IconButton(
                icon: Icon(Icons.close_rounded, size: 18, color: Colors.grey.shade500),
                onPressed: () => setState(() {
                  _fotoBase64   = null;
                  _fotoFileName = null;
                }),
              ),
          ],
        ),
      ),
    );
  }

  // ── Halaman sukses ────────────────────────────────────────────────────────

  Widget _buildSuccess(BuildContext context) {
    final login = ref.watch(registrationProvider).login;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 24),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.10),
            border: Border.all(color: _kSky.withValues(alpha: 0.5), width: 2),
          ),
          child: const Icon(Icons.check_circle_outline_rounded,
              size: 44, color: _kSky),
        ),
        const SizedBox(height: 24),
        const Text(
          'Registrasi Berhasil!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Informasi login telah dikirim ke WhatsApp Anda.\nSilakan cek pesan masuk.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.70),
            fontSize: 14,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kSky.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Text(
                'Username untuk login:',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.60),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                login ?? '(lihat WhatsApp Anda)',
                style: const TextStyle(
                  color: _kSky,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 36),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _kSky,
              foregroundColor: _kBlue1,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
            onPressed: () {
              ref.read(registrationProvider.notifier).reset();
              context.go('/login');
            },
            child: const Text(
              'Login Sekarang',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 1),
            ),
          ),
        ),
      ],
    );
  }

  // ── Field builder ─────────────────────────────────────────────────────────

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool enabled,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction action = TextInputAction.next,
    int maxLines = 1,
    String? Function(String?)? validator,
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
      keyboardType: maxLines > 1 ? TextInputType.multiline : keyboardType,
      textInputAction: action,
      maxLines: maxLines,
      style: const TextStyle(color: _kDark, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle:
            const TextStyle(color: Color(0xFF888888), fontSize: 14),
        hintStyle:
            const TextStyle(color: Color(0xFFBBBBBB), fontSize: 13),
        prefixIcon: Icon(icon, color: _kSky, size: 20),
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
      validator: validator ??
          (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
    );
  }
}

// ── Ampera Bridge Silhouette (reuse dari login) ───────────────────────────────

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

    final riverY = h * 0.62;
    canvas.drawRect(Rect.fromLTWH(0, riverY, w, h - riverY), fill);

    final deckY = h * 0.52;
    final deckH = h * 0.10;
    canvas.drawRect(Rect.fromLTWH(0, deckY, w, deckH), fill);

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
        canvas.drawLine(
            Offset(x, deckY + deckH), Offset(x + segW, deckY), truss);
      }
    }

    final t1x = w * 0.30;
    final t2x = w * 0.70;
    final tW   = w * 0.032;
    final tTop = h * 0.0;
    final tBot = deckY + deckH;

    canvas.drawRect(Rect.fromLTWH(t1x - tW / 2, tTop, tW, tBot - tTop), fill);
    canvas.drawRect(Rect.fromLTWH(t2x - tW / 2, tTop, tW, tBot - tTop), fill);

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

    canvas.drawRect(
        Rect.fromLTWH(t1x - tW * 2, tTop, tW * 4, h * 0.065), fill);
    canvas.drawRect(
        Rect.fromLTWH(t2x - tW * 2, tTop, tW * 4, h * 0.065), fill);

    final anchorY = h * 0.06;
    const steps = 8;
    for (int i = 0; i <= steps; i++) {
      final t = i / steps.toDouble();
      canvas.drawLine(Offset(t1x, anchorY),
          Offset(t1x - w * 0.28 * t, deckY), cable);
      canvas.drawLine(Offset(t1x, anchorY),
          Offset(t1x + w * 0.16 * t, deckY), cable);
      canvas.drawLine(Offset(t2x, anchorY),
          Offset(t2x + w * 0.28 * t, deckY), cable);
      canvas.drawLine(Offset(t2x, anchorY),
          Offset(t2x - w * 0.16 * t, deckY), cable);
    }

    final shimmer = Paint()
      ..color = const Color(0xFF001228)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, riverY, w, h * 0.06), shimmer);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
