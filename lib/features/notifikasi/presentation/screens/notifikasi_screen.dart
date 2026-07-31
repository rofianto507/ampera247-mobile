import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/notifikasi.dart';
import '../providers/notifikasi_provider.dart';

const _kBlue1 = Color(0xFF1D2A44);

class NotifikasiScreen extends ConsumerWidget {
  const NotifikasiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(notifikasiListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FA),
      appBar: AppBar(
        backgroundColor: _kBlue1,
        foregroundColor: Colors.white,
        title: const Text(
          'Notifikasi',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        elevation: 0,
        actions: [
          listAsync.maybeWhen(
            data: (list) {
              final hasUnread = list.any((n) => !n.isRead);
              if (!hasUnread) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => _markAllRead(context, ref),
                child: const Text(
                  'Tandai dibaca',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: listAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _kBlue1)),
        error: (_, _) => const Center(child: Text('Gagal memuat notifikasi')),
        data: (list) {
          if (list.isEmpty) return _EmptyState();
          return RefreshIndicator(
            color: _kBlue1,
            onRefresh: () async {
              ref.invalidate(notifikasiListProvider);
              ref.invalidate(unreadCountProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 4),
              itemBuilder: (_, i) => _NotifTile(item: list[i]),
            ),
          );
        },
      ),
    );
  }

  Future<void> _markAllRead(BuildContext context, WidgetRef ref) async {
    final api  = ref.read(apiClientProvider);
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;
    await markAllRead(api: api, userId: user.id);
    ref.invalidate(notifikasiListProvider);
    ref.invalidate(unreadCountProvider);
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 64,
            color: _kBlue1.withValues(alpha: 0.18),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum Ada Notifikasi',
            style: TextStyle(
              color: _kBlue1.withValues(alpha: 0.55),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Notifikasi layanan akan muncul di sini',
            style: TextStyle(
              color: _kBlue1.withValues(alpha: 0.35),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final NotifikasiItem item;
  const _NotifTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final unread = !item.isRead;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: unread
            ? _kBlue1.withValues(alpha: 0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: unread
              ? _kBlue1.withValues(alpha: 0.12)
              : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: _kBlue1.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TipeIcon(tipe: item.tipe),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.judul,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: unread
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: _kBlue1,
                          ),
                        ),
                      ),
                      if (unread)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 8, top: 2),
                          decoration: const BoxDecoration(
                            color: Color(0xFF2563EB),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.isi,
                    style: TextStyle(
                      fontSize: 12,
                      color: _kBlue1.withValues(alpha: 0.60),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatDate(item.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: _kBlue1.withValues(alpha: 0.35),
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

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return DateFormat('d MMM y, HH:mm', 'id').format(dt);
  }
}

class _TipeIcon extends StatelessWidget {
  final String tipe;
  const _TipeIcon({required this.tipe});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (tipe) {
      'antrian'    => (Icons.confirmation_number_rounded, const Color(0xFF0EA5E9)),
      'rehab'      => (Icons.local_hospital_rounded,      const Color(0xFF10B981)),
      'konseling'  => (Icons.psychology_rounded,           const Color(0xFF8B5CF6)),
      'eform_laka' => (Icons.car_crash_rounded,            const Color(0xFFF59E0B)),
      _            => (Icons.notifications_rounded,        _kBlue1),
    };
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
