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
  outOfScope,
}

// Status belum terhubung berbeda dari daftar kosong, nilai nol, atau kegagalan server AI.
enum CampusSource { records, regulations, contacts, submissions }

class ChatCapabilities {
  const ChatCapabilities();
  String status(CampusSource source) => 'Belum terhubung';
  String get summary =>
      'Asisten ini khusus melayani informasi dan alur di dalam SIAKAD FASILKOM '
      '(KRS, jadwal, nilai, presensi, perwalian PA, bimbingan TA, izin online, dan panduan). '
      'Pertanyaan di luar SIAKAD ditolak agar tidak mengambil info dari luar.';
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
    RequestKind.study => 'Info SIAKAD',
    RequestKind.writing => 'Bantuan menulis · isian manual',
    RequestKind.clarify => 'Perlu penjelasan',
    RequestKind.draft => 'Draf · belum dikirim',
    RequestKind.files => 'Pemeriksaan lokal',
    RequestKind.outOfScope => 'Di luar lingkup SIAKAD',
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
      'siakd': 'siakad',
      'doswal': 'dosen wali',
      'mhs': 'mahasiswa',
      'kls': 'kelas',
      'matkul': 'mata kuliah',
      'skripsian': 'skripsi',
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
    bool hasSiakadContext = false,
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
    if (!hasSiakadContext && !explain && !drafting) {
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
    if (!hasSiakadContext &&
        academic &&
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
    if (!hasSiakadContext &&
        ((_has(
                  v,
                  r'aturan|syarat|ketentuan|batas|deadline|tenggat|biaya|minimal|maksimal|resmi|policy|regulation|kurikulum',
                ) &&
                (academic ||
                    _has(
                      v,
                      r'cuti|kuliah|kampus|dosen|semester|skripsi|magang|angkatan|prodi',
                    ) ||
                    previous?.kind == RequestKind.policy)) ||
            (_has(v, r'kampus|siakad|esa unggul') && !explain))) {
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
    if (known != null) {
      return RequestPlan(
        RequestKind.study,
        text: known,
        studentTopic: StudentIntents.matchTopics(v).firstOrNull?.id,
      );
    }
    // Tolak pertanyaan di luar lingkup SIAKAD agar AI tidak mengambil/mengarang info luar.
    if (!isSiakadTopic(v)) {
      return const RequestPlan(
        RequestKind.outOfScope,
        text:
            'Maaf, asisten ini khusus membantu informasi di dalam SIAKAD FASILKOM '
            '(seperti KRS, jadwal kuliah/mengajar, nilai, presensi, perwalian PA, '
            'bimbingan & sidang TA, izin online/BAP, tagihan, dan panduan kampus). '
            'Saya tidak mengambil atau menjawab informasi dari luar SIAKAD.',
        choices: [
          ChatChoice('Apa itu SIAKAD?', 'apa itu siakad'),
          ChatChoice('Apa itu KRS?', 'apa itu krs'),
          ChatChoice('Cara buat Izin Online', 'apa itu surat izin'),
          ChatChoice('Alur Perwalian PA', 'apa itu perwalian'),
        ],
      );
    }
    return const RequestPlan(RequestKind.study);
  }

  /// Memeriksa apakah pertanyaan berada dalam lingkup SIAKAD Campus App.
  /// Menolak topik eksternal meskipun mengandung kata umum seperti "jadwal" atau "nilai".
  static bool isSiakadTopic(String normalized) {
    final explicitSiakad = _has(
      normalized,
      r'\b(siakad|fasilkom|krs|khs|ipk|ips|sks|nim|nip|nidn|bap|perwalian|sempro|skripsi|tesis|disertasi|yudisium|wisuda|rps|ekivalensi|kkp|kkn|ukt|spp|dosen|mahasiswa|kuliah|semester|prodi|fakultas|bimbingan)\b',
    );
    final clearlyExternal = _has(
      normalized,
      r'\b(bola|liga|pertandingan|piala dunia|sepakbola|basket|badminton|kurs|tukar|rupiah|dolar|saham|crypto|bitcoin|emas|resep|masak|goreng|makanan|minuman|cuaca|hujan|gempa|presiden|menteri|politik|pemilu|film|drakor|anime|artis|lagu|musik|game|wisata|hotel|pesawat|kereta|tiket|python|javascript|php|html|css|java|golang)\b',
    );
    if (clearlyExternal && !explicitSiakad) return false;
    return explicitSiakad ||
        studentTopics.any((topic) => topic.matcher.hasMatch(normalized)) ||
        _has(
          normalized,
          r'\b(campus|kampus|akademik|pa|ta|jadwal|nilai|presensi|absensi|tagihan|pembayaran|izin|cuti|sidang|proposal|beasiswa|konseling|biodata|profil|kurikulum|pengumuman|berita|panduan|pedoman|angkatan|kelas|ruang|mata kuliah|mk|ujian|uts|uas|tugas|magang|pkl|login|password|akun|chatbot|surat|kendala|beranda|dashboard|ampu|acc|revisi)\b',
        );
  }

  // Pengetahuan istilah SIAKAD yang aman ditampilkan lokal maupun menjadi acuan AI.
  static const glossary = {
    'siakad':
        'SIAKAD FASILKOM adalah portal akademik di aplikasi ini untuk mengelola jadwal kuliah/mengajar, KRS, nilai, presensi, perwalian PA, bimbingan TA, izin online, pengumuman, dan panduan.',
    'krs':
        'KRS (Kartu Rencana Studi) adalah daftar mata kuliah yang direncanakan untuk satu semester dan disetujui oleh Dosen PA di SIAKAD.',
    'ipk':
        'IPK (Indeks Prestasi Kumulatif) menggambarkan hasil belajar kumulatif mahasiswa pada SIAKAD.',
    'presensi':
        'Presensi adalah pencatatan kehadiran perkuliahan oleh dosen pada setiap pertemuan kelas di SIAKAD.',
    'sks':
        'SKS (Satuan Kredit Semester) menyatakan bobot kegiatan pembelajaran mata kuliah pada SIAKAD.',
    'cuti':
        'Cuti kuliah adalah penghentian studi sementara melalui prosedur akademik kampus.',
    'perwalian':
        'Perwalian PA adalah konsultasi dan persetujuan KRS oleh Dosen Pembimbing Akademik melalui menu Perwalian PA di SIAKAD.',
    'bap':
        'Dalam SIAKAD ini, BAP bertugas memeriksa pengajuan Izin Online mahasiswa. Berita Acara Perkuliahan adalah catatan pertemuan kelas oleh dosen.',
    'sidang':
        'Seminar Proposal dan Sidang Skripsi dikelola bersama Dosen Pembimbing TA melalui menu Bimbingan TA dan Jadwal Sidang di SIAKAD.',
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
    return '${entries.map((e) => glossary[e.id] ?? e.definition).join('\n\n')}\n\nInformasi ini berasal dari kamus internal SIAKAD Campus App.';
  }

  // Penjelasan dasar tetap tersedia ketika model mati, tanpa mengambil info luar.
  static String offlineStudy(String text) {
    final known = definition(text);
    if (known != null) return known;
    return 'Untuk penjelasan lanjutan seputar SIAKAD, aktifkan AI lokal melalui tombol Aktifkan AI lokal. Sementara itu, bantuan terpandu SIAKAD dan formulir draf tetap tersedia.';
  }
}
