import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_app/data/auth_service.dart';
import 'package:campus_app/features/auth/reset_password_page.dart';

import 'support/fake_auth_service.dart';

class PasswordService extends FakeAuthService {
  int calls = 0;
  final pending = Completer<void>();
  @override
  Future<void> changePassword(String password) async {
    calls++;
    await pending.future;
    throw const AuthException(
      'Hasil perubahan password belum dapat dipastikan.',
    );
  }
}

void main() {
  testWidgets(
    'Password UI menolak input, menahan klik ganda, dan menampilkan hasil tidak pasti',
    (tester) async {
      final service = PasswordService();
      await tester.pumpWidget(
        MaterialApp(home: ResetPasswordPage(service: service)),
      );
      Future<void> enter(String password, String confirmation) async {
        await tester.enterText(find.byType(TextField).first, password);
        await tester.enterText(find.byType(TextField).last, confirmation);
        await tester.ensureVisible(find.text('Simpan password'));
        await tester.tap(find.text('Simpan password'));
        await tester.pump();
      }

      await enter('short', 'short');
      expect(service.calls, 0);
      await enter('x' * 257, 'x' * 257);
      expect(service.calls, 0);
      await enter('test-only-password', 'mismatch');
      expect(service.calls, 0);
      await enter('test-only-password', 'test-only-password');
      expect(service.calls, 1);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      service.pending.complete();
      await tester.pumpAndSettle();
      expect(find.textContaining('belum dapat dipastikan'), findsOneWidget);
      expect(find.textContaining('Password belum berubah'), findsNothing);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
      service.dispose();
    },
  );

  testWidgets(
    'Respons password setelah halaman ditutup tidak menyentuh controller',
    (tester) async {
      final service = PasswordService();
      await tester.pumpWidget(
        MaterialApp(home: ResetPasswordPage(service: service)),
      );
      for (final field in find.byType(TextField).evaluate()) {
        await tester.enterText(
          find.byWidget(field.widget),
          'test-only-password',
        );
      }
      await tester.ensureVisible(find.text('Simpan password'));
      await tester.tap(find.text('Simpan password'));
      await tester.pumpWidget(const SizedBox());
      service.pending.complete();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      service.dispose();
    },
  );
}
