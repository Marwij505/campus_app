// Uji akses chat di seluruh halaman serta pemisahan riwayat antarakun.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_app/main.dart';
import 'package:campus_app/core/app_theme.dart';
import 'package:campus_app/data/student_profile.dart';
import 'package:campus_app/features/dashboard/dashboard_page.dart';
import 'package:campus_app/features/chatbot/chat_page.dart';
import 'package:campus_app/features/chatbot/draft_page.dart';
import 'package:campus_app/shared/pixel_widgets.dart';

void main() {
  setUpAll(() async {
    await (FontLoader('PressStart2P')
          ..addFont(rootBundle.load('assets/fonts/PressStart2P-Regular.ttf')))
        .load();
    await (FontLoader(
      'SpaceMono',
    )..addFont(rootBundle.load('assets/fonts/SpaceMono-Regular.ttf'))).load();
  });
  void viewport(WidgetTester tester, Size size) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
  }

  Future<void> tap(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  final launcher = find.byKey(const ValueKey('chat-launcher'));
  final close = find.byTooltip('Tutup chatbot');

  for (final size in [
    const Size(390, 844),
    const Size(820, 1180),
    const Size(1280, 800),
  ]) {
    testWidgets('Chat mengambang, detail, dan draf memakai sesi sama: $size', (
      tester,
    ) async {
      viewport(tester, size);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.data,
          home: DashboardPage(
            student: const StudentProfile(nim: 'uji'),
            onLogout: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      final rect = tester.getRect(launcher);
      expect(size.width - rect.right, closeTo(16, 1));
      if (size.width < 600) {
        expect(
          rect.bottom,
          lessThan(
            tester
                .getTopLeft(find.byKey(const ValueKey('phone-navigation')))
                .dy,
          ),
        );
      }
      await tap(tester, launcher);
      final chatRect = tester.getRect(find.byType(ChatPage));
      if (size.width >= 700) {
        expect(chatRect.width, closeTo(440, 1));
        expect(size.width - chatRect.right, closeTo(16, 1));
        expect(size.height - chatRect.bottom, closeTo(16, 1));
      } else {
        expect(chatRect.width, size.width);
      }
      await tester.enterText(
        find.byType(TextField),
        'Riwayat dari tombol mengambang',
      );
      tester.view.viewInsets = const FakeViewPadding(bottom: 230);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      tester.view.viewInsets = const FakeViewPadding();
      // Panel dapat berubah menjadi layar penuh tanpa menghapus pesan yang diketik.
      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpAndSettle();
      expect(find.text('Riwayat dari tombol mengambang'), findsOneWidget);
      tester.view.physicalSize = size;
      await tester.pumpAndSettle();
      await tap(tester, find.byTooltip('Kirim pesan'));
      await tap(tester, close);

      // Halaman detail tetap menyediakan tombol yang sama dan riwayat sebelumnya.
      for (final label in [
        'Biodata',
        'KRS',
        'Jadwal Kuliah',
        'Nilai & Presensi',
        'Tagihan',
        'Pembayaran',
        'Konseling',
      ]) {
        final shortcut = find.ancestor(
          of: find.text(label),
          matching: find.byType(PixelTapSurface),
        );
        await tap(tester, shortcut);
        await tap(tester, launcher);
        expect(find.text('Riwayat dari tombol mengambang'), findsOneWidget);
        await tap(tester, close);
        await tester.pageBack();
        await tester.pumpAndSettle();
      }

      await tap(tester, launcher);
      await tap(tester, find.text('Pilihan bantuan & draf'));
      await tap(tester, find.text('Buat Surat Izin'));
      expect(find.byType(DraftPage), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('draft-Nama')),
        'Nama draf tersimpan',
      );
      // Tombol di draf kembali ke chat yang sudah ada, bukan membuka duplikat.
      await tap(tester, launcher);
      expect(find.byType(DraftPage), findsNothing);
      expect(find.byType(ChatPage), findsOneWidget);
      // Pesan terbaru menggulir ke bawah; naik lagi untuk membuka bantuan.
      await tester.drag(
        find
            .descendant(
              of: find.byType(ChatPage),
              matching: find.byType(ListView),
            )
            .first,
        const Offset(0, 1500),
      );
      await tester.pumpAndSettle();
      if (find
          .widgetWithText(OutlinedButton, 'Buat Surat Izin')
          .evaluate()
          .isEmpty) {
        await tap(tester, find.text('Pilihan bantuan & draf'));
      }
      await tap(tester, find.widgetWithText(OutlinedButton, 'Buat Surat Izin'));
      expect(find.text('Nama draf tersimpan'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets(
    'Semua akun memiliki pintasan dan tombol; logout membersihkan chat',
    (tester) async {
      viewport(tester, const Size(390, 844));
      await tester.pumpWidget(const CampusApp());
      await tester.pumpAndSettle();
      expect(launcher, findsNothing);
      for (final nim in ['20240801001', '20240801002']) {
        await tester.enterText(find.byType(TextFormField).at(0), nim);
        await tester.enterText(find.byType(TextFormField).at(1), '123456');
        await tap(tester, find.widgetWithText(PixelButton, 'MASUK'));
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();
        expect(launcher, findsOneWidget);
        expect(
          find.ancestor(
            of: find.text('Smart Chatbot'),
            matching: find.byType(PixelTapSurface),
          ),
          findsOneWidget,
        );
        await tap(tester, launcher);
        expect(find.text('Pesan privat akun pertama'), findsNothing);
        await tester.enterText(
          find.byType(TextField),
          'Pesan privat akun pertama',
        );
        await tap(tester, find.byTooltip('Kirim pesan'));
        await tap(tester, close);
        await tap(tester, find.byTooltip('Keluar'));
        expect(launcher, findsNothing);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
