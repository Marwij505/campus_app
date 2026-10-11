import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_app/core/app_theme.dart';
import 'package:campus_app/data/dashboard_models.dart';
import 'package:campus_app/data/dashboard_repository.dart';
import 'package:campus_app/data/student_profile.dart';
import 'package:campus_app/features/dashboard/dashboard_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    // Font asli mencegah ukuran Ahem menyamarkan masalah layout.
    final pixel = FontLoader('PressStart2P')
      ..addFont(rootBundle.load('assets/fonts/PressStart2P-Regular.ttf'));
    final mono = FontLoader('SpaceMono')
      ..addFont(rootBundle.load('assets/fonts/SpaceMono-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/SpaceMono-Bold.ttf'));
    await pixel.load();
    await mono.load();
  });

  Widget app({
    DashboardRepository repository = const EmptyDashboardRepository(),
    double scale = 1,
  }) => MaterialApp(
    theme: AppTheme.data,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: DashboardPage(
      student: const StudentProfile(nim: 'akun-uji'),
      onLogout: () {},
      repository: repository,
      clock: () => DateTime(2026, 10, 11, 10),
    ),
  );

  void viewport(WidgetTester tester, Size size) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
  }

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(600, 900),
    const Size(900, 600),
    const Size(1280, 800),
    const Size(1920, 1080),
  ]) {
    testWidgets('Beranda kosong tanpa overflow pada $size', (tester) async {
      viewport(tester, size);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.text('AKSES CEPAT'), findsOneWidget);
      expect(find.text('Belum ada jadwal kuliah hari ini'), findsOneWidget);
      expect(find.text('Belum ada jadwal konseling'), findsOneWidget);
      expect(find.text('Belum ada pengumuman'), findsOneWidget);
      expect(find.text('Belum ada berita'), findsOneWidget);
      expect(find.text('Grafik belum tersedia'), findsNWidgets(6));
      expect(
        find.byKey(const ValueKey('phone-navigation')),
        size.width < 600 ? findsOneWidget : findsNothing,
      );
      expect(
        find.byKey(const ValueKey('tablet-navigation')),
        size.width >= 600 && size.width < 1100 ? findsOneWidget : findsNothing,
      );
      if (size.width >= 1280) {
        expect(find.byKey(const ValueKey('desktop-panels')), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
      // Lepas halaman agar timer menit dan controller dibersihkan.
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('HP dengan ukuran teks 200 persen tetap dapat dibaca', (
    tester,
  ) async {
    viewport(tester, const Size(320, 700));
    await tester.pumpWidget(app(scale: 2));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Resize desktop menjadi HP mempertahankan data', (tester) async {
    viewport(tester, const Size(1280, 800));
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('desktop-panels')), findsOneWidget);
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('phone-navigation')), findsOneWidget);
    expect(find.text('NIM: akun-uji'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'Gagal memuat bisa dicoba ulang, tanpa menyamar sebagai data kosong',
    (tester) async {
      viewport(tester, const Size(390, 844));
      await tester.pumpWidget(app(repository: _RetryRepository()));
      await tester.pumpAndSettle();
      expect(
        find.text('Data beranda gagal dimuat. Silakan coba lagi.'),
        findsOneWidget,
      );
      expect(find.text('Belum ada jadwal kuliah hari ini'), findsNothing);
      await tester.ensureVisible(find.text('Coba lagi'));
      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();
      expect(
        find.text('Data beranda gagal dimuat. Silakan coba lagi.'),
        findsNothing,
      );
      expect(find.text('Belum ada jadwal kuliah hari ini'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('Tombol semua membuka jadwal kosong dan Back kembali', (
    tester,
  ) async {
    viewport(tester, const Size(390, 844));
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Semua'));
    await tester.tap(find.text('Semua'));
    await tester.pumpAndSettle();
    expect(find.text('Belum ada jadwal kuliah'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('AKSES CEPAT'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Animasi dapat dimatikan dari pengaturan aksesibilitas', (
    tester,
  ) async {
    viewport(tester, const Size(900, 600));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.data,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: DashboardPage(
          student: const StudentProfile(nim: 'akun-uji'),
          onLogout: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('AKSES CEPAT'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}

class _RetryRepository implements DashboardRepository {
  int attempts = 0;
  @override
  Future<DashboardData> load(String nim) async {
    if (attempts++ == 0) {
      throw Exception('Koneksi uji gagal');
    }
    return const DashboardData();
  }
}
