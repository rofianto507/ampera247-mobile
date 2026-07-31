import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/platform/foto_picker.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/eform_laka.dart';
import '../providers/eform_laka_provider.dart';

const _kBlue0 = Color(0xFF0D1526);
const _kBlue1 = Color(0xFF1D2A44);

// ─────────────────────────────────────────────────────────────────────────────

class EformLakaScreen extends ConsumerStatefulWidget {
  const EformLakaScreen({super.key});

  @override
  ConsumerState<EformLakaScreen> createState() => _EformLakaScreenState();
}

class _EformLakaScreenState extends ConsumerState<EformLakaScreen> {
  final _scrollCtrl = ScrollController();
  String? _filterState; // null = semua

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
    // showModalBottomSheet returns null jika di-dismiss, gunakan sentinel
    if (!mounted) return;
    // _FilterSheet mengembalikan '' untuk "Semua", atau nilai state
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
        maxHeight: MediaQuery.of(context).size.height * 0.85,
        maxWidth: 480,
      ),
      builder: (_) => const _LakaFormSheet(),
    );
    if (added == true && mounted) {
      ref.invalidate(eformLakaListProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(eformLakaListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9FF),
      body: Column(
        children: [
          // ── AppBar custom agar ikut batasan 480px ──────────────────
          Container(
            color: _kBlue1,
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
                          icon: const Icon(Icons.arrow_back,
                              color: Colors.white),
                          onPressed: () => Navigator.maybePop(context),
                        ),
                        const Text(
                          'e-Form Kecelakaan',
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
                                    color: Color(0xFF64B5F6),
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

          // ── Body + FAB dalam satu constraint ──────────────────────
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: listAsync.when(
                        loading: () => const Center(
                          child:
                              CircularProgressIndicator(color: _kBlue1),
                        ),
                        error: (e, _) => Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  size: 48, color: Colors.red),
                              const SizedBox(height: 12),
                              Text('Gagal memuat data',
                                  style: TextStyle(
                                      color: Colors.grey.shade600)),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () =>
                                    ref.invalidate(eformLakaListProvider),
                                child: const Text('Coba lagi'),
                              ),
                            ],
                          ),
                        ),
                        data: (list) {
                          final filtered = _filterState == null
                              ? list
                              : list
                                  .where((e) => e.state == _filterState)
                                  .toList();
                          return RefreshIndicator(
                                  color: _kBlue1,
                                  onRefresh: () async =>
                                      ref.invalidate(eformLakaListProvider),
                                  child: filtered.isEmpty
                                      ? ListView(
                                          physics: const AlwaysScrollableScrollPhysics(),
                                          children: [
                                            SizedBox(
                                              height: MediaQuery.of(context).size.height * 0.6,
                                              child: _EmptyState(
                                                  onRefresh: () => ref.invalidate(eformLakaListProvider)),
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
                                              _LakaCard(item: filtered[i]),
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

// ── Bottom sheet form ─────────────────────────────────────────────────────────

class _LakaFormSheet extends ConsumerStatefulWidget {
  const _LakaFormSheet();

  @override
  ConsumerState<_LakaFormSheet> createState() => _LakaFormSheetState();
}

class _LakaFormSheetState extends ConsumerState<_LakaFormSheet> {
  final _formKey        = GlobalKey<FormState>();
  final _lukaCtrl       = TextEditingController(text: '0');
  final _meninggalCtrl  = TextEditingController(text: '0');
  final _rsCtrl         = TextEditingController();
  final _keteranganCtrl = TextEditingController();

  DateTime   _tanggal       = DateTime.now();
  int?       _yangTerlibatId;
  Uint8List? _fotoBytes;
  bool       _saving = false;
  LatLng?    _lokasi;

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
  }

  @override
  void dispose() {
    _lukaCtrl.dispose();
    _meninggalCtrl.dispose();
    _rsCtrl.dispose();
    _keteranganCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Future<void> _pickTanggal() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _kBlue1),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_tanggal),
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(primary: _kBlue1),
          ),
          child: child!,
        ),
      ),
    );
    if (time == null || !mounted) return;
    setState(() => _tanggal =
        DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _pickFoto() async {
    final bytes = await pickFotoAsBytes();
    if (bytes != null && mounted) setState(() => _fotoBytes = bytes);
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      if (!kIsWeb) {
        // Native: cek layanan GPS dan minta permission secara eksplisit
        final svcEnabled = await Geolocator.isLocationServiceEnabled();
        if (!svcEnabled) { _useFallback(); return; }

        var perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
        if (perm == LocationPermission.deniedForever) { _useFallback(); return; }
      }
      // Web: browser menampilkan dialog saat getCurrentPosition dipanggil
      // Native: permission sudah dikonfirmasi di atas
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (mounted) setState(() => _lokasi = LatLng(pos.latitude, pos.longitude));
    } catch (_) {
      _useFallback();
    }
  }

  void _useFallback() {
    if (mounted) setState(() => _lokasi = const LatLng(-2.9761, 104.7754));
  }

  Future<void> _openLocationPicker() async {
    if (_lokasi == null) return;
    final result = await showDialog<LatLng>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _LocationPickerDialog(initial: _lokasi!),
    );
    if (result != null && mounted) setState(() => _lokasi = result);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final fotoBase64 =
          _fotoBytes != null ? base64Encode(_fotoBytes!) : null;
      final api = ref.read(apiClientProvider);
      await createEformLaka(
        api: api,
        yangTerlibatId: _yangTerlibatId!,
        tanggalKejadian: _tanggal,
        jumlahLukaLuka: int.tryParse(_lukaCtrl.text) ?? 0,
        jumlahMeninggal: int.tryParse(_meninggalCtrl.text) ?? 0,
        rumahSakit: _rsCtrl.text.trim(),
        keterangan: _keteranganCtrl.text.trim(),
        fotoBase64: fotoBase64,
        lat: _lokasi?.latitude,
        lng: _lokasi?.longitude,
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final optionsAsync = ref.watch(yangTerlibatOptionsProvider);
    final dateFmt      = DateFormat('dd MMM yyyy, HH:mm', 'id');

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
                  child: Text(
                    'Tambah Laporan',
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

          // Form body
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

                    // ── Tanggal Kejadian ──────────────────────────────
                    _Label('Tanggal Kejadian'),
                    const SizedBox(height: 6),
                    _TapField(
                      text: dateFmt.format(_tanggal),
                      icon: Icons.calendar_today_rounded,
                      onTap: _saving ? null : _pickTanggal,
                    ),
                    const SizedBox(height: 16),

                    // ── Yang Terlibat ─────────────────────────────────
                    _Label('Yang Terlibat *'),
                    const SizedBox(height: 6),
                    optionsAsync.when(
                      loading: () => const _ShimmerField(),
                      error: (e, _) => Text('Gagal: $e',
                          style: const TextStyle(
                              color: Colors.red, fontSize: 12)),
                      data: (opts) => DropdownButtonFormField<int>(
                        initialValue: _yangTerlibatId,
                        isExpanded: true,
                        decoration: _fieldDecor(
                            hint: 'Pilih jenis keterlibatan',
                            icon: Icons.directions_car_rounded),
                        items: opts
                            .map((o) => DropdownMenuItem<int>(
                                  value: o['id'] as int,
                                  child: Text(o['nama'] as String,
                                      style: const TextStyle(
                                          color: _kBlue0, fontSize: 14)),
                                ))
                            .toList(),
                        onChanged: _saving
                            ? null
                            : (v) =>
                                setState(() => _yangTerlibatId = v),
                        validator: (v) =>
                            v == null ? 'Wajib dipilih' : null,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Jumlah korban (row) ───────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _CounterField(
                            label: 'Luka-luka',
                            controller: _lukaCtrl,
                            color: const Color(0xFFE65100),
                            enabled: !_saving,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _CounterField(
                            label: 'Meninggal',
                            controller: _meninggalCtrl,
                            color: const Color(0xFFB71C1C),
                            enabled: !_saving,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Rumah Sakit ───────────────────────────────────
                    _Label('RS Tujuan (Opsional)'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _rsCtrl,
                      enabled: !_saving,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(color: _kBlue0, fontSize: 14),
                      decoration: _fieldDecor(
                          hint: 'Nama rumah sakit tujuan...',
                          icon: Icons.local_hospital_rounded),
                    ),
                    const SizedBox(height: 16),

                    // ── Lokasi Kejadian ───────────────────────────────
                    _Label('Lokasi Kejadian'),
                    const SizedBox(height: 6),
                    _LocationPreview(
                      key: ValueKey(
                          '${_lokasi?.latitude},${_lokasi?.longitude}'),
                      lokasi: _lokasi,
                      onTap: _saving ? null : _openLocationPicker,
                    ),
                    const SizedBox(height: 16),

                    // ── Foto ──────────────────────────────────────────
                    _Label('Foto Dokumentasi'),
                    const SizedBox(height: 6),
                    _FotoField(
                      fotoBytes: _fotoBytes,
                      onPick: _saving ? null : _pickFoto,
                      onRemove: _saving
                          ? null
                          : () => setState(() => _fotoBytes = null),
                    ),
                    const SizedBox(height: 16),

                    // ── Keterangan ────────────────────────────────────
                    _Label('Keterangan (Opsional)'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _keteranganCtrl,
                      enabled: !_saving,
                      maxLines: 3,
                      textInputAction: TextInputAction.newline,
                      style: const TextStyle(color: _kBlue0, fontSize: 14),
                      decoration: _fieldDecor(
                          hint: 'Detail kejadian, kondisi korban...',
                          icon: Icons.notes_rounded),
                    ),
                    const SizedBox(height: 28),

                    // ── Tombol simpan ─────────────────────────────────
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
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.send_rounded, size: 20),
                        label: Text(
                          _saving ? 'Mengirim...' : 'Kirim Laporan',
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

// ── Shared field decoration ───────────────────────────────────────────────────

InputDecoration _fieldDecor({required String hint, required IconData icon}) {
  const border = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(10)),
    borderSide: BorderSide(color: Color(0xFFDDE3EE)),
  );
  const focusBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(10)),
    borderSide: BorderSide(color: Color(0xFFA2CFFE), width: 2),
  );
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFFB0BAC9), fontSize: 13),
    prefixIcon:
        Icon(icon, color: const Color(0xFF1D2A44).withValues(alpha: 0.45), size: 20),
    filled: true,
    fillColor: Colors.white,
    border: border,
    enabledBorder: border,
    focusedBorder: focusBorder,
    errorBorder: border.copyWith(
        borderSide: const BorderSide(color: Colors.red)),
    contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    isDense: true,
  );
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          color: _kBlue1.withValues(alpha: 0.85),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      );
}

// Tap-to-open field (tanggal)
class _TapField extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback? onTap;
  const _TapField(
      {required this.text, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFDDE3EE)),
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: 18,
                  color: _kBlue1.withValues(alpha: 0.45)),
              const SizedBox(width: 10),
              Text(text,
                  style: const TextStyle(
                      color: _kBlue0,
                      fontSize: 14)),
              const Spacer(),
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

// Counter field (luka/meninggal)
class _CounterField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final Color color;
  final bool enabled;
  const _CounterField(
      {required this.label,
      required this.controller,
      required this.color,
      required this.enabled});

  void _add(int delta) {
    final v = int.tryParse(controller.text) ?? 0;
    final next = (v + delta).clamp(0, 999);
    controller.text = '$next';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(label),
        const SizedBox(height: 6),
        Container(
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFDDE3EE)),
          ),
          child: Row(
            children: [
              _StepBtn(
                icon: Icons.remove,
                color: color,
                onTap: enabled ? () => _add(-1) : null,
              ),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  enabled: enabled,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 15),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ),
              _StepBtn(
                icon: Icons.add,
                color: color,
                onTap: enabled ? () => _add(1) : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _StepBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 46,
          child: Icon(icon, size: 18, color: color),
        ),
      );
}

// Foto field
class _FotoField extends StatelessWidget {
  final Uint8List? fotoBytes;
  final VoidCallback? onPick;
  final VoidCallback? onRemove;
  const _FotoField(
      {required this.fotoBytes,
      required this.onPick,
      required this.onRemove});

  @override
  Widget build(BuildContext context) {
    if (fotoBytes != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(
              fotoBytes!,
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(4),
                child: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: onPick,
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: const Color(0xFFDDE3EE), style: BorderStyle.solid),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_photo_alternate_rounded,
                  size: 28,
                  color: _kBlue1.withValues(alpha: 0.4)),
              const SizedBox(height: 4),
              Text('Tambah Foto',
                  style: TextStyle(
                      color: _kBlue1.withValues(alpha: 0.5),
                      fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

// Loading shimmer untuk dropdown
class _ShimmerField extends StatelessWidget {
  const _ShimmerField();

  @override
  Widget build(BuildContext context) => Container(
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFDDE3EE)),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: _kBlue1),
          ),
        ),
      );
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
          Icon(Icons.car_crash_rounded,
              size: 64, color: _kBlue1.withValues(alpha: 0.25)),
          const SizedBox(height: 16),
          Text('Belum ada laporan',
              style: TextStyle(
                  color: _kBlue1.withValues(alpha: 0.6),
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Tekan + untuk membuat laporan baru',
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

// ── Filter sheet ──────────────────────────────────────────────────────────────

class _FilterSheet extends StatelessWidget {
  final String? current;
  const _FilterSheet({this.current});

  static const _options = [
    (label: 'Semua', value: ''),
    (label: 'Baru', value: 'BARU'),
    (label: 'Diproses', value: 'DIPROSES'),
    (label: 'Selesai', value: 'SELESAI'),
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

// ── Card item ─────────────────────────────────────────────────────────────────

class _LakaCard extends StatelessWidget {
  final EformLaka item;
  const _LakaCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy, HH:mm', 'id');

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
        onTap: () => _showLakaDetail(context, item),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                  _StateBadge(state: item.state),
                  const SizedBox(width: 8),
                  const Icon(Icons.personal_injury_rounded,
                      size: 13, color: Color(0xFFE65100)),
                  const SizedBox(width: 2),
                  Text(
                    '${item.jumlahLukaLuka}',
                    style: const TextStyle(
                      color: Color(0xFFE65100),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.heart_broken_rounded,
                      size: 13, color: Color(0xFFB71C1C)),
                  const SizedBox(width: 2),
                  Text(
                    '${item.jumlahMeninggal}',
                    style: const TextStyle(
                      color: Color(0xFFB71C1C),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (item.keterangan != null && item.keterangan!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  item.keterangan!,
                  style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 11,
                      height: 1.4),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.access_time_rounded,
                      size: 12, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text(
                    dateFmt.format(item.tanggalKejadian),
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Detail bottom sheet ───────────────────────────────────────────────────────

void _showLakaDetail(BuildContext context, EformLaka item) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    constraints: const BoxConstraints(maxWidth: 480),
    builder: (_) => _LakaDetailSheet(item: item),
  );
}

class _LakaDetailSheet extends ConsumerWidget {
  final EformLaka item;
  const _LakaDetailSheet({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFmt = DateFormat('dd MMM yyyy, HH:mm', 'id');
    final hasLokasi = item.lat != null && item.lng != null;
    final fotoAsync = ref.watch(lakaFotoProvider(item.id));

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
            // Handle bar
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
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 8, 4),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Detail Laporan',
                      style: TextStyle(
                        color: _kBlue1,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
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
            // Content
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(16),
                children: [
                  // Kode & State
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _kBlue0.withValues(alpha: 0.1),
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
                      _StateBadge(state: item.state),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Info rows
                  _DetailRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Tanggal Kejadian',
                    value: dateFmt.format(item.tanggalKejadian),
                  ),
                  if (item.yangTerlibatNama != null)
                    _DetailRow(
                      icon: Icons.group_rounded,
                      label: 'Yang Terlibat',
                      value: item.yangTerlibatNama!,
                    ),
                  _DetailRow(
                    icon: Icons.personal_injury_rounded,
                    label: 'Luka-luka',
                    value: '${item.jumlahLukaLuka} orang',
                    valueColor: const Color(0xFFE65100),
                  ),
                  _DetailRow(
                    icon: Icons.heart_broken_rounded,
                    label: 'Meninggal',
                    value: '${item.jumlahMeninggal} orang',
                    valueColor: const Color(0xFFB71C1C),
                  ),
                  if (item.rumahSakit != null && item.rumahSakit!.isNotEmpty)
                    _DetailRow(
                      icon: Icons.local_hospital_rounded,
                      label: 'RS Tujuan',
                      value: item.rumahSakit!,
                    ),
                  if (item.keterangan != null && item.keterangan!.isNotEmpty)
                    _DetailRow(
                      icon: Icons.notes_rounded,
                      label: 'Keterangan',
                      value: item.keterangan!,
                    ),
                  // Foto dokumentasi
                  const SizedBox(height: 8),
                  const _SectionLabel('Foto Dokumentasi'),
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
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: _kBlue1),
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
                              border:
                                  Border.all(color: const Color(0xFFDDE3EE)),
                            ),
                            child: Center(
                              child: Text(
                                'Tidak ada foto',
                                style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 13),
                              ),
                            ),
                          ),
                  ),
                  // Lokasi
                  const SizedBox(height: 16),
                  const _SectionLabel('Lokasi Kejadian'),
                  const SizedBox(height: 8),
                  if (hasLokasi)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        height: 180,
                        child: Stack(
                          children: [
                            AbsorbPointer(
                              child: FlutterMap(
                                options: MapOptions(
                                  initialCenter: LatLng(item.lat!, item.lng!),
                                  initialZoom: 16.0,
                                  interactionOptions: const InteractionOptions(
                                    flags: InteractiveFlag.none,
                                  ),
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate:
                                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName:
                                        'id.polisibaik.ampera247',
                                  ),
                                ],
                              ),
                            ),
                            const Align(
                              alignment: Alignment(0, -0.12),
                              child: Icon(Icons.location_pin,
                                  color: Color(0xFF1D2A44), size: 38),
                            ),
                            Positioned(
                              bottom: 0, left: 0, right: 0,
                              child: Container(
                                color: Colors.black45,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                child: Text(
                                  '${item.lat!.toStringAsFixed(5)}, '
                                  '${item.lng!.toStringAsFixed(5)}',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 11),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFDDE3EE)),
                      ),
                      child: Center(
                        child: Text(
                          'Lokasi tidak tersedia',
                          style: TextStyle(
                              color: Colors.grey.shade400, fontSize: 13),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            // Tombol hapus — hanya muncul saat status BARU
            if (item.state == 'BARU')
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
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
                        label: const Text('Hapus Laporan',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        onPressed: () => _confirmDelete(context, ref),
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
              const Text(
                'Hapus Laporan?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _kBlue1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Laporan ${item.code} akan dihapus permanen dan tidak dapat dikembalikan.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.5),
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
      await deleteEformLaka(api: api, id: item.id);
      ref.invalidate(eformLakaListProvider);
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

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

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
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? _kBlue1,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      );
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
                            'Tambah',
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

// ── Location preview (non-interactive map) ────────────────────────────────────

class _LocationPreview extends StatefulWidget {
  final LatLng? lokasi;
  final VoidCallback? onTap;
  const _LocationPreview({super.key, required this.lokasi, required this.onTap});

  @override
  State<_LocationPreview> createState() => _LocationPreviewState();
}

class _LocationPreviewState extends State<_LocationPreview> {
  Key _mapKey = UniqueKey();

  @override
  void didUpdateWidget(_LocationPreview old) {
    super.didUpdateWidget(old);
    if (widget.lokasi != null) {
      setState(() => _mapKey = UniqueKey());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lokasi == null) {
      return Container(
        height: 90,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFDDE3EE)),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: _kBlue1),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          height: 170,
          child: Stack(
            children: [
              // _mapKey = UniqueKey() di didUpdateWidget → paksa flutter_map
              // recreate seluruh state & tile-nya setiap lokasi berubah
              AbsorbPointer(
                child: FlutterMap(
                  key: _mapKey,
                  options: MapOptions(
                    initialCenter: widget.lokasi!,
                    initialZoom: 16.0,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.none,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName:
                          'id.polisibaik.ampera247',
                    ),
                  ],
                ),
              ),
              // Center pin
              const Align(
                alignment: Alignment(0, -0.12),
                child: Icon(Icons.location_pin,
                    color: Color(0xFF1D2A44), size: 38),
              ),
              // Bottom hint bar
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  color: Colors.black45,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.edit_location_alt_rounded,
                          color: Colors.white, size: 13),
                      const SizedBox(width: 6),
                      Text(
                        '${widget.lokasi!.latitude.toStringAsFixed(5)}, '
                        '${widget.lokasi!.longitude.toStringAsFixed(5)}',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 11),
                      ),
                      const Spacer(),
                      const Text('Tap untuk ubah',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 10)),
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
}

// ── Location picker dialog (full-screen interactive map) ──────────────────────

class _LocationPickerDialog extends StatefulWidget {
  final LatLng initial;
  const _LocationPickerDialog({required this.initial});

  @override
  State<_LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<_LocationPickerDialog> {
  late LatLng _current;
  late final MapController _mapCtrl;

  @override
  void initState() {
    super.initState();
    _current = widget.initial;
    _mapCtrl = MapController();
  }

  @override
  void dispose() {
    _mapCtrl.dispose();
    super.dispose();
  }

  Future<void> _goToMyLocation() async {
    try {
      if (!kIsWeb) {
        var perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
        if (perm == LocationPermission.deniedForever) return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      final ll = LatLng(pos.latitude, pos.longitude);
      _mapCtrl.move(ll, 16.0);
      if (mounted) setState(() => _current = ll);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        body: Stack(
          children: [
            // Interactive map
            FlutterMap(
              mapController: _mapCtrl,
              options: MapOptions(
                initialCenter: _current,
                initialZoom: 16.0,
                onPositionChanged: (camera, _) {
                  setState(() => _current = camera.center);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName:
                      'id.polisibaik.ampera247',
                ),
              ],
            ),

            // Center crosshair pin
            const Align(
              alignment: Alignment(0, -0.06),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_pin,
                      color: Color(0xFF1D2A44), size: 44),
                  SizedBox(height: 22),
                ],
              ),
            ),

            // Top AppBar
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                color: _kBlue1,
                child: SafeArea(
                  bottom: false,
                  child: SizedBox(
                    height: kToolbarHeight,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text(
                          'Pilih Lokasi Kejadian',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // My-location FAB
            Positioned(
              right: 16,
              bottom: 100,
              child: FloatingActionButton.small(
                heroTag: 'myLocation',
                backgroundColor: Colors.white,
                elevation: 3,
                onPressed: _goToMyLocation,
                child: const Icon(Icons.my_location_rounded, color: _kBlue1),
              ),
            ),

            // Confirm bottom bar
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_current.latitude.toStringAsFixed(6)}, '
                      '${_current.longitude.toStringAsFixed(6)}',
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: _kBlue1,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(context, _current),
                        icon: const Icon(Icons.check_rounded, size: 20),
                        label: const Text(
                          'Gunakan Lokasi Ini',
                          style: TextStyle(fontWeight: FontWeight.w700),
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
}

// ── Status badge ──────────────────────────────────────────────────────────────

class _StateBadge extends StatelessWidget {
  final String state;
  const _StateBadge({required this.state});

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (state) {
      'DIPROSES' => (const Color(0xFFFFF3E0), const Color(0xFFE65100)),
      'SELESAI'  => (const Color(0xFFE8F5E9), const Color(0xFF2E7D32)),
      _          => (const Color(0xFFE3F2FD), const Color(0xFF1565C0)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        state,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
