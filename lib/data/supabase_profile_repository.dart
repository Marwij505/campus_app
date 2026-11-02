// Semua operasi memakai JWT pengguna; filter UUID melengkapi, bukan mengganti, RLS.
import 'dart:typed_data';

import 'profile_photo.dart';
import 'profile_phone.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'profile_repository.dart';
import 'student_profile.dart';
import 'biodata_repository.dart';

class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this.client);
  final SupabaseClient client;
  @override
  late final BiodataRepository biodata = BiodataRepository(client);
  static const bucket = 'student-avatars';
  String get _id =>
      client.auth.currentUser?.id ??
      (throw const ProfileException('Sesi berakhir. Silakan masuk kembali.'));
  @override
  Future<StudentProfile> load() async {
    final id = _id;
    final p = await client.from('profiles').select().eq('id', id).maybeSingle();
    final s = await client
        .from('students')
        .select()
        .eq('user_id', id)
        .maybeSingle();
    if (p == null || s == null) {
      throw const ProfileException(
        'Profil belum tersedia atau akses sesi berakhir. Silakan masuk ulang atau hubungi pengelola.',
      );
    }
    Uint8List? photo;
    if (p['avatar_path'] != null) {
      try {
        photo = await client.storage
            .from(bucket)
            .download(p['avatar_path'] as String);
      } catch (_) {
        /* Foto gagal tidak menghilangkan identitas atau referensi server. */
      }
    }
    if (_id != id) {
      throw const ProfileException('Sesi berubah. Muat ulang profil.');
    }
    return StudentProfile.fromRows(
      p,
      s,
      email: client.auth.currentUser?.email,
      avatarBytes: photo,
    );
  }

  /// Kompatibilitas pemanggil lama: validasi memakai pipeline konversi foto.
  static Future<String> validatePhoto(Uint8List bytes) async {
    await ProfilePhoto.prepare(bytes);
    return 'jpg';
  }

  @override
  Future<StudentProfile> save(ProfileChanges changes) async {
    final validation = changes.validate();
    if (validation != null) throw ProfileException(validation);
    final id = _id;
    final previous = await client
        .from('profiles')
        .select('avatar_path,updated_at')
        .eq('id', id)
        .single();
    final oldPath = previous['avatar_path'] as String?;
    String? newPath;
    var committed = false;
    try {
      if (changes.photo != null) {
        final photo = await ProfilePhoto.prepare(changes.photo!);
        const extension = 'jpg';
        newPath = '$id/${DateTime.now().microsecondsSinceEpoch}.$extension';
        await client.storage
            .from(bucket)
            .uploadBinary(
              newPath,
              photo,
              fileOptions: FileOptions(
                contentType: extension == 'png' ? 'image/png' : 'image/jpeg',
                upsert: false,
              ),
            );
      }
      // Versi mencegah dua penyimpanan bersamaan menimpa hasil tanpa diketahui.
      final saved = await client
          .from('profiles')
          .update({
            'preferred_name': changes.preferredName.trim().isEmpty
                ? null
                : changes.preferredName.trim(),
            'phone': changes.phone.trim().isEmpty
                ? null
                : normalizeProfilePhone(changes.phone),
            'avatar_variant': changes.avatarVariant,
            'avatar_path': changes.removePhoto ? null : newPath ?? oldPath,
          })
          .eq('id', id)
          .eq('updated_at', previous['updated_at'])
          .select('id');
      if (saved.isEmpty) {
        throw const ProfileException(
          'Profil berubah atau sesi habis. Muat ulang sebelum menyimpan.',
        );
      }
      committed = true;
      // Foto lama baru dibersihkan sesudah referensi baru tersimpan.
      if (oldPath != null && (newPath != null || changes.removePhoto)) {
        try {
          await client.storage.from(bucket).remove([oldPath]);
        } catch (_) {
          /* Sisa berkas tetap privat; admin dapat membersihkannya. */
        }
      }
      return await load();
    } catch (_) {
      if (!committed && newPath != null) {
        try {
          await client.storage.from(bucket).remove([newPath]);
        } catch (_) {
          /* Pertahankan kesalahan utama. */
        }
      }
      if (committed) {
        throw const ProfileException(
          'Perubahan sudah tersimpan, tetapi pembacaan ulang gagal. Tutup editor lalu tekan Muat ulang; jangan unggah ulang fotonya.',
        );
      }
      rethrow;
    }
  }
}
