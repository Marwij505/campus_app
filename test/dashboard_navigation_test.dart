// Pengujian alur pengguna: menu bawah membuka halaman, lalu Back kembali ke beranda.
// Semua identitas uji berada di memori; tes tidak menyentuh data kampus.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_app/core/app_theme.dart';
import 'package:campus_app/features/dashboard/dashboard_page.dart';
import 'package:campus_app/features/dashboard/dashboard_detail_page.dart';
import 'package:campus_app/features/profile/profile_page.dart';

import 'support/fake_auth_service.dart';

void main() {
  setUpAll(() async {
    // Font asli membantu mendeteksi label sempit dan menghasilkan bukti visual.
    for (final entry in {
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      'SpaceMono': 'assets/fonts/SpaceMono-Regular.ttf',
      'PressStart2P': 'assets/fonts/PressStart2P-Regular.ttf',
    }.entries) {
      await (FontLoader(
        entry.key,
      )..addFont(rootBundle.load(entry.value))).load();
    }
  });

  testWidgets('Menu bawah menggulir ke informasi dashboard', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final auth = FakeAuthService();
    addTearDown(auth.dispose);
    await tester.runAsync(
      () => auth.login(identity: '20240801001', password: '123456'),
    );
    final boundary = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.data,
        home: RepaintBoundary(
          key: boundary,
          child: DashboardPage(
            student: auth.currentUser!,
            authService: auth,
            onLogout: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final chat = find.byKey(const ValueKey('chat-launcher'));
    expect(chat, findsOneWidget);
    final center = tester.getCenter(chat);
    expect(center.dx, closeTo(195, .1));
    // Urutan dan ketinggian tombol utama mengikuti referensi navigasi tengah.
    for (final index in [0, 1, 2, 3]) {
      final point = tester.getCenter(find.byKey(ValueKey('bottom-nav-$index')));
      expect(
        point.dx,
        index < 2 ? lessThan(center.dx) : greaterThan(center.dx),
      );
      expect(point.dy, greaterThan(center.dy));
    }
    expect(tester.takeException(), isNull);
    // Artefak lokal untuk memeriksa bentuk dan jarak selain pengujian logika.
    await tester.runAsync(() async {
      final image =
          await (boundary.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/navigation-verification/dashboard-phone.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });

    // Pastikan judul panel berada dalam area layar yang dapat dibaca.
    void expectPanelVisible(String title) {
      final target = find.text(title);
      expect(target, findsOneWidget);

      final panelTop = tester.getTopLeft(target).dy;
      final headerBottom = tester.getBottomLeft(find.byType(AppBar)).dy;
      final navigationTop = tester
          .getTopLeft(find.byKey(const ValueKey('phone-navigation')))
          .dy;

      expect(panelTop, greaterThanOrEqualTo(headerBottom - 1));
      expect(panelTop, lessThan(navigationTop));
    }

    // Jadwal menampilkan panel dashboard tanpa membuka halaman detail.
    await tester.tap(find.byKey(const ValueKey('bottom-nav-1')));
    await tester.pumpAndSettle();
    expectPanelVisible('JADWAL KULIAH HARI INI');
    expect(find.byType(DashboardDetailPage), findsNothing);

    // Akademik menampilkan panel kemajuan belajar.
    await tester.tap(find.byKey(const ValueKey('bottom-nav-2')));
    await tester.pumpAndSettle();
    expectPanelVisible('KEMAJUAN BELAJAR');
    expect(find.byType(DashboardDetailPage), findsNothing);

    // Profil kembali ke kartu mahasiswa, tanpa membuka halaman Biodata.
    await tester.tap(find.byKey(const ValueKey('bottom-nav-3')));
    await tester.pumpAndSettle();
    expectPanelVisible('NIM: 20240801001');
    expect(find.byType(ProfilePage), findsNothing);

    // Beranda mengembalikan posisi gulir ke awal.
    await tester.tap(find.byKey(const ValueKey('bottom-nav-0')));
    await tester.pumpAndSettle();
    expectPanelVisible('SELAMAT DATANG');

    final homeSemantics = tester.widget<Semantics>(
      find
          .ancestor(
            of: find.byKey(const ValueKey('bottom-nav-0')),
            matching: find.byType(Semantics),
          )
          .first,
    );
    expect(homeSemantics.properties.selected, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
