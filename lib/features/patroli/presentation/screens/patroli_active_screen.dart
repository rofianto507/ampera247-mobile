import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../providers/patroli_providers.dart';
import '../providers/patroli_settings_notifier.dart';
import '../providers/patroli_tracking_notifier.dart';

class PatroliActiveScreen extends ConsumerStatefulWidget {
  const PatroliActiveScreen({super.key});

  @override
  ConsumerState<PatroliActiveScreen> createState() => _PatroliActiveScreenState();
}

class _PatroliActiveScreenState extends ConsumerState<PatroliActiveScreen> {
  static const _kNavy = Color(0xFF1D2A44);

  // Default center: Palembang
  static const _kDefaultCenter = LatLng(-2.9761, 104.7754);

  final _mapController = MapController();
  bool _trackingStarted = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_ensureTracking);
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _ensureTracking() async {
    if (!mounted) return;
    final tracking = ref.read(patroliTrackingProvider);
    if (tracking.isActive) {
      setState(() => _trackingStarted = true);
      return;
    }

    final patroli = await ref.read(activePatroliProvider.future);
    if (patroli == null || !mounted) return;

    // Muat titik yang sudah tersimpan (jika app di-restart saat patroli aktif)
    final existingPoints = await ref.read(patroliTitikProvider(patroli.id).future);
    final interval = ref.read(patroliSettingsProvider);

    await ref
        .read(patroliTrackingProvider.notifier)
        .start(patroli.id, interval,
            existingPoints: existingPoints, kode: patroli.code);

    if (mounted) setState(() => _trackingStarted = true);
  }

  Future<void> _selesai() async {
    final tracking = ref.read(patroliTrackingProvider);
    final patroli  = ref.read(activePatroliProvider).valueOrNull;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => _SelesaiDialog(
        titikCount: tracking.points.length,
        startTime: patroli?.tanggalPatroli,
      ),
    );
    if (confirm != true || !mounted) return;

    await ref.read(patroliTrackingProvider.notifier).stop();
    if (!mounted) return;

    ref.invalidate(activePatroliProvider);
    ref.invalidate(patroliHistoryProvider);
    context.go('/patroli');
  }

  @override
  Widget build(BuildContext context) {
    final tracking  = ref.watch(patroliTrackingProvider);
    final activeAsync = ref.watch(activePatroliProvider);

    // Auto-center map saat titik baru masuk
    ref.listen(patroliTrackingProvider.select((s) => s.points.lastOrNull),
        (_, latest) {
      if (latest != null && mounted) {
        _mapController.move(latest, _mapController.camera.zoom);
      }
    });

    final points = tracking.points;
    final center = points.isNotEmpty ? points.last : _kDefaultCenter;

    return Scaffold(
      appBar: AppBar(
        title: activeAsync.when(
          loading: () => const Text('Patroli Berjalan'),
          error:   (_, _) => const Text('Patroli Berjalan'),
          data: (p) => Text(p?.code ?? 'Patroli Berjalan'),
        ),
        leading: BackButton(onPressed: () => context.go('/patroli')),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red[700],
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              icon: const Icon(Icons.stop_circle_outlined, size: 18),
              label: const Text('Selesai'),
              onPressed: _selesai,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Info bar ─────────────────────────────────────────────────────
          activeAsync.when(
            loading: () => const SizedBox(height: 4, child: LinearProgressIndicator()),
            error: (_, _) => const SizedBox(),
            data: (patroli) => Container(
              color: _kNavy,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  // Timer
                  if (patroli != null)
                    _TimerDisplay(startTime: patroli.tanggalPatroli),
                  const Spacer(),
                  // Jumlah titik
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFFA2CFFE), size: 16),
                      const SizedBox(width: 4),
                      Text('${points.length} titik',
                          style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Status GPS
                  Row(
                    children: [
                      Icon(
                        _trackingStarted ? Icons.gps_fixed : Icons.gps_not_fixed,
                        color: _trackingStarted
                            ? Colors.greenAccent
                            : Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _trackingStarted ? 'Aktif' : 'Memulai...',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Peta ─────────────────────────────────────────────────────────
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 15,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'id.polisibaik.ampera247',
                ),
                if (points.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: points,
                        color: _kNavy,
                        strokeWidth: 4,
                      ),
                    ],
                  ),
                if (points.isNotEmpty)
                  MarkerLayer(
                    markers: [
                      // Titik awal
                      Marker(
                        point: points.first,
                        child: const Icon(Icons.location_on,
                            color: Colors.green, size: 30),
                      ),
                      // Posisi terkini
                      if (points.length > 1)
                        Marker(
                          point: points.last,
                          width: 28,
                          height: 28,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1565C0),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black38,
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),

          // ── Keterangan lokasi ─────────────────────────────────────────────
          activeAsync.maybeWhen(
            data: (p) => p?.kecamatanName != null
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    color: Colors.white,
                    child: Row(
                      children: [
                        const Icon(Icons.place_outlined,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          [p!.kecamatanName, p.desaName]
                              .whereType<String>()
                              .join(' › '),
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : const SizedBox(),
            orElse: () => const SizedBox(),
          ),
        ],
      ),
    );
  }
}

// ── Dialog konfirmasi selesai ─────────────────────────────────────────────────

class _SelesaiDialog extends StatelessWidget {
  final int titikCount;
  final DateTime? startTime;
  const _SelesaiDialog({required this.titikCount, this.startTime});

  @override
  Widget build(BuildContext context) {
    final elapsed = startTime != null
        ? DateTime.now().difference(startTime!)
        : null;
    final durasiStr = elapsed == null
        ? null
        : '${elapsed.inHours.toString().padLeft(2, '0')}:'
            '${(elapsed.inMinutes % 60).toString().padLeft(2, '0')}:'
            '${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ikon peringatan
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.stop_circle_outlined,
                  color: Colors.red[700], size: 44),
            ),
            const SizedBox(height: 16),
            const Text('Selesaikan Patroli?',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Rekaman lokasi akan dihentikan dan patroli ditandai selesai.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 20),

            // Ringkasan durasi & titik
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatChip(
                    icon: Icons.timer_outlined,
                    label: 'Durasi',
                    value: durasiStr ?? '-',
                  ),
                  Container(width: 1, height: 36, color: Colors.grey[300]),
                  _StatChip(
                    icon: Icons.location_on_outlined,
                    label: 'Titik lokasi',
                    value: '$titikCount titik',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tombol
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Selesaikan',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatChip(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    );
  }
}

// ── Timer ─────────────────────────────────────────────────────────────────────

class _TimerDisplay extends StatefulWidget {
  final DateTime startTime;
  const _TimerDisplay({required this.startTime});

  @override
  State<_TimerDisplay> createState() => _TimerDisplayState();
}

class _TimerDisplayState extends State<_TimerDisplay> {
  late Timer _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(
        const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(widget.startTime);
    final h = elapsed.inHours.toString().padLeft(2, '0');
    final m = (elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final s = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return Text(
      '$h:$m:$s',
      style: const TextStyle(
          color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold,
          fontFeatures: [FontFeature.tabularFigures()]),
    );
  }
}
