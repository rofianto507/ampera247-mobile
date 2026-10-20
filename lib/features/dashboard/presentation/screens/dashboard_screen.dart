import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/app_config.dart';
import '../../../antrian/presentation/providers/antrian_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../eform_laka/presentation/providers/eform_laka_provider.dart';
import '../../../rehab/presentation/providers/rehab_provider.dart';
import '../../../notifikasi/presentation/providers/notifikasi_provider.dart';
import '../providers/welcome_screen_provider.dart';
import '../providers/slider_provider.dart';

const _kBlue0 = Color(0xFF0D1526);
const _kBlue1 = Color(0xFF1D2A44);
const _kSky   = Color(0xFFA2CFFE);
const _kRed   = Color(0xFFDD1111);


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

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  // Reset to false tiap restart app (per-session)
  static bool _welcomeShownThisSession = false;

  @override
  void initState() {
    super.initState();
    if (!_welcomeShownThisSession) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowWelcome());
    }
  }

  Future<void> _maybeShowWelcome() async {
    if (_welcomeShownThisSession || !mounted) return;
    _welcomeShownThisSession = true;

    final data = await ref.read(welcomeScreenProvider.future);
    if (data == null || !mounted) return;

    final dio = ref.read(apiClientProvider).dio;
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      barrierDismissible: true,
      builder: (ctx) => _WelcomeDialog(data: data, dio: dio),
    );
  }

  @override
  Widget build(BuildContext context) {
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

// â”€â”€ Welcome Dialog â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _WelcomeDialog extends StatefulWidget {
  final WelcomeScreenData data;
  final Dio dio;
  const _WelcomeDialog({required this.data, required this.dio});

  @override
  State<_WelcomeDialog> createState() => _WelcomeDialogState();
}

class _WelcomeDialogState extends State<_WelcomeDialog> {
  Uint8List? _bytes;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final resp = await widget.dio.get<List<int>>(
        widget.data.imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      if (mounted && resp.data != null) {
        setState(() {
          _bytes = Uint8List.fromList(resp.data!);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      behavior: HitTestBehavior.opaque,
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 56),
                  child: _loading
                      ? const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2)
                      : _bytes == null
                          ? const SizedBox.shrink()
                          : GestureDetector(
                              onTap: () {},
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Image.memory(
                                      _bytes!,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  if (widget.data.buttonUrl.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: FilledButton(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: const Color(0xFF1D2A44),
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        onPressed: () async {
                                          final uri = Uri.tryParse(widget.data.buttonUrl);
                                          if (uri != null && await canLaunchUrl(uri)) {
                                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                                          }
                                        },
                                        child: Text(
                                          widget.data.buttonLabel,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                ),
              ),
              // Tombol tutup
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 28),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ── Banner Slider ──────────────────────────────────────────────────────────────

class _BannerSlider extends ConsumerStatefulWidget {
  const _BannerSlider();
  @override
  ConsumerState<_BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends ConsumerState<_BannerSlider> {
  late final PageController _ctrl;
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = PageController(viewportFraction: 0.88);
  }

  void _startTimer(int count) {
    _timer?.cancel();
    if (count < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      // hasClients: saat slider kembali ke state loading, PageView keluar dari
      // tree dan controller lepas walau State-nya masih mounted.
      if (!mounted || !_ctrl.hasClients) return;
      final next = (_page + 1) % count;
      _ctrl.animateToPage(next, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dio = ref.read(apiClientProvider).dio;

    ref.listen<AsyncValue<List<SliderItem>>>(sliderProvider, (_, next) {
      next.whenData((items) => _startTimer(items.length));
    });

    return ref.watch(sliderProvider).when(
      loading: () => _buildSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          children: [
            SizedBox(
              height: 160,
              child: PageView.builder(
                controller: _ctrl,
                itemCount: items.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => _SlideImageCard(item: items[i], dio: dio),
              ),
            ),
            if (items.length > 1) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(items.length, (i) {
                  final active = i == _page;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active ? _kBlue1 : _kBlue1.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSkeleton() {
    return Container(
      height: 160,
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: _kBlue1.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

class _SlideImageCard extends StatefulWidget {
  final SliderItem item;
  final Dio dio;
  const _SlideImageCard({required this.item, required this.dio});
  @override
  State<_SlideImageCard> createState() => _SlideImageCardState();
}

class _SlideImageCardState extends State<_SlideImageCard>
    with AutomaticKeepAliveClientMixin {
  Uint8List? _bytes;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final resp = await widget.dio.get<List<int>>(
        widget.item.imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      if (mounted && resp.data != null) {
        setState(() => _bytes = Uint8List.fromList(resp.data!));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: _kBlue1,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D1526).withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _bytes == null
            ? const Center(
                child: SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white38),
                ),
              )
            : Image.memory(_bytes!, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
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
            Material(
              color: _kBlue1.withValues(alpha: 0.10),
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => context.push('/profile'),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: ClipOval(
                    child: _AvatarImage(
                      url: '${AppConfig.baseUrl}/web/image/res.users/$userId/image_128',
                      initials: _initials(userName),
                      dio: ref.read(apiClientProvider).dio,
                    ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: _kBlue1.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.push(activity.route),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
          ),
        ),
      ),
    );
  }
}
