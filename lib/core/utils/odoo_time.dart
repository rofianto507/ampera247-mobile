/// Odoo menyimpan & mengirim Datetime dalam UTC ("YYYY-MM-DD HH:MM:SS" tanpa
/// penanda zona). Parse sebagai UTC lalu ubah ke zona perangkat.
DateTime parseOdooUtc(String s) {
  final t = s.trim();
  final hasZone = t.endsWith('Z') || RegExp(r'[+-]\d\d:?\d\d$').hasMatch(t);
  return DateTime.parse(hasZone ? t : '${t.replaceFirst(' ', 'T')}Z').toLocal();
}
