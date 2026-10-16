// Tes menu melalui halaman beranda asli: membuka kelompok, memilih tujuan,
// kembali, dan menggunakan submenu di layar sempit dengan tulisan besar.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_app/core/app_theme.dart';
import 'package:campus_app/data/student_profile.dart';
import 'package:campus_app/features/dashboard/dashboard_page.dart';
import 'package:campus_app/features/dashboard/dashboard_detail_page.dart';
import 'package:campus_app/shared/pixel_widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    // Pakai font aplikasi agar pemeriksaan lebar teks sesuai tampilan sebenarnya.
    await (FontLoader('PressStart2P')
          ..addFont(rootBundle.load('assets/fonts/PressStart2P-Regular.ttf')))
        .load();
    await (FontLoader('SpaceMono')
          ..addFont(rootBundle.load('assets/fonts/SpaceMono-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/SpaceMono-Bold.ttf')))
        .load();
  });

  Future<void> openDashboard(
    WidgetTester tester, {
    Size size = const Size(1280, 800),
    double scale = 1,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.data,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: DashboardPage(
          student: const StudentProfile(nim: 'akun-uji'),
          onLogout: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder entry(String surface, String id) => find.byKey(
    surface == 'mobile'
        ? PageStorageKey('executive-$surface-$id')
        : ValueKey('executive-$surface-$id'),
  );

  Future<void> choose(WidgetTester tester, String surface, String id) async {
    final target = entry(surface, id);
    // ExpansionTile mencakup anak-anaknya: ketuk judulnya, bukan tengah seluruh isi.
    final heading = find
        .descendant(of: target, matching: find.byType(Text))
        .first;
    await tester.ensureVisible(heading);
    await tester.pumpAndSettle();
    await tester.tap(heading);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  Future<void> finish(WidgetTester tester) async {
    // Hapus halaman agar timer pembaruan waktu dashboard ikut dibatalkan.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  }

  // Pastikan pintasan dan menu utama benar-benar membuka halaman baru yang sama.
  // HP juga diuji dengan tulisan dua kali lebih besar agar pesan tetap terbaca.
  for (final config in [
    (size: const Size(390, 844), scale: 2.0),
    (size: const Size(820, 1180), scale: 1.0),
    (size: const Size(1280, 800), scale: 1.0),
  ]) {
    testWidgets('Tiga halaman kosong dari pintasan dan menu: $config', (
      tester,
    ) async {
      await openDashboard(tester, size: config.size, scale: config.scale);
      final desktop = config.size.width >= 1100;
      final surface = desktop ? 'desktop' : 'mobile';
      for (final label in ['Biodata', 'Nilai & Presensi', 'Konseling']) {
        final shortcut = find.ancestor(
          of: find.text(label),
          matching: find.byType(PixelTapSurface),
        );
        await tester.ensureVisible(shortcut);
        await tester.pumpAndSettle();
        await tester.tap(shortcut);
        await tester.pumpAndSettle();
        expect(find.byType(DashboardDetailPage), findsOneWidget);
        expect(find.text('Belum ada data $label'), findsOneWidget);
        expect(find.text('AKSES CEPAT'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.text('AKSES CEPAT'), findsOneWidget);

        if (!desktop) {
          await tester.tap(find.byTooltip('Buka menu'));
          await tester.pumpAndSettle();
        }
        if (label == 'Biodata') {
          // Biodata berada langsung di header desktop atau di dalam drawer.
          final target = find.descendant(
            of: find.byType(desktop ? AppBar : Drawer),
            matching: find.text(label),
          );
          await tester.ensureVisible(target);
          await tester.pumpAndSettle();
          await tester.tap(target);
          await tester.pumpAndSettle();
        } else {
          await choose(
            tester,
            surface,
            label == 'Konseling' ? 'layanan' : 'akademik',
          );
          await choose(
            tester,
            surface,
            label == 'Konseling' ? 'konseling' : 'nilai',
          );
        }
        expect(find.byType(DashboardDetailPage), findsOneWidget);
        expect(find.text('Belum ada data $label'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.text('AKSES CEPAT'), findsOneWidget);
        expect(find.byType(Drawer).hitTestable(), findsNothing);
      }
      await finish(tester);
    });
  }

  testWidgets(
    'Desktop: Program Akademik lengkap dan jadwal memakai tujuan lama',
    (tester) async {
      await openDashboard(tester);
      await choose(tester, 'desktop', 'akademik');
      for (final item in [
        ('krs', 'Kartu Rencana Studi (KRS)'),
        ('jadwal', 'Jadwal Perkuliahan'),
        ('nilai', 'Nilai & Presensi'),
        ('ekivalensi', 'Ekivalensi'),
        ('program-akademik', 'Program Akademik'),
      ]) {
        expect(
          find
              .descendant(
                of: entry('desktop', item.$1),
                matching: find.text(item.$2),
              )
              .hitTestable(),
          findsOneWidget,
        );
      }
      await choose(tester, 'desktop', 'program-akademik');
      for (final label in [
        'Kuliah Kerja Nyata (KKN)',
        'Kuliah Kerja Praktek (KKP)',
        'Praktek Lahan',
        'Project Based',
        'Kampus Berdampak',
        'Pengajuan Praktik Apoteker',
      ]) {
        expect(find.text(label).hitTestable(), findsOneWidget);
      }
      await choose(tester, 'desktop', 'kkn');
      expect(
        find.text('Belum ada data Kuliah Kerja Nyata (KKN)'),
        findsOneWidget,
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      await choose(tester, 'desktop', 'akademik');
      await choose(tester, 'desktop', 'jadwal');
      expect(find.text('Belum ada jadwal kuliah'), findsOneWidget);
      await finish(tester);
    },
  );

  testWidgets('Desktop: Tugas Akhir dan submenu Dokumen serta Referensi', (
    tester,
  ) async {
    await openDashboard(tester);
    await choose(tester, 'desktop', 'tugas-akhir');
    for (final label in ['Skripsi/Tesis', 'Business Plan', 'Disertasi']) {
      expect(find.text(label).hitTestable(), findsOneWidget);
    }
    await choose(tester, 'desktop', 'skripsi-tesis');
    expect(find.text('Belum ada data Skripsi/Tesis'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await choose(tester, 'desktop', 'layanan');
    expect(find.text('Kuesioner').hitTestable(), findsOneWidget);
    await choose(tester, 'desktop', 'dokumen');
    await choose(tester, 'desktop', 'surat-lulus');
    expect(find.text('Belum ada data Surat Keterangan Lulus'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await choose(tester, 'desktop', 'layanan');
    await choose(tester, 'desktop', 'referensi');
    await choose(tester, 'desktop', 'kurikulum');
    expect(find.text('Belum ada data Kurikulum'), findsOneWidget);
    await finish(tester);
  });

  testWidgets(
    'Desktop: hover membuka submenu, Escape dan klik luar menutup menu',
    (tester) async {
      await openDashboard(tester);
      await choose(tester, 'desktop', 'akademik');
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(
        tester.getCenter(entry('desktop', 'program-akademik')),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Kuliah Kerja Nyata (KKN)').hitTestable(),
        findsOneWidget,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Kuliah Kerja Nyata (KKN)').hitTestable(), findsNothing);
      // Klik area beranda yang tidak berada di menu untuk menutup kelompok induk.
      await mouse.moveTo(const Offset(100, 700));
      await tester.tapAt(const Offset(100, 700));
      await tester.pumpAndSettle();
      expect(find.text('Program Akademik').hitTestable(), findsNothing);
      await mouse.removePointer();
      await finish(tester);
    },
  );

  // Menu panjang harus dapat digulir hingga pilihan terakhir, termasuk teks 200%.
  for (final scenario in [
    (size: const Size(320, 568), scale: 1.0),
    (size: const Size(390, 844), scale: 1.0),
    (size: const Size(600, 900), scale: 1.0),
    (size: const Size(320, 700), scale: 2.0),
  ]) {
    testWidgets('Menu HP/tablet dapat digulir: $scenario', (tester) async {
      await openDashboard(tester, size: scenario.size, scale: scenario.scale);
      await tester.tap(find.byTooltip('Buka menu'));
      await tester.pumpAndSettle();
      await choose(tester, 'mobile', 'akademik');
      await choose(tester, 'mobile', 'program-akademik');
      await choose(tester, 'mobile', 'praktik-apoteker');
      expect(
        find.text('Belum ada data Pengajuan Praktik Apoteker'),
        findsOneWidget,
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Buka menu'));
      await tester.pumpAndSettle();
      if (entry('mobile', 'referensi').evaluate().isEmpty) {
        await choose(tester, 'mobile', 'layanan');
      }
      await choose(tester, 'mobile', 'dokumen');
      await choose(tester, 'mobile', 'surat-lulus');
      expect(
        find.text('Belum ada data Surat Keterangan Lulus'),
        findsOneWidget,
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Buka menu'));
      await tester.pumpAndSettle();
      if (entry('mobile', 'referensi').evaluate().isEmpty) {
        await choose(tester, 'mobile', 'layanan');
      }
      await choose(tester, 'mobile', 'referensi');
      await choose(tester, 'mobile', 'kurikulum');
      expect(find.text('Belum ada data Kurikulum'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await finish(tester);
    });
  }
}
