import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/platform/foto_picker.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/rehab.dart';
import '../providers/rehab_provider.dart';

// ─── Konstanta warna ────────────────────────────────────────────────────────
const _kBlue0 = Color(0xFF0D1526);
const _kBlue1 = Color(0xFF1D2A44);
const _kGreen = Color(0xFF1D2A44); // tema utama — seragam dengan eForm Laka

// ─────────────────────────────────────────────────────────────────────────────

class RehabScreen extends ConsumerStatefulWidget {
  const RehabScreen({super.key});
  @override
  ConsumerState<RehabScreen> createState() => _RehabScreenState();
}

class _RehabScreenState extends ConsumerState<RehabScreen> {
  final _scrollCtrl = ScrollController();
  String? _filterState;

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _showFilterSheet() async {
    final selected = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: const BoxConstraints(maxWidth: 480),
      builder: (_) => _FilterSheet(current: _filterState),
    );
    if (!mounted) return;
    if (selected != null) {
      setState(() => _filterState = selected.isEmpty ? null : selected);
    }
  }

  Future<void> _showAddSheet() async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
        maxWidth: 480,
      ),
      builder: (_) => const _RehabFormSheet(),
    );
    if (added == true && mounted) ref.invalidate(rehabListProvider);
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(rehabListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9FF),
      body: Column(
        children: [
          // ── AppBar custom ──────────────────────────────────────────────
          Container(
            color: _kGreen,
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
                          'Permohonan Rehabilitasi',
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
                            if (_filterState != null)
                              Positioned(
                                top: 8, right: 8,
                                child: Container(
                                  width: 8, height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF81C784),
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
                          child: CircularProgressIndicator(color: _kGreen),
                        ),
                        error: (e, _) => Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  size: 48, color: Colors.red),
                              const SizedBox(height: 12),
                              Text('Gagal memuat data',
                                  style: TextStyle(color: Colors.grey.shade600)),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () => ref.invalidate(rehabListProvider),
                                child: const Text('Coba lagi'),
                              ),
                            ],
                          ),
                        ),
                        data: (list) {
                          final filtered = _filterState == null
                              ? list
                              : list.where((e) => e.state == _filterState).toList();
                          return RefreshIndicator(
                                  color: _kGreen,
                                  onRefresh: () async =>
                                      ref.invalidate(rehabListProvider),
                                  child: filtered.isEmpty
                                      ? ListView(
                                          physics: const AlwaysScrollableScrollPhysics(),
                                          children: [
                                            SizedBox(
                                              height: MediaQuery.of(context).size.height * 0.6,
                                              child: _EmptyState(
                                                  onRefresh: () => ref.invalidate(rehabListProvider)),
                                            ),
                                          ],
                                        )
                                      : ListView.builder(
                                          physics: const AlwaysScrollableScrollPhysics(),
                                          controller: _scrollCtrl,
                                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                                          itemCount: filtered.length,
                                          itemBuilder: (_, i) =>
                                              _RehabCard(item: filtered[i]),
                                        ),
                                );
                        },
                      ),
                    ),
                    Positioned(
                      right: 16, bottom: 16,
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
  final String? current;
  const _FilterSheet({this.current});

  static const _options = [
    (label: 'Semua',          value: ''),
    (label: 'Menunggu',       value: 'menunggu'),
    (label: 'Dikonfirmasi',   value: 'konfirmasi'),
    (label: 'Sedang Diproses',value: 'proses'),
    (label: 'Selesai',        value: 'selesai'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Filter Status',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700, color: _kBlue1)),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: _kBlue1),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _options.map((opt) {
              final isActive = (current ?? '') == opt.value;
              return GestureDetector(
                onTap: () => Navigator.pop(context, opt.value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? _kGreen : const Color(0xFFF0F4FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(opt.label,
                      style: TextStyle(
                        color: isActive ? Colors.white : _kBlue1,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      )),
                ),
              );
            }).toList(),
          ),
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
          Icon(Icons.healing_rounded, size: 64, color: _kGreen.withValues(alpha: 0.25)),
          const SizedBox(height: 16),
          Text('Belum ada permohonan',
              style: TextStyle(
                  color: _kGreen.withValues(alpha: 0.7),
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Tekan Ajukan untuk membuat permohonan baru',
              style: TextStyle(color: _kGreen.withValues(alpha: 0.45), fontSize: 13)),
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

class _RehabCard extends StatelessWidget {
  final Rehab item;
  const _RehabCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy', 'id');

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        boxShadow: [
          BoxShadow(
            color: _kBlue1.withValues(alpha: 0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(7),
        onTap: () => _showRehabDetail(context, item),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _kBlue0.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(item.code,
                        style: const TextStyle(
                          color: _kBlue0,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                          letterSpacing: 0.5,
                        )),
                  ),
                  const SizedBox(width: 8),
                  _StateBadge(state: item.state),
                ],
              ),
              const SizedBox(height: 6),
              Text(item.nama,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: _kBlue1),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              if (item.tempatRehabNama != null) ...[
                const SizedBox(height: 2),
                Text(item.tempatRehabNama!,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.access_time_rounded,
                      size: 12, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text(dateFmt.format(item.tanggalPengajuan),
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                  if (item.tanggalJadwal != null) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.event_rounded,
                        size: 12, color: _kGreen.withValues(alpha: 0.7)),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd MMM yyyy', 'id').format(item.tanggalJadwal!),
                      style: TextStyle(
                          color: _kGreen.withValues(alpha: 0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ],
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
      'konfirmasi' => ('Dikonfirmasi',  const Color(0xFFFFF3E0), const Color(0xFFE65100)),
      'proses'     => ('Sedang Diproses', const Color(0xFFE3F2FD), const Color(0xFF1565C0)),
      'selesai'    => ('Selesai',       const Color(0xFFE8F5E9), const Color(0xFF2E7D32)),
      _            => ('Menunggu',      const Color(0xFFF3E5F5), const Color(0xFF6A1B9A)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: TextStyle(
              color: fg, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
    );
  }
}

// ── Detail bottom sheet ───────────────────────────────────────────────────────

void _showRehabDetail(BuildContext context, Rehab item) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    constraints: const BoxConstraints(maxWidth: 480),
    builder: (_) => _RehabDetailSheet(item: item),
  );
}

class _RehabDetailSheet extends ConsumerWidget {
  final Rehab item;
  const _RehabDetailSheet({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFmt = DateFormat('dd MMM yyyy', 'id');
    final fotoAsync = ref.watch(rehabFotoProvider(item.id));

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
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
                width: 36, height: 4,
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
                    child: Text('Detail Permohonan',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700, color: _kBlue1)),
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _kBlue0.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(item.code,
                            style: const TextStyle(
                              color: _kBlue0, fontSize: 12,
                              fontWeight: FontWeight.w700, fontFamily: 'monospace',
                              letterSpacing: 0.5,
                            )),
                      ),
                      const SizedBox(width: 8),
                      _StateBadge(state: item.state),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _DetailRow(icon: Icons.person_rounded, label: 'Nama Lengkap', value: item.nama),
                  if (item.jenisKelamin != null)
                    _DetailRow(
                      icon: Icons.wc_rounded,
                      label: 'Jenis Kelamin',
                      value: item.jenisKelamin == 'laki' ? 'Laki-laki' : 'Perempuan',
                    ),
                  if (item.tempatLahir != null)
                    _DetailRow(icon: Icons.location_city_rounded, label: 'Tempat Lahir', value: item.tempatLahir!),
                  if (item.tanggalLahir != null)
                    _DetailRow(
                      icon: Icons.cake_rounded,
                      label: 'Tanggal Lahir',
                      value: dateFmt.format(item.tanggalLahir!),
                    ),
                  if (item.alamat != null)
                    _DetailRow(icon: Icons.home_rounded, label: 'Alamat', value: item.alamat!),
                  if (item.tempatRehabNama != null)
                    _DetailRow(
                      icon: Icons.local_hospital_rounded,
                      label: 'Tempat Rehabilitasi',
                      value: item.tempatRehabNama!,
                    ),
                  if (item.keterangan != null)
                    _DetailRow(icon: Icons.notes_rounded, label: 'Keterangan', value: item.keterangan!),
                  _DetailRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Tanggal Pengajuan',
                    value: dateFmt.format(item.tanggalPengajuan),
                  ),
                  if (item.tanggalJadwal != null)
                    _DetailRow(
                      icon: Icons.event_available_rounded,
                      label: 'Jadwal Rehabilitasi',
                      value: DateFormat('dd MMM yyyy, HH:mm', 'id').format(item.tanggalJadwal!),
                      valueColor: _kGreen,
                    ),
                  // Foto pemohon
                  const SizedBox(height: 8),
                  const _SectionLabel('Foto Pemohon'),
                  const SizedBox(height: 8),
                  fotoAsync.when(
                    loading: () => Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFDDE3EE)),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: _kGreen),
                        ),
                      ),
                    ),
                    error: (e, s) => const SizedBox.shrink(),
                    data: (base64) => base64 != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.memory(
                              base64Decode(base64),
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Container(
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFDDE3EE)),
                            ),
                            child: Center(
                              child: Text('Tidak ada foto',
                                  style: TextStyle(
                                      color: Colors.grey.shade400, fontSize: 13)),
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
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
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Batalkan Permohonan',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    onPressed: () => _confirmDelete(context, ref),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
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
                child: Icon(Icons.delete_outline_rounded,
                    color: Colors.red.shade700, size: 24),
              ),
              const SizedBox(height: 16),
              const Text('Batalkan Permohonan?',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700, color: _kBlue1)),
              const SizedBox(height: 8),
              Text(
                'Permohonan ${item.code} akan dihapus permanen.',
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
                      child: const Text('Batal',
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
                      child: const Text('Hapus',
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
      await deleteRehab(api: api, id: item.id);
      ref.invalidate(rehabListProvider);
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal menghapus: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }
}

// ── Detail row ────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _DetailRow({required this.icon, required this.label, required this.value, this.valueColor});

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
                    style: TextStyle(
                        color: valueColor ?? _kBlue1,
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

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3));
}

// ── Form tambah permohonan ────────────────────────────────────────────────────

class _RehabFormSheet extends ConsumerStatefulWidget {
  const _RehabFormSheet();
  @override
  ConsumerState<_RehabFormSheet> createState() => _RehabFormSheetState();
}

class _RehabFormSheetState extends ConsumerState<_RehabFormSheet> {
  final _formKey     = GlobalKey<FormState>();
  final _namaCtrl    = TextEditingController();
  final _tLahirCtrl  = TextEditingController();
  final _alamatCtrl  = TextEditingController();
  final _ketCtrl     = TextEditingController();

  String?    _jenisKelamin;
  DateTime?  _tanggalLahir;
  int?       _tempatRehabId;
  Uint8List? _fotoBytes;
  bool       _saving = false;

  @override
  void dispose() {
    _namaCtrl.dispose();
    _tLahirCtrl.dispose();
    _alamatCtrl.dispose();
    _ketCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTanggalLahir() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggalLahir ?? DateTime(1990),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      locale: const Locale('id'),
    );
    if (picked != null && mounted) {
      setState(() => _tanggalLahir = picked);
    }
  }

  Future<void> _pickFoto() async {
    final bytes = await pickFotoAsBytes();
    if (bytes != null && mounted) setState(() => _fotoBytes = bytes);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final fotoBase64 = _fotoBytes != null ? base64Encode(_fotoBytes!) : null;
      final api  = ref.read(apiClientProvider);
      final user = ref.read(authNotifierProvider).valueOrNull;
      await createRehab(
        api: api,
        userId: user!.id,
        nama: _namaCtrl.text.trim(),
        jenisKelamin: _jenisKelamin,
        tempatLahir: _tLahirCtrl.text.trim(),
        tanggalLahir: _tanggalLahir,
        alamat: _alamatCtrl.text.trim(),
        tempatRehabId: _tempatRehabId,
        keterangan: _ketCtrl.text.trim(),
        fotoPemohonBase64: fotoBase64,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Gagal menyimpan: $e'),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tempatAsync = ref.watch(rehabTempatOptionsProvider);
    final dateFmt = DateFormat('dd MMM yyyy', 'id');

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
              width: 40, height: 4,
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
                  child: Text('Ajukan Permohonan',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700, color: _kBlue1)),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: _kBlue1),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Form
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20, right: 20, top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 32,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Nama ─────────────────────────────────────────────
                    _Label('Nama Lengkap *'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _namaCtrl,
                      enabled: !_saving,
                      textCapitalization: TextCapitalization.words,
                      decoration: _inputDecor('Nama lengkap pemohon'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),

                    // ── Jenis Kelamin ─────────────────────────────────────
                    _Label('Jenis Kelamin'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _jenisKelamin,
                      decoration: _inputDecor('Pilih jenis kelamin'),
                      items: const [
                        DropdownMenuItem(value: 'laki',      child: Text('Laki-laki')),
                        DropdownMenuItem(value: 'perempuan', child: Text('Perempuan')),
                      ],
                      onChanged: _saving ? null : (v) => setState(() => _jenisKelamin = v),
                    ),
                    const SizedBox(height: 16),

                    // ── Tempat Lahir ──────────────────────────────────────
                    _Label('Tempat Lahir'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _tLahirCtrl,
                      enabled: !_saving,
                      textCapitalization: TextCapitalization.words,
                      decoration: _inputDecor('Kota tempat lahir'),
                    ),
                    const SizedBox(height: 16),

                    // ── Tanggal Lahir ─────────────────────────────────────
                    _Label('Tanggal Lahir'),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: _saving ? null : _pickTanggalLahir,
                      borderRadius: BorderRadius.circular(10),
                      child: InputDecorator(
                        decoration: _inputDecor('Pilih tanggal lahir'),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_rounded,
                                size: 16, color: Colors.grey.shade500),
                            const SizedBox(width: 8),
                            Text(
                              _tanggalLahir != null
                                  ? dateFmt.format(_tanggalLahir!)
                                  : 'Pilih tanggal lahir',
                              style: TextStyle(
                                color: _tanggalLahir != null
                                    ? Colors.black87
                                    : Colors.grey.shade500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Alamat ────────────────────────────────────────────
                    _Label('Alamat Lengkap'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _alamatCtrl,
                      enabled: !_saving,
                      maxLines: 3,
                      decoration: _inputDecor('Alamat lengkap pemohon'),
                    ),
                    const SizedBox(height: 16),

                    // ── Foto Pemohon ──────────────────────────────────────
                    _Label('Foto Pemohon'),
                    const SizedBox(height: 6),
                    _FotoField(
                      fotoBytes: _fotoBytes,
                      onPick: _saving ? null : _pickFoto,
                      onRemove: _saving ? null : () => setState(() => _fotoBytes = null),
                    ),
                    const SizedBox(height: 16),

                    // ── Tempat Rehabilitasi ───────────────────────────────
                    _Label('Tempat Rehabilitasi'),
                    const SizedBox(height: 6),
                    tempatAsync.when(
                      loading: () => const Center(
                        child: SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: _kGreen),
                        ),
                      ),
                      error: (e, _) => Text('Gagal memuat',
                          style: TextStyle(color: Colors.red.shade400)),
                      data: (list) => DropdownButtonFormField<int>(
                        value: _tempatRehabId,
                        decoration: _inputDecor('Pilih tempat rehabilitasi'),
                        isExpanded: true,
                        items: list
                            .map((t) => DropdownMenuItem<int>(
                                  value: t['id'] as int,
                                  child: Text(t['name'] as String,
                                      overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: _saving
                            ? null
                            : (v) => setState(() => _tempatRehabId = v),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Keterangan ────────────────────────────────────────
                    _Label('Keterangan / Alasan Permohonan'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _ketCtrl,
                      enabled: !_saving,
                      maxLines: 4,
                      decoration: _inputDecor('Jelaskan alasan permohonan rehabilitasi...'),
                    ),
                    const SizedBox(height: 24),

                    // ── Submit ────────────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _saving ? null : _submit,
                        icon: _saving
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.send_rounded, size: 20),
                        label: Text(
                          _saving ? 'Mengirim...' : 'Kirim Permohonan',
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
        borderSide: const BorderSide(color: _kGreen, width: 1.5),
      ),
    );

// ── Expandable FAB (scroll-aware) ─────────────────────────────────────────────

class _ExpandableFab extends StatefulWidget {
  final ScrollController scrollController;
  final VoidCallback onPressed;
  const _ExpandableFab({required this.scrollController, required this.onPressed});

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
      color: _kGreen,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      shadowColor: _kGreen.withValues(alpha: 0.45),
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
                            'Ajukan',
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

// ─────────────────────────────────────────────────────────────────────────────

class _FotoField extends StatelessWidget {
  final Uint8List? fotoBytes;
  final VoidCallback? onPick;
  final VoidCallback? onRemove;
  const _FotoField({required this.fotoBytes, required this.onPick, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    if (fotoBytes != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(fotoBytes!,
                height: 140, width: double.infinity, fit: BoxFit.cover),
          ),
          Positioned(
            top: 6, right: 6,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(4),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      );
    }
    return GestureDetector(
      onTap: onPick,
      child: Container(
        height: 100,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFDDE3EE)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_rounded,
                size: 28, color: Colors.grey.shade400),
            const SizedBox(height: 6),
            Text('Tambah Foto', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
