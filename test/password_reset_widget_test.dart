// Uji perjalanan pemulihan tanpa mengirim email atau mengganti akun sungguhan.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_app/data/auth_service.dart';
import 'package:campus_app/features/auth/forgot_password_page.dart';
import 'package:campus_app/shared/pixel_widgets.dart';

import 'support/fake_auth_service.dart';

class ResetService extends FakeAuthService {
  int requests = 0, confirmations = 0;
  String? failure;
  Completer<void>? pending;
  @override
  Future<void> requestReset(String email) async {
    requests++;
    if (pending != null) await pending!.future;
    if (failure != null) throw AuthException(failure!);
  }

  @override
  Future<void> confirmReset({
    required String email,
    required String code,
    required String password,
  }) async {
    confirmations++;
    if (failure != null) throw AuthException(failure!);
  }
}

Future<void> open(WidgetTester tester, ResetService service) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(home: ForgotPasswordPage(service: service)),
  );
  await tester.pumpAndSettle();
}

Future<void> press(WidgetTester tester, String label) async {
  final button = find.widgetWithText(PixelButton, label);
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> request(WidgetTester tester) async {
  await tester.enterText(
    find.byType(TextFormField).first,
    'student@example.com',
  );
  await press(tester, 'KIRIM KODE OTP');
}

void main() {
  testWidgets(
    'OTP: validasi, konfirmasi password, berhasil tanpa login otomatis',
    (tester) async {
      final service = ResetService();
      await open(tester, service);
      await press(tester, 'KIRIM KODE OTP');
      expect(service.requests, 0);
      await request(tester);
      expect(service.requests, 1);
      expect(find.textContaining('Jika email terdaftar'), findsOneWidget);
      final resend = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Kirim ulang dalam 60 detik'),
      );
      expect(resend.onPressed, isNull);
      await tester.enterText(find.byType(TextFormField).at(1), '123456');
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'PasswordBaru123!',
      );
      await tester.enterText(find.byType(TextFormField).at(3), 'berbeda');
      await press(tester, 'GANTI PASSWORD');
      expect(service.confirmations, 0);
      expect(find.text('Konfirmasi password belum sama.'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).at(1), 'ab23cd');
      await tester.enterText(
        find.byType(TextFormField).at(3),
        'PasswordBaru123!',
      );
      await press(tester, 'GANTI PASSWORD');
      expect(service.confirmations, 1);
      expect(find.textContaining('Password berhasil diganti.'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
      expect(service.hasSession, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'OTP: kegagalan layanan tetap bisa dicoba; kode gagal tidak mengaku berhasil',
    (tester) async {
      final service = ResetService()..failure = 'Layanan email belum siap.';
      await open(tester, service);
      await request(tester);
      expect(find.text('Layanan email belum siap.'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
      service.failure = null;
      await request(tester);
      await tester.enterText(find.byType(TextFormField).at(1), 'AB23CD');
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'PasswordBaru123!',
      );
      await tester.enterText(
        find.byType(TextFormField).at(3),
        'PasswordBaru123!',
      );
      service.failure = 'Kode sudah kedaluwarsa.';
      await press(tester, 'GANTI PASSWORD');
      expect(find.text('Kode sudah kedaluwarsa.'), findsOneWidget);
      expect(find.textContaining('Password berhasil diganti.'), findsNothing);
      await tester.ensureVisible(find.text('Gunakan email lain'));
      await tester.tap(find.text('Gunakan email lain'));
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('KODE OTP'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('OTP: menutup halaman saat permintaan masih berjalan aman', (
    tester,
  ) async {
    final service = ResetService()..pending = Completer<void>();
    await open(tester, service);
    await tester.enterText(find.byType(TextFormField), 'student@example.com');
    final button = find.widgetWithText(PixelButton, 'KIRIM KODE OTP');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
    expect(service.requests, 1);
    await tester.pumpWidget(const SizedBox());
    service.pending!.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Form OTP lengkap tetap muat di layar kecil dengan keyboard', (
    tester,
  ) async {
    await open(tester, ResetService());
    tester.view.physicalSize = const Size(320, 568);
    tester.view.viewInsets = const FakeViewPadding(bottom: 220);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    await request(tester);
    await press(tester, 'GANTI PASSWORD');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
