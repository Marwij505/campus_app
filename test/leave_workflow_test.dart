// Uji lintas peran memakai akun sintetis dan bukti uji; tidak menyentuh data kampus.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:campus_app/data/auth_service.dart';
import 'package:campus_app/data/student_profile.dart';
import 'package:campus_app/features/chatbot/chat_models.dart';
import 'package:campus_app/features/chatbot/chat_controller.dart';
import 'package:campus_app/features/chatbot/chat_policy.dart';
import 'package:campus_app/features/leave/leave_models.dart';
import 'package:campus_app/features/leave/leave_repository.dart';

const studentA = StudentProfile(nim: '20240801001');
const studentB = StudentProfile(nim: '20240801002');
const bap = StudentProfile(nim: 'BAP001', role: UserRole.bap);
const lecturerA = StudentProfile(nim: 'DOS001', role: UserRole.lecturer);
const lecturerB = StudentProfile(nim: 'DOS002', role: UserRole.lecturer);

LeaveDraft fillLeave(LeaveDraft draft) {
  draft.fields.addAll({
    'Nama': 'Mahasiswa Uji',
    'Program studi': 'Program Uji',
    'Jenis izin': 'Sakit',
    'Tanggal mulai': '2026-10-19',
    'Tanggal akhir': '2026-10-20',
    'Alasan': 'Tidak dapat mengikuti perkuliahan karena sakit.',
  });
  draft.classes
    ..clear()
    ..add(
      LeaveClass(
        course: 'MK001 - Mata Kuliah Uji',
        classCode: 'KLS-A',
        date: '2026-10-19',
        lecturerCode: 'DOS002',
      ),
    );
  draft.attachments
    ..clear()
    ..add(
      DraftAttachment(
        'bukti-uji.pdf',
        Uint8List.fromList(utf8.encode('%PDF-1.7\n%%EOF')),
      ),
    );
  return draft;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late StudentProfile? user;
  late LeaveRepository repository;
  setUp(() {
    user = studentA;
    repository = LeaveRepository(
      session: () => user,
      pdfBuilder: (_) async =>
          Uint8List.fromList(utf8.encode('%PDF-1.7 hasil uji')),
    );
  });
  tearDown(() => repository.dispose());

  test(
    'Mahasiswa → BAP → PDF → dosen yang tepat, termasuk nama dosen sama',
    () async {
      expect(repository.inbox, isEmpty);
      expect(demoLecturers[0].name, demoLecturers[1].name);
      final draft = fillLeave(repository.draft);
      final id = repository.submit(draft);
      expect(repository.read(id).status, LeaveStatus.pending);
      expect(() => repository.submit(draft), throwsStateError);
      user = studentB;
      expect(repository.inbox, isEmpty);
      expect(() => repository.read(id), throwsStateError);
      user = lecturerB;
      expect(repository.inbox, isEmpty);
      user = bap;
      expect(repository.inbox, hasLength(1));
      await repository.review(
        id,
        LeaveStatus.approved,
        'Bukti dan perkuliahan sudah diperiksa dalam pengujian.',
        evidenceChecked: true,
      );
      user = studentA;
      expect(repository.read(id).resultPdf, isNotEmpty);
      expect(repository.read(id).draft.attachments, hasLength(1));
      user = lecturerA;
      expect(repository.inbox, isEmpty);
      expect(() => repository.markRead(id), throwsStateError);
      user = lecturerB;
      expect(repository.inbox, hasLength(1));
      expect(repository.read(id).draft.attachments, isEmpty);
      repository.markRead(id);
      repository.markRead(id);
      expect(repository.read(id).readBy, {'DOS002'});
      expect(
        repository
            .read(id)
            .events
            .where((e) => e.description.contains('dibaca dosen')),
        hasLength(1),
      );
    },
  );

  test(
    'Perbaikan mempertahankan nomor, menaikkan versi, lalu penolakan punya PDF',
    () async {
      final id = repository.submit(fillLeave(repository.draft));
      user = bap;
      await repository.review(
        id,
        LeaveStatus.revision,
        'Bukti belum jelas. Lampirkan pengganti.',
        evidenceChecked: true,
      );
      expect(repository.read(id).resultPdf, isNull);
      user = lecturerB;
      expect(repository.inbox, isEmpty);
      user = studentB;
      expect(() => repository.revise(id), throwsStateError);
      user = studentA;
      final fixed = repository.revise(id);
      fixed.fields['Alasan'] = 'Alasan perbaikan dari mahasiswa.';
      expect(repository.submit(fixed, revisionId: id), id);
      expect(repository.read(id).version, 2);
      user = bap;
      await repository.review(
        id,
        LeaveStatus.rejected,
        'Bukti belum memenuhi pemeriksaan simulasi.',
        evidenceChecked: true,
      );
      expect(repository.read(id).status, LeaveStatus.rejected);
      expect(repository.read(id).resultPdf, isNotNull);
      await expectLater(
        repository.review(
          id,
          LeaveStatus.approved,
          'Ganti keputusan',
          evidenceChecked: true,
        ),
        throwsStateError,
      );
    },
  );

  test(
    'Bukti, rentang tanggal, kode penerima dan duplikat perkuliahan divalidasi',
    () {
      final draft = fillLeave(repository.draft);
      draft.classes.single.lecturerCode = 'Dosen Uji';
      expect(draft.validate(demoLecturers), contains('kode'));
      draft.classes.single.lecturerCode = 'DOS001';
      draft.classes.single.date = '2026-10-21';
      expect(draft.validate(demoLecturers), contains('rentang'));
      draft.classes.single.date = '2026-10-19';
      draft.fields['Tanggal akhir'] = '10-19-2026';
      expect(draft.validate(demoLecturers), contains('valid'));
      draft.fields['Tanggal akhir'] = '2026-10-20';
      draft.classes.add(draft.classes.single.copy());
      expect(draft.validate(demoLecturers), contains('dua kali'));
      draft.classes.removeLast();
      draft.classes.add(
        draft.classes.single.copy()..course = 'MK002 - Kuliah lain',
      );
      expect(draft.validate(demoLecturers), isNull);
      draft.attachments.clear();
      expect(() => repository.submit(draft), throwsStateError);
    },
  );

  test(
    'Snapshot menjaga pratinjau dan pengajuan dari perubahan objek luar',
    () {
      final draft = fillLeave(repository.draft);
      final preview = draft.copy();
      draft.fields['Alasan'] = 'Perubahan terlambat';
      final id = repository.submit(draft, preview: preview);
      expect(
        repository.read(id).draft.value('Alasan'),
        isNot('Perubahan terlambat'),
      );
      repository.read(id).draft.fields['Alasan'] = 'Diubah dari hasil baca';
      expect(
        repository.read(id).draft.value('Alasan'),
        preview.value('Alasan'),
      );
    },
  );

  test('Hanya BAP memutuskan dan bukti wajib sudah ditinjau', () async {
    final id = repository.submit(fillLeave(repository.draft));
    await expectLater(
      repository.review(id, LeaveStatus.approved, 'Acc', evidenceChecked: true),
      throwsStateError,
    );
    user = bap;
    await expectLater(
      repository.review(
        id,
        LeaveStatus.approved,
        'Acc',
        evidenceChecked: false,
      ),
      throwsStateError,
    );
    await expectLater(
      repository.review(id, LeaveStatus.approved, '', evidenceChecked: true),
      throwsStateError,
    );
    expect(repository.read(id).status, LeaveStatus.pending);
  });

  test('PDF gagal atau sesi berakhir tidak memfinalkan keputusan / menggandakan proses', () async {
    final pending = Completer<Uint8List>();
    final repo = LeaveRepository(
      session: () => user,
      pdfBuilder: (_) => pending.future,
    );
    final id = repo.submit(fillLeave(repo.draft));
    user = bap;
    final job = repo.review(
      id,
      LeaveStatus.approved,
      'Telah diperiksa',
      evidenceChecked: true,
    );
    await expectLater(
      repo.review(
        id,
        LeaveStatus.approved,
        'Klik kedua',
        evidenceChecked: true,
      ),
      throwsStateError,
    );
    user = null;
    pending.complete(Uint8List(3));
    await expectLater(job, throwsStateError);
    user = bap;
    expect(repo.read(id).status, LeaveStatus.pending);
    repo.dispose();
    user = studentA;
    final failed = LeaveRepository(
      session: () => user,
      pdfBuilder: (_) async => throw StateError('Gagal PDF'),
    );
    final failedId = failed.submit(fillLeave(failed.draft));
    user = bap;
    await expectLater(
      failed.review(
        failedId,
        LeaveStatus.approved,
        'Diperiksa',
        evidenceChecked: true,
      ),
      throwsStateError,
    );
    expect(failed.read(failedId).resultPdf, isNull);
    expect(failed.read(failedId).status, LeaveStatus.pending);
    failed.dispose();
  });

  test(
    'Akun staf login dengan peran yang benar dan masa sesi tetap 30 menit',
    () async {
      var now = DateTime(2026, 10, 19);
      final auth = AuthService(now: () => now);
      expect(
        (await auth.login(identity: 'BAP001', password: '123456')).role,
        UserRole.bap,
      );
      now = now.add(const Duration(minutes: 30));
      expect(auth.currentUser, isNull);
      expect(
        (await auth.login(identity: 'DOS002', password: '123456')).role,
        UserRole.lecturer,
      );
      auth.logout();
      expect(auth.currentUser, isNull);
    },
  );

  test(
    'Izin singkat tidak dijawab model dan tanda tanya menyediakan opsi',
    () async {
      final chat = ChatController();
      for (final text in [
        'izin',
        'ijin',
        'surat izin',
        'izin sakit',
        'mau izin',
        'gak masuk kuliah',
        'status izin',
        'aku mau ijin',
        'izin sakit hari ini',
        'ajukan surat ijin',
        'tidak hadir kuliah besok',
      ]) {
        expect(ChatPolicy.route(text).kind, RequestKind.draft);
        await chat.send(text);
        expect(chat.messages.last.actions, contains(HelpTopic.letter));
        expect(chat.messages.last.isAi, isFalse);
      }
      await chat.send('ijin?');
      expect(chat.messages.last.choices, hasLength(3));
      await chat.send('3');
      expect(chat.messages.last.text, contains('BAP'));
      expect(chat.messages.last.text, isNot(contains('mengetes aktivitas')));
      chat.dispose();
    },
  );

  test(
    'PDF hasil asli dapat dibuat untuk catatan pendek dan banyak halaman',
    () async {
      final repo = LeaveRepository(session: () => user);
      final id = repo.submit(fillLeave(repo.draft));
      user = bap;
      await repo.review(
        id,
        LeaveStatus.approved,
        'Bukti sesuai untuk simulasi ini.',
        evidenceChecked: true,
      );
      final file = File('build/leave-result-test.pdf');
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(repo.read(id).resultPdf!);
      expect(utf8.decode(file.readAsBytesSync().take(5).toList()), '%PDF-');
      user = studentA;
      final draft = fillLeave(repo.draft);
      draft.fields['Alasan'] = List.filled(
        35,
        'Alasan uji panjang untuk memeriksa pemisahan halaman.',
      ).join(' ');
      for (var i = 1; i < 8; i++) {
        draft.classes.add(
          LeaveClass(
            course: 'MK$i - Mata kuliah uji',
            classCode: 'KLS-$i',
            date: '2026-10-20',
            lecturerCode: 'DOS001',
          ),
        );
      }
      final longId = repo.submit(draft);
      user = bap;
      await repo.review(
        longId,
        LeaveStatus.rejected,
        List.filled(
          30,
          'Catatan pemeriksaan simulasi yang tidak menjadi keputusan resmi.',
        ).join(' '),
        evidenceChecked: true,
      );
      File('build/leave-long-test.pdf')
          .writeAsBytesSync(repo.read(longId).resultPdf!);
      repo.dispose();
    },
  );
}
