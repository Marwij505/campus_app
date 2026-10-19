// Uji tampilan responsif, navigasi menu, dan alur draf tanpa menghubungi AI nyata.
import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_app/core/app_theme.dart';
import 'package:campus_app/data/student_profile.dart';
import 'package:campus_app/features/chatbot/chat_controller.dart';
import 'package:campus_app/features/chatbot/chat_models.dart';
import 'package:campus_app/features/chatbot/chat_page.dart';
import 'package:campus_app/features/chatbot/draft_page.dart';
import 'package:campus_app/features/dashboard/dashboard_page.dart';
import 'package:campus_app/shared/pixel_widgets.dart';

void main() {
  setUpAll(() async {
    // Ukuran font asli membuat tes overflow mendekati tampilan pengguna.
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

  Widget app(Widget page, {double scale = 1}) => MaterialApp(
    theme: AppTheme.data,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: page,
  );

  for (final config in [
    (size: const Size(320, 568), scale: 1.0),
    (size: const Size(390, 844), scale: 2.0),
    (size: const Size(820, 1180), scale: 1.0),
    (size: const Size(1280, 800), scale: 1.0),
  ]) {
    testWidgets('Chat responsif dan input bertahan saat rotasi: $config', (
      tester,
    ) async {
      viewport(tester, config.size);
      final chat = ChatController();
      await tester.pumpWidget(
        app(ChatPage(controller: chat), scale: config.scale),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Apa status KRS saya?');
      // Keyboard mengurangi ruang, tetapi kolom pesan tetap tersedia.
      tester.view.viewInsets = const FakeViewPadding(bottom: 230);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      tester.view.viewInsets = const FakeViewPadding();
      tester.view.physicalSize = const Size(844, 390);
      await tester.pumpAndSettle();
      expect(chat.input, 'Apa status KRS saya?');
      await tester.tap(find.byTooltip('Kirim pesan'));
      await tester.pumpAndSettle();
      expect(chat.messages.last.text, contains('belum terhubung'));
      expect(chat.input, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      chat.dispose();
    });
  }

  testWidgets(
    'Draf surat memerlukan bukti, dapat diedit, dan invalid saat bukti dihapus',
    (tester) async {
      viewport(tester, const Size(390, 844));
      final draft = StudentDraft(DraftKind.letter)
        ..fields.addAll({
          'Nama': 'Mahasiswa Uji',
          'NIM': 'uji',
          'Penerima': 'Petugas',
          'Tanggal mulai': '2026-10-16',
          'Tanggal akhir': '2026-10-17',
          'Alasan': 'Keperluan keluarga',
        });
      await tester.pumpWidget(
        app(
          DraftPage(
            draft: draft,
            picker: () async => [
              XFile.fromData(
                Uint8List.fromList(utf8.encode('%PDF-1.7')),
                name: 'bukti.pdf',
                path: 'bukti.pdf',
                mimeType: 'application/pdf',
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      final preview = find.text('Buat pratinjau draf');
      await tester.ensureVisible(preview);
      await tester.pumpAndSettle();
      await tester.tap(preview);
      await tester.pumpAndSettle();
      expect(draft.preview, isNull);
      expect(
        find.textContaining('Tambahkan bukti terlebih dahulu'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Tambah lampiran'));
      await tester.tap(find.text('Tambah lampiran'));
      await tester.pumpAndSettle();
      expect(draft.attachments.length, 1);
      await tester.ensureVisible(preview);
      await tester.tap(preview);
      await tester.pumpAndSettle();
      expect(draft.preview, contains('BELUM DIKIRIM'));
      final editor = find.widgetWithText(
        TextField,
        'Pratinjau draf · dapat diedit',
      );
      await tester.enterText(editor, 'Draf hasil perbaikan pengguna');
      expect(draft.preview, 'Draf hasil perbaikan pengguna');
      await tester.ensureVisible(find.byTooltip('Hapus bukti.pdf'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Hapus bukti.pdf'));
      await tester.pumpAndSettle();
      expect(draft.preview, isNull);
      expect(draft.attachments, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('Draf kendala bisa dibuat tanpa mengirim pengajuan', (
    tester,
  ) async {
    viewport(tester, const Size(320, 700));
    final draft = StudentDraft(DraftKind.issue)
      ..fields.addAll({
        'Nama': 'Uji',
        'NIM': 'uji',
        'Kategori': 'Akses',
        'Ringkasan': 'Kesulitan masuk',
        'Kronologi': 'Muncul pesan gagal masuk.',
      });
    await tester.pumpWidget(app(DraftPage(draft: draft), scale: 2));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Buat pratinjau draf'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buat pratinjau draf'));
    await tester.pumpAndSettle();
    expect(draft.preview, contains('DRAF KENDALA — BELUM DIKIRIM'));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'Pintasan dan Layanan membuka chat yang sama dengan riwayat sesi',
    (tester) async {
      viewport(tester, const Size(820, 1180));
      await tester.pumpWidget(
        app(
          DashboardPage(
            student: const StudentProfile(nim: 'uji'),
            onLogout: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      final shortcut = find.ancestor(
        of: find.text('Smart Chatbot'),
        matching: find.byType(PixelTapSurface),
      );
      await tester.ensureVisible(shortcut);
      await tester.pumpAndSettle();
      await tester.tap(shortcut);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Halo dari uji');
      await tester.tap(find.byTooltip('Kirim pesan'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Tutup chatbot'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Buka menu'));
      await tester.pumpAndSettle();
      final services = find.descendant(
        of: find.byType(Drawer),
        matching: find.text('Layanan'),
      );
      await tester.ensureVisible(services);
      await tester.pumpAndSettle();
      await tester.tap(services);
      await tester.pumpAndSettle();
      final entry = find.descendant(
        of: find.byType(Drawer),
        matching: find.text('Smart Chatbot'),
      );
      await tester.ensureVisible(entry);
      await tester.pumpAndSettle();
      await tester.tap(entry);
      await tester.pumpAndSettle();
      expect(find.byType(ChatPage), findsOneWidget);
      expect(find.text('Halo dari uji'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
