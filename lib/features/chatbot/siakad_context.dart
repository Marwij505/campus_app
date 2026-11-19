// Penyusun konteks & penjawab lokal khusus SIAKAD agar ChatBot (baik mode AI lokal
// maupun mode terpandu) selalu menjawab spesifik dari data SIAKAD aktif pengguna
// dan tidak mengambil informasi dari luar.

import '../../data/dashboard_models.dart';
import '../../data/lecturer_models.dart';
import '../../data/student_profile.dart';
import 'chat_policy.dart';

class SiakadKnowledge {
  const SiakadKnowledge({
    required this.roleLabel,
    required this.accountId,
    required this.greetingName,
    required this.quickPrompts,
    required this.profileSummary,
    this.courses = const [],
    this.schedules = const [],
    this.paAdvisees = const [],
    this.thesisAdvisees = const [],
    this.thesisSchedules = const [],
    this.announcements = const [],
    this.news = const [],
    this.guides = const [],
    this.leaveCount = 0,
    this.isThesisAdvisor = false,
  });

  final String roleLabel;
  final String accountId;
  final String greetingName;
  final List<(String, String)> quickPrompts;
  final String profileSummary;
  final List<LecturerCourseClass> courses;
  final List<ClassSchedule> schedules;
  final List<AcademicAdvisee> paAdvisees;
  final List<ThesisAdvisee> thesisAdvisees;
  final List<ThesisScheduleItem> thesisSchedules;
  final List<CampusNotice> announcements;
  final List<CampusNotice> news;
  final List<CampusGuide> guides;
  final int leaveCount;
  final bool isThesisAdvisor;

  /// Menyusun konteks SIAKAD terfokus sesuai pertanyaan agar AI lokal tetap
  /// cepat, akurat, dan tidak melebihi batas token.
  String contextForQuery(String query) {
    final v = ChatPolicy.normalize(query);
    final sections = <String>[
      profileSummary,
      'Jumlah data Izin Online di kotak masuk sesi ini: $leaveCount.',
    ];

    final askCourses = _match(v, r'mata kuliah|matkul|mk|ampu|kelas|nilai|presensi|sks');
    final askSchedule = _match(v, r'jadwal|mengajar|kuliah|hari ini|besok|ruang');
    final askPa = _match(v, r'pa|perwalian|krs|acc|revisi|bimbingan akademik');
    final askTa = _match(v, r'ta|tugas akhir|skripsi|sidang|sempro|proposal|pembimbing|bimbingan');
    final askInfo = _match(v, r'pengumuman|berita|info|panduan|pedoman|aturan|prosedur');
    final general = !askCourses && !askSchedule && !askPa && !askTa && !askInfo;

    if ((askCourses || general) && courses.isNotEmpty) {
      sections.add(_coursesText());
    }
    if ((askSchedule || general) && schedules.isNotEmpty) {
      sections.add(_schedulesText());
    }
    if ((askPa || general) && paAdvisees.isNotEmpty) {
      sections.add(_paText());
    }
    if ((askTa || general) && thesisAdvisees.isNotEmpty) {
      sections.add(_taText());
    }
    if ((askTa || askSchedule || general) && thesisSchedules.isNotEmpty) {
      sections.add(_taSchedulesText());
    }
    if ((askInfo || general) && announcements.isNotEmpty) {
      sections.add(_noticesText('Pengumuman SIAKAD', announcements));
    }
    if (askInfo && news.isNotEmpty) {
      sections.add(_noticesText('Berita Kampus', news));
    }
    if (askInfo && guides.isNotEmpty) {
      sections.add(_guidesText());
    }

    sections.add(SiakadContextBuilder.appCatalog);
    return sections.join('\n\n');
  }

  /// Jawaban spesifik di Mode Terpandu (tanpa perlu server Ollama aktif),
  /// mengambil langsung bagian data SIAKAD yang relevan dengan pertanyaan user.
  String answerLocally(String query) {
    final v = ChatPolicy.normalize(query);

    if (_match(v, r'mata kuliah|matkul|mk|ampu|input nilai|belum input|presensi kelas')) {
      if (courses.isEmpty) {
        return 'Belum ada data mata kuliah yang tercatat di beranda SIAKAD akun ini.';
      }
      final pendingGrades = courses.where((c) => !c.gradeSubmitted).toList();
      if (_match(v, r'belum input|nilai')) {
        if (pendingGrades.isEmpty) {
          return 'Kabar baik! Semua kelas yang Anda ampu sudah berstatus Nilai Terisi.';
        }
        final list = pendingGrades
            .map(
              (c) =>
                  '• ${c.code} ${c.title} (Kelas ${c.classCode}) — ${c.studentCount} mhs, pertemuan ${c.completedMeetings}/${c.totalMeetings}',
            )
            .join('\n');
        return 'Ada ${pendingGrades.length} kelas yang belum selesai input nilai:\n$list';
      }
      return 'Berikut daftar mata kuliah yang Anda ampu semester ini:\n${_coursesBullets()}';
    }

    if (_match(v, r'perwalian|dosen pa|\bpa\b|acc krs|krs.*(tunggu|acc|revisi)')) {
      if (paAdvisees.isEmpty) {
        return 'Belum ada data mahasiswa bimbingan akademik (PA) pada akun ini.';
      }
      final pending = paAdvisees
          .where((a) => a.krsStatus != KrsApprovalStatus.approved)
          .toList();
      if (_match(v, r'menunggu|tunggu|belum|acc|revisi')) {
        if (pending.isEmpty) {
          return 'Semua mahasiswa bimbingan PA Anda (${paAdvisees.length} orang) sudah berstatus KRS Disetujui.';
        }
        final list = pending
            .map((a) {
              final status = a.krsStatus == KrsApprovalStatus.pending
                  ? 'Menunggu ACC'
                  : 'Perlu Revisi';
              return '• ${a.name} (${a.nim}) · Smt ${a.semester} · IPK ${a.gpa.toStringAsFixed(2)} · [$status] — ${a.note}';
            })
            .join('\n');
        return 'Ada ${pending.length} mahasiswa PA yang perlu tindak lanjut:\n$list';
      }
      return 'Ringkasan mahasiswa bimbingan akademik (PA) Anda (${paAdvisees.length} mahasiswa):\n${_paBullets()}';
    }

    if (_match(v, r'sidang|sempro|seminar proposal|jadwal ta|jadwal bimbingan')) {
      if (!isThesisAdvisor) {
        return 'Akun Anda saat ini berperan sebagai $roleLabel, sehingga belum memiliki jadwal bimbingan/sidang Tugas Akhir.';
      }
      if (thesisSchedules.isEmpty) {
        return 'Belum ada jadwal bimbingan atau sidang TA yang tercatat saat ini.';
      }
      return 'Berikut jadwal bimbingan & sidang TA Anda:\n${_taSchedulesBullets()}';
    }

    if (_match(v, r'bimbingan ta|tugas akhir|skripsi|\bta\b|siap sidang|review ta')) {
      if (!isThesisAdvisor) {
        return 'Akun Anda saat ini berperan sebagai $roleLabel (tanpa tugas Pembimbing TA).';
      }
      if (thesisAdvisees.isEmpty) {
        return 'Belum ada mahasiswa bimbingan TA yang tercatat pada akun ini.';
      }
      if (_match(v, r'siap sidang')) {
        final ready = thesisAdvisees
            .where((a) => a.stage == ThesisStage.readyDefense)
            .toList();
        if (ready.isEmpty) {
          return 'Saat ini belum ada mahasiswa bimbingan TA yang berstatus Siap Sidang.';
        }
        final list = ready
            .map(
              (a) =>
                  '• ${a.name} (${a.nim}) — ${(a.progress * 100).round()}% · ${a.pendingAction}\n  Judul: ${a.title}',
            )
            .join('\n');
        return 'Mahasiswa bimbingan TA yang sudah Siap Sidang (${ready.length} orang):\n$list';
      }
      return 'Daftar mahasiswa bimbingan Tugas Akhir Anda (${thesisAdvisees.length} mahasiswa):\n${_taBullets()}';
    }

    if (_match(v, r'jadwal|mengajar|kuliah|hari ini|besok')) {
      if (schedules.isEmpty) {
        return 'Belum ada jadwal perkuliahan/mengajar yang tersimpan pada beranda SIAKAD akun ini.';
      }
      return 'Berikut jadwal perkuliahan/mengajar terdekat Anda di SIAKAD:\n${_schedulesBullets()}';
    }

    if (_match(v, r'pengumuman|berita')) {
      if (announcements.isEmpty && news.isEmpty) {
        return 'Belum ada pengumuman atau berita kampus yang dimuat di beranda SIAKAD Anda.';
      }
      final parts = <String>[];
      if (announcements.isNotEmpty) {
        parts.add(
          'Pengumuman terbaru:\n${announcements.map((n) => '• ${n.title} (${campusDate(n.publishedAt.toLocal())})\n  ${n.body}').join('\n')}',
        );
      }
      if (news.isNotEmpty && _match(v, r'berita')) {
        parts.add(
          'Berita kampus:\n${news.map((n) => '• ${n.title} (${campusDate(n.publishedAt.toLocal())})\n  ${n.body}').join('\n')}',
        );
      }
      return parts.join('\n\n');
    }

    if (_match(v, r'panduan|pedoman|prosedur|rubrik')) {
      if (guides.isEmpty) {
        return 'Belum ada dokumen panduan SIAKAD yang dimuat pada akun ini.';
      }
      return 'Panduan resmi yang tersedia di SIAKAD Anda:\n${guides.map((g) => '• ${g.title}\n${g.content}').join('\n\n')}';
    }

    if (_match(v, r'hasil izin|kotak masuk izin|jumlah izin')) {
      return 'Saat ini terdapat $leaveCount pengajuan pada kotak masuk Izin Online akun Anda. Ketuk menu Hasil Izin / Izin Online untuk membuka detailnya.';
    }

    // Ringkasan singkat & ramah bila pertanyaan SIAKAD bersifat umum
    return '$profileSummary\n\nKetuk salah satu topik cepat di bawah atau tanyakan spesifik (misal: mata kuliah, jadwal, mahasiswa PA, bimbingan TA, pengumuman, atau panduan).';
  }

  static bool _match(String text, String pattern) =>
      RegExp(pattern).hasMatch(text);

  String _coursesBullets() => courses
      .map(
        (c) =>
            '• ${c.code} · ${c.title} (Kelas ${c.classCode}, ${c.credits} SKS)\n'
            '  ${c.scheduleText} · ${c.room} · ${c.studentCount} mhs · Pertemuan ${c.completedMeetings}/${c.totalMeetings} · ${c.gradeSubmitted ? 'Nilai Terisi' : 'Belum Input Nilai'}',
      )
      .join('\n');

  String _coursesText() => 'Daftar Mata Kuliah Diampu:\n${_coursesBullets()}';

  String _schedulesBullets() => schedules
      .map(
        (s) =>
            '• ${s.code} · ${s.title}\n'
            '  ${campusDate(s.startsAt.toLocal())} · ${campusTime(s.startsAt)}–${campusTime(s.endsAt)} · ${s.room}${s.method == null ? '' : ' (${s.method})'}',
      )
      .join('\n');

  String _schedulesText() => 'Jadwal Kuliah/Mengajar:\n${_schedulesBullets()}';

  String _paBullets() => paAdvisees
      .map((a) {
        final st = switch (a.krsStatus) {
          KrsApprovalStatus.approved => 'Disetujui',
          KrsApprovalStatus.pending => 'Menunggu ACC',
          KrsApprovalStatus.revision => 'Perlu Revisi',
        };
        return '• ${a.name} (${a.nim}) · Smt ${a.semester} · IPK ${a.gpa.toStringAsFixed(2)} · ${a.takenCredits} SKS · [$st] (${a.note})';
      })
      .join('\n');

  String _paText() => 'Daftar Mahasiswa Bimbingan Akademik (PA):\n${_paBullets()}';

  String _taBullets() => thesisAdvisees
      .map((a) {
        final st = switch (a.stage) {
          ThesisStage.proposal => 'Proposal',
          ThesisStage.chapter1To3 => 'Bab 1-3',
          ThesisStage.research => 'Penelitian',
          ThesisStage.finalDraft => 'Bab 4-5',
          ThesisStage.readyDefense => 'Siap Sidang',
        };
        return '• ${a.name} (${a.nim}) · ${a.roleInThesis} · [$st · ${(a.progress * 100).round()}%]\n'
            '  Judul: ${a.title}\n'
            '  Tindak lanjut: ${a.pendingAction} (terakhir: ${a.lastGuidanceDate})';
      })
      .join('\n');

  String _taText() => 'Daftar Mahasiswa Bimbingan TA:\n${_taBullets()}';

  String _taSchedulesBullets() => thesisSchedules
      .map(
        (t) =>
            '• [${t.type}] ${t.studentName} (${t.nim})\n'
            '  ${t.dateLabel} · ${t.timeLabel} · ${t.location}\n'
            '  Topik: ${t.topic}',
      )
      .join('\n');

  String _taSchedulesText() =>
      'Jadwal Bimbingan & Sidang TA:\n${_taSchedulesBullets()}';

  String _noticesText(String title, List<CampusNotice> items) =>
      '$title:\n${items.map((n) => '• ${n.title} (${campusDate(n.publishedAt.toLocal())}): ${n.body}').join('\n')}';

  String _guidesText() =>
      'Panduan SIAKAD:\n${guides.map((g) => '• ${g.title}: ${g.content}').join('\n')}';
}

class SiakadContextBuilder {
  static const appCatalog =
      'Layanan SIAKAD FASILKOM di aplikasi ini:\n'
      '- Mahasiswa: Beranda, Biodata, KRS, Jadwal Kuliah, Nilai & Presensi, Tagihan, Pembayaran, Konseling, Izin Online (diajukan ke BAP, hasil PDF diteruskan ke dosen sesuai kode), Tugas Akhir, Pengumuman, Berita, dan Pedoman.\n'
      '- Dosen Akademik (DOS001): Jadwal Mengajar, Mata Kuliah Diampu, Input Nilai, Presensi Kelas, Perwalian PA (filter/cari/ACC/revisi KRS), dan Hasil Izin.\n'
      '- Dosen Akademik + Pembimbing TA (DOS002): Semua menu Dosen Akademik ditambah Mahasiswa Bimbingan TA (filter/cari/log bimbingan/ACC tahap) dan Jadwal Bimbingan & Sidang TA.\n'
      '- BAP (BAP001): Pemeriksaan antrean Izin Online serta penerbitan hasil PDF.';

  static SiakadKnowledge fromStudent({
    required StudentProfile student,
    required DashboardData data,
    int leaveCount = 0,
  }) {
    final p = data.student ?? student;
    final lines = <String>[
      'Peran aktif: Mahasiswa (NIM: ${p.nim}).',
      if (p.name != null) 'Nama: ${p.name}.',
      if (p.major != null) 'Program Studi: ${p.major}.',
      if (p.semester != null) 'Semester: ${p.semester}.',
      if (p.gpa != null) 'IPK: ${p.gpa!.toStringAsFixed(2)}.',
      if (p.passedCredits != null) 'SKS lulus: ${p.passedCredits}.',
      'Jadwal kuliah tersimpan: ${data.classes.length}, pengumuman: ${data.announcements.length}, panduan: ${data.guides.length}.',
    ];
    return SiakadKnowledge(
      roleLabel: 'Mahasiswa',
      accountId: p.nim,
      greetingName: p.name ?? p.nim,
      profileSummary: lines.join('\n'),
      schedules: data.classes,
      announcements: data.announcements,
      news: data.news,
      guides: data.guides,
      leaveCount: leaveCount,
      quickPrompts: const [
        ('Jadwal kuliah', 'Cek jadwal kuliah saya di SIAKAD'),
        ('Apa itu KRS?', 'apa itu krs'),
        ('Cara Izin Online', 'apa itu surat izin'),
        ('Pengumuman', 'Ada pengumuman kampus apa di SIAKAD?'),
        ('Panduan SIAKAD', 'Ada panduan apa saja di SIAKAD?'),
      ],
    );
  }

  static SiakadKnowledge fromLecturer({
    required StudentProfile user,
    required LecturerDashboardData data,
    int leaveCount = 0,
  }) {
    final prof = data.profile;
    final w = data.workload;
    final isThesis =
        prof?.isThesisAdvisor ??
        (user.lecturerType == LecturerType.academicAndThesis);
    final pendingPa = data.paAdvisees
        .where((a) => a.krsStatus != KrsApprovalStatus.approved)
        .length;
    final pendingGrades =
        data.courses.where((c) => !c.gradeSubmitted).length;

    final lines = <String>[
      'Peran aktif: ${prof?.roleLabel ?? 'Dosen Akademik'} (Kode: ${prof?.code ?? user.nim}).',
      if (prof != null)
        'Nama: ${prof.name} · NIDN: ${prof.nidn} · ${prof.department} (${prof.academicRank}).',
      'Beban semester: ${w.totalCourses} mata kuliah (${w.totalClasses} kelas, ${w.totalCredits} SKS, ${w.totalStudents} mahasiswa).',
      'Pertemuan: ${w.completedMeetings}/${w.targetMeetings} · Belum input nilai: $pendingGrades kelas · Perwalian PA: ${w.paApproved}/${w.paTotal} disetujui ($pendingPa menunggu).',
      if (isThesis)
        'Bimbingan TA: ${w.thesisActive}/${w.thesisCapacity} mahasiswa aktif · ${w.thesisPendingReviews} review menunggu · ${w.thesisReadyDefense} siap sidang · ${data.thesisSchedules.length} jadwal TA.',
    ];

    return SiakadKnowledge(
      roleLabel: prof?.roleLabel ?? 'Dosen Akademik',
      accountId: prof?.code ?? user.nim,
      greetingName: prof?.name ?? user.nim,
      profileSummary: lines.join('\n'),
      courses: data.courses,
      schedules: data.schedules,
      paAdvisees: data.paAdvisees,
      thesisAdvisees: data.thesisAdvisees,
      thesisSchedules: data.thesisSchedules,
      announcements: data.announcements,
      news: data.news,
      guides: data.guides,
      leaveCount: leaveCount,
      isThesisAdvisor: isThesis,
      quickPrompts: isThesis
          ? const [
              ('Mahasiswa Bimbingan TA', 'Siapa saja mahasiswa bimbingan TA saya?'),
              ('Siap Sidang TA', 'Siapa mahasiswa bimbingan TA yang siap sidang?'),
              ('Jadwal Sidang & TA', 'Apa jadwal bimbingan dan sidang TA saya?'),
              ('PA Menunggu ACC', 'Siapa saja mahasiswa PA yang menunggu ACC KRS?'),
              ('Mata Kuliah Diampu', 'Apa saja mata kuliah yang saya ampu semester ini?'),
            ]
          : const [
              ('Mata Kuliah Diampu', 'Apa saja mata kuliah yang saya ampu semester ini?'),
              ('PA Menunggu ACC', 'Siapa saja mahasiswa PA yang menunggu ACC KRS?'),
              ('Belum Input Nilai', 'Kelas mana yang belum input nilai?'),
              ('Jadwal Mengajar', 'Apa jadwal mengajar saya di SIAKAD?'),
              ('Pengumuman', 'Ada pengumuman apa di SIAKAD?'),
            ],
    );
  }
}
