// Akses data bagian biodata, dengan JWT pemilik dan pemeriksaan sesi di database.
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'biodata_fields.dart';
import 'profile_repository.dart';

class BiodataRepository {
  BiodataRepository(this.client);
  final SupabaseClient client;
  String get userId =>
      client.auth.currentUser?.id ??
      (throw const ProfileException('Sesi berakhir. Silakan masuk kembali.'));

  Future<Map<String, dynamic>> loadSection(BiodataSection section) async {
    final id = userId;
    final row = await client
        .from(section.table)
        .select()
        .eq('user_id', id)
        .maybeSingle()
        .timeout(const Duration(seconds: 20));
    if (id != userId) {
      throw const ProfileException('Sesi berubah. Muat ulang halaman.');
    }
    return row ?? {};
  }

  Future<Map<String, dynamic>> saveSection(
    BiodataSection section,
    Map<String, String> values,
    String? version,
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

  Future<List<Map<String, dynamic>>> finance() => client
      .from('student_finance')
      .select()
      .eq('user_id', userId)
      .order('billed_on', ascending: false)
      .timeout(const Duration(seconds: 20));

  Future<List<Map<String, dynamic>>> documents() => client
      .from('student_documents')
      .select()
      .eq('user_id', userId)
      .order('kind')
      .timeout(const Duration(seconds: 20));

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
    final id = userId;
    final extension = {
      'application/pdf': 'pdf',
      'image/jpeg': 'jpg',
      'image/png': 'png',
      'application/msword': 'doc',
    }[mime]!;
    final path =
        '$id/$kind-${DateTime.now().microsecondsSinceEpoch}.$extension';
    final safeName = safeDocumentName(filename, mime);
    await client.storage
        .from(documentBucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: mime, upsert: false),
        );
    try {
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
          throw const ProfileException(
            'Berkas berubah. Muat ulang sebelum mencoba lagi.',
          );
        }
      }
    } catch (_) {
      // Unggahan baru dibuang bila metadata gagal; berkas lama tetap tersedia.
      try {
        await client.storage.from(documentBucket).remove([path]);
      } catch (_) {}
      rethrow;
    }
    if (previous != null) {
      try {
        await client.storage.from(documentBucket).remove([
          previous['path'] as String,
        ]);
      } catch (_) {}
    }
  }

  Future<Uint8List> downloadDocument(Map<String, dynamic> row) => client.storage
      .from(documentBucket)
      .download(row['path'] as String)
      .timeout(const Duration(seconds: 20));

  Future<void> deleteDocument(Map<String, dynamic> row) async {
    final removed = await client
        .from('student_documents')
        .delete()
        .eq('user_id', userId)
        .eq('kind', row['kind'])
        .eq('updated_at', row['updated_at'])
        .select();
    if (removed.isEmpty) {
      throw const ProfileException(
        'Berkas berubah atau sesi habis. Muat ulang dahulu.',
      );
    }
    // Metadata hilang lebih dulu agar aplikasi tidak menawarkan berkas yang dihapus.
    try {
      await client.storage.from(documentBucket).remove([row['path'] as String]);
    } catch (_) {}
  }
}
