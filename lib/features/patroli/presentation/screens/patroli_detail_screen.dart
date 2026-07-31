import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../providers/patroli_providers.dart';

class PatroliDetailScreen extends ConsumerWidget {
  final int patroliId;
  const PatroliDetailScreen({super.key, required this.patroliId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync  = ref.watch(patroliDetailProvider(patroliId));
    final titikAsync   = ref.watch(patroliTitikProvider(patroliId));
    final personelAsync = ref.watch(patroliPersonelProvider(patroliId));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9FF),
      appBar: AppBar(
        title: detailAsync.when(
          loading: () => const Text('Detail Patroli'),
          error:   (_, _) => const Text('Detail Patroli'),
          data: (p) => Text(p?.code ?? 'Detail Patroli'),
        ),
        leading: BackButton(onPressed: () => context.go('/patroli')),
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat: $e')),
        data: (patroli) {
          if (patroli == null) {
            return const Center(child: Text('Data tidak ditemukan'));
          }
          final fmt = DateFormat('dd MMM yyyy HH:mm', 'id_ID');
          final durasi = patroli.durasi;
          final durasiStr = durasi == null
              ? '-'
              : '${durasi.inHours.toString().padLeft(2, '0')}:'
                  '${(durasi.inMinutes % 60).toString().padLeft(2, '0')} jam';

          final lokasiStr = [patroli.kecamatanName, patroli.desaName]
              .whereType<String>()
              .join(' › ');

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Kartu info utama ───────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    // Header status
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: _stateColor(patroli.state)
                            .withValues(alpha: 0.1),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12)),
                      ),
                      child: Row(
                        children: [
                          Icon(_stateIcon(patroli.state),
                              color: _stateColor(patroli.state)),
                          const SizedBox(width: 8),
                          Text(patroli.stateLabel,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _stateColor(patroli.state))),
                          const Spacer(),
                          Text(patroli.code,
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    ),
                    // Detail fields
                    _InfoRow(
                      icon: Icons.schedule_outlined,
                      label: 'Mulai',
                      value: fmt.format(patroli.tanggalPatroli),
                    ),
                    if (patroli.tanggalSelesai != null)
                      _InfoRow(
                        icon: Icons.flag_outlined,
                        label: 'Selesai',
                        value: fmt.format(patroli.tanggalSelesai!),
                      ),
                    _InfoRow(
                      icon: Icons.timer_outlined,
                      label: 'Durasi',
                      value: durasiStr,
                    ),
                    if (lokasiStr.isNotEmpty)
                      _InfoRow(
                        icon: Icons.place_outlined,
                        label: 'Lokasi',
                        value: lokasiStr,
                      ),
                    if (patroli.keterangan?.isNotEmpty ?? false)
                      _InfoRow(
                        icon: Icons.notes_outlined,
                        label: 'Keterangan',
                        value: patroli.keterangan!,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Rute patroli (peta) ────────────────────────────────────────
              const _SectionTitle('Rute Patroli'),
              const SizedBox(height: 8),
              titikAsync.when(
                loading: () => const _MapPlaceholder(loading: true),
                error: (_, _) => const _MapPlaceholder(loading: false),
                data: (points) => _RouteMap(points: points),
              ),
              const SizedBox(height: 16),

              // ── Personel ───────────────────────────────────────────────────
              const _SectionTitle('Personel'),
              const SizedBox(height: 8),
              personelAsync.when(
                loading: () => const Center(
                    child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator())),
                error: (e, _) =>
                    Text('Gagal memuat personel: $e',
                        style: const TextStyle(color: Colors.red)),
                data: (list) => list.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Tidak ada data personel',
                            style: TextStyle(color: Colors.grey)),
                      )
                    : Column(
                        children: list
                            .asMap()
                            .entries
                            .map((e) => _PersonelTile(
                                  no: e.key + 1,
                                  nama: e.value['nama'] as String? ?? '-',
                                  pangkat:
                                      e.value['pangkat'] as String?,
                                ))
                            .toList(),
                      ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Color _stateColor(String state) => switch (state) {
        'berjalan' => Colors.blue,
        'selesai'  => Colors.green,
        _          => Colors.orange,
      };

  IconData _stateIcon(String state) => switch (state) {
        'berjalan' => Icons.directions_car,
        'selesai'  => Icons.check_circle_outline,
        _          => Icons.schedule,
      };
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style:
            const TextStyle(fontSize: 15, fontWeight: FontWeight.bold));
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[500]),
          const SizedBox(width: 10),
          SizedBox(
            width: 72,
            child: Text(label,
                style: TextStyle(
                    fontSize: 13, color: Colors.grey[600])),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _RouteMap extends StatelessWidget {
  final List<LatLng> points;
  const _RouteMap({required this.points});

  static const _kNavy = Color(0xFF1D2A44);

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map_outlined, color: Colors.grey, size: 40),
              SizedBox(height: 8),
              Text('Tidak ada data titik lokasi',
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    final center = points[points.length ~/ 2];

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 280,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: 14,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.pinchZoom |
                  InteractiveFlag.drag,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'id.polisibaik.ampera247',
            ),
            if (points.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(
                      points: points,
                      color: _kNavy,
                      strokeWidth: 4),
                ],
              ),
            MarkerLayer(
              markers: [
                Marker(
                  point: points.first,
                  child: const Icon(Icons.location_on,
                      color: Colors.green, size: 30),
                ),
                if (points.length > 1)
                  Marker(
                    point: points.last,
                    child: const Icon(Icons.flag,
                        color: Colors.red, size: 28),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  final bool loading;
  const _MapPlaceholder({required this.loading});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Center(
        child: loading
            ? const CircularProgressIndicator()
            : const Text('Gagal memuat peta',
                style: TextStyle(color: Colors.grey)),
      ),
    );
  }
}

class _PersonelTile extends StatelessWidget {
  final int no;
  final String nama;
  final String? pangkat;
  const _PersonelTile(
      {required this.no, required this.nama, this.pangkat});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: const Color(0xFF1D2A44),
            child: Text('$no',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(nama,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          if (pangkat != null)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFA2CFFE).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(pangkat!,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500)),
            ),
        ],
      ),
    );
  }
}
