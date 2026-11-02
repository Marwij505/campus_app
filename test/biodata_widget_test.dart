// Tes alur pengguna memakai SDK Supabase asli dengan server HTTP terkendali.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_app/data/biodata_fields.dart';
import 'package:campus_app/data/biodata_repository.dart';
import 'package:campus_app/data/student_profile.dart';
import 'package:campus_app/features/profile/biodata_form.dart';
import 'package:campus_app/features/profile/profile_records.dart';

import 'support/supabase_fixture.dart';

void main() {
  for (final section in biodataSections) {
    testWidgets(
      '${section.label}: validasi, gagal, simpan, muat ulang, batal',
      (tester) async {
        final server = SupabaseFixture();
        await tester.runAsync(
          () => server.client.auth.setSession('test-refresh'),
        );
        final repo = BiodataRepository(server.client);
        var dirty = false, saves = 0;
        final student = StudentProfile.fromRows(
          server.profile,
          server.student,
          email: 'student@example.test',
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: BiodataForm(
                  section: section,
                  repository: repo,
                  student: student,
                  onSaved: () async {
                    saves++;
                  },
                  onDirty: (v) => dirty = v,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Edit'));
        await tester.pumpAndSettle();
        expect(dirty, isTrue);
        if (section.key == 'accessibility') {
          await tester.tap(find.byType(DropdownButtonFormField<String>).first);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Ya').last);
          await tester.pumpAndSettle();
        }
        final input = find.byType(TextFormField).first;
        await tester.ensureVisible(input);
        final value = section.key == 'biodata'
            ? '1234567890123456'
            : 'Isian uji';
        if (section.key == 'biodata') {
          await tester.enterText(input, '123');
          await tester.ensureVisible(find.text('Simpan'));
          await tester.tap(find.text('Simpan'));
          await tester.pumpAndSettle();
          expect(find.text('NIK harus 16 digit.'), findsOneWidget);
          expect(saves, 0);
        }
        await tester.ensureVisible(input);
        await tester.enterText(input, value);
        server.failSave = true;
        await tester.ensureVisible(find.text('Simpan'));
        await tester.tap(find.text('Simpan'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Belum berhasil disimpan'), findsOneWidget);
        expect(find.text(value), findsOneWidget);
        expect(saves, 0);
        server.failSave = false;
        await tester.tap(find.text('Simpan'));
        await tester.pumpAndSettle();
        expect(saves, 1);
        expect(dirty, isFalse);
        await tester.tap(find.text('Muat ulang'));
        await tester.pumpAndSettle();
        expect(find.text(value), findsOneWidget);
        await tester.tap(find.text('Edit'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(input);
        await tester.enterText(input, 'Belum disimpan');
        await tester.ensureVisible(find.text('Batal'));
        await tester.tap(find.text('Batal'));
        await tester.pumpAndSettle();
        expect(find.text(value), findsOneWidget);
        expect(find.text('Belum disimpan'), findsNothing);
        expect(dirty, isFalse);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(server.dispose);
      },
    );
  }

  testWidgets('Gagal memuat tidak membuka editor; muat ulang memulihkan', (
    tester,
  ) async {
    final server = SupabaseFixture()..failSections = true;
    await tester.runAsync(() => server.client.auth.setSession('test-refresh'));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: BiodataForm(
              section: biodataSections.first,
              repository: BiodataRepository(server.client),
              student: StudentProfile.fromRows(server.profile, server.student),
              onSaved: () async {},
              onDirty: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Data belum dapat dimuat'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Edit'))
          .onPressed,
      isNull,
    );
    server.failSections = false;
    await tester.tap(find.text('Muat ulang'));
    await tester.pumpAndSettle();
    expect(find.text('No induk kependudukan'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(server.dispose);
  });

  for (final docs in [false, true]) {
    testWidgets(
      'Panel ${docs ? 'berkas' : 'keuangan'} kosong dan galat jelas',
      (tester) async {
        final server = SupabaseFixture()..failSections = true;
        await tester.runAsync(
          () => server.client.auth.setSession('test-refresh'),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: ProfileRecords(
                  repository: BiodataRepository(server.client),
                  documents: docs,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('Data belum dapat dimuat'), findsOneWidget);
        server.failSections = false;
        await tester.tap(find.text('Muat ulang'));
        await tester.pumpAndSettle();
        if (docs) {
          expect(find.text('Belum ada'), findsNWidgets(5));
          expect(find.text('Pilih berkas'), findsNWidgets(5));
        } else {
          expect(
            find.textContaining('Belum ada riwayat keuangan'),
            findsOneWidget,
          );
          expect(find.textContaining('Rp '), findsNothing);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(server.dispose);
      },
    );
  }
  testWidgets('Riwayat terisi tetap terbaca di HP dengan teks 200 persen', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 700);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final server = SupabaseFixture();
    // Data buatan hanya berada di server tes, tidak pernah dikirim ke Supabase nyata.
    server.financeRows.add({
      'period': 'Semester ganjil uji',
      'category': 'Biaya kuliah',
      'description': 'Tagihan untuk pengujian',
      'amount': 999999999999.99,
      'paid': 1000,
      'billed_on': '2026-11-01',
      'due_on': '2026-11-30',
    });
    await tester.runAsync(() => server.client.auth.setSession('test-refresh'));
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: ProfileRecords(
                repository: BiodataRepository(server.client),
                documents: false,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Belum lunas · Tagihan 2026-11-01'), findsOneWidget);
    expect(find.text('Subtotal Biaya kuliah'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(server.dispose);
  });
}
