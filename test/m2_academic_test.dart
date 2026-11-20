import 'dart:convert';

import 'package:campus_app/data/dashboard_models.dart';
import 'package:campus_app/features/academic/academic_calendar.dart';
import 'package:campus_app/features/academic/academic_page.dart';
import 'package:campus_app/features/academic/academic_repository.dart';
import 'package:campus_app/features/dashboard/dashboard_page.dart';
import 'package:campus_app/data/student_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Json fixture() {
  final period = <String, dynamic>{
    'id': '2026-1',
    'label': 'Ganjil 2026/2027',
    'starts_at': '2026-09-21T00:00:00+07:00',
    'ends_at': '2027-01-18T00:00:00+07:00',
    'registration_opens': '2026-08-20T00:00:00+07:00',
    'registration_closes': '2026-09-20T00:00:00+07:00',
    'krs_opens': '2026-08-20T00:00:00+07:00',
    'krs_closes': '2026-09-20T00:00:00+07:00',
    'max_credits': 24,
  };
  return {
    'available': true,
    'demo': true,
    'server_now': '2026-11-15T12:00:00+07:00',
    'stage': 'Semester aktif',
    'period': period,
    'periods': [period],
    'registration': {
      'semester': 1,
      'entry_year': 2026,
      'campus': 'Bekasi',
      'curriculum': '2026',
      'status': 'active',
      'track': 'regular',
      'initial_paid_at': '2026-09-01T09:00:00+07:00',
    },
    'krs': {'status': 'approved', 'version': 1},
    'krs_items': ['class-1'],
    'courses': [
      {
        'code': 'CSF101',
        'name': 'Dasar Sistem Informasi',
        'credits': 3,
        'semester': 1,
        'required': true,
      },
    ],
    'offerings': [
      {
        'id': 'class-1',
        'course_code': 'CSF101',
        'lecturer': 'Dosen Simulasi',
        'class_code': 'DEMO-R',
        'room': 'Ruang Demo',
        'mode': 'Tatap muka',
        'slots': [
          {'weekday': 1, 'starts': '08:00', 'ends': '10:00', 'kind': 'Teori'},
        ],
      },
    ],
    'events': [
      {
        'id': 'meeting-8',
        'kind': 'class',
        'meeting': 8,
        'title': 'Dasar Sistem Informasi',
        'course_code': 'CSF101',
        'class_code': 'DEMO-R',
        'lecturer': 'Dosen Simulasi',
        'room': 'Ruang Demo',
        'mode': 'Tatap muka',
        'plan': 'Rencana demo',
        'starts_at': '2026-11-16T08:00:00+07:00',
        'ends_at': '2026-11-16T10:00:00+07:00',
        'revision': 1,
        'cancelled': false,
      },
    ],
    'invoices': [],
    'payments': [],
    'notifications': [],
    'equivalences': [],
    'permissions': [],
  };
}

class FixtureAcademicRepository extends AcademicRepository {
  Json value = fixture();
  bool fail = false;
  int reads = 0;
  final actions = <String>[];
  @override
  Future<AcademicSnapshot> snapshot([String? period]) async {
    reads++;
    if (fail) throw const AcademicException('Fixture gagal memuat');
    return AcademicSnapshot(value);
  }

  @override
  Future<Json> command(String action, String period, Json data) async {
    actions.add(action);
    return {'ok': true};
  }

  @override
  Future<Json> review(String studentId, String period) async => {};
}

void main() {
  testWidgets(
    'Staff context opens the authorized panel without student registration',
    (tester) async {
      final repo = FixtureAcademicRepository();
      repo.value['registration'] = <String, dynamic>{};
      repo.value['staff'] = true;
      repo.value['demo'] = false;
      repo.value['permissions'] = ['academic', 'validator'];
      repo.value['stage'] = 'Layanan akademik petugas';
      await tester.pumpWidget(
        MaterialApp(
          home: AcademicPage(repository: repo, onLogout: () {}),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Layanan akademik petugas'), findsOneWidget);
      expect(find.text('Simpan draf'), findsNothing);
      expect(find.textContaining('Semester null'), findsNothing);
      await tester.tap(find.text('Panel petugas berwenang'));
      await tester.pumpAndSettle();
      expect(find.text('NIM mahasiswa'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  test('Dashboard and academic views share authoritative events and semester boundary', () async {
    final repo = FixtureAcademicRepository();
    final d = await repo.load('ignored-client-nim');
    expect(d.classes.single.meeting, 8);
    expect(d.progress.currentSemester, 1);
    expect(
      todayClasses(d.classes, DateTime.parse('2026-11-16T02:00:00Z')),
      hasLength(1),
    );
    expect(campusTime(d.classes.single.startsAt), '08:00');
    expect(academicTime('2026-12-31T18:00:00Z'), '01/01/2027 01:00 WIB');
    repo.value['server_now'] = '2027-01-18T00:00:00+07:00';
    expect((await repo.load('ignored')).classes, isEmpty);
    expect(
      (await repo.snapshot()).events,
      hasLength(1),
      reason: 'History remains readable',
    );
    repo.value['server_now'] = '2026-11-15T12:00:00+07:00';
    (repo.value['events'] as List).single['cancelled'] = true;
    expect((await repo.load('ignored')).classes, isEmpty);
  });

  test('iCalendar stable UID, UTC, escaping, CRLF and UTF8 folding', () {
    final start = DateTime.parse('2026-12-31T23:30:00+07:00');
    final e = AcademicCalendarEvent(
      id: 'course-meeting',
      title: 'Kuliah, ujian; ${'é' * 80}\nCatatan',
      start: start,
      end: start.add(const Duration(hours: 2)),
      revision: 4,
    );
    final text = e.ics(DateTime.utc(2026));
    expect(text, contains('UID:course-meeting@campus-app.demo\r\n'));
    expect(text, contains('DTSTART:20261231T163000Z'));
    expect(text, contains('DTEND:20261231T183000Z'));
    expect(text, contains('SEQUENCE:4'));
    expect(text, contains(r'Kuliah\, ujian\;'));
    for (final line in text.split('\r\n')) {
      expect(utf8.encode(line).length, lessThanOrEqualTo(75));
    }
    expect(text.replaceAll('\r\n ', ''), contains(r'\nCatatan'));
    expect(text, isNot(contains('rekening')));
    expect(
      text,
      isNot(contains('VALARM')),
      reason: 'Reminder selected in calendar app, not falsely promised',
    );
  });

  test('Date-only events preserve all-day exclusive end', () {
    final e = AcademicCalendarEvent(
      id: 'deadline',
      title: 'Tenggat registrasi',
      start: DateTime.utc(2026, 11, 30),
      end: DateTime.utc(2026, 12),
      allDay: true,
    );
    final text = e.ics(DateTime.utc(2026));
    expect(text, contains('DTSTART;VALUE=DATE:20261130'));
    expect(text, contains('DTEND;VALUE=DATE:20261201'));
  });

  testWidgets(
    'Academic page distinguishes load failure, retry, approved KRS and empty equivalence',
    (tester) async {
      final repo = FixtureAcademicRepository()..fail = true;
      await tester.pumpWidget(
        MaterialApp(
          home: AcademicPage(repository: repo, initialTab: 'Ekivalensi'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Data gagal dimuat'), findsOneWidget);
      repo.fail = false;
      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();
      expect(find.text('Belum ada ekivalensi'), findsOneWidget);
      expect(find.text('SIMULASI — Kurikulum 2026'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, 'KRS'));
      await tester.pumpAndSettle();
      final save = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Simpan draf'),
      );
      expect(save.onPressed, isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('Dashboard opens real academic route and refreshes on resume', (
    tester,
  ) async {
    final repo = FixtureAcademicRepository();
    await tester.binding.setSurfaceSize(const Size(1250, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: DashboardPage(
          student: const StudentProfile(nim: 'fixture', name: 'Dante'),
          onLogout: () {},
          repository: repo,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Tidak ada kelas hari ini'), findsOneWidget);
    await tester.tap(find.byTooltip('Notifikasi'));
    await tester.pumpAndSettle();
    expect(find.text('Akademik & Keuangan'), findsOneWidget);
    final reads = repo.reads;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(repo.reads, greaterThan(reads));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'Android calendar opens confirmation form with no financial fields',
    (tester) async {
      final calls = <MethodCall>[];
      const channel = MethodChannel('campus_app/calendar');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        calls.add(call);
        return true;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      final event = AcademicCalendarEvent(
        id: 'bill-fixture',
        title: 'Tenggat pembayaran',
        start: DateTime.utc(2027),
        end: DateTime.utc(2027, 1, 1, 0, 15),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => addAcademicCalendar(context, event),
              child: const Text('Export'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Export'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(calls, isEmpty);
      await tester.tap(find.text('Export'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();
      expect(calls.single.method, 'insert');
      expect(
        (calls.single.arguments as Map).keys,
        unorderedEquals(['title', 'start', 'end', 'allDay']),
      );
    },
    skip: kIsWeb,
  );

  testWidgets(
    'Calendar export rejects a changed schedule before opening a form',
    (tester) async {
      final repo = FixtureAcademicRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: AcademicPage(repository: repo, initialTab: 'Jadwal Kuliah'),
        ),
      );
      await tester.pumpAndSettle();
      (repo.value['events'] as List).single['revision'] = 2;
      await tester.ensureVisible(find.text('Tambah ke Kalender'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tambah ke Kalender'));
      await tester.pumpAndSettle();
      expect(
        find.text('Jadwal berubah. Muat ulang sebelum mengekspor.'),
        findsOneWidget,
      );
      expect(find.byType(AlertDialog), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('Calendar export rejects a bill paid since the screen loaded', (
    tester,
  ) async {
    final repo = FixtureAcademicRepository();
    repo.value['invoices'] = [
      {
        'id': 'invoice',
        'plan': 1,
        'principal': 17500000,
        'paid': 0,
        'cancelled': false,
        'installments': [
          {
            'id': 'installment',
            'ordinal': 1,
            'amount': 17500000,
            'paid': false,
            'due_at': '2026-11-20T09:00:00+07:00',
          },
        ],
      },
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: AcademicPage(repository: repo, initialTab: 'Pembayaran'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byTooltip('Tambah ke Kalender'),
      350,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    (repo.value['invoices'] as List).single['installments'][0]['paid'] = true;
    await tester.tap(find.byTooltip('Tambah ke Kalender'));
    await tester.pumpAndSettle();
    expect(
      find.text('Tagihan selesai atau dibatalkan. Hapus pengingat lama.'),
      findsOneWidget,
    );
    expect(find.byType(AlertDialog), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
