import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/barang_bukti.dart';
import '../providers/barang_bukti_provider.dart';

const _kBlue0 = Color(0xFF0D1526);
const _kBlue1 = Color(0xFF1D2A44);

// ─────────────────────────────────────────────────────────────────────────────

class BarangBuktiScreen extends ConsumerStatefulWidget {
  const BarangBuktiScreen({super.key});
  @override
  ConsumerState<BarangBuktiScreen> createState() => _BarangBuktiScreenState();
}

class _BarangBuktiScreenState extends ConsumerState<BarangBuktiScreen> {
  static const _filterOptions = [
    ('nopol',  'No. Kendaraan', 'Contoh: BG 1234 AB'),
    ('rangka', 'No. Rangka',  'Contoh: MH1JF813...'),
    ('mesin',  'No. Mesin',   'Contoh: JF81E1...'),
  ];

  String _filterType = 'nopol';
  final _queryCtrl = TextEditingController();

  bool _searching = false;
  List<BarangBukti>? _result;
  String? _error;
  String _lastQuery = '';
  String _lastFilterType = 'nopol';

  @override
  void initState() {
    super.initState();
    _queryCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  String get _hintText => _filterOptions
      .firstWhere((e) => e.$1 == _filterType, orElse: () => _filterOptions[0])
      .$3;

  bool get _canSearch => _queryCtrl.text.trim().isNotEmpty && !_searching;

  Future<void> _search() async {
    final q = _queryCtrl.text.trim();
    if (q.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _searching = true;
      _result = null;
      _error = null;
      _lastQuery = q;
      _lastFilterType = _filterType;
    });
    try {
      final results = await searchBarangBukti(
        api: ref.read(apiClientProvider),
        filterType: _filterType,
        query: q,
      );
      if (mounted) setState(() => _result = results);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9FF),
      body: Column(
        children: [
          _buildAppBar(),
          // Search card — fixed, tidak ikut scroll
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: _buildSearchCard(),
              ),
            ),
          ),
          // Area konten — centered untuk state, scrollable untuk hasil
          Expanded(child: _buildContentArea()),
        ],
      ),
    );
  }

  // ── Content area ────────────────────────────────────────────────────────────

  Widget _buildContentArea() {
    if (_searching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _centeredScrollable(_buildError());
    }
    if (_result == null) {
      return _centeredScrollable(_buildHint());
    }
    if (_result!.isEmpty) {
      return _centeredScrollable(_buildEmpty());
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildResultsHeader(),
                const SizedBox(height: 12),
                ..._result!.map(_buildResultCard),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _centeredScrollable(Widget child) => LayoutBuilder(
        builder: (_, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: child),
          ),
        ),
      );

  // ── AppBar ──────────────────────────────────────────────────────────────────

  Widget _buildAppBar() => Container(
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
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.maybePop(context),
                    ),
                    const Text(
                      'Cek Barang Bukti',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  // ── Search card ─────────────────────────────────────────────────────────────

  Widget _buildSearchCard() => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: _kBlue1.withValues(alpha: 0.15),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _kBlue1.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.manage_search_rounded, color: _kBlue1, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cek Status Barang Bukti',
                          style: TextStyle(
                            color: _kBlue0,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Kasus Curanmor (Pencurian Kendaraan)',
                          style: TextStyle(color: Color(0xFF6B7A99), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'CARI BERDASARKAN',
                style: TextStyle(
                  color: Color(0xFF9AA5BE),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: _filterOptions.map((opt) {
                  final selected = _filterType == opt.$1;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Material(
                      color: selected ? _kBlue1 : _kBlue1.withValues(alpha: 0.06),
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: selected ? _kBlue1 : _kBlue1.withValues(alpha: 0.18),
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                          if (_filterType == opt.$1) return;
                          setState(() {
                            _filterType = opt.$1;
                            _queryCtrl.clear();
                            _result = null;
                            _error = null;
                          });
                        },
                        splashColor: (selected ? Colors.white : _kBlue1)
                            .withValues(alpha: 0.25),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          child: Text(
                            opt.$2,
                            style: TextStyle(
                              color: selected ? Colors.white : _kBlue1,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _queryCtrl,
                textCapitalization: TextCapitalization.characters,
                onSubmitted: (_) => _search(),
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF9AA5BE),
                    size: 22,
                  ),
                  hintText: _hintText,
                  hintStyle: const TextStyle(
                    color: Color(0xFFB0BDD4),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  suffixIcon: _queryCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            size: 18,
                            color: Color(0xFF9AA5BE),
                          ),
                          onPressed: () {
                            _queryCtrl.clear();
                            setState(() {
                              _result = null;
                              _error = null;
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF4F9FF),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _kBlue1.withValues(alpha: 0.4)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _canSearch ? _search : null,
                  icon: const Icon(Icons.search_rounded, size: 18),
                  label: const Text('Cari Barang Bukti'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kBlue1,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _kBlue1.withValues(alpha: 0.35),
                    disabledForegroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  // ── State widgets ───────────────────────────────────────────────────────────

  Widget _buildError() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 12),
            const Text(
              'Terjadi kesalahan',
              style: TextStyle(fontWeight: FontWeight.w600, color: _kBlue0),
            ),
            const SizedBox(height: 4),
            Text(
              _error ?? '',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7A99)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _search,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Coba lagi'),
              style: TextButton.styleFrom(foregroundColor: _kBlue1),
            ),
          ],
        ),
      );

  Widget _buildHint() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _kBlue1.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_car_outlined,
                size: 44,
                color: _kBlue1,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Masukkan nomor kendaraan',
              style: TextStyle(
                color: _kBlue0,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Cari menggunakan nomor kendaraan, nomor rangka, atau\nnomor mesin untuk melihat status barang bukti.',
              style: TextStyle(
                color: Color(0xFF6B7A99),
                fontSize: 13,
                height: 1.55,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildEmpty() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.search_off_rounded,
                  size: 44, color: Colors.orange.shade400),
            ),
            const SizedBox(height: 16),
            const Text(
              'Data tidak ditemukan',
              style: TextStyle(
                color: _kBlue0,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(
                  color: Color(0xFF6B7A99),
                  fontSize: 13,
                  height: 1.55,
                ),
                children: [
                  const TextSpan(text: 'Tidak ada data dengan '),
                  TextSpan(
                    text: '$_lastFilterLabel "$_lastQuery"',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _kBlue1,
                    ),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
          ],
        ),
      );

  String get _lastFilterLabel => const {
        'nopol':  'No. Kendaraan',
        'rangka': 'No. Rangka',
        'mesin':  'No. Mesin',
      }[_lastFilterType] ??
      'No. Kendaraan';

  // ── Results ─────────────────────────────────────────────────────────────────

  Widget _buildResultsHeader() {
    final count = _result?.length ?? 0;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: _kBlue1.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$count hasil',
            style: const TextStyle(
              color: _kBlue1,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'pencarian "$_lastQuery"',
            style: const TextStyle(color: Color(0xFF6B7A99), fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(BarangBukti bb) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          elevation: 1,
          shadowColor: _kBlue1.withValues(alpha: 0.1),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _showDetail(bb),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        bb.code,
                        style: const TextStyle(
                          color: _kBlue0,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const Spacer(),
                      _StatusBadge(state: bb.state, label: bb.stateLabel),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    [
                      bb.jenisKendaraanLabel,
                      if (bb.merek != null) bb.merek!,
                      if (bb.tipe != null) bb.tipe!,
                      if (bb.tahunKendaraan != null) bb.tahunKendaraan.toString(),
                    ].join(' · '),
                    style: const TextStyle(color: Color(0xFF4A5568), fontSize: 13),
                  ),
                  if (bb.warna != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Warna: ${bb.warna}',
                      style: const TextStyle(color: Color(0xFF6B7A99), fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: Color(0xFFEEF2F7)),
                  const SizedBox(height: 10),
                  if (bb.nomorPolisi != null)
                    _InfoRow(icon: Icons.badge_rounded, label: 'No. Kendaraan', value: bb.nomorPolisi!),
                  if (bb.nomorRangka != null)
                    _InfoRow(icon: Icons.numbers_rounded, label: 'Rangka', value: bb.nomorRangka!),
                  if (bb.nomorMesin != null)
                    _InfoRow(icon: Icons.settings_outlined, label: 'Mesin', value: bb.nomorMesin!),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (bb.tanggalPenerimaan != null) ...[
                        const Icon(Icons.calendar_today_outlined, size: 13, color: Color(0xFF9AA5BE)),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('d MMM y', 'id').format(bb.tanggalPenerimaan!),
                          style: const TextStyle(color: Color(0xFF6B7A99), fontSize: 12),
                        ),
                      ],
                      if (bb.lokasiPenyimpanan != null) ...[
                        const SizedBox(width: 12),
                        const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF9AA5BE)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            bb.lokasiPenyimpanan!,
                            style: const TextStyle(color: Color(0xFF6B7A99), fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  void _showDetail(BarangBukti bb) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
        maxWidth: 480,
      ),
      builder: (_) => _DetailSheet(bb: bb),
    );
  }
}

// ── StatusBadge ───────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String state;
  final String label;
  const _StatusBadge({required this.state, required this.label});

  Color get _color => const <String, Color>{
        'diterima':     Color(0xFF7B1FA2),
        'disimpan':     Color(0xFF1565C0),
        'diproses':     Color(0xFFE65100),
        'dikembalikan': Color(0xFF2E7D32),
        'dimusnahkan':  Color(0xFFC62828),
      }[state] ??
      Colors.grey;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: _color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      );
}

// ── InfoRow ───────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 14, color: const Color(0xFF9AA5BE)),
            const SizedBox(width: 6),
            SizedBox(
              width: 52,
              child: Text(
                label,
                style: const TextStyle(color: Color(0xFF6B7A99), fontSize: 12),
              ),
            ),
            const Text(' : ', style: TextStyle(color: Color(0xFF9AA5BE), fontSize: 12)),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF2D3748),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      );
}

// ── DetailSheet ───────────────────────────────────────────────────────────────

class _DetailSheet extends StatelessWidget {
  final BarangBukti bb;
  const _DetailSheet({required this.bb});

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDE3EE),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bb.code,
                          style: const TextStyle(
                            color: _kBlue0,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                        if (bb.nomorPerkara != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            'No. Perkara: ${bb.nomorPerkara}',
                            style: const TextStyle(color: Color(0xFF6B7A99), fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _StatusBadge(state: bb.state, label: bb.stateLabel),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _section('IDENTITAS KENDARAAN'),
                    const SizedBox(height: 8),
                    _row('Jenis', bb.jenisKendaraanLabel),
                    if (bb.merek != null) _row('Merek', bb.merek!),
                    if (bb.tipe != null) _row('Tipe / Model', bb.tipe!),
                    if (bb.warna != null) _row('Warna', bb.warna!),
                    if (bb.tahunKendaraan != null)
                      _row('Tahun', bb.tahunKendaraan.toString()),
                    const SizedBox(height: 16),
                    _section('NOMOR KENDARAAN'),
                    const SizedBox(height: 8),
                    if (bb.nomorPolisi != null)
                      _row('No. Kendaraan', bb.nomorPolisi!, bold: true),
                    if (bb.nomorRangka != null)
                      _row('No. Rangka', bb.nomorRangka!, bold: true),
                    if (bb.nomorMesin != null)
                      _row('No. Mesin', bb.nomorMesin!, bold: true),
                    if (bb.namaPemilikStnk != null) ...[
                      const SizedBox(height: 16),
                      _section('PEMILIK KENDARAAN'),
                      const SizedBox(height: 8),
                      _row('Nama', bb.namaPemilikStnk!),
                    ],
                    const SizedBox(height: 16),
                    _section('PENERIMAAN'),
                    const SizedBox(height: 8),
                    if (bb.tanggalPenerimaan != null)
                      _row('Tgl. Diterima',
                          DateFormat('d MMMM y', 'id').format(bb.tanggalPenerimaan!)),
                    if (bb.lokasiPenyimpanan != null)
                      _row('Lokasi', bb.lokasiPenyimpanan!),
                    _row('Pelapor', bb.namaPerlapor),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _kBlue1,
                          side: BorderSide(color: _kBlue1.withValues(alpha: 0.3)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Tutup'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Widget _section(String text) => Text(
        text,
        style: TextStyle(
          color: _kBlue1.withValues(alpha: 0.5),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
        ),
      );

  Widget _row(String label, String value, {bool bold = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 90,
              child: Text(
                label,
                style: const TextStyle(color: Color(0xFF6B7A99), fontSize: 13),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Text(':', style: TextStyle(color: Color(0xFF9AA5BE), fontSize: 13)),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  color: _kBlue0,
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: bold ? 0.5 : 0,
                ),
              ),
            ),
          ],
        ),
      );
}
