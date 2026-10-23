// Menerjemahkan pesan pendek menjadi kebutuhan layanan sebelum meminta jawaban AI.
// Pencocokan dibatasi pada pola kebutuhan, agar pelajaran seperti "nilai variabel"
// tetap diteruskan ke tutor. Tidak ada data akademik buatan dalam jawaban ini.
import 'chat_models.dart';
import 'student_topics.dart';

class StudentAnswer {
  const StudentAnswer(
    this.text, {
    this.topic,
    this.choices = const [],
    this.clarify = false,
  });
  final String text;
  final String? topic;
  final List<ChatChoice> choices;
  final bool clarify;
}

class StudentIntents {
  // Satu pemilih istilah untuk cek data dan glosarium; frasa panjang menang.
  static List<StudentTopic> matchTopics(String value) {
    final result = <StudentTopic>[];
    var rest = value;
    final ordered = [...studentTopics]
      ..sort(
        (a, b) => (b.matcher.firstMatch(value)?.group(0)?.length ?? 0)
            .compareTo(a.matcher.firstMatch(value)?.group(0)?.length ?? 0),
      );
    for (final item in ordered) {
      if (item.matcher.hasMatch(rest)) {
        result.add(item);
        rest = rest.replaceAll(item.matcher, ' ');
      }
    }
    return result;
  }

  static StudentTopic? topic(String? id) {
    for (final item in studentTopics) {
      if (item.id == id) return item;
    }
    return null;
  }

  // Hanya kata yang sudah dikenali boleh dibuang. Sisa kata berarti pertanyaan
  // lebih kompleks dan harus diperiksa oleh aturan lain, bukan ditebak.
  static final _qualifiers = RegExp(
    r'\b(cek|lihat|tampilkan|tolong|dong|donk|kak|kawan|please|pls|plis|cepat|cepet|sekarang|terbaru|saya|aku|ku|nya|apa|ada|berapa|kapan|jam|ga|gak|nggak|status|dan|serta|hari ini|besok|lusa|kemarin|minggu ini|semester ini|semester lalu|semester (?:1[0-4]|[1-9]))\b',
  );
  static final _period = RegExp(
    r'\b(hari ini|besok|lusa|kemarin|minggu ini|semester ini|semester lalu|semester (?:1[0-4]|[1-9]))\b',
  );

  static StudentAnswer? resolve(
    String value, {
    required bool questionMark,
    String? previousTopic,
    DateTime? now,
  }) {
    final semester = RegExp(r'^(?:(?:saya|aku) )?semester (\d+)$')
        .firstMatch(value);
    if (semester != null) {
      return _semester(int.tryParse(semester.group(1)!) ?? 0);
    }

    var query = value;
    final previous = topic(previousTopic);
    // Rujukan singkat hanya memakai topik terakhir, tidak mencari chat lama.
    if (previous != null &&
        RegExp(
          r'^(?:kalau |kalo |terus |yang )?(hari ini|besok|lusa|kemarin|minggu ini|semester ini|semester lalu|semester (?:1[0-4]|[1-9])|data saya|punya saya|datanya|statusnya)(?: dong)?$',
        ).hasMatch(query)) {
      query = '${previous.id} ${_period.firstMatch(query)?.group(0) ?? 'saya'}';
      questionMark = false; // "besok?" sudah jelas setelah membahas jadwal.
    }
    if (RegExp(
      r'^(hari ini|besok|lusa|kemarin|minggu ini|hari ini ada apa|ada apa hari ini)$',
    ).hasMatch(query)) {
      final period = _period.firstMatch(query)!.group(0);
      return StudentAnswer(
        'Informasi apa yang ingin kamu cek untuk $period? Data jadwal, ujian, dan tugas belum terhubung.',
        clarify: true,
        choices: [
          ChatChoice('Jadwal kuliah', 'cek jadwal $period'),
          ChatChoice('Jadwal ujian', 'cek ujian $period'),
          ChatChoice('Tugas kuliah', 'cek tugas $period'),
        ],
      );
    }
    if (RegExp(r'^(bantuan|menu|help|info)$').hasMatch(query)) {
      return const StudentAnswer(
        'Mau cek apa? Kamu bisa mengetik singkat, misalnya jadwal, ipk, atau krs. '
        'Bantuan tersedia dari semester awal hingga semester 14; data kampus belum terhubung.',
        clarify: true,
        choices: [
          ChatChoice('Jadwal hari ini', 'cek jadwal hari ini'),
          ChatChoice('KRS saya', 'cek krs saya'),
          ChatChoice('Progres studi', 'cek progres studi saya'),
        ],
      );
    }

    final matches = matchTopics(query);
    var rest = query;
    // Frasa terpanjang lebih dahulu: "tugas akhir" bukan "tugas kuliah",
    // "jadwal ujian" bukan dua permintaan terpisah.
    for (final item in matches) {
      rest = rest.replaceAll(item.matcher, ' ');
    }
    if (matches.isEmpty) return null;
    if (matches.length > 1 && !RegExp(r'\b(dan|serta)\b').hasMatch(query)) {
      return null;
    }
    if (rest.replaceAll(_qualifiers, ' ').trim().isNotEmpty) return null;

    final time = _period.firstMatch(query)?.group(0);
    final explicit =
        time != null ||
        RegExp(r'\b(cek|lihat|tampilkan|saya|aku|ku|nya|berapa|kapan|ada)\b')
            .hasMatch(query);
    final single = matches.length == 1 ? matches.single : null;
    if (questionMark && !explicit && single != null) {
      return StudentAnswer(
        'Mau cek ${single.label} kamu atau memahami pengertiannya?',
        topic: single.id,
        clarify: true,
        choices: [
          ChatChoice(
            single.daily ? 'Cek hari ini' : 'Cek data saya',
            'cek ${single.id} ${single.daily ? 'hari ini' : 'saya'}',
          ),
          ChatChoice('Pengertian ${single.label}', 'apa itu ${single.id}'),
          if (single.daily) ChatChoice('Cek besok', 'cek ${single.id} besok'),
        ],
      );
    }
    final clock = now ?? DateTime.now();
    return StudentAnswer(
      '${matches.map((item) => _unavailable(item, time, clock)).join('\n\n')}\n\n'
      'Sumber kampus belum terhubung. Ini belum membuktikan ada atau tidaknya catatan.',
      topic: single?.id,
      choices: [
        if (single != null)
          ChatChoice('Pengertian ${single.label}', 'apa itu ${single.id}'),
        if (single?.daily == true)
          ChatChoice('Cek besok', 'cek ${single!.id} besok'),
      ],
    );
  }

  static String _unavailable(
    StudentTopic item,
    String? requested,
    DateTime now,
  ) {
    final period = requested ?? (item.daily ? 'hari ini' : 'terbaru');
    final offset = switch (period) {
      'hari ini' => 0,
      'besok' => 1,
      'lusa' => 2,
      'kemarin' => -1,
      _ => null,
    };
    // Tanggal berasal dari perangkat, bukan tanggal server atau kalender kampus.
    final date = offset == null
        ? null
        : DateTime(now.year, now.month, now.day + offset);
    final stamp = date == null
        ? ''
        : ' (${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}, tanggal perangkat)';
    return '${item.label} ${period == 'terbaru' ? 'terbaru kamu' : 'kamu untuk $period$stamp'} belum dapat diperiksa.';
  }

  static StudentAnswer _semester(int semester) {
    if (semester < 1 || semester > 14) {
      return const StudentAnswer(
        'Panduan pilihan semester saat ini mencakup semester 1–14. Ini bukan batas masa studi resmi. '
        'Kebutuhan apa yang ingin kamu cek?',
        clarify: true,
        choices: [ChatChoice('Progres studi', 'cek progres studi saya')],
      );
    }
    return StudentAnswer(
      'Untuk semester $semester, kebutuhan apa yang ingin kamu cek? '
      'Semester ini adalah keterangan darimu, belum diverifikasi dari profil kampus. '
      'Pilihan berikut bukan syarat atau batas masa studi resmi.',
      clarify: true,
      choices: [
        ChatChoice('Jadwal hari ini', 'cek jadwal hari ini'),
        ChatChoice('KRS semester $semester', 'cek krs semester $semester'),
        if (semester <= 2) const ChatChoice('Mengenal SKS', 'apa itu sks'),
        if (semester >= 5) const ChatChoice('Magang / KKP', 'cek magang saya'),
        if (semester >= 7) const ChatChoice('Tugas akhir', 'cek skripsi saya'),
        const ChatChoice('Progres studi', 'cek progres studi saya'),
      ],
    );
  }
}
