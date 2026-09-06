import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/patroli.dart';
import '../../domain/entities/patroli_grup.dart';
import '../providers/patroli_providers.dart';
import '../widgets/patroli_mulai_sheet.dart';

class PatroliHomeScreen extends ConsumerWidget {
  const PatroliHomeScreen({super.key});

  static const _kNavy = Color(0xFF1D2A44);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grupAsync   = ref.watch(patroliGrupProvider);
    final activeAsync = ref.watch(activePatroliProvider);
    final histAsync   = ref.watch(patroliHistoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9FF),
      appBar: AppBar(
        title: const Text('Patroli'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Pengaturan',
            onPressed: () => context.go('/patroli/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
            onPressed: () => ref.read(authNotifierProvider.notifier).logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: _kNavy,
        onRefresh: () async {
          ref.invalidate(patroliGrupProvider);
          ref.invalidate(activePatroliProvider);
          ref.invalidate(patroliHistoryProvider);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            // ── Kartu Grup ──────────────────────────────────────────────────
            grupAsync.when(
              loading: () => const _Shimmer(),
              error: (e, _) => _ErrorCard(e.toString()),
              data: (grup) => grup == null
                  ? const _ErrorCard(
                      'Akun ini belum terdaftar di grup patroli. Hubungi admin.')
                  : _GrupCard(grup: grup),
            ),
            const SizedBox(height: 16),

            // ── Status Patroli ───────────────────────────────────────────────
            activeAsync.when(
              loading: () => const _Shimmer(),
              error: (_, _) => const SizedBox(),
              data: (active) {
                final grup = grupAsync.valueOrNull;
                if (active != null) {
                  return _ActiveCard(
                    patroli: active,
                    onTap: () => context.go('/patroli/active'),
                  );
                }
                if (grup != null) {
                  return _MulaiButton(
                    grupId: grup.id,
                    onStarted: () {
                      ref.invalidate(activePatroliProvider);
                      context.go('/patroli/active');
                    },
                  );
                }
                return const SizedBox();
              },
            ),
            const SizedBox(height: 24),

            // ── Riwayat ──────────────────────────────────────────────────────
            const Text('Riwayat Patroli',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            histAsync.when(
              loading: () => const _Shimmer(),
              error: (e, _) => _ErrorCard(e.toString()),
              data: (list) => list.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                          child: Text('Belum ada riwayat patroli',
                              style: TextStyle(color: Colors.grey))),
                    )
                  : Column(
                      children: list.map((p) => _HistoryItem(patroli: p)).toList()),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Kartu info grup ──────────────────────────────────────────────────────────

class _GrupCard extends StatelessWidget {
  final PatroliGrup grup;
  const _GrupCard({required this.grup});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1D2A44),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text(grup.jenisIcon, style: const TextStyle(fontSize: 36)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(grup.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                if (grup.noPol != null) ...[
                  const SizedBox(height: 4),
                  Text(grup.noPol!,
                      style: const TextStyle(
                          color: Color(0xFFA2CFFE), fontSize: 14)),
                ],
                const SizedBox(height: 4),
                Text(grup.jenisLabel,
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Kartu patroli aktif ──────────────────────────────────────────────────────

class _ActiveCard extends StatelessWidget {
  final Patroli patroli;
  final VoidCallback onTap;
  const _ActiveCard({required this.patroli, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.green[700],
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.white.withValues(alpha: 0.15),
        highlightColor: Colors.white.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.directions_car, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Patroli Sedang Berjalan',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(patroli.code,
                        style: const TextStyle(color: Colors.white70)),
                    if (patroli.kecamatanName != null)
                      Text(patroli.kecamatanName!,
                          style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tombol Mulai ─────────────────────────────────────────────────────────────

class _MulaiButton extends StatelessWidget {
  final int grupId;
  final VoidCallback onStarted;
  const _MulaiButton({required this.grupId, required this.onStarted});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF1D2A44),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        icon: const Icon(Icons.play_arrow_rounded, size: 28),
        label: const Text('Mulai Patroli Baru', style: TextStyle(fontSize: 16)),
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(16))),
          builder: (_) => PatroliMulaiSheet(
            grupId: grupId,
            onStarted: onStarted,
          ),
        ),
      ),
    );
  }
}

// ── Item riwayat ─────────────────────────────────────────────────────────────

class _HistoryItem extends StatelessWidget {
  final Patroli patroli;
  const _HistoryItem({required this.patroli});

  @override
  Widget build(BuildContext context) {
    final fmt     = DateFormat('dd MMM yyyy HH:mm', 'id_ID');
    final durasi  = patroli.durasi;
    final durasiStr = durasi == null
        ? '-'
        : '${durasi.inHours.toString().padLeft(2, '0')}:'
            '${(durasi.inMinutes % 60).toString().padLeft(2, '0')} jam';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: patroli.state == 'selesai'
              ? Colors.green[50]
              : Colors.orange[50],
          child: Icon(
            Icons.shield_outlined,
            color: patroli.state == 'selesai'
                ? Colors.green[700]
                : Colors.orange[700],
          ),
        ),
        title: Text(patroli.code,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (patroli.kecamatanName != null)
              Text(
                [patroli.kecamatanName, patroli.desaName]
                    .whereType<String>()
                    .join(' - '),
                style: const TextStyle(fontSize: 12),
              ),
            Text(fmt.format(patroli.tanggalPatroli),
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _StateBadge(patroli.state),
            if (durasi != null)
              Text(durasiStr,
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        onTap: () => context.go('/patroli/detail/${patroli.id}'),
        isThreeLine: patroli.kecamatanName != null,
      ),
    );
  }
}

class _StateBadge extends StatelessWidget {
  final String state;
  const _StateBadge(this.state);

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (state) {
      'selesai'  => ('Selesai', Colors.green),
      'berjalan' => ('Berjalan', Colors.blue),
      _          => ('Menunggu', Colors.orange),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

class _Shimmer extends StatelessWidget {
  const _Shimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(
              child: Text(message,
                  style: const TextStyle(color: Colors.red, fontSize: 13))),
        ],
      ),
    );
  }
}
