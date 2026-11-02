// Uji layar kecil, pembesaran teks, kegagalan simpan, dan gambar avatar lokal.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_app/core/app_theme.dart';
import 'package:campus_app/data/supabase_auth_service.dart';
import 'package:campus_app/features/profile/profile_page.dart';
import 'package:campus_app/shared/student_profile_avatar.dart';

import 'support/supabase_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await (FontLoader(
      'SpaceMono',
    )..addFont(rootBundle.load('assets/fonts/SpaceMono-Regular.ttf'))).load();
    await (FontLoader('PressStart2P')
          ..addFont(rootBundle.load('assets/fonts/PressStart2P-Regular.ttf')))
        .load();
  });
  for (final size in [
    const Size(320, 700),
    const Size(800, 1000),
    const Size(1440, 1000),
  ]) {
    testWidgets('Profil dan editor muat pada $size', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      // SDK menyiapkan isolate JSON; gunakan waktu nyata di luar jam palsu widget.
      late SupabaseFixture server;
      late SupabaseAuthService auth;
      await tester.runAsync(() async {
        server = SupabaseFixture();
        auth = SupabaseAuthService(server.client);
        await auth.login(identity: '20240801001', password: 'test-password');
      });
      final profileBoundary = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.data,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(size.width == 320 ? 2 : 1),
            ),
            child: child!,
          ),
          home: RepaintBoundary(
            key: profileBoundary,
            child: ProfilePage(service: auth),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Prismatine Dante Viergo'), findsWidgets);
      expect(find.text('Belum diverifikasi'), findsOneWidget);
      expect(tester.takeException(), isNull);
      // Simpan tampilan awal untuk pemeriksaan visual selain pemeriksaan overflow.
      await tester.runAsync(() async {
        final picture =
            await (profileBoundary.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
        final file = File(
          'build/profile-verification/profile-${size.width.toInt()}.png',
        );
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        picture.dispose();
      });
      // Seluruh tab diuji, termasuk formulir saat keyboard/teks besar dipakai.
      for (final tab in [
        'Biodata',
        'Pendidikan',
        'Keluarga',
        'Pekerjaan',
        'Disabilitas',
        'Riwayat Keuangan',
        'Berkas',
      ]) {
        final menu = find.widgetWithText(ListTile, tab);
        await tester.ensureVisible(menu);
        await tester.tap(menu);
        await tester.pumpAndSettle();
        if (find.text('Edit').evaluate().isNotEmpty) {
          await tester.ensureVisible(find.text('Edit'));
          await tester.tap(find.text('Edit'));
          await tester.pumpAndSettle();
          if (find.byType(TextFormField).evaluate().isNotEmpty) {
            await tester.ensureVisible(find.byType(TextFormField).first);
          }
          expect(tester.takeException(), isNull, reason: '$tab editor $size');
          // Pindah tab tidak boleh diam-diam membuang isian yang belum disimpan.
          final target = find.widgetWithText(
            ListTile,
            tab == 'Biodata' ? 'Pendidikan' : 'Biodata',
          );
          await tester.ensureVisible(target);
          await tester.tap(target);
          await tester.pumpAndSettle();
          expect(find.text('Tinggalkan perubahan?'), findsOneWidget);
          await tester.tap(find.text('Tetap mengedit'));
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('Batal'));
          await tester.tap(find.text('Batal'));
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull, reason: '$tab $size');
      }
      await tester.ensureVisible(find.text('Edit foto / nama panggilan'));
      await tester.tap(find.text('Edit foto / nama panggilan'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNWidgets(2));
      expect(tester.takeException(), isNull);
      final name = find.byType(TextField).first;
      await tester.ensureVisible(name);
      await tester.enterText(name, 'Panggilan Baru');
      server.failSave = true;
      await tester.ensureVisible(find.text('Simpan profil'));
      await tester.tap(find.text('Simpan profil'));
      await tester.pumpAndSettle();
      expect(find.textContaining('belum berhasil disimpan'), findsOneWidget);
      expect(auth.currentUser!.preferredName, 'Dante');
      expect(find.text('Panggilan Baru'), findsOneWidget);
      server.failSave = false;
      await tester.ensureVisible(find.text('Simpan profil'));
      await tester.tap(find.text('Simpan profil'));
      await tester.pumpAndSettle();
      expect(auth.currentUser!.preferredName, 'Panggilan Baru');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      auth.dispose();
      await tester.runAsync(server.dispose);
    });
  }
  testWidgets('Render semua avatar ukuran 48, 64, 128 untuk inspeksi visual', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(700, 650);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final boundary = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.data,
        home: Scaffold(
          body: RepaintBoundary(
            key: boundary,
            child: ColoredBox(
              color: AppTheme.paper,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final variant in ['male', 'female', 'neutral'])
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Text(variant),
                            for (final size in [48.0, 64.0, 128.0])
                              StudentProfileAvatar(
                                variant: variant,
                                size: size,
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.runAsync(() async {
      final image =
          await (boundary.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/profile-verification/avatars.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  });
}
