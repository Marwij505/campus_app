import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_app/main.dart';
import 'package:campus_app/shared/pixel_widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Gunakan font produksi, bukan font Ahem bawaan test, agar ukuran teks realistis.
  setUpAll(() async {
    final pixel = FontLoader('PressStart2P')
      ..addFont(rootBundle.load('assets/fonts/PressStart2P-Regular.ttf'));
    final mono = FontLoader('SpaceMono')
      ..addFont(rootBundle.load('assets/fonts/SpaceMono-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/SpaceMono-Bold.ttf'));
    await pixel.load();
    await mono.load();
  });

  testWidgets('Login gagal, login berhasil, logout, dan pemulihan demo', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);

    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const CampusApp());
    await tester.pumpAndSettle();

    Future<void> submit(String label) async {
      final button = find.widgetWithText(PixelButton, label);

      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();

      // Majukan waktu simulasi server, lalu selesaikan animasi.
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
    }

    await tester.enterText(find.byType(TextFormField).at(0), '20240801002');
    await tester.enterText(find.byType(TextFormField).at(1), 'salah');

    await submit('MASUK');

    expect(find.text('NIM / NIP atau password salah.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(1), '123456');

    await submit('MASUK');

    expect(find.text('Reifan Ardissa'), findsOneWidget);
    expect(find.text('AKSES CEPAT'), findsOneWidget);

    await tester.tap(find.byTooltip('Keluar'));
    await tester.pumpAndSettle();

    expect(find.text('SIAKAD.EXE'), findsOneWidget);

    await tester.ensureVisible(find.text('Lupa password?'));
    await tester.tap(find.text('Lupa password?'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'bukan-email');
    await submit('KIRIM LINK RESET');

    expect(find.text('Alamat email belum valid.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'demo@example.com');
    await submit('KIRIM LINK RESET');

    expect(find.textContaining('Email belum dikirim'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  // Uji layout pada ponsel kecil, ukuran referensi, dan layar lebih lebar.
  // Jangan menghapus exception: overflow merupakan kegagalan UI yang perlu diperbaiki.
  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(600, 900),
  ]) {
    testWidgets('Login dan reset tidak overflow pada $size', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(const CampusApp());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final forgot = find.text('Lupa password?');
      await tester.ensureVisible(forgot);
      await tester.tap(forgot);
      await tester.pumpAndSettle();
      expect(find.text('RESET_PASSWORD.EXE'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Kembali ke login'));
      await tester.tap(find.text('Kembali ke login'));
      await tester.pumpAndSettle();
      expect(find.text('SIAKAD.EXE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Keyboard terbuka: form tetap dapat digulir', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(const CampusApp());
    await tester.pumpAndSettle();
    final button = find.widgetWithText(PixelButton, 'MASUK');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text('NIM / NIP wajib diisi.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
