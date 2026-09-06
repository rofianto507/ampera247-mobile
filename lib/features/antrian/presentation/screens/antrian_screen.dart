import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/antrian.dart';
import '../providers/antrian_provider.dart';

// ── Konstanta warna ──────────────────────────────────────────────────────────
const _kBlue1 = Color(0xFF1D2A44);
const _kBlue  = Color(0xFF1D2A44); // tema utama — seragam dengan eForm Laka

// ─────────────────────────────────────────────────────────────────────────────

class AntrianScreen extends ConsumerStatefulWidget {
  const AntrianScreen({super.key});
  @override
  ConsumerState<AntrianScreen> createState() => _AntrianScreenState();
}

class _AntrianScreenState extends ConsumerState<AntrianScreen> {
  final _scrollCtrl = ScrollController();
  String? _filterState;
  String? _filterLayanan;

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  bool get _hasFilter => _filterState != null || _filterLayanan != null;

  Future<void> _showFilterSheet() async {
    final list = ref.read(antrianListProvider).valueOrNull ?? [];
    final availableLayanan = list
        .map((e) => e.layananNama)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();

    final result = await showModalBottomSheet<(String, String)>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: const BoxConstraints(maxWidth: 480),
      builder: (_) => _FilterSheet(
        currentState:   _filterState,
        currentLayanan: _filterLayanan,
        availableLayanan: availableLayanan,
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      _filterState   = result.$1.isEmpty ? null : result.$1;
      _filterLayanan = result.$2.isEmpty ? null : result.$2;
    });
  }

  Future<void> _showAddSheet() async {
    final nomorAntrian = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
        maxWidth: 480,
      ),
      builder: (_) => const _AntrianFormSheet(),
    );
    if (nomorAntrian != null && mounted) {
      ref.invalidate(antrianListProvider);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Nomor antrian Anda: $nomorAntrian'),
        backgroundColor: _kBlue,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(antrianListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9FF),
      body: Column(
        children: [
          // ── AppBar custom ──────────────────────────────────────────────
          Container(
            color: _kBlue,
            child: SafeArea(
              bottom: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: SizedBox(
                    height: kToolbarHeight,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.maybePop(context),
                        ),
                        const Text(
                          'Antrian Layanan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        Stack(
                          alignment: Alignment.topRight,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.filter_list_rounded,
                                  color: Colors.white),
                              onPressed: _showFilterSheet,
                            ),
                            if (_hasFilter)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF90CAF9),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Body ──────────────────────────────────────────────────────
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: listAsync.when(
                        loading: () => const Center(
                          child: CircularProgressIndicator(color: _kBlue),
                        ),
                        error: (e, _) => Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  size: 48, color: Colors.red),
                              const SizedBox(height: 12),
                              Text('Gagal memuat data',
                                  style:
                                      TextStyle(color: Colors.grey.shade600)),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () =>
                                    ref.invalidate(antrianListProvider),
                                child: const Text('Coba lagi'),
                              ),
                            ],
                          ),
                        ),
                        data: (list) {
                          final filtered = list.where((e) {
                            final stateOk   = _filterState   == null || e.state       == _filterState;
                            final layananOk = _filterLayanan == null || e.layananNama == _filterLayanan;
                            return stateOk && layananOk;
                          }).toList();
                          return RefreshIndicator(
                                  color: _kBlue,
                                  onRefresh: () async =>
                                      ref.invalidate(antrianListProvider),
                                  child: filtered.isEmpty
                                      ? ListView(
                                          physics: const AlwaysScrollableScrollPhysics(),
                                          children: [
                                            SizedBox(
                                              height: MediaQuery.of(context).size.height * 0.6,
                                              child: _EmptyState(
                                                  onRefresh: () => ref.invalidate(antrianListProvider)),
                                            ),
                                          ],
                                        )
                                      : ListView.builder(
                                          physics: const AlwaysScrollableScrollPhysics(),
                                          controller: _scrollCtrl,
                                          padding: const EdgeInsets.fromLTRB(
                                              16, 16, 16, 80),
                                          itemCount: filtered.length,
                                          itemBuilder: (_, i) =>
                                              _AntrianCard(item: filtered[i]),
                                        ),
                                );
                        },
                      ),
                    ),
                    Positioned(
                      right: 16,
                      bottom: 16,
                      child: _ExpandableFab(
                        scrollController: _scrollCtrl,
                        onPressed: _showAddSheet,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter sheet ──────────────────────────────────────────────────────────────

class _FilterSheet extends StatelessWidget {
  final String? currentState;
  final String? currentLayanan;
  final List<String> availableLayanan;

  const _FilterSheet({
    this.currentState,
    this.currentLayanan,
    required this.availableLayanan,
  });

  static const _stateOptions = [
    (label: 'Semua',        value: ''),
    (label: 'Menunggu',     value: 'menunggu'),
    (label: 'Dikonfirmasi', value: 'konfirmasi'),
    (label: 'Dipanggil',    value: 'dipanggil'),
    (label: 'Selesai',      value: 'selesai'),
    (label: 'Batal',        value: 'batal'),
  ];

  Widget _chip(BuildContext context, String label, bool isActive,
      VoidCallback onTap) {
    return Material(
      color: isActive ? _kBlue : const Color(0xFFF0F4FF),
      borderRadius: BorderRadius.circular(6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: (isActive ? Colors.white : _kBlue).withValues(alpha: 0.25),
        highlightColor: (isActive ? Colors.white : _kBlue).withValues(alpha: 0.12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(label,
              style: TextStyle(
                color: isActive ? Colors.white : _kBlue1,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              )),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final curState   = currentState   ?? '';
    final curLayanan = currentLayanan ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Filter',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _kBlue1)),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: _kBlue1),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          // Seksi Status
          const Text('STATUS',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey,
                  letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _stateOptions
                .map((o) => _chip(
                      context,
                      o.label,
                      curState == o.value,
                      () => Navigator.pop(context, (o.value, curLayanan)),
                    ))
                .toList(),
          ),

          // Seksi Jenis Layanan
          if (availableLayanan.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('JENIS LAYANAN',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey,
                    letterSpacing: 1.2)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(context, 'Semua', curLayanan == '',
                    () => Navigator.pop(context, (curState, ''))),
                ...availableLayanan.map((name) => _chip(
                      context,
                      name,
                      curLayanan == name,
                      () => Navigator.pop(context, (curState, name)),
                    )),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onRefresh;
  const _EmptyState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.confirmation_number_rounded,
              size: 64, color: _kBlue.withValues(alpha: 0.25)),
          const SizedBox(height: 16),
          Text('Belum ada antrian',
              style: TextStyle(
                  color: _kBlue.withValues(alpha: 0.7),
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Tekan Ambil untuk mengambil nomor antrian',
              style:
                  TextStyle(color: _kBlue.withValues(alpha: 0.45), fontSize: 13)),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}

// ── Card item ─────────────────────────────────────────────────────────────────

class _AntrianCard extends StatelessWidget {
  final Antrian item;
  const _AntrianCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy', 'id');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: _kBlue1.withValues(alpha: 0.07),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _showAntrianDetail(context, item),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _kBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.nomorUrut.toString().padLeft(3, '0'),
                          style: const TextStyle(
                            color: _kBlue,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'monospace',
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.layananNama?.split(' ').first ?? '-',
                          style: TextStyle(
                            color: _kBlue.withValues(alpha: 0.6),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _kBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(item.nomorAntrian,
                                  style: const TextStyle(
                                    color: _kBlue,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'monospace',
                                    letterSpacing: 0.5,
                                  )),
                            ),
                            const SizedBox(width: 6),
                            _StateBadge(state: item.state),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(item.atasNama,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _kBlue1),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(item.loketNama,
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_rounded,
                                size: 11, color: Colors.grey.shade400),
                            const SizedBox(width: 4),
                            Text(dateFmt.format(item.tanggalBooking),
                                style: TextStyle(
                                    color: Colors.grey.shade500, fontSize: 11)),
                          ],
                        ),
                      ],
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

// ── State badge ───────────────────────────────────────────────────────────────

class _StateBadge extends StatelessWidget {
  final String state;
  const _StateBadge({required this.state});

  @override
  Widget build(BuildContext context) {
    final (String label, Color bg, Color fg) = switch (state) {
      'konfirmasi' => ('Dikonfirmasi', const Color(0xFFE3F2FD), const Color(0xFF1565C0)),
      'dipanggil'  => ('Dipanggil',   const Color(0xFFFFF8E1), const Color(0xFFE65100)),
      'selesai'    => ('Selesai',      const Color(0xFFE8F5E9), const Color(0xFF2E7D32)),
      'batal'      => ('Batal',        const Color(0xFFEEEEEE), const Color(0xFF757575)),
      _            => ('Menunggu',     const Color(0xFFF3E5F5), const Color(0xFF6A1B9A)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3)),
    );
  }
}

// ── Detail bottom sheet ───────────────────────────────────────────────────────

void _showAntrianDetail(BuildContext context, Antrian item) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    constraints: const BoxConstraints(maxWidth: 480),
    builder: (_) => _AntrianDetailSheet(item: item),
  );
}

class _AntrianDetailSheet extends ConsumerWidget {
  final Antrian item;
  const _AntrianDetailSheet({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFmt = DateFormat('dd MMM yyyy', 'id');

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 6),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 8, 4),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Detail Antrian',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _kBlue1)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: _kBlue1),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(16),
                children: [
                  // Nomor antrian prominent
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: _kBlue.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          item.nomorAntrian,
                          style: const TextStyle(
                            color: _kBlue,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'monospace',
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _StateBadge(state: item.state),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _DetailRow(
                      icon: Icons.person_rounded,
                      label: 'Atas Nama',
                      value: item.atasNama),
                  if (item.layananNama != null)
                    _DetailRow(
                        icon: Icons.category_rounded,
                        label: 'Jenis Layanan',
                        value: item.layananNama!),
                  _DetailRow(
                      icon: Icons.storefront_rounded,
                      label: 'Loket',
                      value: item.loketNama),
                  _DetailRow(
                      icon: Icons.calendar_today_rounded,
                      label: 'Tanggal Booking',
                      value: dateFmt.format(item.tanggalBooking)),
                  if (item.catatan != null)
                    _DetailRow(
                        icon: Icons.notes_rounded,
                        label: 'Catatan',
                        value: item.catatan!),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            if (item.state == 'menunggu')
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text('Batalkan Antrian',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    onPressed: () => _confirmBatal(context, ref),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmBatal(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                child: Icon(Icons.cancel_outlined,
                    color: Colors.red.shade700, size: 24),
              ),
              const SizedBox(height: 16),
              const Text('Batalkan Antrian?',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _kBlue1)),
              const SizedBox(height: 8),
              Text(
                'Antrian ${item.nomorAntrian} akan dibatalkan.',
                style: TextStyle(
                    color: Colors.grey.shade600, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kBlue1,
                        side: const BorderSide(color: Color(0xFFDDE3EE)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Tutup',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Batalkan',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      final api = ref.read(apiClientProvider);
      await batalAntrian(api: api, id: item.id);
      ref.invalidate(antrianListProvider);
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal membatalkan: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }
}

// ── Detail helpers ─────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: _kBlue1.withValues(alpha: 0.6)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        color: _kBlue1,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Form tambah antrian ───────────────────────────────────────────────────────

class _AntrianFormSheet extends ConsumerStatefulWidget {
  const _AntrianFormSheet();
  @override
  ConsumerState<_AntrianFormSheet> createState() => _AntrianFormSheetState();
}

class _AntrianFormSheetState extends ConsumerState<_AntrianFormSheet> {
  final _formKey    = GlobalKey<FormState>();
  final _namaCtrl   = TextEditingController();
  final _catatanCtrl = TextEditingController();

  int?       _jenisLayananId;
  int?       _loketId;
  DateTime   _tanggalBooking = DateTime.now();
  bool       _saving = false;

  @override
  void dispose() {
    _namaCtrl.dispose();
    _catatanCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggalBooking,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _kBlue),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _tanggalBooking = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_loketId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Pilih loket terlebih dahulu'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _saving = true);
    try {
      final api  = ref.read(apiClientProvider);
      final user = ref.read(authNotifierProvider).valueOrNull;
      final nomor = await createAntrian(
        api: api,
        userId: user!.id,
        atasNama: _namaCtrl.text.trim(),
        loketId: _loketId!,
        tanggalBooking: _tanggalBooking,
        catatan: _catatanCtrl.text.trim(),
      );
      if (mounted) Navigator.pop(context, nomor);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Gagal membuat antrian: $e'),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final jenisAsync = ref.watch(jenisLayananOptionsProvider);
    final dateFmt    = DateFormat('dd MMM yyyy', 'id');

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 2),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 8, 4),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Ambil Nomor Antrian',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _kBlue1)),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: _kBlue1),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Form body
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 32,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Jenis Layanan ─────────────────────────────────────
                    _Label('Jenis Layanan *'),
                    const SizedBox(height: 6),
                    jenisAsync.when(
                      loading: () => const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: _kBlue),
                        ),
                      ),
                      error: (e, _) => Text('Gagal memuat',
                          style: TextStyle(color: Colors.red.shade400)),
                      data: (list) => DropdownButtonFormField<int>(
                        value: _jenisLayananId,
                        decoration: _inputDecor('Pilih jenis layanan'),
                        isExpanded: true,
                        items: list
                            .map((j) => DropdownMenuItem<int>(
                                  value: j['id'] as int,
                                  child: Text(j['name'] as String,
                                      overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        validator: (v) =>
                            v == null ? 'Pilih jenis layanan' : null,
                        onChanged: _saving
                            ? null
                            : (v) => setState(() {
                                  _jenisLayananId = v;
                                  _loketId = null;
                                }),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Loket (muncul setelah jenis layanan dipilih) ───────
                    if (_jenisLayananId != null) ...[
                      _Label('Loket *'),
                      const SizedBox(height: 6),
                      _LoketDropdown(
                        jenisLayananId: _jenisLayananId!,
                        value: _loketId,
                        enabled: !_saving,
                        onChanged: (v) => setState(() => _loketId = v),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Tanggal Booking ───────────────────────────────────
                    _Label('Tanggal Booking *'),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: _saving ? null : _pickTanggal,
                      borderRadius: BorderRadius.circular(10),
                      child: InputDecorator(
                        decoration: _inputDecor(''),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_rounded,
                                size: 16, color: Colors.grey.shade500),
                            const SizedBox(width: 8),
                            Text(
                              dateFmt.format(_tanggalBooking),
                              style: const TextStyle(
                                  color: Colors.black87, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Atas Nama ─────────────────────────────────────────
                    _Label('Atas Nama *'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _namaCtrl,
                      enabled: !_saving,
                      textCapitalization: TextCapitalization.words,
                      decoration:
                          _inputDecor('Nama penerima layanan'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'Nama wajib diisi'
                              : null,
                    ),
                    const SizedBox(height: 16),

                    // ── Catatan ───────────────────────────────────────────
                    _Label('Catatan (opsional)'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _catatanCtrl,
                      enabled: !_saving,
                      maxLines: 3,
                      decoration: _inputDecor('Catatan tambahan...'),
                    ),
                    const SizedBox(height: 24),

                    // ── Submit ────────────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kBlue,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _saving ? null : _submit,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Icon(
                                Icons.confirmation_number_rounded,
                                size: 20),
                        label: Text(
                          _saving ? 'Memproses...' : 'Ambil Nomor Antrian',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Loket dropdown (lazy-load per jenis layanan) ──────────────────────────────

class _LoketDropdown extends ConsumerWidget {
  final int jenisLayananId;
  final int? value;
  final bool enabled;
  final ValueChanged<int?> onChanged;
  const _LoketDropdown({
    required this.jenisLayananId,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loketAsync = ref.watch(loketOptionsProvider(jenisLayananId));
    return loketAsync.when(
      loading: () => const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: _kBlue),
        ),
      ),
      error: (e, _) =>
          Text('Gagal memuat loket', style: TextStyle(color: Colors.red.shade400)),
      data: (list) {
        if (list.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 16, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Text('Tidak ada loket aktif untuk layanan ini',
                    style: TextStyle(
                        color: Colors.orange.shade700, fontSize: 13)),
              ],
            ),
          );
        }
        return DropdownButtonFormField<int>(
          value: value,
          decoration: _inputDecor('Pilih loket'),
          isExpanded: true,
          items: list
              .map((l) => DropdownMenuItem<int>(
                    value: l['id'] as int,
                    child: Text(
                      '${l['name']} (kuota: ${l['kuota']})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
              .toList(),
          validator: (v) => v == null ? 'Pilih loket' : null,
          onChanged: enabled ? onChanged : null,
        );
      },
    );
  }
}

// ── Expandable FAB ────────────────────────────────────────────────────────────

class _ExpandableFab extends StatefulWidget {
  final ScrollController scrollController;
  final VoidCallback onPressed;
  const _ExpandableFab(
      {required this.scrollController, required this.onPressed});

  @override
  State<_ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<_ExpandableFab> {
  bool _extended = false;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (!mounted) return;
    final dir = widget.scrollController.position.userScrollDirection;
    if (dir == ScrollDirection.reverse && !_extended) {
      setState(() => _extended = true);
    } else if (dir == ScrollDirection.forward && _extended) {
      setState(() => _extended = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kBlue,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      shadowColor: _kBlue.withValues(alpha: 0.45),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        splashColor: Colors.white.withValues(alpha: 0.15),
        highlightColor: Colors.white.withValues(alpha: 0.08),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeInOut,
          height: 52,
          padding: EdgeInsets.symmetric(horizontal: _extended ? 20 : 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, color: Colors.white, size: 22),
              AnimatedSize(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeInOut,
                child: _extended
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(width: 8),
                          Text(
                            'Ambil Antrian',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helpers UI ────────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600, color: _kBlue1));
}

InputDecoration _inputDecor(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDDE3EE)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDDE3EE)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _kBlue, width: 1.5),
      ),
    );
