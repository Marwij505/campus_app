// Semua operasi memakai JWT pengguna; filter UUID melengkapi, bukan mengganti, RLS.
import 'dart:typed_data';

import 'profile_photo.dart';
import 'account_operation.dart';
import 'profile_phone.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'profile_repository.dart';
import 'student_profile.dart';
import 'biodata_repository.dart';

class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this.client, {this.sessionGeneration});
  final SupabaseClient client;
  final int Function()? sessionGeneration;
  @override
  late final BiodataRepository biodata = BiodataRepository(
    client,
    sessionGeneration: sessionGeneration,
  );
  static const bucket = 'student-avatars';
  String get _id =>
      client.auth.currentUser?.id ??
      (throw const ProfileException('Sesi berakhir. Silakan masuk kembali.'));
  @override
  Future<StudentProfile> load() async {
    final operation = AccountOperation(client, sessionGeneration);
    final id = _id;
    final p = await client.from('profiles').select().eq('id', id).maybeSingle();
    operation.check();
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
        photo = await operation.download(bucket, p['avatar_path'] as String);
      } catch (_) {
        /* Foto gagal tidak menghilangkan identitas atau referensi server. */
      }
    }
    operation.check();
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
    final operation = AccountOperation(client, sessionGeneration);
    final id = _id;
    final previous = await client
        .from('profiles')
        .select('avatar_path,updated_at')
        .eq('id', id)
        .single();
    operation.check();
    if (changes.expectedVersion == null ||
        previous['updated_at'] != changes.expectedVersion) {
      throw const ProfileConflict();
    }
    final oldPath = previous['avatar_path'] as String?;
    String? newPath;
    var committed = false;
    var metadataStarted = false;
    try {
      if (changes.photo != null) {
        final photo = await ProfilePhoto.prepare(changes.photo!);
        const extension = 'jpg';
        operation.check();
        newPath = '$id/${AccountOperation.newId()}.$extension';
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
      operation.check();
      metadataStarted = true;
      // Bandingkan versi editor, bukan snapshot yang baru dibaca saat Simpan.
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
          .eq('updated_at', changes.expectedVersion!)
          .select('id');
      if (saved.isEmpty) {
        throw const ProfileConflict();
      }
      committed = true;
      // Foto lama baru dibersihkan sesudah referensi baru tersimpan.
      if (oldPath != null && (newPath != null || changes.removePhoto)) {
        await operation.cleanup(bucket, oldPath);
      }
      operation.check();
      return await load();
    } catch (error) {
      if (!committed &&
          newPath != null &&
          metadataStarted &&
          AccountOperation.rejected(error)) {
        await operation.cleanup(bucket, newPath);
      }
      if (committed) {
        throw const ProfileException(
          'Perubahan sudah tersimpan, tetapi pembacaan ulang gagal. Tutup editor lalu tekan Muat ulang; jangan unggah ulang fotonya.',
        );
      }
      if (!AccountOperation.rejected(error) &&
          (metadataStarted || newPath != null)) {
        // Referensi bisa sudah tersimpan meskipun respons hilang. Pertahankan
        // objek privat sampai pengguna memuat ulang; jangan mencoba ulang otomatis.
        throw const ProfileUncertain();
      }
      rethrow;
    }
  }
}
