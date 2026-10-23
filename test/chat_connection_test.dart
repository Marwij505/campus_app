// Uji perpindahan jaringan tanpa bergantung pada Wi-Fi atau Ollama sungguhan.
import 'dart:async';
import 'dart:convert';

import 'package:campus_app/features/chatbot/chat_connection.dart';
import 'package:campus_app/features/chatbot/chat_controller.dart';
import 'package:campus_app/features/chatbot/chat_models.dart';
import 'package:campus_app/features/chatbot/chat_page.dart';
import 'package:campus_app/features/chatbot/ollama_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _ready = '{"models":[{"name":"qwen2.5:1.5b"}]}';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Alamat mengikuti browser, emulator, dan konfigurasi komputer', () {
    expect(ChatConnection.addressesFor(), ['http://127.0.0.1:11435']);
    expect(
      ChatConnection.addressesFor(android: true).first,
      'http://10.0.2.2:11435',
    );
    expect(
      ChatConnection.addressesFor(webHost: '192.168.1.5').first,
      'http://192.168.1.5:11435',
    );
    expect(
      ChatConnection.addressesFor(generated: ['http://192.168.1.8:11435'])
          .first,
      'http://192.168.1.8:11435',
    );
    expect(
      ChatConnection.addressesFor(
        manual: 'http://192.168.1.9:11435',
        android: true,
      ),
      ['http://192.168.1.9:11435'],
    );
    expect(
      ChatConnection.addressesFor(
        configured: 'https://ai.example.test',
        android: true,
      ),
      ['https://ai.example.test'],
    );
  });

  test('Alamat menolak kredensial, path, dan HTTP publik', () {
    for (final invalid in [
      'http://example.com',
      'http://192.168.1.4/api/chat',
      'http://user:secret@localhost:11435',
      'file:///tmp/model',
      'http://192.168.999.2',
    ]) {
      expect(
        () => OllamaService.validateAddress(invalid),
        throwsA(isA<ChatServiceException>()),
      );
    }
    for (final valid in [
      'http://10.0.2.2:11435',
      'http://192.168.1.4:11435',
      'http://172.16.1.4:11435',
      'http://localhost:11435',
      'https://ai.example.test',
    ]) {
      expect(OllamaService.validateAddress(valid).host, isNotEmpty);
    }
  });

  test(
    'Kandidat gagal dilewati; hanya server dengan model siap yang dipilih',
    () async {
      final checked = <String>[];
      final service = OllamaService(
        addresses: () async => [
          'http://10.0.2.2:11435',
          'http://192.168.1.2:11435',
          'http://192.168.1.3:11435',
        ],
        clientFactory: () => MockClient((request) async {
          checked.add(request.url.host);
          if (request.url.host == '10.0.2.2') {
            throw http.ClientException('offline');
          }
          return http.Response(
            request.url.host.endsWith('.2') ? '{"models":[]}' : _ready,
            200,
          );
        }),
      );
      await service.check();
      expect(checked, ['10.0.2.2', '192.168.1.2', '192.168.1.3']);
      expect(service.connectedAddress, 'http://192.168.1.3:11435');
      service.cancel();
    },
  );

  test('Alamat baru diperiksa kembali sebelum mengirim percakapan', () async {
    var address = 'http://192.168.1.2:11435';
    String? postedHost;
    final service = OllamaService(
      addresses: () async => [address],
      clientFactory: () => MockClient((request) async {
        if (request.method == 'GET') return http.Response(_ready, 200);
        postedHost = request.url.host;
        return http.Response(
          jsonEncode({
            'done': true,
            'done_reason': 'stop',
            'message': {
              'content': jsonEncode({
                'category': 'study',
                'status': 'general',
                'answer': 'Jawaban lokal',
                'missing_information': [],
                'references': [],
                'action': 'none',
              }),
            },
          }),
          200,
        );
      }),
    );
    await service.check();
    address = 'http://192.168.1.3:11435';
    expect(
      await service.reply([const ChatMessage('Halo', isUser: true)]),
      'Jawaban lokal',
    );
    expect(postedHost, '192.168.1.3');
    service.cancel();
  });

  test(
    'Pembatalan menghentikan pencarian dan mencegah pengiriman pesan',
    () async {
      final pending = Completer<http.Response>();
      var requests = 0;
      final service = OllamaService(
        addresses: () async => [
          'http://192.168.1.2:11435',
          'http://192.168.1.3:11435',
        ],
        clientFactory: () => MockClient((request) {
          requests++;
          return pending.future;
        }),
      );
      final reply = service.reply([const ChatMessage('Halo', isUser: true)]);
      final assertion = expectLater(
        reply,
        throwsA(isA<ChatServiceException>()),
      );
      await Future<void>.delayed(Duration.zero);
      service.cancel();
      pending.complete(http.Response(_ready, 200));
      await assertion;
      expect(requests, 1);
      expect(service.connectedAddress, isNull);
    },
  );

  test(
    'Otomatis pulih setelah offline; pilihan terpandu tidak ditimpa',
    () async {
      final fake = _ConnectionFake()..offline = true;
      final chat = ChatController(service: fake);
      await chat.autoConnect();
      expect(chat.mode, ChatMode.guided);
      expect(chat.error, isNotNull);
      fake.offline = false;
      await chat.autoConnect();
      expect(chat.mode, ChatMode.localAi);
      expect(chat.error, isNull);
      chat.useGuided();
      final checks = fake.checks;
      await chat.autoConnect();
      expect(chat.mode, ChatMode.guided);
      expect(fake.checks, checks);
      chat.dispose();
    },
  );

  test(
    'Alamat manual tersimpan; kosong mengembalikan pencarian otomatis',
    () async {
      SharedPreferences.setMockInitialValues({});
      await ChatConnection.saveAddress('http://192.168.1.6:11435');
      expect(await ChatConnection.savedAddress(), 'http://192.168.1.6:11435');
      expect(
        (await SharedPreferences.getInstance()).getString(
          'campus.localAi.address',
        ),
        'http://192.168.1.6:11435',
      );
      expect(await ChatConnection.candidates(), ['http://192.168.1.6:11435']);
      await ChatConnection.saveAddress('');
      expect(await ChatConnection.savedAddress(), isEmpty);
    },
  );

  testWidgets('Chat otomatis aktif dan pengaturan bisa dikoreksi pada HP', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await ChatConnection.saveAddress('');
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final chat = ChatController(service: _ConnectionFake());
    await tester.pumpWidget(MaterialApp(home: ChatPage(controller: chat)));
    await tester.pumpAndSettle();
    expect(find.text('AI LOKAL AKTIF'), findsOneWidget);
    await tester.tap(find.byTooltip('Pengaturan koneksi'));
    await tester.pumpAndSettle();
    final field = find.widgetWithText(TextField, 'Alamat komputer AI');
    await tester.enterText(field, 'http://example.com');
    await tester.tap(find.text('Simpan & sambungkan'));
    await tester.pumpAndSettle();
    expect(find.textContaining('HTTP hanya'), findsOneWidget);
    await tester.enterText(field, 'http://192.168.1.7:11435');
    await tester.tap(find.text('Simpan & sambungkan'));
    await tester.pumpAndSettle();
    expect(find.text('Koneksi AI lokal'), findsNothing);
    expect(await ChatConnection.savedAddress(), 'http://192.168.1.7:11435');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    chat.dispose();
    await ChatConnection.saveAddress('');
  });
}

// Pengganti server membuat status online/offline dapat diuji tanpa unduhan model.
class _ConnectionFake implements ChatService {
  bool offline = false;
  int checks = 0;
  @override
  Future<void> check() async {
    checks++;
    if (offline) throw const ChatServiceException('Server offline');
  }

  @override
  Future<String> reply(List<ChatMessage> history) async => 'Jawaban lokal';
  @override
  void cancel() {}
}
