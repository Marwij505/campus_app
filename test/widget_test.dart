import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_app/main.dart';
import 'package:campus_app/shared/pixel_widgets.dart';

void main() {
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
}
