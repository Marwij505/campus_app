import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_app/main.dart';

void main() {
  /// ==========================================================
  /// SIAKAD FASILKOM WIDGET TEST
  /// ==========================================================

  group(
    'SIAKAD Fasilkom - Authentication',
    () {
      // ========================================================
      // TEST 1
      // Login Page tampil.
      // ========================================================

      testWidgets(
        'Login page tampil dengan komponen utama',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            const CampusApp(),
          );

          await tester.pumpAndSettle();

          expect(
            find.text('Selamat Datang'),
            findsOneWidget,
          );

          expect(
            find.text(
              'Masuk untuk mengakses layanan\n'
              'akademik fakultas',
            ),
            findsOneWidget,
          );

          expect(
            find.text('Lupa Password?'),
            findsOneWidget,
          );

          expect(
            find.text('Ingat saya'),
            findsOneWidget,
          );

          // NIM + Password.
          expect(
            find.byType(TextFormField),
            findsNWidgets(2),
          );

          expect(
            find.widgetWithText(
              ElevatedButton,
              'Login',
            ),
            findsOneWidget,
          );
        },
      );

      // ========================================================
      // TEST 2
      // Form kosong.
      // ========================================================

      testWidgets(
        'Login kosong menampilkan validasi',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            const CampusApp(),
          );

          await tester.pumpAndSettle();

          final loginButton =
              find.widgetWithText(
            ElevatedButton,
            'Login',
          );

          await tester.tap(loginButton);

          await tester.pumpAndSettle();

          expect(
            find.text(
              'NIM / NIDN / Email wajib diisi.',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'Password wajib diisi.',
            ),
            findsOneWidget,
          );
        },
      );

      // ========================================================
      // TEST 3
      // Remember Me.
      // ========================================================

      testWidgets(
        'Ingat saya dapat diaktifkan',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            const CampusApp(),
          );

          await tester.pumpAndSettle();

          final checkbox =
              find.byType(Checkbox);

          expect(
            checkbox,
            findsOneWidget,
          );

          await tester.tap(checkbox);

          await tester.pump();

          final checkboxWidget =
              tester.widget<Checkbox>(
            checkbox,
          );

          expect(
            checkboxWidget.value,
            true,
          );
        },
      );

      // ========================================================
      // TEST 4
      // Forgot Password navigation.
      // ========================================================

      testWidgets(
        'Lupa Password membuka Forgot Password Page',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            const CampusApp(),
          );

          await tester.pumpAndSettle();

          await tester.tap(
            find.text('Lupa Password?'),
          );

          // Menunggu slide + fade selesai.
          await tester.pumpAndSettle();

          expect(
            find.text('Lupa Password'),
            findsOneWidget,
          );

          expect(
            find.text('Kirim Link Reset'),
            findsOneWidget,
          );
        },
      );

      // ========================================================
      // TEST 5
      // Login dummy berhasil.
      // ========================================================

      testWidgets(
        'Login dummy berhasil masuk Dashboard',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            const CampusApp(),
          );

          await tester.pumpAndSettle();

          final fields =
              find.byType(TextFormField);

          // NIM.
          await tester.enterText(
            fields.at(0),
            '2024010001',
          );

          // Password.
          await tester.enterText(
            fields.at(1),
            'fasilkom123',
          );

          await tester.tap(
            find.widgetWithText(
              ElevatedButton,
              'Login',
            ),
          );

          // Tunggu dummy server + animation.
          await tester.pumpAndSettle();

          expect(
            find.text('Dashboard'),
            findsOneWidget,
          );

          expect(
            find.textContaining(
              'Login berhasil.',
            ),
            findsOneWidget,
          );
        },
      );
    },
  );
}