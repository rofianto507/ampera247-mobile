import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/url_helper.dart';
import '../../domain/entities/sertifikasi.dart';
import '../providers/sertifikasi_provider.dart';

const _kNavy  = Color(0xFF1D2A44);
const _kSky   = Color(0xFFA2CFFE);
const _kGreen = Color(0xFF2ECC71);

final _dateFmt = DateFormat('d MMM yyyy', 'id_ID');

class SertifikasiScreen extends ConsumerWidget {
  const SertifikasiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(sertifikasiListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: _kNavy,
        foregroundColor: Colors.white,
        title: const Text('Sertifikasi Anti Narkoba',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.invalidate(sertifikasiListProvider),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(sertifikasiListProvider),
        ),
        data: (list) => list.isEmpty
            ? _EmptyView(onRefresh: () => ref.invalidate(sertifikasiListProvider))
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(sertifikasiListProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  itemCount: list.length,
                  itemBuilder: (ctx, i) =>
                      _SertifikasiCard(item: list[i]),
                ),
              ),
      ),
    );
  }
}

// ── Card ────────────────────────────────────────────────────────────────────────

class _SertifikasiCard extends StatelessWidget {
  final Sertifikasi item;
  const _SertifikasiCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final expired = item.tanggalExpired;
    final isExpiringSoon = expired != null &&
        expired.difference(DateTime.now()).inDays <= 7;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showDetail(context, item),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _kNavy.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.verified_outlined,
                        color: _kNavy, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _kNavy,
                      ),
                    ),
                  ),
                  if (isExpiringSoon)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Segera Berakhir',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _Chip(Icons.quiz_outlined,
                      '${item.jumlahSoal} Soal'),
                  _Chip(Icons.timer_outlined,
                      '${item.waktuMenit} Menit'),
                  _Chip(Icons.star_half_outlined,
                      'Lulus ≥ ${item.nilaiKelulusan}%'),
                ],
              ),
              if (item.tanggalExpired != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.event_outlined,
                        size: 14,
                        color: isExpiringSoon
                            ? Colors.orange
                            : Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      'Berakhir: ${_dateFmt.format(item.tanggalExpired!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isExpiringSoon
                            ? Colors.orange.shade700
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Detail bottom sheet ──────────────────────────────────────────────────────────

void _showDetail(BuildContext context, Sertifikasi item) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _DetailSheet(item: item),
  );
}

class _DetailSheet extends StatelessWidget {
  final Sertifikasi item;
  const _DetailSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    return Container(
      constraints: BoxConstraints(
          maxHeight: mq.size.height * 0.85),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1D2A44), Color(0xFF243356)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified,
                    color: _kSky, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _kGreen.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Aktif',
                            style: TextStyle(
                                color: _kGreen,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Scrollable body
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info grid
                  _InfoGrid(item: item),
                  if (item.notes?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 16),
                    const Text('Catatan',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: _kNavy)),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F6FB),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        item.notes!,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF4A5568)),
                      ),
                    ),
                  ],
                  // Statistik
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _StatBox(
                          label: 'Total Peserta',
                          value: '${item.totalPeserta}',
                          icon: Icons.people_outline,
                          color: _kSky,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatBox(
                          label: 'Peserta Lulus',
                          value: '${item.totalLulus}',
                          icon: Icons.check_circle_outline,
                          color: _kGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          // CTA button
          Padding(
            padding: EdgeInsets.fromLTRB(
                16, 8, 16, 16 + mq.padding.bottom),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _kNavy,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.open_in_browser, size: 20),
                label: const Text(
                  'Ikuti Sertifikasi',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
                onPressed: item.urlPublic.isNotEmpty
                    ? () => _openUrl(item.urlPublic)
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openUrl(String url) {
    if (url.isNotEmpty) openExternalUrl(url);
  }
}

// ── Info grid ────────────────────────────────────────────────────────────────────

class _InfoGrid extends StatelessWidget {
  final Sertifikasi item;
  const _InfoGrid({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FB),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _InfoRow(
            Icons.quiz_outlined, 'Jumlah Soal',
            '${item.jumlahSoal} soal',
          ),
          const Divider(height: 1),
          _InfoRow(
            Icons.timer_outlined, 'Waktu Pengerjaan',
            '${item.waktuMenit} menit',
          ),
          const Divider(height: 1),
          _InfoRow(
            Icons.star_half_outlined, 'Nilai Kelulusan',
            '≥ ${item.nilaiKelulusan}%',
          ),
          if (item.tanggalAktif != null) ...[
            const Divider(height: 1),
            _InfoRow(
              Icons.play_circle_outline, 'Tanggal Mulai',
              _dateFmt.format(item.tanggalAktif!),
            ),
          ],
          if (item.tanggalExpired != null) ...[
            const Divider(height: 1),
            _InfoRow(
              Icons.event_busy_outlined, 'Tanggal Berakhir',
              _dateFmt.format(item.tanggalExpired!),
              valueColor: item.tanggalExpired!
                          .difference(DateTime.now())
                          .inDays <=
                      7
                  ? Colors.orange.shade700
                  : null,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow(this.icon, this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _kNavy.withValues(alpha: 0.6)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF718096))),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? _kNavy,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat box ─────────────────────────────────────────────────────────────────────

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatBox(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: color)),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: Color(0xFF718096))),
        ],
      ),
    );
  }
}

// ── Chip ─────────────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _kNavy.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _kNavy),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: _kNavy,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── Empty & Error states ─────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final VoidCallback onRefresh;
  const _EmptyView({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_outlined,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('Belum ada sertifikasi aktif',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF718096))),
          const SizedBox(height: 8),
          const Text('Cek kembali nanti',
              style:
                  TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined,
                size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('Gagal memuat data',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4A5568))),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF9CA3AF))),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Coba Lagi'),
              style: FilledButton.styleFrom(backgroundColor: _kNavy),
            ),
          ],
        ),
      ),
    );
  }
}
