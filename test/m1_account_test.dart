// Fault injection memakai SDK asli; seluruh HTTP terisolasi, tanpa akun nyata.
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:campus_app/data/auth_service.dart';
import 'package:campus_app/data/biodata_repository.dart';
import 'package:campus_app/data/biodata_fields.dart';
import 'package:campus_app/data/profile_repository.dart';
import 'package:campus_app/data/supabase_auth_service.dart';
import 'package:campus_app/data/supabase_profile_repository.dart';

import 'support/supabase_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SupabaseFixture server;
  late SupabaseAuthService auth;
  late SupabaseProfileRepository profiles;
  late BiodataRepository documents;
  test('Unduhan berkas memakai gateway; sesi ditolak tidak memakai fallback Storage', () async {
    final fixture = SupabaseFixture();
    final service = SupabaseAuthService(fixture.client);
    await service.login(
      identity: '20240801001',
      password: 'test-only-password',
    );
    final repository = BiodataRepository(fixture.client);
    fixture.photoBytes = Uint8List.fromList([1, 2, 3]);
    final row = {'path': '${SupabaseFixture.id}/test.pdf'};
    expect(await repository.downloadDocument(row), [1, 2, 3]);
    fixture.sessionValid = false;
    await expectLater(
      repository.downloadDocument(row),
      throwsA(isA<ProfileException>()),
    );
    expect(
      fixture.requests
          .where((r) => r.url.path.endsWith('/functions/v1/private-file'))
          .length,
      2,
    );
    expect(
      fixture.requests.where(
        (r) => r.method == 'GET' && r.url.path.contains('/storage/v1/'),
      ),
      isEmpty,
    );
    service.dispose();
    await fixture.client.dispose();
  });
  setUp(() async {
    server = SupabaseFixture();
    auth = SupabaseAuthService(server.client);
    await auth.login(identity: '20240801001', password: 'test-only-password');
    profiles = auth.profiles as SupabaseProfileRepository;
    documents = profiles.biodata;
  });
  tearDown(() async {
    auth.dispose();
    await server.dispose();
  });
  Uint8List photo() =>
      Uint8List.fromList(img.encodePng(img.Image(width: 2, height: 2)));
  ProfileChanges changes({
    String? version,
    String name = 'Baru',
    bool image = false,
  }) => ProfileChanges(
    expectedVersion: version ?? server.profile['updated_at'] as String,
    preferredName: name,
    phone: '',
    avatarVariant: 'female',
    photo: image ? photo() : null,
  );
  Future<void> upload([Map<String, dynamic>? previous]) =>
      documents.uploadDocument(
        'ktp',
        'uji.pdf',
        Uint8List.fromList('%PDF-1.4 test'.codeUnits),
        previous,
      );
  Matcher uncertain = throwsA(isA<ProfileUncertain>());

  for (final exists in [false, true]) {
    test(
      'M1-07 RPC menolak telepon snapshot lama; baris awal $exists',
      () async {
        final section = biodataSections.first;
        var snapshot = await documents.loadSection(section);
        if (exists) {
          snapshot = await documents.saveSection(
            section,
            {'phone': '081111111111'},
            null,
            profileVersion: snapshot['_profile_version'] as String,
          );
        }
        final profile = await profiles.load();
        await profiles.save(
          ProfileChanges(
            expectedVersion: profile.version,
            preferredName: 'Dante',
            phone: '082222222222',
            avatarVariant: 'male',
          ),
        );
        await expectLater(
          documents.saveSection(
            section,
            {'phone': '081111111111'},
            snapshot['updated_at'] as String?,
            profileVersion: snapshot['_profile_version'] as String,
          ),
          throwsA(isA<ProfileConflict>()),
        );
        expect(server.profile['phone'], '+6282222222222');
        snapshot = await documents.loadSection(section);
        expect(snapshot['phone'], '+6282222222222');
        await documents.saveSection(
          section,
          {'phone': '083333333333'},
          snapshot['updated_at'] as String?,
          profileVersion: snapshot['_profile_version'] as String,
        );
        await expectLater(
          profiles.save(changes(version: profile.version)),
          throwsA(isA<ProfileConflict>()),
        );
        expect(server.profile['phone'], '+6283333333333');
      },
    );
  }

  test(
    'M1-07 RPC belum dipasang tidak jatuh ke penulisan tabel langsung',
    () async {
      server.missingBiodataRpc = true;
      await expectLater(
        documents.loadSection(biodataSections.first),
        throwsA(
          isA<ProfileException>().having(
            (e) => e.message,
            'pesan',
            contains('perlu diperbarui'),
          ),
        ),
      );
      await expectLater(
        documents.saveSection(
          biodataSections.first,
          {},
          null,
          profileVersion: server.profile['updated_at'] as String,
        ),
        throwsA(
          isA<ProfileException>().having(
            (e) => e.message,
            'pesan',
            contains('perlu diperbarui'),
          ),
        ),
      );
      expect(
        server.requests.where((r) => r.url.path.endsWith('/student_biodata')),
        isEmpty,
      );
    },
  );

  test(
    'M1-01 snapshot editor lama ditolak dan versi mikrodetik utuh',
    () async {
      server.profile['updated_at'] = '2026-11-09T00:00:00.123456+00:00';
      final original = await profiles.load();
      expect(original.version, server.profile['updated_at']);
      await profiles.save(changes(version: original.version, name: 'Pemenang'));
      await expectLater(
        profiles.save(changes(version: original.version, image: true)),
        throwsA(isA<ProfileConflict>()),
      );
      expect(server.profile['preferred_name'], 'Pemenang');
      expect(server.objects, isEmpty);
      final latest = await profiles.load();
      await profiles.save(
        changes(version: latest.version, name: 'Ditinjau ulang'),
      );
      expect(server.profile['preferred_name'], 'Ditinjau ulang');
    },
  );

  test('M1-01 dua simpan bersamaan hanya satu menang', () async {
    final edit = changes();
    final outcomes = await Future.wait(
      List.generate(2, (_) async {
        try {
          await profiles.save(edit);
          return true;
        } on ProfileConflict {
          return false;
        }
      }),
    );
    expect(outcomes.where((v) => v).length, 1);
  });

  test('M1-01 versi hilang ditolak tanpa PATCH', () async {
    await expectLater(
      profiles.save(
        const ProfileChanges(
          expectedVersion: null,
          preferredName: '',
          phone: '',
          avatarVariant: 'male',
        ),
      ),
      throwsA(isA<ProfileConflict>()),
    );
    expect(server.requests.where((r) => r.method == 'PATCH'), isEmpty);
  });

  for (final kind in ['foto', 'dokumen']) {
    test('M1-02 $kind metadata commit respons hilang mempertahankan objek aktif', () async {
      server.loseMetadataResponse = true;
      if (kind == 'foto') {
        await expectLater(profiles.save(changes(image: true)), uncertain);
        expect(
          server.objects,
          contains('student-avatars/${server.profile['avatar_path']}'),
        );
        server.loseMetadataResponse = false;
        expect((await profiles.load()).preferredName, 'Baru');
      } else {
        await expectLater(upload(), uncertain);
        expect(
          server.objects,
          contains(
            '${BiodataRepository.documentBucket}/${server.documentRows.single['path']}',
          ),
        );
      }
      expect(server.requests.where((r) => r.method == 'DELETE'), isEmpty);
    });

    test(
      'M1-02 $kind upload respons hilang tidak menulis metadata atau cleanup',
      () async {
        server.loseUploadResponse = true;
        await expectLater(
          kind == 'foto' ? profiles.save(changes(image: true)) : upload(),
          uncertain,
        );
        expect(server.objects.length, 1);
        expect(
          server.requests.where(
            (r) => r.method == 'DELETE' || r.method == 'PATCH',
          ),
          isEmpty,
        );
        expect(server.documentRows, isEmpty);
        expect(server.profile['avatar_path'], isNull);
      },
    );

    test('M1-02 $kind upload ditolak tidak mengubah metadata', () async {
      server.failUpload = true;
      await expectLater(
        kind == 'foto' ? profiles.save(changes(image: true)) : upload(),
        uncertain,
      );
      expect(server.objects, isEmpty);
      expect(server.profile['avatar_path'], isNull);
      expect(server.documentRows, isEmpty);
    });

    test(
      'M1-02 $kind penolakan metadata pasti membersihkan hanya objek baru',
      () async {
        server.failSave = true;
        await expectLater(
          kind == 'foto' ? profiles.save(changes(image: true)) : upload(),
          throwsA(anything),
        );
        expect(server.objects, isEmpty);
        expect(server.requests.where((r) => r.method == 'DELETE').length, 1);
      },
    );

    test(
      'M1-02 $kind gagal hapus lama tidak membatalkan metadata baru',
      () async {
        if (kind == 'foto') {
          await profiles.save(changes(image: true));
          final old = server.profile['avatar_path'];
          server.failDelete = true;
          await profiles.save(changes(image: true));
          expect(server.profile['avatar_path'], isNot(old));
        } else {
          await upload();
          final old = Map<String, dynamic>.from(server.documentRows.single);
          server.failDelete = true;
          await upload(old);
          expect(server.documentRows.single['path'], isNot(old['path']));
        }
        expect(server.objects.length, 2);
      },
    );

    test('M1-05 $kind logout saat upload mencegah tahap metadata', () async {
      server.uploadGate = Completer<void>();
      final pending = expectLater(
        kind == 'foto' ? profiles.save(changes(image: true)) : upload(),
        uncertain,
      );
      // Tunggu upload masuk ke fake transport, bukan waktu jaringan nyata.
      while (server.objects.isEmpty) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      await auth.logout();
      server.uploadGate!.complete();
      await pending;
      expect(server.requests.where((r) => r.method == 'PATCH'), isEmpty);
      expect(server.documentRows, isEmpty);
      expect(auth.currentUser, isNull);
    });
  }

  test(
    'M1-02 PATCH dokumen commit respons hilang mempertahankan pengganti',
    () async {
      await upload();
      final previous = Map<String, dynamic>.from(server.documentRows.single);
      server.loseMetadataResponse = true;
      await expectLater(upload(previous), uncertain);
      expect(server.documentRows.single['path'], isNot(previous['path']));
      expect(server.objects.length, 2);
    },
  );

  test(
    'M1-02 snapshot dokumen lama ditolak dan foto konflik tidak terpasang',
    () async {
      await upload();
      final previous = Map<String, dynamic>.from(server.documentRows.single);
      await upload(previous);
      final winner = server.documentRows.single['path'];
      await expectLater(upload(previous), throwsA(isA<ProfileConflict>()));
      expect(server.documentRows.single['path'], winner);
      server.conflict = true;
      await expectLater(
        profiles.save(changes(image: true)),
        throwsA(isA<ProfileConflict>()),
      );
      expect(server.profile['avatar_path'], isNull);
      expect(server.objects.length, 1);
    },
  );

  test(
    'M1-02 reload profil gagal setelah commit memberi hasil tersimpan',
    () async {
      server.failProfileReload = true;
      await expectLater(
        profiles.save(changes(image: true)),
        throwsA(
          isA<ProfileException>().having(
            (e) => e.message,
            'pesan',
            contains('sudah tersimpan'),
          ),
        ),
      );
      expect(
        server.objects,
        contains('student-avatars/${server.profile['avatar_path']}'),
      );
    },
  );

  test('M1-03 validasi password 12–256 konsisten sebelum jaringan', () async {
    final count = server.requests.length;
    for (final value in ['short', 'x' * 257]) {
      await expectLater(
        auth.changePassword(value),
        throwsA(isA<AuthException>()),
      );
    }
    expect(server.requests.length, count);
  });

  test('M1-03 perubahan password sukses tidak trim dan menutup sesi', () async {
    const password = '  test-only-password  ';
    await auth.changePassword(password);
    expect(server.changedPassword, password);
    expect(auth.hasSession, isFalse);
    expect(server.client.auth.currentSession, isNull);
  });

  test('M1-03 respons password hilang tidak memberi kepastian palsu', () async {
    server.losePasswordResponse = true;
    await expectLater(
      auth.changePassword('test-only-password'),
      throwsA(
        isA<AuthException>().having(
          (e) => e.message,
          'pesan',
          contains('belum dapat dipastikan'),
        ),
      ),
    );
    expect(server.changedPassword, 'test-only-password');
  });

  test('M1-03 password ditolak dibedakan dari respons tidak pasti', () async {
    server.passwordStatus = 422;
    await expectLater(
      auth.changePassword('test-only-password'),
      throwsA(
        isA<AuthException>().having(
          (e) => e.message,
          'pesan',
          contains('ditolak'),
        ),
      ),
    );
    expect(server.changedPassword, isNull);
  });

  test(
    'M1-05 respons password sesi lama tidak mengeluarkan sesi baru',
    () async {
      server.passwordGate = Completer<void>();
      final pending = expectLater(
        auth.changePassword('test-only-password'),
        throwsA(isA<AuthException>()),
      );
      await Future<void>.delayed(Duration.zero);
      await auth.logout();
      await auth.login(identity: '20240801001', password: 'test-only-password');
      server.passwordGate!.complete();
      await pending;
      expect(auth.hasSession, isTrue);
    },
  );

  test('M1-05 batas server dan akun nonaktif menutup akses', () async {
    server.expiry = server.serverNow;
    await auth.checkSession();
    expect(auth.hasSession, isFalse);
    server.expiry = server.serverNow.add(const Duration(minutes: 30));
    server.profile['is_enabled'] = false;
    await expectLater(
      auth.login(identity: '20240801001', password: 'test-only-password'),
      throwsA(isA<AuthException>()),
    );
    expect(auth.currentUser, isNull);
  });
}
