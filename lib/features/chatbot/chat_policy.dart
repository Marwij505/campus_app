// Aturan aplikasi memilih bantuan sebelum model dipanggil. Tidak berisi data mahasiswa.
import 'chat_models.dart';
import 'student_intents.dart';
import 'student_topics.dart';

enum RequestKind {
  study,
  writing,
  personal,
  policy,
  action,
  draft,
  clarify,
  files,
}

// Status belum terhubung berbeda dari daftar kosong, nilai nol, atau kegagalan server AI.
enum CampusSource { records, regulations, contacts, submissions }

class ChatCapabilities {
  const ChatCapabilities();
  String status(CampusSource source) => 'Belum terhubung';
  String get summary =>
      'Data akademik, panduan resmi, kontak dosen, dan pengiriman belum terhubung. '
      'Penjelasan umum dan draf dari isian manual tersedia; lampiran hanya diperiksa format/ukurannya.';
}

class RequestPlan {
  const RequestPlan(
    this.kind, {
    this.text,
    this.actions = const [],
    this.followUp = false,
    this.choices = const [],
    this.studentTopic,
  });
  final RequestKind kind;
  final String? text;
  final List<HelpTopic> actions;
  final bool followUp;
  final List<ChatChoice> choices;
  final String? studentTopic;
  bool get usesAi => kind == RequestKind.study || kind == RequestKind.writing;
  String get label => switch (kind) {
    RequestKind.study => 'Penjelasan umum',
    RequestKind.writing => 'Bantuan menulis · isian manual',
    RequestKind.clarify => 'Perlu penjelasan',
    RequestKind.draft => 'Draf · belum dikirim',
    RequestKind.files => 'Pemeriksaan lokal',
    _ => 'Sumber belum terhubung',
  };
}

class ChatPolicy {
  // Variasi bahasa umum dinormalisasi; teks asli tetap dipakai dalam percakapan.
  static String normalize(String text) {
    var value = text
        .toLowerCase()
        .replaceAll(RegExp(r'[,/&]'), ' dan ')
        .replaceAllMapped(
          RegExp(r'\b(?:smt|semester)(\d{1,2})\b'),
          (match) => 'semester ${match.group(1)}',
        )
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    const aliases = {
      'krss': 'krs',
      'ksr': 'krs',
      'jdwl': 'jadwal',
      'jdw': 'jadwal',
      'jadwl': 'jadwal',
      'jadual': 'jadwal',
      'bsk': 'besok',
      'hr': 'hari',
      'skrg': 'sekarang',
      'smstr': 'semester',
      'ipkk': 'ipk',
      'presnsi': 'presensi',
      'ijin': 'izin',
      'sy': 'saya',
      'gw': 'saya',
      'gue': 'saya',
      'knp': 'kenapa',
      'brp': 'berapa',
      'gmn': 'bagaimana',
      'yg': 'yang',
      'td': 'tadi',
      'wa': 'whatsapp',
      'smt': 'semester',
      'nilaiku': 'nilai saya',
      'ipkku': 'ipk saya',
      'jadwalku': 'jadwal saya',
      'tagihanku': 'tagihan saya',
    };
    for (final entry in aliases.entries) {
      value = value.replaceAll(RegExp('\\b${entry.key}\\b'), entry.value);
    }
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static bool _has(String value, String pattern) =>
      RegExp(pattern).hasMatch(value);

  static RequestPlan route(
    String input, {
    RequestPlan? previous,
    DateTime? now,
  }) {
    final v = normalize(input);
    // Pilihan angka berlaku hanya untuk jawaban terakhir. Tombol membawa
    // pertanyaan lengkap, sehingga tombol chat lama tidak memakai konteks baru.
    if (previous != null && previous.choices.isNotEmpty) {
      final number = RegExp(r'^(?:pilihan |opsi |nomor )?(\d+)$').firstMatch(v);
      if (number != null) {
        final index = (int.tryParse(number.group(1)!) ?? 0) - 1;
        if (index >= 0 && index < previous.choices.length) {
          return route(previous.choices[index].prompt, now: now);
        }
        return RequestPlan(
          RequestKind.clarify,
          text:
              'Pilih nomor 1–${previous.choices.length} atau ketuk salah satu pilihan.',
          choices: previous.choices,
          studentTopic: previous.studentTopic,
        );
      }
    }
    if (RegExp(r'^(?:pilihan |opsi |nomor )?\d+$').hasMatch(v)) {
      return const RequestPlan(
        RequestKind.clarify,
        text: 'Belum ada pilihan aktif. Ketik topiknya dahulu, misalnya jadwal? atau ipk?',
      );
    }
    if (RegExp(r'^(pengertian|pengertiannya|definisi|artinya|apa itu)$')
        .hasMatch(v)) {
      if (previous?.studentTopic != null) {
        return route('apa itu ${previous!.studentTopic}', now: now);
      }
      return const RequestPlan(
        RequestKind.clarify,
        text: 'Istilah apa yang ingin kamu pahami? Misalnya: apa itu IPK.',
      );
    }
    final academic =
        (_has(
              v,
              r'\b(krs|ipk|ips|nilai|presensi|absensi|tagihan|jadwal|biodata|profil|nim|sks|pengajuan|pembayaran|beasiswa|ukt)\b|grades|attendance|tuition',
            ) ||
            _has(v, r'(cuti|izin|kelulusan).*(ditolak|status)|kapan.*lulus') ||
            (studentTopics.any((topic) => topic.matcher.hasMatch(v)) &&
                _has(
                  v,
                  r'\b(cek|lihat|tampilkan|ditolak|disetujui|status|kapan)\b',
                ))) &&
        !(_has(v, r'variabel|array|pemrograman|pointer') &&
            !_has(v, r'krs|ipk|presensi|tagihan|nim'));
    final personal = _has(
      v,
      r'\b(saya|aku|ku|milik|teman|mahasiswa|my)\b|\b\w+(?:ku|nya)\b|\b\d{8,}\b',
    );
    final explain = _has(
      v,
      r'apa itu|apa yang dimaksud|pengertian|definisi|secara umum|konsep|what is',
    );
    final drafting = _has(
      v,
      r'buat|susun|tulis|bantu|draf|draft|rapikan|rapihin',
    );
    final sending = _has(
      v,
      r'\b(kirim|kirimkan|kirimkanlah|ajukan|setujui|bayarkan|submit|send|approve)\b|sudah dikirim|status pengajuan',
    );
    // Permintaan izin singkat membuka layanan, bukan meminta model mengarang arti.
    final leave = _has(
      v,
      r'^(?:(?:saya|aku) )?(?:(?:mau|ingin|buat|bikin|bantu|tolong|form|formulir|ajukan) )?(?:surat )?izin(?: online| sakit| kuliah| tidak masuk| tidak hadir| dong)*(?: hari ini| besok)?$|^(?:gak|ga|nggak|tidak) (?:bisa )?(?:masuk|hadir)(?: kuliah)?(?: hari ini| besok)?$',
    );
    final leaveStatus = _has(
      v,
      r'^(status|riwayat|hasil|cek status) (?:surat |pengajuan )?izin(?: saya)?$|^izin(?: saya)? (ditolak|disetujui|sudah diacc)$',
    );
    if (!explain && (leave || leaveStatus || v == 'surat')) {
      if ((input.contains('?') || input.contains('？')) &&
          _has(v, r'^(izin|surat|surat izin|izin online)$')) {
        return const RequestPlan(
          RequestKind.clarify,
          text: 'Mau membuat izin, melihat hasil pemeriksaan BAP, atau memahami alurnya?',
          choices: [
            ChatChoice('Buat izin', 'buat surat izin'),
            ChatChoice('Status / hasil izin', 'status izin'),
            ChatChoice('Pengertian dan alur', 'apa itu surat izin'),
          ],
        );
      }
      return RequestPlan(
        RequestKind.draft,
        text: leaveStatus
            ? 'Buka Izin Online untuk melihat pengajuan dan hasil pemeriksaan BAP milik akunmu. Chat tidak menyimpulkan status dari pesan. Saat ini alurnya simulasi lokal, belum terhubung ke kampus.'
            : HelpTopic.letter.reply,
        actions: const [HelpTopic.letter],
      );
    }
    if (sending) {
      return const RequestPlan(
        RequestKind.action,
        text: 'Pengiriman, pelacakan, dan persetujuan belum terhubung. Saya belum mengirim atau mengubah apa pun. Anda dapat menyiapkan draf untuk diperiksa sendiri.',
        actions: [HelpTopic.letter, HelpTopic.issue],
      );
    }
    if (academic && _has(v, r'hitung|simulasi|calculate')) {
      return const RequestPlan(
        RequestKind.policy,
        text: 'Perhitungan akademik tervalidasi belum tersedia. Data dan rumus resmi kampus belum terhubung, jadi saya belum dapat menentukan IPK, batas SKS, atau hasil akademik resmi. Angka yang diketik di chat tetap isian manual.',
      );
    }
    if (drafting && _has(v, r'surat|izin|kendala|laporan')) {
      final issue = _has(v, r'kendala|laporan');
      return RequestPlan(
        RequestKind.draft,
        text: issue ? HelpTopic.issue.reply : HelpTopic.letter.reply,
        actions: [issue ? HelpTopic.issue : HelpTopic.letter],
      );
    }
    if (_has(v, r'\b(kontak|nomor|whatsapp|email)\b') &&
        _has(v, r'dosen|pak|bu|pembimbing|petugas|kampus')) {
      return RequestPlan(
        RequestKind.personal,
        text: HelpTopic.contact.reply,
        actions: [HelpTopic.issue],
      );
    }
    if (!explain && !drafting) {
      final student = StudentIntents.resolve(
        v,
        questionMark: input.contains('?') || input.contains('？'),
        previousTopic: previous?.studentTopic,
        now: now,
      );
      if (student != null) {
        return RequestPlan(
          student.clarify ? RequestKind.clarify : RequestKind.personal,
          text: student.text,
          choices: student.choices,
          studentTopic: student.topic,
          actions: student.clarify ? const [] : const [HelpTopic.issue],
        );
      }
    }
    if (academic &&
        !(_has(
              v,
              r'aturan|syarat|ketentuan|batas|deadline|tenggat|biaya|minimal|maksimal',
            ) &&
            !_has(v, r'ditolak')) &&
        (personal ||
            _has(
              v,
              r'cek|lihat|tampilkan|ditolak|lunas|berapa|check|show|my ',
            )) &&
        !(explain &&
            !_has(v, r'ditolak|milik|berapa|cek|lihat|tampilkan|kenapa'))) {
      return const RequestPlan(
        RequestKind.personal,
        text: 'Data akademik belum terhubung, jadi saya belum dapat memeriksa catatan atau penyebab status tersebut. Ini tidak berarti nilai nol, KRS ditolak, atau tagihan lunas. Anda dapat menyiapkan draf kendala tanpa mengisi data sensitif di chat.',
        actions: [HelpTopic.issue],
      );
    }
    if ((_has(
              v,
              r'aturan|syarat|ketentuan|batas|deadline|tenggat|biaya|minimal|maksimal|resmi|policy|regulation|kurikulum',
            ) &&
            (academic ||
                _has(
                  v,
                  r'cuti|kuliah|kampus|dosen|semester|skripsi|magang|angkatan|prodi',
                ) ||
                previous?.kind == RequestKind.policy)) ||
        (_has(v, r'kampus|siakad|esa unggul') && !explain)) {
      return const RequestPlan(
        RequestKind.policy,
        text: 'Panduan resmi kampus belum terhubung. Saya belum dapat memastikan aturan, biaya, tanggal, atau syarat yang berlaku untuk prodi dan angkatan Anda. Anda bisa meminta penjelasan konsep secara umum atau menyiapkan pertanyaan untuk petugas.',
        actions: [HelpTopic.issue],
      );
    }
    if (!explain &&
        _has(v, r'mau cuti|ingin cuti|berhenti kuliah sementara|cuti kuliah')) {
      return const RequestPlan(
        RequestKind.clarify,
        text: 'Anda ingin penjelasan cuti secara umum atau bantuan menyiapkan draf pertanyaan kepada petugas? Ketentuan resmi cuti kampus belum terhubung.',
        actions: [HelpTopic.issue],
      );
    }
    if (_has(v, r'berkas|lampiran|screenshot|pdf|ocr|bukti sakit')) {
      return RequestPlan(
        RequestKind.files,
        text: HelpTopic.files.reply,
        actions: [HelpTopic.letter, HelpTopic.issue],
      );
    }
    // Lanjutan tanpa konteks tidak diteruskan ke model untuk menebak percakapan lama.
    if (_has(v, r'^(syaratnya|aturannya|berapa biayanya|kapan batasnya)$')) {
      if (previous != null && !previous.usesAi) return previous;
      return const RequestPlan(
        RequestKind.clarify,
        text: 'Syarat atau aturan untuk layanan apa yang Anda maksud? Sumber resmi kampus belum terhubung.',
      );
    }
    final followUp =
        _has(
          v,
          r'^(lanjut|lanjutkan|contoh(nya)?|lebih sederhana|lebih singkat|jelaskan lagi|sederhanakan|yang tadi|itu tadi|kenapa begitu|latihan|buat lebih|perjelas)\b',
        ) ||
        v == 'bagaimana dengan itu' ||
        _has(v, r'^(bagaimana|gimana|cara|terus|lalu).*(nya|tadi|itu)$');
    if (followUp) {
      if (previous == null) {
        return const RequestPlan(
          RequestKind.clarify,
          text: 'Topik atau teks mana yang ingin Anda lanjutkan? Sebutkan satu topiknya agar saya tidak menebak konteks.',
        );
      }
      if (!previous.usesAi) return previous;
      return RequestPlan(previous.kind, followUp: true);
    }
    if (_has(
      v,
      r'rapikan|rapihin|perbaiki ejaan|lebih formal|sunting|parafrase',
    )) {
      if (!v.contains('teks') && input.length < 45) {
        return const RequestPlan(
          RequestKind.clarify,
          text: 'Teks mana yang ingin dirapikan? Untuk alasan surat izin, gunakan formulir agar identitas, tanggal, dan bukti tetap diperiksa aplikasi.',
          actions: [HelpTopic.letter],
        );
      }
      return const RequestPlan(RequestKind.writing);
    }
    if (_has(v, r'kendala login|error siakad|gagal masuk|gagal login|lapor')) {
      return RequestPlan(
        RequestKind.draft,
        text: HelpTopic.issue.reply,
        actions: [HelpTopic.issue],
      );
    }
    // Definisi eksplisit memakai kamus yang sama dengan tombol pilihan.
    final known = definition(input);
    return RequestPlan(
      RequestKind.study,
      text: known,
      studentTopic: known == null
          ? null
          : StudentIntents.matchTopics(v).firstOrNull?.id,
    );
  }

  // Pengetahuan istilah umum, bukan data mahasiswa atau kebijakan kampus.
  static const glossary = {
    'krs': 'KRS (Kartu Rencana Studi) adalah daftar mata kuliah yang direncanakan untuk satu semester. Prosedur pengisian dan persetujuannya mengikuti ketentuan kampus.',
    'ipk': 'IPK (Indeks Prestasi Kumulatif) menggambarkan hasil belajar kumulatif. Nilai IPK pribadi dan aturan perhitungannya harus diambil dari sistem serta pedoman kampus.',
    'presensi': 'Presensi adalah pencatatan kehadiran dalam kegiatan perkuliahan. Batas kehadiran dan konsekuensinya mengikuti aturan resmi kampus.',
    'sks': 'SKS (Satuan Kredit Semester) menyatakan bobot kegiatan pembelajaran mata kuliah. Batas pengambilan SKS memerlukan pedoman resmi yang berlaku.',
    'cuti': 'Cuti kuliah secara umum berarti penghentian studi sementara melalui prosedur kampus. Durasi, biaya, dan persetujuannya memerlukan aturan resmi.',
  };

  static String? definition(String text) {
    final value = normalize(text);
    if (!_has(
      value,
      r'^(apa itu|apa yang dimaksud|pengertian|definisi|what is)\b',
    )) {
      return null;
    }
    final entries = StudentIntents.matchTopics(value);
    if (entries.isEmpty) return null;
    return '${entries.map((e) => glossary[e.id] ?? e.definition).join('\n\n')}\n\nIni penjelasan umum, bukan data atau ketentuan resmi kampus Anda.';
  }

  // Penjelasan dasar tetap tersedia ketika model mati, tanpa syarat kampus buatan.
  static String offlineStudy(String text) {
    final known = definition(text);
    if (known != null) return known;
    return 'Untuk penjelasan belajar atau penyuntingan bebas, sambungkan AI lokal melalui tombol Aktifkan AI lokal. Sementara itu, bantuan terpandu dan formulir draf tetap tersedia. Data kampus belum terhubung.';
  }
}
