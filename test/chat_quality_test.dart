// Paket pertanyaan tetap untuk kondisi proyek tanpa database/panduan kampus.
import 'dart:convert';
import 'dart:io';

import 'package:campus_app/features/chatbot/chat_controller.dart';
import 'package:campus_app/features/chatbot/chat_models.dart';
import 'package:campus_app/features/chatbot/chat_policy.dart';
import 'package:campus_app/features/chatbot/chat_protocol.dart';
import 'package:campus_app/features/chatbot/draft_language.dart';
import 'package:campus_app/features/chatbot/ollama_service.dart';
import 'package:campus_app/features/chatbot/chat_page.dart';
import 'package:campus_app/features/chatbot/draft_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, Object> result({String answer = 'Penjelasan umum'}) => {
  'category': 'study',
  'status': 'general',
  'answer': answer,
  'missing_information': <String>[],
  'references': <String>[],
  'action': 'none',
};

void main() {
  final cases = jsonDecode(
    File('test/fixtures/chatbot_quality.json').readAsStringSync(),
  ) as List;
  for (final entry in cases) {
    test('Rute: ${entry['question']}', () {
      expect(
        ChatPolicy.route(entry['question'] as String).kind.name,
        entry['kind'],
      );
    });
  }

  test(
    'Sumber belum terhubung tidak disamakan dengan kosong atau angka nol',
    () async {
      final fake = _QualityService();
      final chat = ChatController(service: fake);
      await chat.enableAi();
      for (final question in [
        'Berapa IPK saya?',
        'Kenapa KRS saya ditolak?',
        'Tampilkan nilai teman saya',
        'Kirim surat ini sekarang',
      ]) {
        await chat.send(question);
        expect(chat.messages.last.text, contains('belum terhubung'));
        expect(chat.messages.last.isAi, isFalse);
        expect(chat.messages.last.actions, isNotEmpty);
      }
      expect(fake.requests, isEmpty);
      expect(chat.capabilities.status(CampusSource.records), 'Belum terhubung');
      chat.dispose();
    },
  );

  test(
    'Konsep akademik diteruskan ke tutor; topik baru tidak membawa data lama',
    () async {
      final fake = _QualityService();
      final chat = ChatController(service: fake);
      await chat.enableAi();
      await chat.send('Apa itu KRS?');
      expect(fake.requests, isEmpty);
      expect(chat.messages.last.text, contains('Kartu Rencana Studi'));
      await chat.send('Jelaskan lagi lebih sederhana');
      expect(fake.requests.last.first.text, 'Apa itu KRS?');
      await chat.send('Jelaskan fungsi dalam pemrograman');
      expect(fake.requests.last.length, 1);
      chat.newConversation();
      final count = fake.requests.length;
      await chat.send('Lanjutkan yang tadi');
      expect(fake.requests.length, count);
      expect(chat.messages.last.text, contains('Topik atau teks'));
      chat.dispose();
    },
  );

  test(
    'Lanjutan pertanyaan personal tetap memakai batas sumber, bukan model',
    () async {
      final fake = _QualityService();
      final chat = ChatController(service: fake);
      await chat.enableAi();
      await chat.send('Berapa IPK saya?');
      await chat.send('Jelaskan lagi');
      expect(fake.requests, isEmpty);
      expect(chat.messages.last.label, 'Sumber belum terhubung');
      chat.dispose();
    },
  );

  test('Glosarium umum dapat dipakai tanpa Ollama', () async {
    final chat = ChatController(service: _QualityService());
    await chat.send('Apa itu KRS?');
    expect(chat.messages.last.text, contains('Kartu Rencana Studi'));
    expect(chat.messages.last.text, contains('penjelasan umum'));
    chat.dispose();
  });

  test(
    'Konteks mempertahankan anchor dan percakapan terbaru dalam anggaran',
    () {
      final history = <ChatMessage>[
        const ChatMessage('Jelaskan fungsi', isUser: true),
        const ChatMessage('Fungsi mengelompokkan instruksi.'),
      ];
      for (var i = 0; i < 20; i++) {
        history.add(ChatMessage('Contoh ke-$i ${'x' * 150}', isUser: true));
        history.add(ChatMessage('Jawaban $i ${'y' * 500}'));
      }
      history.add(const ChatMessage('Lanjutkan yang tadi', isUser: true));
      final context = ChatProtocol.context(history);
      expect(context.first.text, 'Jelaskan fungsi');
      expect(context.last.text, 'Lanjutkan yang tadi');
      expect(context.any((m) => m.text.startsWith('Jawaban 19')), isTrue);
      expect(
        context.fold<int>(0, (n, m) => n + m.text.length),
        lessThanOrEqualTo(6500),
      );
      expect(context.length, lessThan(history.length));
      final short = ChatProtocol.context(
        history.take(2).toList()
          ..add(const ChatMessage('Contohnya?', isUser: true)),
      );
      expect(short[1].text, 'Fungsi mengelompokkan instruksi.');
    },
  );

  test('Struktur menolak sumber palsu, aksi, field tambahan, dan klarifikasi rusak', () {
    expect(
      ChatProtocol.parse(jsonEncode(result()), ChatTask.study),
      'Penjelasan umum',
    );
    for (final invalid in [
      result()..['references'] = ['Pedoman kampus halaman 8'],
      result()..['action'] = 'send',
      result()..['status'] = 'official',
      result()..['unexpected'] = true,
      result()..['category'] = 'clarification',
      result()..['missing_information'] = ['Pertanyaan A?', 'Pertanyaan B?'],
      result()..['answer'] = '',
      result()
        ..['category'] = 'clarification'
        ..['missing_information'] = ['fungsi'],
      result(answer: 'Saya telah mengirim surat Anda.'),
    ]) {
      expect(
        () => ChatProtocol.parse(jsonEncode(invalid), ChatTask.study),
        throwsFormatException,
      );
    }
  });

  test('Hasil terpotong dan JSON rusak tidak menjadi pesan AI', () async {
    for (final response in [
      {
        'done': true,
        'done_reason': 'length',
        'message': {'content': jsonEncode(result())},
      },
      {
        'done': false,
        'done_reason': 'stop',
        'message': {'content': jsonEncode(result())},
      },
      {
        'done': true,
        'done_reason': 'stop',
        'message': {'content': '{invalid'},
      },
    ]) {
      final service = OllamaService(
        clientFactory: () => MockClient(
          (request) async => http.Response(
            request.method == 'GET'
                ? '{"models":[{"name":"qwen2.5:1.5b"}]}'
                : jsonEncode(response),
            200,
          ),
        ),
      );
      final chat = ChatController(service: service);
      await chat.enableAi();
      await chat.send('Apa itu variabel?');
      expect(chat.canRetry, isTrue);
      expect(chat.messages.where((m) => m.isAi), isEmpty);
      chat.dispose();
    }
  });

  test('Penyunting hanya mengganti bahasa; fakta dan angka tetap verbatim', () {
    const original =
        'aku gak bisa hadir tanggal 2026-10-20 karena sakit. Dokter A, 2 hari.';
    expect(
      DraftLanguage.apply(original, '{"edits":["aku","gak bisa"]}'),
      'saya tidak dapat hadir tanggal 2026-10-20 karena sakit. Dokter A, 2 hari.',
    );
    for (final invalid in [
      '{"edits":["diagnosis demam berdarah"]}',
      '{"edits":["aku","aku"]}',
      '{"edits":[],"diagnosis":"baru"}',
    ]) {
      expect(
        () => DraftLanguage.apply(original, invalid),
        throwsFormatException,
      );
    }
  });

  test('Konteks yang tidak muat tidak diam-diam memakai jawaban lama', () {
    expect(
      () => ChatProtocol.context([
        const ChatMessage('Topik awal', isUser: true),
        const ChatMessage('Jawaban awal'),
        ChatMessage('q' * 2000, isUser: true),
        ChatMessage('a' * 4500),
        const ChatMessage('Lanjutkan yang tadi', isUser: true),
      ]),
      throwsA(isA<ContextLimitException>()),
    );
    expect(
      ChatProtocol.parse(
        jsonEncode(result()..['missing_information'] = ['fungsi']),
        ChatTask.study,
      ),
      'Penjelasan umum',
    );
  });

  testWidgets(
    'Respons sumber belum tersedia menawarkan tombol draf yang berfungsi',
    (tester) async {
      final chat = ChatController(service: _QualityService());
      await tester.pumpWidget(MaterialApp(home: ChatPage(controller: chat)));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField),
        'Kenapa KRS saya ditolak?',
      );
      await tester.tap(find.byTooltip('Kirim pesan'));
      await tester.pumpAndSettle();
      final action = find.widgetWithText(OutlinedButton, 'Laporkan Kendala');
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(find.byType(DraftPage), findsOneWidget);
      expect(find.text('DRAF LOKAL · BELUM DIKIRIM'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      chat.dispose();
    },
  );

  test('Penyunting mengirim teks pilihan saja, dengan skema khusus', () async {
    final service = OllamaService(
      clientFactory: () => MockClient((request) async {
        if (request.method == 'GET') {
          return http.Response('{"models":[{"name":"qwen2.5:1.5b"}]}', 200);
        }
        final body = jsonDecode(request.body) as Map;
        expect(body['format']['required'], ['edits']);
        expect(body['messages'].length, 2);
        final user =
            jsonDecode(body['messages'][1]['content'] as String) as Map;
        expect(user.keys.toSet(), {'text', 'allowed_edits'});
        expect(user['text'], 'aku gak bisa hadir');
        return http.Response(
          jsonEncode({
            'done': true,
            'done_reason': 'stop',
            'message': {'content': '{"edits":["aku","gak bisa"]}'},
          }),
          200,
        );
      }),
    );
    expect(
      await service.polish('aku gak bisa hadir'),
      'saya tidak dapat hadir',
    );
  });
}

class _QualityService implements ChatService {
  final requests = <List<ChatMessage>>[];
  @override
  Future<void> check() async {}
  @override
  Future<String> reply(List<ChatMessage> history) async {
    requests.add(List.of(history));
    return 'Penjelasan umum untuk ${history.last.text}';
  }

  @override
  void cancel() {}
}
