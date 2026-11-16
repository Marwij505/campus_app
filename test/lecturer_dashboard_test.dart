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
    test('AuthService generates proper lecturer profile for DOS001 and DOS002', () async {
      final service = AuthService();

      final dos1 = await service.login(identity: 'DOS001', password: '123456');
      expect(dos1.role, UserRole.lecturer);
      expect(dos1.name?.contains('Hendra Gunawan'), true);
      expect(dos1.faculty, 'Fakultas Ilmu Komputer');

      service.logout();

      final dos2 = await service.login(identity: 'DOS002', password: '123456');
      expect(dos2.role, UserRole.lecturer);
      expect(dos2.name?.contains('Sri Wahyuni'), true);
      expect(dos2.major?.contains('Teknik Informatika'), true);
    });

    testWidgets('DOS001 can login and sees Lecturer Dashboard with Teaching Panel', (tester) async {
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
      expect(find.text('JADWAL MENGAJAR & KELAS KULIAH'), findsOneWidget);

      // Verify switching to Advisor role (for DOS001, label is DPA without skripsi)
      await tester.tap(find.text('DOSEN PEMBIMBING (DPA)'));
      await tester.pumpAndSettle();

      expect(find.byType(AdvisorPanel), findsOneWidget);
      expect(find.text('VALIDASI & APPROVAL KRS:'), findsOneWidget);
      // Dosen Akademik does NOT have bimbingan skripsi
      expect(find.text('Bimbingan Skripsi'), findsNothing);
    });

    testWidgets('DOS002 opens Advisor Panel by default and can approve KRS and view Thesis', (tester) async {
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

      // Dosen Pembimbing DOS002 HAS bimbingan skripsi
      expect(find.text('Bimbingan Skripsi'), findsOneWidget);

      // Check pending KRS approval exists (e.g. Reifan Ardissa)
      expect(find.text('Reifan Ardissa'), findsWidgets);
      expect(find.text('ACC KRS'), findsWidgets);

      // Tap ACC KRS for first request
      await tester.tap(find.text('ACC KRS').first);
      await tester.pumpAndSettle();

      expect(find.textContaining('Telah Disetujui'), findsWidgets);

      // Switch to Bimbingan Skripsi subtab and verify it renders cleanly
      await tester.tap(find.text('Bimbingan Skripsi'));
      await tester.pumpAndSettle();

      expect(find.text('MAHASISWA BIMBINGAN TUGAS AKHIR / SKRIPSI'), findsOneWidget);
      expect(find.textContaining('Dimas Wahyu Pratama'), findsOneWidget);
      expect(find.textContaining('Logbook'), findsWidgets);
    });
  });
}
