// Validasi profil, pembatasan payload edit, dan jawaban identitas tanpa jaringan AI.
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:campus_app/data/profile_repository.dart';
import 'package:campus_app/data/student_profile.dart';
import 'package:campus_app/data/supabase_profile_repository.dart';
import 'package:campus_app/features/chatbot/chat_controller.dart';
import 'package:campus_app/features/chatbot/profile_answers.dart';

import 'support/supabase_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SupabaseFixture server;
  setUp(() => server = SupabaseFixture());
  tearDown(() => server.dispose());
  StudentProfile profile() =>
      StudentProfile.fromRows(server.profile, server.student);
  // Gambar benar-benar didekode; bukan sekadar ekstensi atau signature palsu.
  Future<Uint8List> png() async {
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawColor(const ui.Color(0xff123456), ui.BlendMode.src);
    final picture = recorder.endRecording();
    final image = await picture.toImage(2, 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    picture.dispose();
    return data!.buffer.asUint8List();
  }

  test('NULL tetap belum diketahui; varian lama memakai netral', () {
    server.profile['avatar_variant'] = 'legacy';
    final p = profile();
    expect(p.avatarVariant, 'neutral');
    expect(p.gpa, isNull);
    expect(p.entryYear, isNull);
    expect(p.semester, isNull);
    expect(p.verificationStatus, 'unverified');
    server.profile['preferred_name'] = null;
    expect(profile().greetingName, 'Prismatine Dante Viergo');
    server.student['user_id'] = 'other';
    expect(profile, throwsFormatException);
  });
  test('Panggilan opsional dan telepon/varian divalidasi', () {
    expect(
      const ProfileChanges(
        preferredName: '',
        phone: '',
        avatarVariant: 'male',
      ).validate(),
      isNull,
    );
    expect(
      ProfileChanges(
        preferredName: 'a' * 51,
        phone: '',
        avatarVariant: 'male',
      ).validate(),
      isNotNull,
    );
    expect(
      const ProfileChanges(
        preferredName: 'Dante',
        phone: '08invalid',
        avatarVariant: 'female',
      ).validate(),
      isNotNull,
    );
    expect(
      const ProfileChanges(
        preferredName: 'Dante',
        phone: '+6281234567890',
        avatarVariant: 'admin',
      ).validate(),
      isNotNull,
    );
  });
  test('Simpan hanya mengirim field yang diizinkan dan varian tidak menghapus foto', () async {
    await server.client.auth.setSession('test-refresh');
    final repo = SupabaseProfileRepository(server.client);
    final p = await repo.save(
      const ProfileChanges(
        preferredName: ' Dante Baru ',
        phone: '',
        avatarVariant: 'female',
      ),
    );
    expect(p.preferredName, 'Dante Baru');
    expect(p.name, 'Prismatine Dante Viergo');
    expect(p.nim, '20240801001');
    final patch = server.requests.firstWhere((r) => r.method == 'PATCH');
    expect((jsonDecode(patch.body) as Map).keys.toSet(), {
      'preferred_name',
      'phone',
      'avatar_variant',
      'avatar_path',
    });
    server.profile['avatar_path'] = '${SupabaseFixture.id}/existing.png';
    await repo.save(
      const ProfileChanges(
        preferredName: '',
        phone: '',
        avatarVariant: 'neutral',
      ),
    );
    expect(server.profile['avatar_path'], '${SupabaseFixture.id}/existing.png');
    expect(server.profile['preferred_name'], isNull);
  });
  test('Simpan gagal tidak mengganti profil tersimpan', () async {
    await server.client.auth.setSession('test-refresh');
    server.failSave = true;
    await expectLater(
      SupabaseProfileRepository(server.client).save(
        const ProfileChanges(
          preferredName: 'Gagal',
          phone: '',
          avatarVariant: 'female',
        ),
      ),
      throwsA(anything),
    );
    expect(server.profile['preferred_name'], 'Dante');
  });
  test(
    'Foto kosong, besar, signature palsu dan gambar rusak ditolak',
    () async {
      for (final bytes in [
        Uint8List(0),
        Uint8List(2097153),
        Uint8List.fromList([1, 2, 3]),
        Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10, 0, 0]),
      ]) {
        await expectLater(
          SupabaseProfileRepository.validatePhoto(bytes),
          throwsA(isA<ProfileException>()),
        );
      }
    },
  );
  test('Foto baru disimpan sebelum foto lama dihapus; hapus foto kembali ke avatar', () async {
    await server.client.auth.setSession('test-refresh');
    server.photoBytes = await png();
    server.profile['avatar_path'] = '${SupabaseFixture.id}/old.png';
    final repo = SupabaseProfileRepository(server.client);
    final saved = await repo.save(
      ProfileChanges(
        preferredName: 'Dante',
        phone: '',
        avatarVariant: 'male',
        photo: server.photoBytes,
      ),
    );
    expect(saved.avatarBytes, server.photoBytes);
    expect(saved.avatarPath, isNot(endsWith('/old.png')));
    final patch = server.requests.indexWhere((r) => r.method == 'PATCH');
    final deletion = server.requests.indexWhere((r) => r.method == 'DELETE');
    expect(deletion, greaterThan(patch));
    expect(server.requests[deletion].body, contains('old.png'));
    final removed = await repo.save(
      const ProfileChanges(
        preferredName: 'Dante',
        phone: '',
        avatarVariant: 'female',
        removePhoto: true,
      ),
    );
    expect(removed.avatarPath, isNull);
    expect(removed.avatarBytes, isNull);
    expect(removed.avatarVariant, 'female');
  });
  test(
    'PATCH gagal membersihkan unggahan baru dan mempertahankan foto lama',
    () async {
      await server.client.auth.setSession('test-refresh');
      server.photoBytes = await png();
      server.profile['avatar_path'] = '${SupabaseFixture.id}/old.png';
      server.failSave = true;
      await expectLater(
        SupabaseProfileRepository(server.client).save(
          ProfileChanges(
            preferredName: 'Dante',
            phone: '',
            avatarVariant: 'female',
            photo: server.photoBytes,
          ),
        ),
        throwsA(anything),
      );
      expect(server.profile['avatar_path'], endsWith('/old.png'));
      final deletion = server.requests.singleWhere((r) => r.method == 'DELETE');
      expect(deletion.body, isNot(contains('old.png')));
    },
  );
  test(
    'Pertanyaan identitas memakai profil, bukan tebakan atau materi belajar',
    () {
      final p = profile();
      for (final input in ['nama', 'namaku', 'siapa saya', 'nama saya siapa']) {
        expect(
          ProfileAnswers.reply(input, p),
          contains('Prismatine Dante Viergo'),
        );
      }
      expect(ProfileAnswers.reply('nim', p), contains('20240801001'));
      expect(
        ProfileAnswers.reply('jurusan', p),
        contains('Teknik Informatika'),
      );
      expect(ProfileAnswers.reply('semester', p), contains('belum tersedia'));
      expect(ProfileAnswers.reply('ipk', p), contains('belum diintegrasikan'));
      expect(ProfileAnswers.reply('nim?', p), contains('pilih'));
      expect(
        ProfileAnswers.reply('ganti nama saya menjadi Budi', p),
        contains('pengelola'),
      );
      expect(
        ProfileAnswers.reply('nama mahasiswa lain', p),
        contains('diizinkan'),
      );
      for (final input in [
        'nama variabel',
        'materi semester 1',
        'apa itu IPK',
        'nama dosen',
      ]) {
        expect(ProfileAnswers.reply(input, p), isNull);
      }
    },
  );
  test(
    'Chat memuat identitas draf dan logout menghapus profil serta isinya',
    () async {
      final chat = ChatController();
      chat.updateProfile(profile());
      expect(chat.letter.fields['NIM'], '20240801001');
      await chat.send('nim');
      expect(chat.messages.last.text, contains('20240801001'));
      chat.newConversation();
      expect(chat.messages.single.text, contains('Dante'));
      chat.dispose();
      expect(chat.profile, isNull);
      expect(chat.messages, isEmpty);
      expect(chat.letter.fields, isEmpty);
    },
  );
  test(
    'Email kampus, pribadi, dan login tidak tertukar dengan lokasi kampus',
    () {
      server.student['campus_email'] = 'dante@example.edu';
      final p = StudentProfile.fromRows(
        server.profile,
        server.student,
        email: 'login@example.test',
      );
      expect(
        ProfileAnswers.reply('email kampus', p),
        contains('dante@example.edu'),
      );
      expect(
        ProfileAnswers.reply('email pribadi', p),
        contains('Biodata → Kontak'),
      );
      expect(ProfileAnswers.reply('email', p), contains('login@example.test'));
      expect(ProfileAnswers.reply('email', p), contains('dante@example.edu'));
      expect(ProfileAnswers.reply('kampus', p), contains('Lokasi kampus'));
    },
  );
}
