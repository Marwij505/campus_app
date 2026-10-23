// Tinjauan pengguna, pembatalan, dan validasi surat tetap berlaku setelah AI menyunting.
import 'dart:async';

import 'package:campus_app/features/chatbot/draft_editor.dart';
import 'package:campus_app/features/chatbot/draft_language.dart';
import 'package:campus_app/features/chatbot/draft_page.dart';
import 'package:campus_app/features/chatbot/chat_models.dart';
import 'package:campus_app/features/chatbot/ollama_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Editor implements DraftEditorService {
  final pending = Completer<String>();
  String? received;
  bool canceled = false;
  @override
  Future<String> polish(String source) {
    received = source;
    return pending.future;
  }

  @override
  void cancel() {
    canceled = true;
  }
}

void main() {
  testWidgets('Usulan ditinjau, diterapkan ke alasan, bukti tetap wajib', (
    tester,
  ) async {
    final fake = _Editor();
    final draft = StudentDraft(DraftKind.letter)
      ..fields.addAll({
        'Nama': 'Mahasiswa Uji',
        'NIM': 'UJI-1',
        'Penerima': 'Petugas Uji',
        'Tanggal mulai': '2026-10-20',
        'Tanggal akhir': '2026-10-21',
        'Alasan': 'aku gak bisa hadir',
      });
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: DraftPage(draft: draft, editor: fake),
      ),
    );
    await tester.ensureVisible(find.text('Rapikan bahasa dengan AI'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rapikan bahasa dengan AI'));
    await tester.pump();
    expect(fake.received, 'aku gak bisa hadir');
    fake.pending.complete('saya tidak dapat hadir');
    await tester.pumpAndSettle();
    expect(find.text('Tinjau usulan bahasa'), findsOneWidget);
    expect(draft.value('Alasan'), 'aku gak bisa hadir');
    await tester.tap(find.text('Terapkan usulan'));
    await tester.pumpAndSettle();
    expect(draft.value('Alasan'), 'saya tidak dapat hadir');
    expect(draft.value('Nama'), 'Mahasiswa Uji');
    expect(draft.value('Tanggal mulai'), '2026-10-20');
    expect(draft.validate(), contains('bukti'));
    expect(draft.preview, isNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Teks berubah ketika AI bekerja: usulan lama tidak diterapkan', (
    tester,
  ) async {
    final fake = _Editor();
    var source = 'aku gak bisa hadir';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DraftEditor(
            service: fake,
            readText: () => source,
            onApply: (value) => source = value,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Rapikan bahasa dengan AI'));
    await tester.pump();
    source = 'Alasan terbaru';
    fake.pending.complete('saya tidak dapat hadir');
    await tester.pumpAndSettle();
    expect(source, 'Alasan terbaru');
    expect(find.textContaining('Teks sudah berubah'), findsOneWidget);
    expect(find.text('Terapkan usulan'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'AI mati tidak menghapus teks; balasan setelah halaman ditutup diabaikan',
    (tester) async {
      for (final disposeEarly in [false, true]) {
        final fake = _Editor();
        var source = 'aku gak bisa hadir';
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DraftEditor(
                service: fake,
                readText: () => source,
                onApply: (value) => source = value,
              ),
            ),
          ),
        );
        await tester.tap(find.text('Rapikan bahasa dengan AI'));
        await tester.pump();
        if (disposeEarly) await tester.pumpWidget(const SizedBox());
        fake.pending.completeError(
          const ChatServiceException('AI tidak terhubung.'),
        );
        await tester.pumpAndSettle();
        expect(source, 'aku gak bisa hadir');
        if (!disposeEarly) {
          expect(find.textContaining('template draf'), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        expect(fake.canceled, isTrue);
      }
    },
  );
}
