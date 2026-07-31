import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/app_config.dart';
import '../../../antrian/presentation/providers/antrian_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../eform_laka/presentation/providers/eform_laka_provider.dart';
import '../../../rehab/presentation/providers/rehab_provider.dart';
import '../../../notifikasi/presentation/providers/notifikasi_provider.dart';

const _kBlue0 = Color(0xFF0D1526);
const _kBlue1 = Color(0xFF1D2A44);
const _kBlue2 = Color(0xFF243356);
const _kSky   = Color(0xFFA2CFFE);
const _kRed   = Color(0xFFDD1111);

// â”€â”€ Slide data â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _Slide {
  final List<Color> gradient;
  final IconData? icon;
  final String? imagePath;
  final String title;
  final String subtitle;
  final String? route;
  final Color? titleColor;
  final Color? subtitleColor;
  const _Slide({
    required this.gradient,
    this.icon,
    this.imagePath,
    required this.title,
    required this.subtitle,
    this.route,
    this.titleColor,
    this.subtitleColor,
  });
}

const _slides = [
  _Slide(
    gradient: [Color(0xFFB8860B), Color(0xFFDAA520)],
    imagePath: 'assets/images/logo.png',
    title: 'AMPERA247',
    subtitle: 'Aplikasi Layanan Publik Digital Kota Palembang',
    titleColor: Color(0xFFCC0000),
    subtitleColor: Color(0xFF1A1A2E),
  ),
  _Slide(
    gradient: [Color(0xFF1D2A44), Color(0xFF243356)],
    icon: Icons.car_crash_rounded,
    title: 'e-Form Kecelakaan',
    subtitle: 'Laporkan kecelakaan langsung dari genggaman Anda',
    route: '/eform-laka',
  ),
  _Slide(
    gradient: [Color(0xFF243356), Color(0xFF0D1526)],
    icon: Icons.verified_rounded,
    title: 'Sertifikasi Anti Narkoba',
    subtitle: 'Ikuti tes sertifikasi bebas narkoba secara online',
    route: '/sertifikasi',
  ),
  _Slide(
    gradient: [Color(0xFF0D1526), Color(0xFF243356)],
    icon: Icons.healing_rounded,
    title: 'Rehabilitasi Narkoba',
    subtitle: 'Ajukan permohonan rehab narkoba secara mudah dan cepat',
    route: '/rehab',
  ),
  _Slide(
    gradient: [Color(0xFF1D2A44), Color(0xFF0D1526)],
    icon: Icons.psychology_rounded,
    title: 'Konseling Online',
    subtitle: 'Konsultasikan masalah narkoba dengan konselor profesional',
    route: '/konseling',
  ),
  _Slide(
    gradient: [Color(0xFF243356), Color(0xFF1D2A44)],
    icon: Icons.confirmation_number_rounded,
    title: 'Antrian Online',
    subtitle: 'Ambil nomor antrian layanan publik tanpa perlu menunggu',
    route: '/antrian',
  ),
];

// ── Activity model (riwayat layanan) ─────────────────────────────────────────

class _Activity {
  final String title;
  final String ref;
  final DateTime date;
  final String stateLabel;
  final Color stateColor;
  final IconData icon;
  final Color iconColor;
  final String route;

  const _Activity({
    required this.title,
    required this.ref,
    required this.date,
    required this.stateLabel,
    required this.stateColor,
    required this.icon,
    required this.iconColor,
    required this.route,
  });
}

String _actDate(DateTime d) {
  const m = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
  return '${d.day} ${m[d.month - 1]} ${d.year}';
}

Color _actStateColor(String s) => switch (s) {
  'selesai'    => const Color(0xFF10B981),
  'batal'      => const Color(0xFFEF4444),
  'dipanggil'  => const Color(0xFF8B5CF6),
  'konfirmasi' => const Color(0xFF3B82F6),
  'proses'     => const Color(0xFF3B82F6),
  'BARU'       => const Color(0xFF3B82F6),
  _            => const Color(0xFFF59E0B),
};

String _actStateLabel(String s) => switch (s) {
  'menunggu'   => 'Menunggu',
  'konfirmasi' => 'Dikonfirmasi',
  'dipanggil'  => 'Dipanggil',
  'proses'     => 'Diproses',
  'selesai'    => 'Selesai',
  'batal'      => 'Dibatalkan',
  'BARU'       => 'Baru',
  _            => s,
};

final riwayatLayananProvider =
    FutureProvider.autoDispose<List<_Activity>>((ref) async {
  final api  = ref.watch(apiClientProvider);
  final user = ref.watch(authNotifierProvider).valueOrNull;
  if (user == null) return [];

  final antrian   = await ref.watch(antrianListProvider.future);
  final rehab     = await ref.watch(rehabListProvider.future);
  final eformLaka = await ref.watch(eformLakaListProvider.future);

  final kRes = await api.callKw(
    model: 'digital_kamtibmas.konseling',
    method: 'search_read',
    args: [[['user_id', '=', user.id]]],
    kwargs: {
      'fields': ['code', 'tanggal_pengajuan', 'state'],
      'order': 'id desc',
      'limit': 10,
    },
  );

  final list = <_Activity>[];

  for (final a in antrian) {
    list.add(_Activity(
      title: 'Antrian Online',
      ref: a.nomorAntrian,
      date: a.tanggalBooking,
      stateLabel: _actStateLabel(a.state),
      stateColor: _actStateColor(a.state),
      icon: Icons.confirmation_number_rounded,
      iconColor: const Color(0xFF0277BD),
      route: '/antrian',
    ));
  }

  for (final r in rehab) {
    list.add(_Activity(
      title: 'Rehabilitasi',
      ref: r.code,
      date: r.tanggalPengajuan,
      stateLabel: _actStateLabel(r.state),
      stateColor: _actStateColor(r.state),
      icon: Icons.healing_rounded,
      iconColor: const Color(0xFF2E7D32),
      route: '/rehab',
    ));
  }

  for (final e in eformLaka) {
    list.add(_Activity(
      title: 'e-Form Kecelakaan',
      ref: e.code,
      date: e.tanggalKejadian,
      stateLabel: _actStateLabel(e.state),
      stateColor: _actStateColor(e.state),
      icon: Icons.car_crash_rounded,
      iconColor: const Color(0xFF1565C0),
      route: '/eform-laka',
    ));
  }

  for (final k in (kRes as List)) {
    final m  = k as Map<String, dynamic>;
    final ds = m['tanggal_pengajuan'];
    final st = m['state'] as String? ?? 'menunggu';
    list.add(_Activity(
      title: 'Konseling Online',
      ref: m['code'] as String? ?? '-',
      date: ds is String ? DateTime.tryParse(ds) ?? DateTime.now() : DateTime.now(),
      stateLabel: _actStateLabel(st),
      stateColor: _actStateColor(st),
      icon: Icons.psychology_rounded,
      iconColor: const Color(0xFF6A1B9A),
      route: '/konseling',
    ));
  }

  list.sort((a, b) => b.date.compareTo(a.date));
  return list.take(5).toList();
});

// â”€â”€ Dashboard â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).valueOrNull;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FA),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            children: [
              _Header(
                  userName: user?.name ?? '-',
                  userId: user?.id ?? 0,
                  ref: ref),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // â”€â”€ Banner slider â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                      const _BannerSlider(),
                      const SizedBox(height: 20),

                      // â”€â”€ Grid layanan â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionLabel('LAYANAN'),
                            const SizedBox(height: 10),
                            GridView.count(
                              crossAxisCount: 3,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 1.05,
                              children: [
                                _MenuCard(
                                  icon: Icons.car_crash_rounded,
                                  label: 'e-Form KLL',
                                  iconColor: const Color(0xFF1565C0),
                                  onTap: () => context.push('/eform-laka'),
                                ),
                                _MenuCard(
                                  icon: Icons.confirmation_number_rounded,
                                  label: 'Antrian',
                                  iconColor: const Color(0xFF0277BD),
                                  onTap: () => context.push('/antrian'),
                                ),
                                _MenuCard(
                                  icon: Icons.verified_rounded,
                                  label: 'Sertifikasi',
                                  iconColor: const Color(0xFF00695C),
                                  onTap: () => context.push('/sertifikasi'),
                                ),
                                _MenuCard(
                                  icon: Icons.healing_rounded,
                                  label: 'Rehabilitasi',
                                  iconColor: const Color(0xFF2E7D32),
                                  onTap: () => context.push('/rehab'),
                                ),
                                _MenuCard(
                                  icon: Icons.manage_search_rounded,
                                  label: 'Barang Bukti',
                                  iconColor: const Color(0xFF37474F),
                                  onTap: () => context.push('/barang-bukti'),
                                ),
                                _MenuCard(
                                  icon: Icons.psychology_rounded,
                                  label: 'Konseling',
                                  iconColor: const Color(0xFF6A1B9A),
                                  onTap: () => context.push('/konseling'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const _RiwayatSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: TextStyle(
          color: _kBlue1.withValues(alpha: 0.5),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 2.5,
        ),
      );
}

// â”€â”€ Banner Slider â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _BannerSlider extends StatefulWidget {
  const _BannerSlider();

  @override
  State<_BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<_BannerSlider> {
  late final PageController _ctrl;
  late final Timer _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = PageController(viewportFraction: 0.88);
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_page + 1) % _slides.length;
      _ctrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _ctrl,
            itemCount: _slides.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => _SlideCard(slide: _slides[i]),
          ),
        ),
        const SizedBox(height: 10),
        // Dot indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_slides.length, (i) {
            final active = i == _page;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active
                    ? _kBlue1
                    : _kBlue1.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _SlideCard extends StatelessWidget {
  final _Slide slide;
  const _SlideCard({required this.slide});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: slide.route != null
          ? () => context.push(slide.route!)
          : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: slide.gradient,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D1526).withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative circle motif
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              right: 20,
              bottom: -30,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Icon
                  if (slide.imagePath != null)
                    Image.asset(
                      slide.imagePath!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.contain,
                    )
                  else
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(slide.icon, color: Colors.white, size: 28),
                    ),
                  const SizedBox(width: 16),
                  // Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          slide.title,
                          style: TextStyle(
                            color: slide.titleColor ?? Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          slide.subtitle,
                          style: TextStyle(
                            color: slide.subtitleColor ??
                                Colors.white.withValues(alpha: 0.80),
                            fontSize: 12,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (slide.route != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Buka Layanan',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 11,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _Header extends StatelessWidget {
  final String userName;
  final int userId;
  final WidgetRef ref;

  const _Header(
      {required this.userName, required this.userId, required this.ref});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Selamat Pagi';
    if (h < 15) return 'Selamat Siang';
    if (h < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  String _initials(String name) {
    final parts =
        name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 8, 16),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => context.push('/profile'),
              child: CircleAvatar(
                radius: 26,
                backgroundColor: _kBlue1.withValues(alpha: 0.10),
                child: ClipOval(
                  child: _AvatarImage(
                    url:
                        '${AppConfig.baseUrl}/web/image/res.users/$userId/image_128',
                    initials: _initials(userName),
                    dio: ref.read(apiClientProvider).dio,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _greeting(),
                    style: TextStyle(
                      color: _kBlue1.withValues(alpha: 0.75),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    userName,
                    style: const TextStyle(
                      color: _kBlue0,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Builder(builder: (context) {
              final count = ref.watch(unreadCountProvider).valueOrNull ?? 0;
              return IconButton(
                onPressed: () => context.push('/notifikasi'),
                icon: Badge(
                  isLabelVisible: count > 0,
                  label: Text(
                    count > 99 ? '99+' : '$count',
                    style: const TextStyle(fontSize: 9),
                  ),
                  backgroundColor: _kRed,
                  child: const Icon(Icons.notifications_none_rounded,
                      color: _kBlue1, size: 22),
                ),
              );
            }),
            ],
          ),
        ),
    );
  }
}

// â”€â”€ Avatar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _AvatarImage extends StatefulWidget {
  final String url;
  final String initials;
  final Dio dio;
  const _AvatarImage(
      {required this.url, required this.initials, required this.dio});

  @override
  State<_AvatarImage> createState() => _AvatarImageState();
}

class _AvatarImageState extends State<_AvatarImage> {
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
    if (_bytes != null) {
      return Image.memory(_bytes!, width: 44, height: 44, fit: BoxFit.cover);
    }
    return Text(widget.initials,
        style: const TextStyle(
            color: _kSky, fontSize: 14, fontWeight: FontWeight.w700));
  }
}

// â”€â”€ Menu Card (compact 3-col) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      elevation: 1.5,
      shadowColor: _kBlue1.withValues(alpha: 0.12),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 12, 6, 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _kBlue1.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _kBlue0,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Riwayat Layanan section ───────────────────────────────────────────────────

class _RiwayatSection extends ConsumerWidget {
  const _RiwayatSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(riwayatLayananProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RIWAYAT LAYANAN',
            style: TextStyle(
              color: _kBlue1.withValues(alpha: 0.5),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 10),
          async.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (_, _) => const SizedBox.shrink(),
            data: (items) => items.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.history_rounded,
                            size: 48,
                            color: _kBlue1.withValues(alpha: 0.2),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Belum ada riwayat layanan',
                            style: TextStyle(
                              color: _kBlue1.withValues(alpha: 0.55),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Mulai gunakan layanan di atas',
                            style: TextStyle(
                              color: _kBlue1.withValues(alpha: 0.35),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: items.map((a) => _ActivityTile(a)).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final _Activity activity;
  const _ActivityTile(this.activity);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push(activity.route),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: _kBlue1.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: activity.iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(activity.icon, color: activity.iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    style: const TextStyle(
                      color: _kBlue0,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${activity.ref} · ${_actDate(activity.date)}',
                    style: TextStyle(
                      color: _kBlue1.withValues(alpha: 0.55),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: activity.stateColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                activity.stateLabel,
                style: TextStyle(
                  color: activity.stateColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
