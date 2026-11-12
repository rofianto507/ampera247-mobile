import '../../../../core/utils/odoo_time.dart';

class NotifikasiItem {
  final int id;
  final String judul;
  final String isi;
  final String tipe;
  final bool isRead;
  final DateTime createdAt;

  const NotifikasiItem({
    required this.id,
    required this.judul,
    required this.isi,
    required this.tipe,
    required this.isRead,
    required this.createdAt,
  });

  factory NotifikasiItem.fromJson(Map<String, dynamic> j) => NotifikasiItem(
        id: j['id'] as int,
        judul: j['judul'] as String? ?? '',
        isi: j['isi'] as String? ?? '',
        tipe: j['tipe'] as String? ?? 'system',
        isRead: j['is_read'] as bool? ?? false,
        createdAt: j['created_at'] != null
            ? parseOdooUtc(j['created_at'] as String)
            : DateTime.now(),
      );
}
