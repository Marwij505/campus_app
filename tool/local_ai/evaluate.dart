// Jalankan manual setelah start.ps1. Hasil disimpan untuk tinjauan isi, bukan skor kebenaran otomatis.
import 'dart:convert';
import 'dart:io';

import 'package:campus_app/features/chatbot/chat_models.dart';
import 'package:campus_app/features/chatbot/chat_policy.dart';
import 'package:campus_app/features/chatbot/ollama_service.dart';

Future<void> main() async {
  final addressFile = File('.local-ai/endpoint.txt');
  final service = OllamaService(
    addresses: () async => [
      addressFile.existsSync()
          ? addressFile.readAsStringSync().trim()
          : OllamaService.endpoint,
    ],
  );
  final rows = <Map<String, Object>>[];
  final watch = Stopwatch()..start();
  final fixtures = jsonDecode(
    File('test/fixtures/chatbot_quality.json').readAsStringSync(),
  ) as List;
  final passed = fixtures
      .where(
        (item) =>
            ChatPolicy.route(item['question'] as String).kind.name ==
            item['kind'],
      )
      .length;
  stdout.writeln('Rute pertanyaan: $passed/${fixtures.length} sesuai acuan.');
  var history = <ChatMessage>[];
  RequestPlan? previous;
  try {
    for (final question in [
      'Apa itu KRS? Jelaskan singkat secara umum.',
      'Kenapa KRS saya ditolak?',
      'Apa syarat cuti kampus?',
      'Jelaskan fungsi dalam pemrograman dengan satu contoh sederhana.',
      'Jelaskan lagi lebih sederhana.',
      'jadwal',
      'bsk?',
      'ipk?',
      '2',
      'datanya',
      'semester14',
    ]) {
      final plan = ChatPolicy.route(question, previous: previous);
      previous = plan;
      if (!plan.followUp) history = [];
      final String answer;
      final definition = plan.kind == RequestKind.study
          ? plan.text ?? ChatPolicy.definition(question)
          : null;
      if (definition != null) {
        answer = definition;
        history.addAll([
          ChatMessage(question, isUser: true),
          ChatMessage(answer),
        ]);
      } else if (plan.usesAi) {
        history.add(ChatMessage(question, isUser: true));
        answer = await service.reply(history);
        history.add(ChatMessage(answer, isAi: true));
      } else {
        answer = plan.text!;
      }
      rows.add({
        'question': question,
        'kind': plan.kind.name,
        'source': plan.usesAi && definition == null ? 'ollama' : 'application',
        'answer': answer,
        'choices': plan.choices.map((choice) => choice.label).toList(),
      });
      stdout.writeln('${plan.kind.name}: $question\n$answer\n');
    }
    const original = 'aku gak bisa hadir pada 2026-10-20 karena sakit. makasih';
    final revised = await service.polish(original);
    rows.add({
      'question': original,
      'kind': 'draft_edit',
      'source': 'ollama_constrained_edits',
      'answer': revised,
    });
    stdout.writeln('Usulan bahasa: $revised');
  } on ChatServiceException catch (error) {
    rows.add({'error': error.message});
    stderr.writeln(error.message);
    exitCode = 1;
  } finally {
    service.cancel();
    watch.stop();
    final report = File('build/local-ai-quality.json');
    report.parent.createSync(recursive: true);
    report.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'model': OllamaService.model,
        'routing_passed': passed,
        'routing_total': fixtures.length,
        'duration_ms': watch.elapsedMilliseconds,
        'results': rows,
        'note': 'Keluaran nyata perlu dinilai manusia. Tes rute dan skema tidak membuktikan semua jawaban model benar.',
      }),
    );
    stdout.writeln('Laporan: ${report.path}');
  }
}
