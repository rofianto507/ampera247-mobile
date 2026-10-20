import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/config/app_config.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

const _kPrivacyPolicyUrl =
    'https://ampera2407.id/kebijakan-privasi';
const _kChildSafetyEmail = 'selstudiojember@gmail.com';

const _kBlue0 = Color(0xFF0D1526);
const _kBlue1 = Color(0xFF1D2A44);
const _kSky   = Color(0xFFA2CFFE);

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  String _initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final dio  = ref.read(apiClientProvider).dio;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FA),
      appBar: AppBar(
        backgroundColor: _kBlue1,
        foregroundColor: Colors.white,
        title: const Text(
          'Profil Saya',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        elevation: 0,
      ),
      body: user == null
          ? const SizedBox.shrink()
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                  // ── Header + overlapping identity card ─────────────────
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Blue background — alignment: center ensures content is always centered
                      Container(
                        width: double.infinity,
                        color: _kBlue1,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 60),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _AvatarLarge(
                              url: '${AppConfig.baseUrl}/web/image/res.users/${user.id}/image_128',
                              initials: _initials(user.name),
                              dio: dio,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              user.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.login,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.60),
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      // Decorative circles
                      Positioned(right: -24, top: -24,
                          child: _decorCircle(140, 0.06)),
                      Positioned(left: -16, top: 50,
                          child: _decorCircle(70, 0.04)),
                      Positioned(right: 20, top: 110,
                          child: _decorCircle(90, 0.04)),

                      // Identity card — extends 80px below the blue area
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: -80,
                        child: _SectionCard(
                          children: [
                            _InfoTile(
                              icon: Icons.person_rounded,
                              label: 'Nama Lengkap',
                              value: user.name,
                            ),
                            const _Divider(),
                            _InfoTile(
                              icon: Icons.alternate_email_rounded,
                              label: 'Username / Email',
                              value: user.login,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // ── Below-fold content ──────────────────────────────────
                  const SizedBox(height: 80),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                    child: Column(
                      children: [
                        // ── Tentang Aplikasi ───────────────────────────
                        _SectionCard(
                          children: [
                            _LinkTile(
                              icon: Icons.privacy_tip_outlined,
                              label: 'Kebijakan Privasi',
                              onTap: () async {
                                final uri = Uri.parse(_kPrivacyPolicyUrl);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri,
                                      mode: LaunchMode.externalApplication);
                                }
                              },
                            ),
                            const _Divider(),
                            _LinkTile(
                              icon: Icons.child_care_rounded,
                              label: 'Laporkan Masalah Keselamatan Anak',
                              color: Colors.orange[800]!,
                              onTap: () async {
                                final uri = Uri(
                                  scheme: 'mailto',
                                  path: _kChildSafetyEmail,
                                  queryParameters: {
                                    'subject': 'Laporan Keselamatan Anak - AMPERA2407',
                                    'body':
                                        'Halo Tim AMPERA2407,\n\nSaya ingin melaporkan masalah keselamatan anak:\n\n[Jelaskan masalah di sini]\n\nTerima kasih.',
                                  },
                                );
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri);
                                }
                              },
                            ),
                            const _Divider(),
                            const _InfoTile(
                              icon: Icons.info_outline_rounded,
                              label: 'Versi Aplikasi',
                              value: 'AMPERA2407 v1.0.0 (Build 1)',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Hapus akun
                        _SectionCard(
                          children: [
                            _LinkTile(
                              icon: Icons.delete_outline_rounded,
                              label: 'Hapus Akun',
                              color: Colors.red[700]!,
                              onTap: () => _confirmDeleteAccount(context, ref),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Logout button
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFDC2626),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.logout_rounded, size: 18),
                            label: const Text(
                              'Keluar dari Akun',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                            onPressed: () => _confirmLogout(context, ref),
                          ),
                        ),
                        const SizedBox(height: 32),

                      ],
                    ),
                  ),
                      ],
                    ),
                  ),
                ),

                // ── Versi — fixed bottom, rata tengah ──────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Text(
                        'AMPERA2407 v1.0',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _kBlue1.withValues(alpha: 0.60),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'AMPERA2407',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _kBlue1.withValues(alpha: 0.40),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _confirmDeleteAccount(
      BuildContext context, WidgetRef ref) async {
    final reasonCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.delete_forever_rounded,
                      color: Colors.red.shade700, size: 24),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Hapus Akun?',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _kBlue1),
                ),
                const SizedBox(height: 8),
                Text(
                  'Permintaan akan dicatat dan diproses admin dalam '
                  'maksimal 30 hari kerja. Seluruh data dan riwayat '
                  'Anda akan dihapus secara permanen.',
                  style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                      height: 1.5),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Alasan (opsional)',
                    hintStyle:
                        TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                          color: Colors.red.shade300),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _kBlue1,
                          side: const BorderSide(
                              color: Color(0xFFDDE3EE)),
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Batal',
                            style: TextStyle(
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Ajukan',
                            style: TextStyle(
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
    );

    if (confirmed != true || !context.mounted) {
      reasonCtrl.dispose();
      return;
    }

    try {
      final dio = ref.read(apiClientProvider).dio;
      final resp = await dio.post(
        '/api/dkm/hapus-akun',
        data: {
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {'alasan': reasonCtrl.text.trim()},
        },
      );
      reasonCtrl.dispose();
      final body = resp.data as Map<String, dynamic>?;
      final result = body?['result'] as Map<String, dynamic>?;
      final ok = result?['ok'] == true;
      if (!context.mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Permintaan dikirim. Kami akan memproses dalam 30 hari kerja.'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
        await ref.read(authNotifierProvider.notifier).logout();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Gagal mengirim permintaan. Coba lagi.'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      reasonCtrl.dispose();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Terjadi kesalahan jaringan. Coba lagi.'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.logout_rounded,
                    color: Colors.red.shade700, size: 24),
              ),
              const SizedBox(height: 16),
              const Text(
                'Keluar dari Akun?',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _kBlue1),
              ),
              const SizedBox(height: 8),
              Text(
                'Anda akan keluar dari sesi ini dan harus login kembali.',
                style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    height: 1.5),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kBlue1,
                        side: const BorderSide(
                            color: Color(0xFFDDE3EE)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Batal',
                          style:
                              TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Keluar',
                          style:
                              TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (ok == true) {
      await ref.read(authNotifierProvider.notifier).logout();
    }
  }
}

// ── Link tile ─────────────────────────────────────────────────────────────────

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _LinkTile(
      {required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? _kBlue0;
    final iconColor = color ?? _kBlue1.withValues(alpha: 0.40);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: c,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: _kBlue1.withValues(alpha: 0.25)),
          ],
        ),
      ),
    );
  }
}

// ── Decorative circle ─────────────────────────────────────────────────────────

Widget _decorCircle(double size, double opacity) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );

// ── Large avatar ──────────────────────────────────────────────────────────────

class _AvatarLarge extends StatefulWidget {
  final String url;
  final String initials;
  final Dio dio;
  const _AvatarLarge(
      {required this.url, required this.initials, required this.dio});

  @override
  State<_AvatarLarge> createState() => _AvatarLargeState();
}

class _AvatarLargeState extends State<_AvatarLarge> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final resp = await widget.dio.get<List<int>>(
        widget.url,
        options: Options(responseType: ResponseType.bytes),
      );
      if (mounted && resp.data != null) {
        setState(() => _bytes = Uint8List.fromList(resp.data!));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 44,
      backgroundColor: Colors.white.withValues(alpha: 0.15),
      child: ClipOval(
        child: _bytes != null
            ? Image.memory(_bytes!, width: 88, height: 88, fit: BoxFit.cover)
            : Text(
                widget.initials,
                style: const TextStyle(
                  color: _kSky,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }
}

// ── Section card ──────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _kBlue1.withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => Divider(
        height: 1,
        indent: 52,
        endIndent: 16,
        color: _kBlue1.withValues(alpha: 0.07),
      );
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: _kBlue1.withValues(alpha: 0.40), size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: _kBlue1.withValues(alpha: 0.45),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: _kBlue0,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
