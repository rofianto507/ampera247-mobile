import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/patroli_settings_notifier.dart';

class PatroliSettingsScreen extends ConsumerWidget {
  const PatroliSettingsScreen({super.key});

  static const _kNavy = Color(0xFF1D2A44);

  static const _options = [
    (label: '10 detik', value: 10),
    (label: '15 detik', value: 15),
    (label: '30 detik', value: 30),
    (label: '1 menit',  value: 60),
    (label: '2 menit',  value: 120),
    (label: '5 menit',  value: 300),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final interval = ref.watch(patroliSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Patroli'),
        leading: BackButton(onPressed: () => context.go('/patroli')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Interval Rekam Lokasi',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Posisi GPS direkam dan dikirim ke server setiap interval yang dipilih. '
            'Interval lebih pendek menghasilkan rute lebih akurat tetapi '
            'menggunakan lebih banyak baterai dan data.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),

          RadioGroup<int>(
            groupValue: interval,
            onChanged: (v) {
              if (v != null) {
                ref.read(patroliSettingsProvider.notifier).setInterval(v);
              }
            },
            child: Column(
              children: _options
                  .map(
                    (opt) => RadioListTile<int>(
                      value: opt.value,
                      title: Text(opt.label),
                      subtitle: opt.value == 30
                          ? const Text('Default',
                              style: TextStyle(fontSize: 12))
                          : null,
                      activeColor: _kNavy,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  )
                  .toList(),
            ),
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Perubahan interval berlaku pada sesi patroli berikutnya. '
                    'Jika patroli sedang berjalan, interval saat ini tetap digunakan.',
                    style: TextStyle(fontSize: 13, color: Colors.blue),
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
