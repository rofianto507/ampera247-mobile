import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

const _kBlue1 = Color(0xFF1D2A44);
const _kSky = Color(0xFFA2CFFE);
const _kMaxNameLength = 60;
const _kMaxPhotoSide = 1024;

/// Bottom sheet ubah nama + foto profil. Mengembalikan true bila tersimpan.
Future<bool> showEditProfileSheet(
  BuildContext context, {
  required String currentName,
  required String currentPhotoUrl,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _EditProfileSheet(
      currentName: currentName,
      currentPhotoUrl: currentPhotoUrl,
    ),
  );
  return saved == true;
}

class _EditProfileSheet extends ConsumerStatefulWidget {
  final String currentName;
  final String currentPhotoUrl;
  const _EditProfileSheet(
      {required this.currentName, required this.currentPhotoUrl});

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  Uint8List? _currentPhoto; // foto sekarang dari server (untuk pratinjau)
  Uint8List? _newPhoto; // sudah diperkecil, siap diunggah
  bool _saving = false;
  bool _picking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.currentName);
    _loadCurrentPhoto();
  }

  Future<void> _loadCurrentPhoto() async {
    try {
      final resp = await ref.read(apiClientProvider).dio.get<List<int>>(
            widget.currentPhotoUrl,
            options: Options(responseType: ResponseType.bytes),
          );
      if (mounted && resp.data != null) {
        setState(() => _currentPhoto = Uint8List.fromList(resp.data!));
      }
    } catch (_) {
      // tampilkan inisial saja
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  String _initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  /// Perkecil ke maks 1024 px sisi terpanjang lalu simpan sebagai PNG,
  /// supaya unggahan kecil dan selalu di bawah batas 5 MB server.
  Future<Uint8List> _downscale(Uint8List bytes) async {
    final probe = await ui.instantiateImageCodec(bytes);
    final frame = await probe.getNextFrame();
    final w = frame.image.width;
    final h = frame.image.height;
    frame.image.dispose();
    probe.dispose();

    final longest = w > h ? w : h;
    final codec = longest <= _kMaxPhotoSide
        ? await ui.instantiateImageCodec(bytes)
        : await ui.instantiateImageCodec(
            bytes,
            targetWidth: w >= h ? _kMaxPhotoSide : null,
            targetHeight: h > w ? _kMaxPhotoSide : null,
          );
    final out = await codec.getNextFrame();
    final data = await out.image.toByteData(format: ui.ImageByteFormat.png);
    out.image.dispose();
    codec.dispose();
    if (data == null) throw StateError('encode gagal');
    return data.buffer.asUint8List();
  }

  Future<void> _pickPhoto() async {
    if (_picking || _saving) return;
    setState(() {
      _picking = true;
      _error = null;
    });
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      final bytes = result?.files.single.bytes;
      if (bytes == null) return;
      final small = await _downscale(bytes);
      if (!mounted) return;
      setState(() => _newPhoto = small);
    } catch (_) {
      if (mounted) setState(() => _error = 'Foto tidak dapat dibaca. Pilih foto lain.');
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (name.isEmpty) {
      setState(() => _error = 'Nama tidak boleh kosong');
      return;
    }
    final nameChanged = name != widget.currentName;
    if (!nameChanged && _newPhoto == null) {
      Navigator.pop(context, false);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final dio = ref.read(apiClientProvider).dio;
      final params = <String, dynamic>{};
      if (nameChanged) params['nama'] = name;
      if (_newPhoto != null) params['foto'] = base64Encode(_newPhoto!);

      final resp = await dio.post(
        '/api/dkm/profil/update',
        data: {'jsonrpc': '2.0', 'method': 'call', 'params': params},
      );
      final body = resp.data as Map<String, dynamic>?;
      final result = body?['result'] as Map<String, dynamic>?;
      if (result?['ok'] != true) {
        if (mounted) {
          setState(() => _error =
              (result?['error'] as String?) ?? 'Gagal menyimpan. Coba lagi.');
        }
        return;
      }
      if (nameChanged) {
        await ref.read(authNotifierProvider.notifier).updateName(name);
      }
      if (_newPhoto != null) {
        ref.read(profilePhotoVersionProvider.notifier).bump();
      }
      if (mounted) Navigator.pop(context, true);
    } on DioException {
      if (mounted) {
        setState(() => _error = 'Koneksi gagal. Periksa jaringan Anda.');
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Terjadi kesalahan. Coba lagi.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final photo = _newPhoto ?? _currentPhoto;
    final busy = _saving || _picking;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24, 4, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Edit Profil',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w800, color: _kBlue1),
            ),
            const SizedBox(height: 20),
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: _kBlue1.withValues(alpha: 0.10),
                    child: ClipOval(
                      child: photo != null
                          ? Image.memory(photo,
                              width: 104, height: 104, fit: BoxFit.cover)
                          : Text(
                              _initials(_nameCtrl.text),
                              style: const TextStyle(
                                  color: _kBlue1,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800),
                            ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Material(
                      color: _kBlue1,
                      shape: const CircleBorder(
                          side: BorderSide(color: Colors.white, width: 2)),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: busy ? null : _pickPhoto,
                        child: Padding(
                          padding: const EdgeInsets.all(9),
                          child: _picking
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.camera_alt_rounded,
                                  size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: busy ? null : _pickPhoto,
              child: Text(_newPhoto == null ? 'Ganti Foto' : 'Pilih Foto Lain'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              enabled: !_saving,
              maxLength: _kMaxNameLength,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() => _error = null),
              onSubmitted: (_) => _save(),
              decoration: InputDecoration(
                labelText: 'Nama Lengkap',
                prefixIcon: const Icon(Icons.person_outline_rounded,
                    color: _kSky, size: 20),
                filled: true,
                fillColor: const Color(0xFFFAF7F7),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(_error!,
                    style:
                        TextStyle(color: Colors.red.shade700, fontSize: 13)),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kBlue1,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _saving ? null : () => Navigator.pop(context, false),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _kBlue1,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: busy ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Simpan',
                            style: TextStyle(fontWeight: FontWeight.w700)),
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
