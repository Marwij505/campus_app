// Kontrak profil memudahkan pengujian tanpa akun/database sungguhan.
import 'dart:typed_data';

import 'student_profile.dart';
import 'profile_phone.dart';
import 'biodata_repository.dart';

class ProfileException implements Exception {
  const ProfileException(this.message);
  final String message;
}

class ProfileChanges {
  const ProfileChanges({
    required this.preferredName,
    required this.phone,
    required this.avatarVariant,
    this.photo,
    this.removePhoto = false,
  });
  final String preferredName, phone, avatarVariant;
  final Uint8List? photo;
  final bool removePhoto;
  String? validate() {
    if (preferredName.trim().length > 50 ||
        RegExp(r'[\x00-\x1F\x7F]').hasMatch(preferredName)) {
      return 'Nama panggilan maksimal 50 karakter tanpa karakter kontrol.';
    }
    if (!validProfilePhone(phone)) {
      return 'Nomor telepon tidak valid. Gunakan 08…, 62…, atau +kode negara.';
    }
    if (!['male', 'female', 'neutral'].contains(avatarVariant)) {
      return 'Pilih avatar yang tersedia.';
    }
    if (photo != null && removePhoto) return 'Pilih unggah atau hapus foto.';
    return null;
  }
}

abstract class ProfileRepository {
  BiodataRepository? get biodata;
  Future<StudentProfile> load();
  Future<StudentProfile> save(ProfileChanges changes);
}
