// Uji otomatis dashboard khusus dosen (Dosen Akademik & Dosen + Pembimbing TA),
// data dummy dosen, dan alur login menuju halaman dosen.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_app/core/app_theme.dart';
import 'package:campus_app/data/auth_service.dart';
import 'package:campus_app/data/lecturer_repository.dart';
import 'package:campus_app/data/student_profile.dart';
import 'package:campus_app/features/dashboard/lecturer_dashboard_page.dart';
import 'package:campus_app/features/leave/leave_page.dart';
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

  void viewport(WidgetTester tester, Size size) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
  }

  test('AuthService membedakan DOS001 (Akademik) dan DOS002 (Pembimbing TA)', () async {
    final service = AuthService();

    final academic = await service.login(identity: 'DOS001', password: '123456');
    expect(academic.role, UserRole.lecturer);
    expect(academic.lecturerType, LecturerType.academic);
    service.logout();

    final advisor = await service.login(identity: 'DOS002', password: '123456');
    expect(advisor.role, UserRole.lecturer);
    expect(advisor.lecturerType, LecturerType.academicAndThesis);
    service.logout();
  });

  test('DemoLecturerRepository menyediakan data dummy sesuai peran dosen', () async {
    const repo = DemoLecturerRepository();
    final academic = await repo.load('DOS001', now: DateTime(2026, 10, 12, 9));
    final advisor = await repo.load('DOS002', now: DateTime(2026, 10, 12, 9));

    expect(academic.profile?.type, LecturerType.academic);
    expect(academic.courses, isNotEmpty);
    expect(academic.paAdvisees, isNotEmpty);
    expect(academic.thesisAdvisees, isEmpty);
    expect(academic.thesisSchedules, isEmpty);

    expect(advisor.profile?.type, LecturerType.academicAndThesis);
    expect(advisor.courses, isNotEmpty);
    expect(advisor.paAdvisees, isNotEmpty);
    expect(advisor.thesisAdvisees, isNotEmpty);
    expect(advisor.thesisSchedules, isNotEmpty);
  });

  for (final size in [
    const Size(390, 844),
    const Size(820, 1180),
    const Size(1280, 800),
  ]) {
    testWidgets('Dashboard Dosen Akademik (DOS001) tanpa overflow pada $size', (
      tester,
    ) async {
      viewport(tester, size);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.data,
          home: LecturerDashboardPage(
            lecturer: const StudentProfile(
              nim: 'DOS001',
              role: UserRole.lecturer,
              lecturerType: LecturerType.academic,
            ),
            onLogout: () {},
            clock: () => DateTime(2026, 10, 12, 9),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('BERANDA DOSEN AKADEMIK'), findsOneWidget);
      expect(find.text('Dr. Budi Santoso, M.Kom.'), findsOneWidget);
      expect(find.text('MATA KULIAH DIAMPU'), findsOneWidget);
      expect(find.text('MAHASISWA BIMBINGAN AKADEMIK (PA)'), findsOneWidget);
      expect(find.text('MAHASISWA BIMBINGAN TUGAS AKHIR (TA)'), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });

    testWidgets(
      'Dashboard Dosen Akademik + Pembimbing TA (DOS002) tanpa overflow pada $size',
      (tester) async {
        viewport(tester, size);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.data,
            home: LecturerDashboardPage(
              lecturer: const StudentProfile(
                nim: 'DOS002',
                role: UserRole.lecturer,
                lecturerType: LecturerType.academicAndThesis,
              ),
              onLogout: () {},
              clock: () => DateTime(2026, 10, 12, 9),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('BERANDA DOSEN & PEMBIMBING TA'), findsOneWidget);
        expect(find.text('Dr. Ir. Ratna Sari, S.T., M.T.'), findsOneWidget);
        expect(find.text('MAHASISWA BIMBINGAN TUGAS AKHIR (TA)'), findsOneWidget);
        expect(find.text('JADWAL BIMBINGAN & SIDANG TA'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      },
    );
  }

  testWidgets('Login DOS002 membuka dashboard dosen dan dapat membuka Hasil Izin', (
    tester,
  ) async {
    viewport(tester, const Size(1280, 800));
    await tester.pumpWidget(const CampusApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'DOS002');
    await tester.enterText(find.byType(TextFormField).at(1), '123456');

    final loginButton = find.widgetWithText(PixelButton, 'MASUK');
    await tester.ensureVisible(loginButton);
    await tester.tap(loginButton);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('BERANDA DOSEN & PEMBIMBING TA'), findsOneWidget);
    expect(find.text('Dr. Ir. Ratna Sari, S.T., M.T.'), findsOneWidget);

    final izinShortcut = find.ancestor(
      of: find.text('Hasil Izin'),
      matching: find.byType(PixelTapSurface),
    );
    await tester.ensureVisible(izinShortcut);
    await tester.tap(izinShortcut);
    await tester.pumpAndSettle();

    expect(find.byType(LeavePage), findsOneWidget);
    expect(find.text('Dosen · Hasil Izin'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
