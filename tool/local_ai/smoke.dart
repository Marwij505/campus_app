// Uji sambungan nyata secara manual: dart run tool/local_ai/smoke.dart.
// Tidak memakai profil atau lampiran mahasiswa.
import 'dart:io';

import 'package:campus_app/features/chatbot/chat_models.dart';
import 'package:campus_app/features/chatbot/ollama_service.dart';

Future<void> main() async {
  final addressFile = File('.local-ai/endpoint.txt');
  final address = addressFile.existsSync()
      ? addressFile.readAsStringSync().trim()
      : OllamaService.endpoint;
  final service = OllamaService(addresses: () async => [address]);
  try {
    await service.check();
    final reply = await service.reply([
      const ChatMessage(
        'Jelaskan apa itu variabel dalam pemrograman dalam dua kalimat bahasa Indonesia.',
        isUser: true,
      ),
    ]);
    stdout.writeln('Model lokal siap. Jawaban nyata:\n$reply');
  } finally {
    service.cancel();
  }
}
