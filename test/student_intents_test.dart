// Uji kebutuhan mahasiswa tanpa server: jawaban cepat harus tetap berguna
// ketika Ollama mati, dan tidak boleh mengaku sudah membaca data kampus.
import 'package:campus_app/features/chatbot/chat_controller.dart';
import 'package:campus_app/features/chatbot/chat_models.dart';
import 'package:campus_app/features/chatbot/chat_page.dart';
import 'package:campus_app/features/chatbot/chat_policy.dart';
import 'package:campus_app/features/chatbot/ollama_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 12, 31, 23, 59);
  const quickCases = {
    'krs': 'KRS',
    'IPK': 'IPK',
    'ips': 'IPS',
    'jadwal': 'Jadwal kuliah',
    'nilai': 'Nilai dan KHS',
    'presnsi': 'Presensi',
    'tagihan': 'Tagihan',
    'pembayaran': 'Pembayaran',
    'uts': 'Jadwal ujian',
    'tugas': 'Tugas kuliah',
    'pengumuman': 'Pengumuman',
    'sks': 'SKS',
    'skripsi': 'Tugas akhir',
    'bimbingan': 'Bimbingan',
    'magang': 'Magang / KKP',
    'kkn': 'KKN',
    'beasiswa': 'Beasiswa',
    'cuti': 'Cuti kuliah',
    'wisuda': 'Kelulusan',
    'progres': 'Progres studi',
    'biodata': 'Biodata',
    'konseling': 'Konseling',
    'jadwal ujian': 'Jadwal ujian',
    'tugas akhir': 'Tugas akhir',
    'ksr dong': 'KRS',
    'brp ipkk sy?': 'IPK',
    'kuliah hr ini ada ga?': 'Jadwal kuliah',
    'status skripsi': 'Tugas akhir',
  };
  for (final item in quickCases.entries) {
    test('Cek cepat: ${item.key}', () {
      final answer = ChatPolicy.route(item.key, now: today);
      expect(answer.kind, RequestKind.personal);
      expect(answer.text, contains(item.value));
      expect(answer.text, contains('belum terhubung'));
      expect(answer.text, isNot(contains('adalah')));
      expect(answer.usesAi, isFalse);
    });
  }

  test(
    'Tanda tanya ambigu memberikan pilihan, pertanyaan jelas langsung dijawab',
    () {
      for (final query in [
        'ipk?',
        'krs??',
        'jadwal？',
        'skripsi?',
        'konseling?',
      ]) {
        final answer = ChatPolicy.route(query);
        expect(answer.kind, RequestKind.clarify);
        expect(answer.choices.length, greaterThanOrEqualTo(2));
        expect(
          ChatPolicy.route(answer.choices[0].prompt).kind,
          RequestKind.personal,
        );
        final definition = ChatPolicy.route(answer.choices[1].prompt);
        expect(definition.kind, RequestKind.study);
        expect(definition.text, contains('penjelasan umum'));
      }
      for (final query in [
        'jadwal hari ini?',
        'cek krs?',
        'ipk saya?',
        'jadwal jam berapa hari ini?',
      ]) {
        expect(ChatPolicy.route(query).kind, RequestKind.personal);
      }
      expect(
        ChatPolicy.route('apa itu IPK?').text,
        contains('Indeks Prestasi Kumulatif'),
      );
    },
  );

  test('Tanggal perangkat, pergantian tahun, dan lanjutan besok tidak ditebak model', () {
    final first = ChatPolicy.route('jadwal', now: today);
    expect(first.text, contains('hari ini (31/12/2026, tanggal perangkat)'));
    final next = ChatPolicy.route('bsk?', previous: first, now: today);
    expect(next.studentTopic, 'jadwal');
    expect(next.text, contains('besok (01/01/2027, tanggal perangkat)'));
    expect(ChatPolicy.route('jdwl bsk', now: today).text, next.text);
    expect(
      ChatPolicy.route('jadwal lusa', now: today).text,
      contains('02/01/2027'),
    );
    expect(
      ChatPolicy.route('jadwal kemarin', now: today).text,
      contains('30/12/2026'),
    );
    expect(
      ChatPolicy.route('jadwal', now: DateTime(2027, 1, 1)).text,
      contains('01/01/2027'),
    );
    expect(
      ChatPolicy.route('ipk', now: today).text,
      isNot(contains('hari ini')),
    );
  });

  test('Konteks pilihan terbatas pada topik terakhir dan hilang saat topik diganti', () {
    final question = ChatPolicy.route('ipk?');
    final selected = ChatPolicy.route('2', previous: question);
    expect(selected.text, contains('Indeks Prestasi Kumulatif'));
    expect(
      ChatPolicy.route('pengertiannya', previous: question).text,
      selected.text,
    );
    expect(ChatPolicy.route('datanya', previous: selected).studentTopic, 'ipk');
    expect(
      ChatPolicy.route('1', previous: question).kind,
      RequestKind.personal,
    );
    expect(
      ChatPolicy.route('99', previous: question).choices,
      question.choices,
    );
    expect(ChatPolicy.route('1').kind, RequestKind.clarify);
    expect(
      ChatPolicy.route('9' * 100, previous: question).kind,
      RequestKind.clarify,
    );
    final lesson = ChatPolicy.route(
      'Jelaskan fungsi pemrograman',
      previous: question,
    );
    expect(
      ChatPolicy.route('besok?', previous: lesson).kind,
      RequestKind.clarify,
    );
    expect(
      ChatPolicy.route('pengertian', previous: lesson).kind,
      RequestKind.clarify,
    );
    // Tombol lama sudah berisi pertanyaan lengkap, jadi tidak berubah menjadi topik jadwal.
    final schedule = ChatPolicy.route('jadwal?');
    expect(
      ChatPolicy.route(question.choices[1].prompt, previous: schedule).text,
      contains('Indeks Prestasi Kumulatif'),
    );
  });

  test('Semester 1–14 memberi pilihan lokal tanpa menyimpulkan kelulusan atau batas studi', () {
    for (var semester = 1; semester <= 14; semester++) {
      final answer = ChatPolicy.route('smt$semester');
      expect(answer.kind, RequestKind.clarify);
      expect(answer.text, contains('semester $semester'));
      expect(answer.text, contains('belum diverifikasi'));
      expect(answer.text, contains('bukan syarat atau batas masa studi resmi'));
      for (final choice in answer.choices) {
        final selected = ChatPolicy.route(choice.prompt);
        expect(selected.text, isNotNull, reason: choice.prompt);
      }
    }
    expect(
      ChatPolicy.route('semester 15').text,
      contains('bukan batas masa studi resmi'),
    );
  });

  test(
    'Angka semester sangat panjang ditangani sebagai pilihan di luar cakupan',
    () {
      expect(
        ChatPolicy.route('semester ${'9' * 100}').kind,
        RequestKind.clarify,
      );
    },
  );

  test(
    'Istilah panjang tidak mengambil konteks istilah pendek yang berbeda',
    () {
      final cuti = ChatPolicy.route('apa itu cuti kuliah?');
      expect(cuti.studentTopic, 'cuti');
      expect(cuti.text, isNot(contains('Jadwal kuliah memuat')));
      expect(ChatPolicy.route('datanya', previous: cuti).studentTopic, 'cuti');
      final exam = ChatPolicy.route('apa itu jadwal ujian?');
      expect(exam.studentTopic, 'ujian');
      expect(exam.text, isNot(contains('Jadwal kuliah memuat')));
    },
  );

  test(
    'Gabungan dan singkatan tidak menelan pertanyaan pelajaran atau aturan',
    () {
      for (final query in [
        'ipk dan jadwal',
        'ipk, jadwal',
        'nilai & presensi',
      ]) {
        final answer = ChatPolicy.route(query);
        expect(answer.kind, RequestKind.personal);
        expect(
          answer.studentTopic,
          isNull,
        ); // Lanjutan harus memilih satu topik.
      }
      for (final query in [
        'nilai variabel',
        'buat jadwal belajar',
        'Jelaskan skripsi secara umum',
      ]) {
        expect(ChatPolicy.route(query).kind, RequestKind.study);
      }
      expect(ChatPolicy.route('deadline krs').kind, RequestKind.policy);
      expect(
        ChatPolicy.route('syarat lulus semester 14').kind,
        RequestKind.policy,
      );
      expect(ChatPolicy.route('Setujui KRS saya').kind, RequestKind.action);
      expect(ChatPolicy.route('Buat surat izin').kind, RequestKind.draft);
      expect(
        ChatPolicy.route('Kenapa skripsi saya ditolak?').kind,
        RequestKind.personal,
      );
      expect(
        ChatPolicy.route('Kapan jadwal bimbingan saya keluar?').kind,
        RequestKind.personal,
      );
    },
  );

  test(
    'Mode terpandu dan AI memberi jawaban cepat sama tanpa panggilan model',
    () async {
      for (final ai in [false, true]) {
        final service = _StudentService();
        final chat = ChatController(service: service);
        if (ai) await chat.enableAi();
        await chat.send('ipk?');
        expect(chat.messages.last.choices, hasLength(2));
        await chat.send('2');
        expect(chat.messages.last.text, contains('Indeks Prestasi Kumulatif'));
        expect(chat.messages.last.isAi, isFalse);
        await chat.send('datanya');
        expect(chat.messages.last.text, contains('IPK terbaru kamu'));
        chat.newConversation();
        await chat.send('2');
        expect(chat.messages.last.text, contains('Belum ada pilihan aktif'));
        await chat.send('jdwl bsk');
        expect(chat.messages.last.text, contains('besok'));
        expect(service.requests, 0);
        chat.dispose();
      }
    },
  );

  testWidgets('Pilihan berfungsi pada layar HP tanpa mengubah desain chat', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service = _StudentService();
    final chat = ChatController(service: service);
    await tester.pumpWidget(MaterialApp(home: ChatPage(controller: chat)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'ipk?');
    await tester.tap(find.byTooltip('Kirim pesan'));
    await tester.pumpAndSettle();
    final choice = find.widgetWithText(OutlinedButton, '2. Pengertian IPK');
    await tester.ensureVisible(choice);
    await tester.pumpAndSettle();
    await tester.tap(choice);
    await tester.pumpAndSettle();
    expect(chat.messages.last.text, contains('Indeks Prestasi Kumulatif'));
    expect(tester.takeException(), isNull);
    expect(service.requests, 0);
    await tester.pumpWidget(const SizedBox());
    chat.dispose();
  });
}

// Menandai jika jalur cepat tidak sengaja memanggil model.
class _StudentService implements ChatService {
  int requests = 0;
  @override
  Future<void> check() async {}
  @override
  Future<String> reply(List<ChatMessage> history) async {
    requests++;
    return 'Jawaban tutor';
  }

  @override
  void cancel() {}
}
