import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/patroli_providers.dart';
import '../providers/patroli_settings_notifier.dart';
import '../providers/patroli_tracking_notifier.dart';

class PatroliMulaiSheet extends ConsumerStatefulWidget {
  final int grupId;
  final VoidCallback onStarted;

  const PatroliMulaiSheet({
    super.key,
    required this.grupId,
    required this.onStarted,
  });

  @override
  ConsumerState<PatroliMulaiSheet> createState() => _PatroliMulaiSheetState();
}

class _PatroliMulaiSheetState extends ConsumerState<PatroliMulaiSheet> {
  static const _kNavy = Color(0xFF1D2A44);

  int? _kecamatanId;
  int? _desaId;
  final _keteranganCtrl = TextEditingController();

  // Daftar personel: {nama, pangkat}
  final List<({TextEditingController nama, TextEditingController pangkat})> _personel = [];

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _addPersonel(); // minimal 1 personel
  }

  @override
  void dispose() {
    _keteranganCtrl.dispose();
    for (final p in _personel) {
      p.nama.dispose();
      p.pangkat.dispose();
    }
    super.dispose();
  }

  void _addPersonel() {
    setState(() {
      _personel.add((
        nama: TextEditingController(),
        pangkat: TextEditingController(),
      ));
    });
  }

  void _removePersonel(int index) {
    if (_personel.length <= 1) return;
    final p = _personel.removeAt(index);
    p.nama.dispose();
    p.pangkat.dispose();
    setState(() {});
  }

  Future<bool> _showLocationDisclosure() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F0FE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_on,
                    color: Color(0xFF1565C0), size: 36),
              ),
              const SizedBox(height: 16),
              const Text('Akses Lokasi Diperlukan',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              const Text(
                'Aplikasi ini akan mengakses lokasi perangkat Anda '
                'secara berkala selama patroli berlangsung untuk:\n\n'
                '• Merekam rute perjalanan patroli\n'
                '• Menyimpan titik koordinat ke server\n'
                '• Memantau posisi oleh pengawas\n\n'
                'Data lokasi hanya direkam saat patroli aktif '
                'dan tidak digunakan untuk tujuan lain.',
                style: TextStyle(fontSize: 13, height: 1.6, color: Colors.black87),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Tidak'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _kNavy,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Izinkan'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return result ?? false;
  }

  Future<void> _submit() async {
    // Validasi
    if (_kecamatanId == null) {
      setState(() => _error = 'Pilih kecamatan terlebih dahulu.');
      return;
    }
    if (_personel[0].nama.text.trim().isEmpty) {
      setState(() => _error = 'Isi minimal satu nama personel.');
      return;
    }

    // Prominent disclosure sebelum minta izin lokasi
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      final disclosed = await _showLocationDisclosure();
      if (!disclosed || !mounted) return;
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      setState(() => _error = 'Izin lokasi diperlukan untuk merekam rute patroli.');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      final api = ref.read(apiClientProvider);
      final now = DateTime.now().toUtc();
      final nowStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')} '
          '${now.hour.toString().padLeft(2, '0')}:'
          '${now.minute.toString().padLeft(2, '0')}:'
          '${now.second.toString().padLeft(2, '0')}';

      // 1. Buat record patroli
      final patroliId = await api.callKw(
        model: 'digital_kamtibmas.patroli',
        method: 'create',
        args: [
          {
            'grup_id': widget.grupId,
            'tanggal_patroli': nowStr,
            'kecamatan_id': _kecamatanId,
            if (_desaId != null) 'desa_id': _desaId,
            if (_keteranganCtrl.text.trim().isNotEmpty)
              'keterangan': _keteranganCtrl.text.trim(),
          }
        ],
      ) as int;

      // 2. Buat personel
      final personelData = _personel
          .where((p) => p.nama.text.trim().isNotEmpty)
          .map((p) => {
                'patroli_id': patroliId,
                'nama': p.nama.text.trim(),
                if (p.pangkat.text.trim().isNotEmpty) 'pangkat': p.pangkat.text.trim(),
              })
          .toList();
      if (personelData.isNotEmpty) {
        await api.callKw(
          model: 'digital_kamtibmas.patroli_personel',
          method: 'create',
          args: [personelData],
        );
      }

      // 3. Mulai patroli (ubah state ke berjalan)
      await api.callKw(
        model: 'digital_kamtibmas.patroli',
        method: 'action_mulai',
        args: [[patroliId]],
      );

      // 4. Mulai GPS tracking
      final interval = ref.read(patroliSettingsProvider);
      await ref.read(patroliTrackingProvider.notifier).start(patroliId, interval);

      if (mounted) {
        Navigator.of(context).pop();
        widget.onStarted();
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final kecAsync    = ref.watch(kecamatanOptionsProvider);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight   = MediaQuery.sizeOf(context).height * 0.92;

    return Padding(
      // Dorong sheet naik setinggi keyboard
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text('Mulai Patroli Baru',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: maxHeight - bottomInset - 80, // 80 = handle + header
            ),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Text(_error!, style: const TextStyle(color: Colors.red)),
                  ),

                // Kecamatan
                const Text('Kecamatan *',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                kecAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Gagal memuat: $e',
                      style: const TextStyle(color: Colors.red)),
                  data: (list) => DropdownButtonFormField<int>(
                    initialValue: _kecamatanId,
                    decoration: _inputDecor('Pilih kecamatan'),
                    items: list.map((k) => DropdownMenuItem<int>(
                      value: k['id'] as int,
                      child: Text(k['name'] as String),
                    )).toList(),
                    onChanged: (v) => setState(() {
                      _kecamatanId = v;
                      _desaId = null;
                    }),
                  ),
                ),
                const SizedBox(height: 14),

                // Desa
                if (_kecamatanId != null) ...[
                  const Text('Desa/Kelurahan',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Consumer(builder: (_, ref, _) {
                    final desaAsync = ref.watch(desaByKecamatanProvider(_kecamatanId!));
                    return desaAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('Gagal memuat: $e',
                          style: const TextStyle(color: Colors.red)),
                      data: (list) => DropdownButtonFormField<int>(
                        initialValue: _desaId,
                        decoration: _inputDecor('Pilih desa (opsional)'),
                        items: list.map((d) => DropdownMenuItem<int>(
                          value: d['id'] as int,
                          child: Text(d['name'] as String),
                        )).toList(),
                        onChanged: (v) => setState(() => _desaId = v),
                      ),
                    );
                  }),
                  const SizedBox(height: 14),
                ],

                // Keterangan / Rute
                const Text('Keterangan / Rute',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _keteranganCtrl,
                  decoration: _inputDecor('Deskripsi rute atau catatan (opsional)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),

                // Personel
                Row(children: [
                  const Text('Personel *',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _addPersonel,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Tambah'),
                    style: TextButton.styleFrom(foregroundColor: _kNavy),
                  ),
                ]),
                const SizedBox(height: 6),
                ..._personel.asMap().entries.map((e) => _PersonelRow(
                      index: e.key,
                      namaCtrl: e.value.nama,
                      pangkatCtrl: e.value.pangkat,
                      canDelete: _personel.length > 1,
                      onDelete: () => _removePersonel(e.key),
                    )),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _kNavy,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Konfirmasi & Mulai Patroli',
                            style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),
              ],            // children Column (SingleChildScrollView)
            ),              // Column
          ),                // SingleChildScrollView
        ),                  // ConstrainedBox
      ],                    // children Column (Padding)
    ),                      // Column
  );                        // Padding + return
  }

  InputDecoration _inputDecor(String hint) => InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      );
}

class _PersonelRow extends StatelessWidget {
  final int index;
  final TextEditingController namaCtrl;
  final TextEditingController pangkatCtrl;
  final bool canDelete;
  final VoidCallback onDelete;

  const _PersonelRow({
    required this.index,
    required this.namaCtrl,
    required this.pangkatCtrl,
    required this.canDelete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: TextFormField(
              controller: namaCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'Nama ${index + 1}',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: pangkatCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'Pangkat',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
            ),
          ),
          if (canDelete)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}
