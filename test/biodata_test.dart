// Uji isi gambar, normalisasi nomor, penyimpanan bagian, dan konflik versi.
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:campus_app/data/biodata_fields.dart';
import 'package:campus_app/data/biodata_repository.dart';
import 'package:campus_app/data/profile_photo.dart';
import 'package:campus_app/data/profile_phone.dart';
import 'package:campus_app/data/profile_repository.dart';

import 'support/supabase_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Nomor lokal, spasi, dan kode negara disimpan seragam', () {
    for (final value in [
      '0812 3456 7890',
      '0812-3456-7890',
      '6281234567890',
      '+62 (812) 34567890',
    ]) {
      expect(validProfilePhone(value), isTrue);
      expect(normalizeProfilePhone(value), '+6281234567890');
    }
    expect(normalizeProfilePhone('+1 202 555 0123'), '+12025550123');
    expect(validProfilePhone('telepon08'), isFalse);
    expect(validProfilePhone('081'), isFalse);
  });
  test(
    'Nama unduhan tidak membawa path, nama khusus Windows, atau ekstensi palsu',
    () {
      expect(
        BiodataRepository.safeDocumentName(
          '../../surat.exe',
          'application/pdf',
        ),
        'surat.pdf',
      );
      expect(
        BiodataRepository.safeDocumentName(r'C:\temp\KTP.png', 'image/jpeg'),
        'KTP.jpg',
      );
      expect(
        BiodataRepository.safeDocumentName('CON.pdf', 'application/pdf'),
        'dokumen-CON.pdf',
      );
      expect(
        () => BiodataRepository.safeDocumentName('', 'application/pdf'),
        throwsA(isA<ProfileException>()),
      );
    },
  );
  test(
    'Foto JPG PNG GIF BMP TIFF ICO menjadi JPEG tanpa metadata kamera',
    () async {
      final original = img.Image(width: 16, height: 24, numChannels: 4);
      img.fill(original, color: img.ColorRgba8(12, 80, 180, 128));
      for (final bytes in [
        img.encodeJpg(original),
        img.encodePng(original),
        img.encodeGif(original),
        img.encodeBmp(original),
        img.encodeTiff(original),
        img.encodeIco(original),
      ]) {
        final result = await ProfilePhoto.prepare(Uint8List.fromList(bytes));
        final decoded = img.decodeJpg(result)!;
        expect(decoded.width, 16);
        expect(decoded.height, 24);
        expect(result.length, lessThan(2 * 1024 * 1024));
      }
    },
  );
  test(
    'Foto besar diperkecil, konten rusak dan batas ukuran ditolak',
    () async {
      final bytes = img.encodePng(img.Image(width: 2048, height: 1024));
      final result = img.decodeJpg(await ProfilePhoto.prepare(bytes))!;
      expect(result.width, 1024);
      expect(result.height, 512);
      for (final bad in [
        Uint8List(0),
        Uint8List(ProfilePhoto.maxInputBytes + 1),
        Uint8List.fromList([1, 2, 3]),
      ]) {
        await expectLater(
          ProfilePhoto.prepare(bad),
          throwsA(isA<ProfileException>()),
        );
      }
    },
  );
  test('Validasi NIK, NISN, nilai, email dan tanggal kalender', () {
    BiodataField field(String key) =>
        biodataSections.expand((s) => s.fields).firstWhere((f) => f.key == key);
    expect(field('nik').validate('123'), isNotNull);
    expect(field('nik').validate('1234567890123456'), isNull);
    expect(field('nisn').validate('0012345678'), isNull);
    expect(field('average_score').validate('NaN'), isNotNull);
    expect(field('average_score').validate('100,01'), isNotNull);
    expect(field('average_score').serialize('82,5'), 82.5);
    expect(field('private_email').validate('a@'), isNotNull);
    expect(field('birth_date').validate('2025-02-30'), isNotNull);
    expect(field('birth_date').validate('2004-02-29'), isNull);
    expect(field('birth_date').validate('2999-01-01'), isNotNull);
  });
  test(
    'Setiap bagian menyimpan hanya kolomnya; konflik tidak menimpa',
    () async {
      final server = SupabaseFixture();
      addTearDown(server.dispose);
      await server.client.auth.setSession('test-refresh');
      final repo = BiodataRepository(server.client);
      for (final section in biodataSections) {
        expect(await repo.loadSection(section), isEmpty);
        final values = <String, String>{
          'role': 'admin',
          'phone': '081234567890',
        };
        final row = await repo.saveSection(section, values, null);
        expect(row['role'], isNull);
        expect(row['user_id'], SupabaseFixture.id);
        expect(await repo.loadSection(section), row);
        server.conflict = true;
        await expectLater(
          repo.saveSection(section, values, row['updated_at'] as String),
          throwsA(isA<ProfileException>()),
        );
        server.conflict = false;
      }
      expect(server.profile['phone'], '+6281234567890');
    },
  );
  test('Lampiran gagal tidak menghapus berkas lama; metadata sukses mendahului hapus', () async {
    final server = SupabaseFixture();
    addTearDown(server.dispose);
    await server.client.auth.setSession('test-refresh');
    final repo = BiodataRepository(server.client);
    final bytes = Uint8List.fromList('%PDF-1.7\n test'.codeUnits);
    await repo.uploadDocument('ktp', 'KTP.pdf', bytes, null);
    final first = (await repo.documents()).single;
    final old = first['path'];
    server.conflict = true;
    await expectLater(
      repo.uploadDocument('ktp', 'baru.pdf', bytes, first),
      throwsA(isA<ProfileException>()),
    );
    expect((await repo.documents()).single['path'], old);
    server.conflict = false;
    await repo.uploadDocument('ktp', 'baru.pdf', bytes, first);
    final saved = (await repo.documents()).single;
    expect(saved['path'], isNot(old));
    await repo.deleteDocument(saved);
    expect(await repo.documents(), isEmpty);
    expect(
      () => BiodataRepository.documentMime(
        Uint8List.fromList('executable'.codeUnits),
      ),
      throwsA(isA<ProfileException>()),
    );
  });
}
