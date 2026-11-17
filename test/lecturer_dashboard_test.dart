import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_app/data/auth_service.dart';
import 'package:campus_app/data/student_profile.dart';
import 'package:campus_app/features/lecturer_dashboard/advisor_panel.dart';
import 'package:campus_app/features/lecturer_dashboard/lecturer_dashboard_page.dart';
import 'package:campus_app/features/lecturer_dashboard/teaching_panel.dart';
import 'package:campus_app/main.dart';
import 'package:campus_app/shared/pixel_widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final pixel = FontLoader('PressStart2P')
      ..addFont(rootBundle.load('assets/fonts/PressStart2P-Regular.ttf'));
    final mono = FontLoader('SpaceMono')
      ..addFont(rootBundle.load('assets/fonts/SpaceMono-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/SpaceMono-Bold.ttf'));
    await pixel.load();
    await mono.load();
  });

  group('Lecturer Dashboard Tests', () {
    testWidgets('lecturer dashboards render every tab on a narrow phone', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 720);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      for (final nip in ['DOS001', 'DOS002']) {
        await tester.pumpWidget(
          MaterialApp(
            home: LecturerDashboardPage(
              key: ValueKey(nip),
              lecturerProfile: StudentProfile(
                nim: nip,
                role: UserRole.lecturer,
              ),
              onLogout: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: '$nip initial dashboard',
        );
        expect(
          find.byKey(const ValueKey('lecturer-nav-Perkuliahan & Jadwal')),
          findsNothing,
          reason: 'compact dashboard has no always-visible horizontal menu',
        );
        if (nip == 'DOS002') {
          expect(find.text('Bimbingan Skripsi'), findsOneWidget);
        }

        for (final label in [
          'Perkuliahan & Jadwal',
          'Perwalian Mahasiswa',
          if (nip == 'DOS002') 'Bimbingan Skripsi',
          'Rekap Nilai & Kelas',
        ]) {
          await tester.tap(find.byTooltip('Buka menu navigasi'));
          await tester.pumpAndSettle();
          final tab = find.text(label).first;
          expect(
            find.text(label),
            findsWidgets,
            reason: '$nip exposes tab $label',
          );
          final menuItem = find.byKey(ValueKey('lecturer-nav-$label'));
          await tester.ensureVisible(menuItem);
          await tester.tap(menuItem);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$nip tab $label');
          expect(find.byTooltip('Buka menu navigasi'), findsOneWidget);
          expect(find.byTooltip('Tutup menu navigasi'), findsNothing);
        }

        if (nip == 'DOS002') {
          await tester.tap(find.byTooltip('Buka menu navigasi'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Perwalian Mahasiswa').first);
          await tester.pumpAndSettle();

          final studentTab = find.text('Daftar Mahasiswa Wali').first;
          await tester.ensureVisible(studentTab);
          await tester.tap(studentTab);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$nip advisee subtab');

          final thesisTab = find.text('Bimbingan Skripsi').last;
          await tester.ensureVisible(thesisTab);
          await tester.tap(thesisTab);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$nip thesis subtab');
        }
      }
    });

    testWidgets('desktop lecturer sidebar can collapse and expand', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1024, 768);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: LecturerDashboardPage(
            lecturerProfile: const StudentProfile(
              nim: 'DOS001',
              role: UserRole.lecturer,
            ),
            onLogout: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'initial desktop layout');

      expect(find.text('Perwalian Mahasiswa'), findsOneWidget);
      await tester.tap(find.byTooltip('Sembunyikan menu navigasi'));
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: 'collapsed sidebar layout',
      );
      expect(find.text('Perwalian Mahasiswa'), findsNothing);

      await tester.tap(find.byTooltip('Tampilkan menu navigasi'));
      await tester.pumpAndSettle();
      final expandedError = tester.takeException();
      expect(
        expandedError,
        isNull,
        reason: 'expanded sidebar layout: $expandedError',
      );
      expect(find.text('Perwalian Mahasiswa'), findsOneWidget);
    });

    test(
      'AuthService generates proper lecturer profile for DOS001 and DOS002',
      () async {
        final service = AuthService();

        final dos1 = await service.login(
          identity: 'DOS001',
          password: '123456',
        );
        expect(dos1.role, UserRole.lecturer);
        expect(dos1.name?.contains('Hendra Gunawan'), true);
        expect(dos1.faculty, 'Fakultas Ilmu Komputer');

        service.logout();

        final dos2 = await service.login(
          identity: 'DOS002',
          password: '123456',
        );
        expect(dos2.role, UserRole.lecturer);
        expect(dos2.name?.contains('Sri Wahyuni'), true);
        expect(dos2.major?.contains('Teknik Informatika'), true);
      },
    );

    testWidgets(
      'DOS001 can login and sees Lecturer Dashboard with Teaching Panel',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(1024, 768);

        await tester.pumpWidget(const CampusApp());
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextFormField).at(0), 'DOS001');
        await tester.enterText(find.byType(TextFormField).at(1), '123456');

        final button = find.widgetWithText(PixelButton, 'MASUK');
        await tester.tap(button);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        // Check Lecturer Dashboard is mounted
        expect(find.byType(LecturerDashboardPage), findsOneWidget);
        expect(find.text('SIAKAD · PORTAL DOSEN FASILKOM'), findsOneWidget);
        expect(find.textContaining('Dr. Ir. Hendra Gunawan'), findsOneWidget);
        expect(find.byType(TeachingPanel), findsOneWidget);
        expect(
          find.text('TIMELINE PERKULIAHAN SEMESTER AKTIF'),
          findsOneWidget,
        );

        // Verify switching to Perwalian tab (for DOS001, dosen akademik pengampu without skripsi)
        await tester.tap(find.text('Perwalian Mahasiswa'));
        await tester.pumpAndSettle();

        expect(find.byType(AdvisorPanel), findsOneWidget);
        expect(
          find.text('ANTREAN VALIDASI RENCANA STUDI (KRS)'),
          findsOneWidget,
        );
        // Dosen Akademik DOS001 does NOT have bimbingan skripsi
        expect(find.text('Bimbingan Skripsi'), findsNothing);
      },
    );

    testWidgets(
      'DOS002 opens Advisor Panel by default and can approve KRS and view Thesis',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(1024, 768);

        await tester.pumpWidget(const CampusApp());
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextFormField).at(0), 'DOS002');
        await tester.enterText(find.byType(TextFormField).at(1), '123456');

        final button = find.widgetWithText(PixelButton, 'MASUK');
        await tester.tap(button);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        expect(find.byType(LecturerDashboardPage), findsOneWidget);
        expect(find.textContaining('Prof. Dr. Sri Wahyuni'), findsOneWidget);
        expect(find.byType(AdvisorPanel), findsOneWidget);

        // Dosen Pembimbing DOS002 HAS bimbingan skripsi tab
        expect(find.text('Bimbingan Skripsi'), findsWidgets);

        // Check pending KRS approval exists (e.g. Reifan Ardissa)
        expect(find.text('Reifan Ardissa'), findsWidgets);
        expect(find.text('Setujui (ACC)'), findsWidgets);

        // Approve the first pending KRS request.
        final approveButton = find.text('Setujui (ACC)').first;
        await tester.ensureVisible(approveButton);
        await tester.tap(approveButton);
        await tester.pumpAndSettle();

        expect(find.textContaining('Disetujui'), findsWidgets);

        // Switch to Bimbingan Skripsi subtab and verify it renders cleanly
        final thesisTab = find.text('Bimbingan Skripsi').first;
        await tester.ensureVisible(thesisTab);
        await tester.tap(thesisTab);
        await tester.pumpAndSettle();

        expect(
          find.text('PORTAL PEMBIMBINGAN SKRIPSI & TUGAS AKHIR'),
          findsOneWidget,
        );
        expect(find.textContaining('Dimas Wahyu Pratama'), findsOneWidget);
        expect(find.textContaining('Logbook'), findsWidgets);
      },
    );
  });
}
