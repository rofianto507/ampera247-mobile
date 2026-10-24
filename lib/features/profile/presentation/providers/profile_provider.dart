import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Naik setiap foto profil berhasil diganti. Dipakai sebagai key + query pada
/// URL avatar (dashboard & profil) supaya gambar lama tidak tertahan di cache.
class ProfilePhotoVersion extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state = DateTime.now().millisecondsSinceEpoch;
}

final profilePhotoVersionProvider =
    NotifierProvider<ProfilePhotoVersion, int>(ProfilePhotoVersion.new);
