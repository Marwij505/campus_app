// Uji aturan draf, keterbatasan data, dan proses AI tanpa ketergantungan server nyata.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:campus_app/features/chatbot/chat_models.dart';
import 'package:campus_app/features/chatbot/chat_controller.dart';
import 'package:campus_app/features/chatbot/ollama_service.dart';

void main() {
  test('Surat wajib bukti, tanggal valid, dan urutan tanggal', () {
    final draft = StudentDraft(DraftKind.letter);
    expect(draft.validate(), isNotNull);
    draft.fields.addAll({
      'Nama': 'Mahasiswa uji',
      'NIM': 'uji',
      'Penerima': 'Petugas',
      'Tanggal mulai': '2026-10-16',
      'Tanggal akhir': '2026-10-17',
      'Alasan': 'Keperluan keluarga',
    });
    expect(draft.validate(), contains('bukti'));
    expect(draft.compose, throwsStateError);
    draft.attachments.add(
      DraftAttachment('bukti.pdf', Uint8List.fromList(utf8.encode('%PDF-1.7'))),
    );
    expect(draft.validate(), isNull);
    expect(draft.compose(), contains('BELUM DIKIRIM'));
    expect(draft.compose(), contains('Keperluan keluarga'));
    draft.fields['Tanggal akhir'] = '2026-10-15';
    expect(draft.validate(), contains('mendahului'));
    draft.fields['Tanggal akhir'] = '2026-02-31';
    expect(draft.validate(), contains('valid'));
  });

  test('Lampiran menolak kosong, terlalu besar, dan ekstensi palsu', () {
    expect(DraftAttachment.validate('bukti.pdf', Uint8List(0)), isNotNull);
    expect(
      DraftAttachment.validate('bukti.pdf', Uint8List(5 * 1024 * 1024 + 1)),
      isNotNull,
    );
    expect(
      DraftAttachment.validate('bukti.pdf', Uint8List.fromList([1, 2, 3])),
      isNotNull,
    );
    expect(
      DraftAttachment.validate(
        'bukti.exe',
        Uint8List.fromList(utf8.encode('%PDF-1.7')),
      ),
      isNotNull,
    );
    expect(
      DraftAttachment.validate(
        'bukti.pdf',
        Uint8List.fromList(utf8.encode('%PDF-1.7')),
      ),
      isNull,
    );
  });

  test(
    'Data pribadi tidak diteruskan ke model dan input kosong diabaikan',
    () async {
      final fake = _FakeChat();
      final chat = ChatController(service: fake);
      await chat.enableAi();
      await chat.send('   ');
      expect(chat.messages.length, 1);
      await chat.send('Berapa IPK saya?');
      expect(fake.calls, 0);
      expect(chat.messages.last.text, contains('belum terhubung'));
      expect(chat.messages.last.isAi, isFalse);
      chat.dispose();
    },
  );

  test('Klik ganda, retry, pembatalan, dan balasan setelah logout', () async {
    final fake = _FakeChat();
    final chat = ChatController(service: fake);
    await chat.enableAi();
    final first = chat.send('Apa itu variabel?');
    await chat.send('Apa itu variabel?');
    expect(fake.calls, 1);
    fake.pending.completeError(const ChatServiceException('Tidak tersambung'));
    await first;
    expect(chat.canRetry, isTrue);
    final retry = chat.retry();
    expect(chat.messages.where((m) => m.isUser).length, 1);
    fake.pending.complete('Variabel menyimpan nilai.');
    await retry;
    expect(chat.messages.last.isAi, isTrue);
    final canceled = chat.send('Jelaskan lebih lanjut');
    chat.useGuided();
    fake.pending.complete('Balasan terlambat');
    await canceled;
    expect(chat.messages.any((m) => m.text == 'Balasan terlambat'), isFalse);
    await chat.enableAi();
    final afterLogout = chat.send('Apa itu fungsi?');
    chat.dispose();
    fake.pending.complete('Tidak boleh tampil');
    await afterLogout;
    expect(chat.messages, isEmpty);
  });

  test('Ollama mati tetap menyediakan bantuan terpandu', () async {
    final service = OllamaService(
      clientFactory: () =>
          MockClient((_) async => throw http.ClientException('offline')),
    );
    final chat = ChatController(service: service);
    await chat.enableAi();
    expect(chat.mode, ChatMode.guided);
    expect(chat.error, contains('belum terhubung'));
    await chat.send('Buat surat izin');
    expect(chat.messages.last.text, contains('simulasi lokal'));
    expect(chat.messages.last.actions, contains(HelpTopic.letter));
    chat.dispose();
  });

  test(
    'HTTP memeriksa model, system prompt, stream, dan jawaban UTF-8',
    () async {
      final service = OllamaService(
        clientFactory: () => MockClient((request) async {
          expect(request.url.host, '127.0.0.1');
          expect(request.url.port, 11435);
          if (request.method == 'GET') {
            return http.Response('{"models":[{"name":"qwen2.5:1.5b"}]}', 200);
          }
          final body = jsonDecode(request.body) as Map;
          expect(body['stream'], isFalse);
          expect(body['messages'][0]['role'], 'system');
          expect(body['messages'][0]['content'], contains('BELUM terhubung'));
          expect(body['messages'][1]['content'], 'Halo');
          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'done': true,
                'done_reason': 'stop',
                'message': {
                  'content': jsonEncode({
                    'category': 'study',
                    'status': 'general',
                    'answer': 'Halo, mari belajar!',
                    'missing_information': [],
                    'references': [],
                    'action': 'none',
                  }),
                },
              }),
            ),
            200,
          );
        }),
      );
      await service.check();
      expect(
        await service.reply([const ChatMessage('Halo', isUser: true)]),
        'Halo, mari belajar!',
      );
    },
  );

  test(
    'Model hilang dan respons rusak menghasilkan pesan yang jelas',
    () async {
      final service = OllamaService(
        clientFactory: () => MockClient(
          (request) async => http.Response(
            request.method == 'GET' ? '{"models":[]}' : '{}',
            200,
          ),
        ),
      );
      await expectLater(service.check(), throwsA(isA<ChatServiceException>()));
      await expectLater(
        service.reply([const ChatMessage('Halo', isUser: true)]),
        throwsA(isA<ChatServiceException>()),
      );
    },
  );
}

// Model tiruan memberi kendali kapan jawaban selesai agar balapan async bisa diuji.
class _FakeChat implements ChatService {
  int calls = 0;
  Completer<String> pending = Completer<String>();
  @override
  Future<void> check() async {}
  @override
  Future<String> reply(List<ChatMessage> history) {
    calls++;
    pending = Completer<String>();
    return pending.future;
  }

  @override
  void cancel() {}
}
