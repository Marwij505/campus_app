// Uji tombol dan formulir nyata pada layar HP, tablet, serta desktop.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_app/core/app_theme.dart';
import 'package:campus_app/data/student_profile.dart';
import 'package:campus_app/features/leave/leave_page.dart';
import 'package:campus_app/features/leave/leave_form.dart';
import 'package:campus_app/features/leave/leave_models.dart';
import 'package:campus_app/features/leave/leave_repository.dart';
import 'package:campus_app/features/leave/leave_widgets.dart';

import 'leave_workflow_test.dart' show fillLeave, studentA, bap, lecturerB;

void main() {
  setUpAll(() async {
    await (FontLoader(
      'SpaceMono',
    )..addFont(rootBundle.load('assets/fonts/SpaceMono-Regular.ttf'))).load();
  });

  Future<void> tap(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  testWidgets('Menghapus perkuliahan tidak menukar isian baris yang tersisa', (
    tester,
  ) async {
    final repo = LeaveRepository(session: () => studentA);
    addTearDown(repo.dispose);
    final draft = fillLeave(repo.draft);
    draft.classes.add(
      LeaveClass(
        course: 'MK002 - Kedua',
        classCode: 'B',
        date: '2026-10-20',
        lecturerCode: 'DOS001',
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.data,
        home: LeaveForm(repository: repo),
      ),
    );
    await tester.pumpAndSettle();
    await tap(tester, find.text('Hapus perkuliahan').first);
    expect(draft.classes.single.course, 'MK002 - Kedua');
    expect(find.text('MK001 - Mata Kuliah Uji'), findsNothing);
    expect(find.text('MK002 - Kedua'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final width in [390.0, 820.0, 1280.0]) {
    testWidgets('Pengajuan, keputusan BAP, dan kotak masuk dosen: $width', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      StudentProfile user = studentA;
      final repo = LeaveRepository(
        session: () => user,
        pdfBuilder: (_) async => Uint8List.fromList([37, 80, 68, 70]),
      );
      addTearDown(repo.dispose);
      Future<void> mount() async {
        // Widget baru meniru pergantian akun, repository tetap hidup di AuthGate.
        await tester.pumpWidget(
          MaterialApp(
            key: ValueKey(user.nim),
            theme: AppTheme.data,
            home: LeavePage(repository: repo),
          ),
        );
        await tester.pumpAndSettle();
      }

      fillLeave(repo.draft);
      await mount();
      await tap(tester, find.text('Buat pengajuan izin'));
      final date = find.descendant(
        of: find.byType(LeaveDateField).first,
        matching: find.byType(TextFormField),
      );
      await tap(tester, date);
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await tap(tester, find.text('OK'));
      expect(repo.draft.value('Tanggal mulai'), '2026-10-19');
      await tap(tester, find.text('Periksa & ajukan izin'));
      await tap(tester, find.text('Kembali edit'));
      expect(repo.inbox, isEmpty);
      await tap(tester, find.text('Periksa & ajukan izin'));
      await tap(tester, find.text('Ajukan ke BAP (simulasi)'));
      expect(repo.inbox.single.status, LeaveStatus.pending);
      expect(tester.takeException(), isNull);

      user = bap;
      await mount();
      await tap(tester, find.textContaining('IZIN-1 · versi'));
      await tap(tester, find.byType(CheckboxListTile));
      await tap(tester, find.byType(DropdownButtonFormField<LeaveStatus>));
      await tap(tester, find.text('Disetujui BAP').last);
      await tester.ensureVisible(find.byType(TextField));
      await tester.enterText(
        find.byType(TextField),
        'Bukti dan kode dosen telah ditinjau.',
      );
      await tap(tester, find.text('Tinjau keputusan'));
      await tap(tester, find.text('Simpan keputusan'));
      expect(repo.inbox.single.status, LeaveStatus.approved);
      expect(find.text('Unduh / bagikan hasil PDF'), findsOneWidget);
      expect(tester.takeException(), isNull);

      user = lecturerB;
      await mount();
      await tap(tester, find.textContaining('IZIN-1 · versi'));
      expect(find.byType(LeaveAttachments), findsNothing);
      await tap(tester, find.text('Tandai hasil sudah dibaca'));
      expect(repo.read('IZIN-1').readBy, contains('DOS002'));
      expect(tester.takeException(), isNull);
    });
  }
}
