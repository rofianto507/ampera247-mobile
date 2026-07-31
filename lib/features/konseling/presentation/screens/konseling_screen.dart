import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/konseling.dart';
import '../providers/konseling_provider.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _kBlue0 = Color(0xFF0D1526);
const _kBlue1 = Color(0xFF1D2A44);

const _stateColor = {
  'menunggu':   Color(0xFF6B7280),
  'konfirmasi': Color(0xFF3B82F6),
  'proses':     Color(0xFFF59E0B),
  'selesai':    Color(0xFF10B981),
};

// ── Screen ────────────────────────────────────────────────────────────────────

class KonselingScreen extends ConsumerStatefulWidget {
  const KonselingScreen({super.key});

  @override
  ConsumerState<KonselingScreen> createState() => _KonselingScreenState();
}

class _KonselingScreenState extends ConsumerState<KonselingScreen> {
  final _scrollCtrl = ScrollController();
  List<Konseling>? _items;
  bool _loading = true;
  String? _error;
  String? _filterState; // null = semua

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final api  = ref.read(apiClientProvider);
      final user = ref.read(authNotifierProvider).valueOrNull;
      if (user == null) throw Exception('Sesi tidak valid');
      final items = await fetchMyKonseling(api: api, userId: user.id);
      setState(() { _items = items; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
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

  void _openForm() async {
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _KonselingFormSheet(ref: ref),
    );
    if (submitted == true) _load();
  }

  void _openDetail(Konseling item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _KonselingDetailSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9FF),
      appBar: AppBar(
        backgroundColor: _kBlue0,
        foregroundColor: Colors.white,
        title: const Text('Konseling Online',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        elevation: 0,
        actions: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list_rounded, color: Colors.white),
                onPressed: _showFilterSheet,
              ),
              if (_filterState != null)
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF64B5F6),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _ExpandableFab(
        scrollController: _scrollCtrl,
        onPressed: _openForm,
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 48, color: Colors.red.shade300),
              const SizedBox(height: 12),
              const Text('Gagal memuat data',
                  style: TextStyle(
                      color: _kBlue0,
                      fontWeight: FontWeight.w600,
                      fontSize: 15)),
              const SizedBox(height: 6),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: _kBlue1,
                    foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      );
    }
    if (_items == null || _items!.isEmpty) {
      return _EmptyState(onRefresh: _load);
    }
    final filtered = _filterState == null
        ? _items!
        : _items!.where((e) => e.state == _filterState).toList();

    if (filtered.isEmpty) {
      return _EmptyState(onRefresh: _load);
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: filtered.length,
        itemBuilder: (_, i) => _KonselingCard(
          item: filtered[i],
          onTap: () => _openDetail(filtered[i]),
        ),
      ),
    );
  }
}

// ── Card ──────────────────────────────────────────────────────────────────────

class _KonselingCard extends StatelessWidget {
  final Konseling item;
  final VoidCallback onTap;

  const _KonselingCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: _kBlue1.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _kBlue0.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.code,
                        style: const TextStyle(
                          color: _kBlue0,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const Spacer(),
                    _StatusBadge(state: item.state, label: item.stateLabel),
                  ],
                ),
                const SizedBox(height: 6),
                Text(item.nama,
                    style: TextStyle(
                        color: Colors.grey.shade700, fontSize: 13)),
                if (item.tanggalPengajuan != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 12, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(_fmtDate(item.tanggalPengajuan!),
                          style: TextStyle(
                              color: Colors.grey.shade400, fontSize: 11)),
                    ],
                  ),
                ],
                if (item.state == 'konfirmasi' && item.tanggalJadwal != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.event_available_rounded,
                            size: 13, color: Color(0xFF3B82F6)),
                        const SizedBox(width: 5),
                        Text('Jadwal: ${_fmtDatetime(item.tanggalJadwal!)}',
                            style: const TextStyle(
                                color: Color(0xFF3B82F6),
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _fmtDate(String d) {
    try {
      return DateFormat('dd MMM yyyy', 'id').format(DateTime.parse(d));
    } catch (_) {
      return d;
    }
  }

  String _fmtDatetime(String d) {
    try {
      return DateFormat('dd MMM yyyy, HH:mm', 'id')
          .format(DateTime.parse(d).toLocal());
    } catch (_) {
      return d;
    }
  }
}

// ── Status Badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String state;
  final String label;

  const _StatusBadge({required this.state, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = _stateColor[state] ?? const Color(0xFF6B7280);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

// ── Form Sheet ────────────────────────────────────────────────────────────────

class _KonselingFormSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;

  const _KonselingFormSheet({required this.ref});

  @override
  ConsumerState<_KonselingFormSheet> createState() =>
      _KonselingFormSheetState();
}

class _KonselingFormSheetState extends ConsumerState<_KonselingFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _namaCtrl        = TextEditingController();
  final _nikCtrl         = TextEditingController();
  final _noHpCtrl        = TextEditingController();
  final _tempatLahirCtrl = TextEditingController();
  final _alamatCtrl      = TextEditingController();
  final _keteranganCtrl  = TextEditingController();

  String? _jenisKelamin;
  DateTime? _tanggalLahir;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final user = widget.ref.read(authNotifierProvider).valueOrNull;
    if (user != null) _namaCtrl.text = user.name;
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _nikCtrl.dispose();
    _noHpCtrl.dispose();
    _tempatLahirCtrl.dispose();
    _alamatCtrl.dispose();
    _keteranganCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggalLahir ?? DateTime(1990),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _tanggalLahir = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      final api  = widget.ref.read(apiClientProvider);
      final user = widget.ref.read(authNotifierProvider).valueOrNull;

      final data = <String, dynamic>{
        'nama':      _namaCtrl.text.trim(),
        'user_id':   user?.id,
        if (_nikCtrl.text.trim().isNotEmpty)
          'nik': _nikCtrl.text.trim(),
        if (_noHpCtrl.text.trim().isNotEmpty)
          'no_hp': _noHpCtrl.text.trim(),
        if (_jenisKelamin != null)
          'jenis_kelamin': _jenisKelamin,
        if (_tempatLahirCtrl.text.trim().isNotEmpty)
          'tempat_lahir': _tempatLahirCtrl.text.trim(),
        if (_tanggalLahir != null)
          'tanggal_lahir': DateFormat('yyyy-MM-dd').format(_tanggalLahir!),
        if (_alamatCtrl.text.trim().isNotEmpty)
          'alamat': _alamatCtrl.text.trim(),
        'keterangan': _keteranganCtrl.text.trim(),
      };

      await createKonseling(api: api, data: data);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permohonan konseling berhasil dikirim'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.97,
      minChildSize: 0.5,
      builder: (_, sc) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
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
                    child: Text(
                      'Ajukan Konseling Online',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _kBlue1,
                      ),
                    ),
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
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  controller: sc,
                  padding: EdgeInsets.fromLTRB(20, 16, 20, bottom + 20),
                  children: [
                    _sectionLabel('IDENTITAS PEMOHON'),
                    const SizedBox(height: 10),
                    _field(
                      ctrl: _namaCtrl,
                      label: 'Nama Lengkap',
                      icon: Icons.person_outline_rounded,
                      required: true,
                    ),
                    const SizedBox(height: 12),
                    _field(
                      ctrl: _nikCtrl,
                      label: 'NIK (16 digit)',
                      icon: Icons.badge_outlined,
                      keyboardType: TextInputType.number,
                      maxLength: 16,
                      validator: (v) {
                        if (v != null && v.isNotEmpty && v.length != 16) {
                          return 'NIK harus 16 digit';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _field(
                      ctrl: _noHpCtrl,
                      label: 'No. HP / WA',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    // Jenis Kelamin
                    _SectionField(
                      label: 'Jenis Kelamin',
                      icon: Icons.wc_rounded,
                      child: Row(
                        children: [
                          _GenderChip(
                            label: 'Laki-laki',
                            selected: _jenisKelamin == 'laki',
                            onTap: () =>
                                setState(() => _jenisKelamin = 'laki'),
                          ),
                          const SizedBox(width: 10),
                          _GenderChip(
                            label: 'Perempuan',
                            selected: _jenisKelamin == 'perempuan',
                            onTap: () =>
                                setState(() => _jenisKelamin = 'perempuan'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _field(
                      ctrl: _tempatLahirCtrl,
                      label: 'Tempat Lahir',
                      icon: Icons.location_city_outlined,
                    ),
                    const SizedBox(height: 12),
                    // Tanggal Lahir
                    _SectionField(
                      label: 'Tanggal Lahir',
                      icon: Icons.cake_outlined,
                      onTap: _pickDate,
                      child: InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(10),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                          child: Text(
                            _tanggalLahir != null
                                ? DateFormat('dd MMMM yyyy', 'id')
                                    .format(_tanggalLahir!)
                                : 'Pilih tanggal lahir',
                            style: TextStyle(
                              color: _tanggalLahir != null
                                  ? _kBlue0
                                  : Colors.grey.shade400,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _field(
                      ctrl: _alamatCtrl,
                      label: 'Alamat Lengkap',
                      icon: Icons.home_outlined,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    _sectionLabel('URAIAN PERMASALAHAN'),
                    const SizedBox(height: 10),
                    _field(
                      ctrl: _keteranganCtrl,
                      label: 'Ceritakan permasalahan Anda...',
                      icon: Icons.notes_rounded,
                      maxLines: 6,
                      required: true,
                      requiredMsg: 'Uraian permasalahan wajib diisi',
                    ),
                    const SizedBox(height: 24),
                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kBlue1,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _submitting ? null : _submit,
                        icon: _submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.send_rounded, size: 20),
                        label: Text(
                          _submitting ? 'Mengirim...' : 'Kirim Permohonan',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: TextStyle(
          color: _kBlue1.withValues(alpha: 0.55),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 2.5,
        ),
      );

  Widget _field({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    int? maxLength,
    bool required = false,
    String? requiredMsg,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: _kBlue1.withValues(alpha: 0.6)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kBlue1, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        counterText: '',
      ),
      validator: validator ??
          (required
              ? (v) => (v == null || v.trim().isEmpty)
                  ? (requiredMsg ?? '$label wajib diisi')
                  : null
              : null),
    );
  }
}

// ── Gender Chip ───────────────────────────────────────────────────────────────

class _GenderChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _GenderChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _kBlue1 : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected ? _kBlue1 : Colors.grey.shade300, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey.shade600,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ── Section Field Wrapper ─────────────────────────────────────────────────────

class _SectionField extends StatelessWidget {
  final String label;
  final IconData icon;
  final Widget child;
  final VoidCallback? onTap;

  const _SectionField({
    required this.label,
    required this.icon,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: _kBlue1.withValues(alpha: 0.6)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12)),
                const SizedBox(height: 4),
                child,
              ],
            ),
          ),
          if (onTap != null)
            Icon(Icons.chevron_right_rounded,
                color: Colors.grey.shade400, size: 20),
        ],
      ),
    );
  }
}

// ── Detail Sheet ──────────────────────────────────────────────────────────────

class _KonselingDetailSheet extends StatelessWidget {
  final Konseling item;

  const _KonselingDetailSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, sc) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
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
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _kBlue0.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.code,
                            style: const TextStyle(
                              color: _kBlue0,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            item.nama,
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
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
                controller: sc,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  // Status timeline
                  _buildTimeline(),
                  const SizedBox(height: 20),
                  // Info jadwal jika sudah dikonfirmasi
                  if (item.state != 'menunggu') ...[
                    _InfoCard(children: [
                      if (item.tanggalJadwal != null)
                        _InfoRow(
                          icon: Icons.event_available_rounded,
                          label: 'Jadwal Konseling',
                          value: _fmtDatetime(item.tanggalJadwal!),
                          highlight: true,
                        ),
                      if (item.konselorNama != null)
                        _InfoRow(
                          icon: Icons.person_pin_circle_outlined,
                          label: 'Konselor',
                          value: item.konselorNama!,
                        ),
                    ]),
                    const SizedBox(height: 12),
                  ],
                  // Detail pengajuan
                  _InfoCard(children: [
                    _InfoRow(
                      icon: Icons.calendar_today_rounded,
                      label: 'Tanggal Pengajuan',
                      value: item.tanggalPengajuan != null
                          ? _fmtDate(item.tanggalPengajuan!)
                          : '-',
                    ),
                  ]),
                  if (item.keterangan != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Uraian Permasalahan',
                              style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5)),
                          const SizedBox(height: 8),
                          Text(item.keterangan!,
                              style: const TextStyle(
                                  color: _kBlue0,
                                  fontSize: 13,
                                  height: 1.5)),
                        ],
                      ),
                    ),
                  ],
                  if (item.channelId != null) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6A1B9A),
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          final router = GoRouter.of(context);
                          Navigator.of(context).pop();
                          router.push('/konseling/chat', extra: {
                            'channelId': item.channelId!,
                            'title': 'Konsultasi ${item.code}',
                          });
                        },
                        icon: const Icon(Icons.chat_rounded, size: 20),
                        label: const Text(
                          'Buka Konsultasi',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    final steps = [
      ('menunggu',   'Menunggu',        Icons.hourglass_empty_rounded),
      ('konfirmasi', 'Dikonfirmasi',    Icons.check_circle_outline_rounded),
      ('proses',     'Sedang Diproses', Icons.psychology_outlined),
      ('selesai',    'Selesai',         Icons.task_alt_rounded),
    ];

    final currentIdx = steps.indexWhere((s) => s.$1 == item.state);

    return Row(
      children: List.generate(steps.length, (i) {
        final done    = i <= currentIdx;
        final current = i == currentIdx;
        final color   = done
            ? (_stateColor[steps[i].$1] ?? _kBlue1)
            : Colors.grey.shade300;

        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  if (i > 0)
                    Expanded(
                      child: Container(
                          height: 2,
                          color: i <= currentIdx
                              ? (_stateColor[steps[i].$1] ??
                                  _kBlue1)
                              : Colors.grey.shade300),
                    ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: done
                          ? color.withValues(alpha: 0.12)
                          : Colors.grey.shade100,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: done ? color : Colors.grey.shade300,
                          width: current ? 2 : 1),
                    ),
                    child: Icon(steps[i].$3,
                        size: 14,
                        color: done ? color : Colors.grey.shade400),
                  ),
                  if (i < steps.length - 1)
                    Expanded(
                      child: Container(
                          height: 2,
                          color: i < currentIdx
                              ? (_stateColor[steps[i + 1].$1] ??
                                  _kBlue1)
                              : Colors.grey.shade300),
                    ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                steps[i].$2,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: done ? color : Colors.grey.shade400,
                  fontSize: 9,
                  fontWeight: current ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  String _fmtDate(String d) {
    try {
      return DateFormat('dd MMMM yyyy', 'id').format(DateTime.parse(d));
    } catch (_) {
      return d;
    }
  }

  String _fmtDatetime(String d) {
    try {
      return DateFormat('dd MMM yyyy, HH:mm', 'id')
          .format(DateTime.parse(d).toLocal());
    } catch (_) {
      return d;
    }
  }
}

// ── Info Card & Row ───────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(children: children),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon,
                size: 16,
                color: highlight ? const Color(0xFF3B82F6) : Colors.grey.shade400),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(value,
                      style: TextStyle(
                          color:
                              highlight ? const Color(0xFF3B82F6) : _kBlue0,
                          fontSize: 13,
                          fontWeight: highlight
                              ? FontWeight.w700
                              : FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      );
}

// ── Filter sheet ─────────────────────────────────────────────────────────────

class _FilterSheet extends StatelessWidget {
  final String? current;
  const _FilterSheet({this.current});

  static const _options = [
    (label: 'Semua',            value: ''),
    (label: 'Menunggu',         value: 'menunggu'),
    (label: 'Dikonfirmasi',     value: 'konfirmasi'),
    (label: 'Sedang Diproses',  value: 'proses'),
    (label: 'Selesai',          value: 'selesai'),
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
                child: Text(
                  'Filter Status',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _kBlue1,
                  ),
                ),
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? _kBlue1 : const Color(0xFFF0F4FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    opt.label,
                    style: TextStyle(
                      color: isActive ? Colors.white : _kBlue1,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
          Icon(Icons.psychology_outlined,
              size: 64, color: _kBlue1.withValues(alpha: 0.25)),
          const SizedBox(height: 16),
          Text('Belum ada permohonan konseling',
              style: TextStyle(
                  color: _kBlue1.withValues(alpha: 0.6),
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Tekan tombol + untuk mengajukan',
              style: TextStyle(
                  color: _kBlue1.withValues(alpha: 0.4), fontSize: 13)),
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

// ── Expandable FAB ────────────────────────────────────────────────────────────

class _ExpandableFab extends StatefulWidget {
  final ScrollController scrollController;
  final VoidCallback onPressed;

  const _ExpandableFab({
    required this.scrollController,
    required this.onPressed,
  });

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
      color: _kBlue1,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      shadowColor: _kBlue1.withValues(alpha: 0.45),
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
