// Akses data bagian biodata, dengan JWT pemilik dan pemeriksaan sesi di database.
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'biodata_fields.dart';
import 'account_operation.dart';
import 'profile_repository.dart';

class BiodataRepository {
  BiodataRepository(this.client, {this.sessionGeneration});
  final SupabaseClient client;
  final int Function()? sessionGeneration;
  String get userId =>
      client.auth.currentUser?.id ??
      (throw const ProfileException('Sesi berakhir. Silakan masuk kembali.'));

  Future<Map<String, dynamic>> loadSection(BiodataSection section) async {
    final operation = AccountOperation(client, sessionGeneration);
    if (section.key == 'biodata') {
      try {
        final result = await client
            .rpc('load_student_biodata')
            .timeout(const Duration(seconds: 20));
        operation.check();
        if (result == null) {
          throw const ProfileException(
            'Akses biodata tidak tersedia. Masuk ulang.',
          );
        }
        return Map<String, dynamic>.from(result as Map);
      } on PostgrestException catch (e) {
        if (e.code == 'PGRST202' || e.code == '42883') {
          throw const ProfileException(
            'Layanan penyimpanan biodata perlu diperbarui oleh pengelola.',
          );
        }
        rethrow;
      }
    }
    final id = userId;
    final row = await client
        .from(section.table)
        .select()
        .eq('user_id', id)
        .maybeSingle()
        .timeout(const Duration(seconds: 20));
    operation.check();
    return row ?? {};
  }

  Future<Map<String, dynamic>> saveSection(
    BiodataSection section,
    Map<String, String> values,
    String? version, {
    String? profileVersion,
  }) async {
    final operation = AccountOperation(client, sessionGeneration);
    try {
      final row = await _saveSection(section, values, version, profileVersion);
      operation.check();
      return row;
    } catch (error) {
      if (error is ProfileException || AccountOperation.rejected(error)) {
        rethrow;
      }
      throw const ProfileUncertain();
    }
  }

  Future<Map<String, dynamic>> _saveSection(
    BiodataSection section,
    Map<String, String> values,
    String? version,
    String? profileVersion,
  ) async {
    final id = userId;
    final data = <String, dynamic>{};
    // Daftar kolom berasal dari aplikasi, bukan nama kolom bebas dari masukan pengguna.
    for (final field in section.fields) {
      final value = values[field.key] ?? '';
      final error = field.validate(value);
      if (error != null) throw ProfileException('${field.label}: $error');
      data[field.key] = field.serialize(value);
    }
    if (section.key == 'accessibility' && data['has_disability'] != 'Ya') {
      data['description'] = null;
      data['accommodations'] = null;
    }
    if (section.key == 'biodata') {
      if (profileVersion == null) throw const ProfileConflict();
      try {
        final row = await client
            .rpc(
              'save_student_biodata',
              params: {
                'p_values': data,
                'p_expected_profile_version': profileVersion,
                'p_expected_biodata_version': version,
              },
            )
            .timeout(const Duration(seconds: 20));
        return Map<String, dynamic>.from(row as Map);
      } on PostgrestException catch (e) {
        if (e.code == 'PT409' || e.code == '40001' || e.code == '23505') {
          throw const ProfileConflict();
        }
        if (e.code == 'PGRST202' || e.code == '42883') {
          throw const ProfileException(
            'Layanan penyimpanan biodata perlu diperbarui oleh pengelola.',
          );
        }
        rethrow;
      }
    }
    if (version == null) {
      // INSERT tidak menimpa data bila tab lain lebih dahulu membuat barisnya.
      return await client
          .from(section.table)
          .insert({'user_id': id, ...data})
          .select()
          .single()
          .timeout(const Duration(seconds: 20));
    }
    final rows = await client
        .from(section.table)
        .update(data)
        .eq('user_id', id)
        .eq('updated_at', version)
        .select()
        .timeout(const Duration(seconds: 20));
    if (rows.isEmpty) {
      throw const ProfileException(
        'Data berubah di tempat lain atau sesi habis. Salin isian penting, lalu muat ulang.',
      );
    }
    return rows.single;
  }

  Future<T> _read<T>(Future<T> Function() read) async {
    final operation = AccountOperation(client, sessionGeneration);
    final result = await read();
    operation.check();
    return result;
  }

  Future<List<Map<String, dynamic>>> finance() => _read(() async {
    try {
      final value = await client
          .rpc('m2_finance')
          .timeout(const Duration(seconds: 20));
      return (value as List)
          .map((r) => Map<String, dynamic>.from(r as Map))
          .toList();
    } on PostgrestException catch (e) {
      // Preserve M1 reads until the additive M2 backend has been authorized/deployed.
      if (e.code != 'PGRST202' && e.code != '42883') rethrow;
      return await client
          .from('student_finance')
          .select()
          .eq('user_id', userId)
          .order('billed_on', ascending: false)
          .timeout(const Duration(seconds: 20));
    }
  });

  Future<List<Map<String, dynamic>>> documents() => _read(
    () => client
        .from('student_documents')
        .select()
        .eq('user_id', userId)
        .order('kind')
        .timeout(const Duration(seconds: 20)),
  );

  static const documentBucket = 'student-documents';
  static const documentKinds = {
    'ktp': 'File KTP',
    'diploma': 'File Ijazah',
    'kk': 'File KK',
    'payment_statement': 'Surat Pernyataan Pembayaran Biaya Kuliah',
    'passport': 'File Paspor',
  };

  /// Nama ekspor tidak boleh menjadi path atau memakai ekstensi executable.
  /// MIME berasal dari pemeriksaan isi; nama lama dari database juga dibersihkan.
  static String safeDocumentName(String filename, String mime) {
    final extension = {
      'application/pdf': 'pdf',
      'image/jpeg': 'jpg',
      'image/png': 'png',
      'application/msword': 'doc',
    }[mime];
    if (extension == null) {
      throw const ProfileException('Format berkas tidak didukung.');
    }
    var name = filename
        .split(RegExp(r'[/\\]'))
        .last
        .replaceAll(RegExp(r'[\x00-\x1F\x7F<>:"|?*]'), '')
        .trim();
    if (name.isEmpty || name.length > 200) {
      throw const ProfileException('Nama berkas harus berisi 1–200 karakter.');
    }
    name = name
        .replaceFirst(RegExp(r'\.[^.]*$'), '')
        .replaceAll(RegExp(r'[. ]+$'), '');
    if (name.isEmpty) name = 'dokumen';
    if (RegExp(
      r'^(con|prn|aux|nul|com[1-9]|lpt[1-9])$',
      caseSensitive: false,
    ).hasMatch(name)) {
      name = 'dokumen-$name';
    }
    if (name.length > 195) name = name.substring(0, 195);
    return '$name.$extension';
  }

  /// Pemeriksaan isi awal menghindari berkas executable yang hanya diganti ekstensi.
  static String documentMime(Uint8List bytes) {
    if (bytes.isEmpty || bytes.length > 512 * 1024) {
      throw const ProfileException('Berkas maksimal 0,5 MB.');
    }
    bool starts(List<int> prefix) =>
        bytes.length >= prefix.length &&
        List.generate(
          prefix.length,
          (i) => bytes[i] == prefix[i],
        ).every((v) => v);
    if (starts([37, 80, 68, 70, 45])) return 'application/pdf';
    if (starts([255, 216, 255])) return 'image/jpeg';
    if (starts([137, 80, 78, 71, 13, 10, 26, 10])) return 'image/png';
    if (starts([208, 207, 17, 224, 161, 177, 26, 225])) {
      return 'application/msword';
    }
    throw const ProfileException(
      'Gunakan berkas PDF, JPG, PNG, atau DOC yang valid.',
    );
  }

  Future<void> uploadDocument(
    String kind,
    String filename,
    Uint8List bytes,
    Map<String, dynamic>? previous,
  ) async {
    if (!documentKinds.containsKey(kind)) {
      throw const ProfileException('Jenis berkas tidak dikenal.');
    }
    final mime = documentMime(bytes);
    final operation = AccountOperation(client, sessionGeneration);
    final id = userId;
    final extension = {
      'application/pdf': 'pdf',
      'image/jpeg': 'jpg',
      'image/png': 'png',
      'application/msword': 'doc',
    }[mime]!;
    final path = '$id/$kind-${AccountOperation.newId()}.$extension';
    final safeName = safeDocumentName(filename, mime);
    try {
      await client.storage
          .from(documentBucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: mime, upsert: false),
          );
    } catch (_) {
      // Upload mungkin selesai di server. Tidak ada metadata baru atau cleanup.
      throw const ProfileUncertain();
    }
    try {
      operation.check();
      final data = {
        'path': path,
        'file_name': safeName,
        'mime_type': mime,
        'size_bytes': bytes.length,
      };
      if (previous == null) {
        await client.from('student_documents').insert({
          'user_id': id,
          'kind': kind,
          ...data,
        });
      } else {
        final rows = await client
            .from('student_documents')
            .update(data)
            .eq('user_id', id)
            .eq('kind', kind)
            .eq('updated_at', previous['updated_at'])
            .select();
        if (rows.isEmpty) {
          throw const ProfileConflict();
        }
      }
    } catch (error) {
      // Hanya penolakan pasti membuktikan objek baru bukan referensi aktif.
      if (AccountOperation.rejected(error)) {
        await operation.cleanup(documentBucket, path);
        rethrow;
      }
      throw const ProfileUncertain();
    }
    if (previous != null) {
      await operation.cleanup(documentBucket, previous['path'] as String);
    }
    operation.check();
  }

  Future<Uint8List> downloadDocument(Map<String, dynamic> row) => _read(
    () => AccountOperation(
      client,
      sessionGeneration,
    ).download(documentBucket, row['path'] as String),
  );

  Future<void> deleteDocument(Map<String, dynamic> row) async {
    final operation = AccountOperation(client, sessionGeneration);
    try {
      final removed = await client
          .from('student_documents')
          .delete()
          .eq('user_id', userId)
          .eq('kind', row['kind'])
          .eq('updated_at', row['updated_at'])
          .select();
      if (removed.isEmpty) {
        throw const ProfileConflict();
      }
      // Metadata hilang lebih dulu agar aplikasi tidak menawarkan berkas yang dihapus.
      await operation.cleanup(documentBucket, row['path'] as String);
      operation.check();
    } catch (error) {
      if (AccountOperation.rejected(error)) rethrow;
      throw const ProfileUncertain();
    }
  }
}
