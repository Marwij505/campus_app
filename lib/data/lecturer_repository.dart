// Penyedia data dashboard dosen beserta data dummy lokal untuk akun DOS001
// (Dosen Akademik) dan DOS002 (Dosen Akademik + Pembimbing TA).

import 'dashboard_models.dart';
import 'lecturer_models.dart';
import 'student_profile.dart';

/// Kontrak pengambilan data dashboard dosen berdasarkan kode/NIP dosen.
abstract class LecturerRepository {
  Future<LecturerDashboardData> load(String code, {DateTime? now});
}

/// Implementasi dummy lokal agar kedua peran dosen dapat langsung diakses
/// setelah login menggunakan akun simulasi DOS001 atau DOS002.
class DemoLecturerRepository implements LecturerRepository {
  const DemoLecturerRepository();

  @override
  Future<LecturerDashboardData> load(String code, {DateTime? now}) async {
    final base = (now ?? DateTime.now()).toLocal();
    final today = DateTime(base.year, base.month, base.day);

    if (code == 'DOS002') {
      return _buildAdvisorAndAcademic(today);
    }
    return _buildAcademicOnly(today, code: code);
  }

  LecturerDashboardData _buildAcademicOnly(
    DateTime today, {
    required String code,
  }) => LecturerDashboardData(
    profile: LecturerProfile(
      code: code,
      type: LecturerType.academic,
      name: 'Dr. Budi Santoso, M.Kom.',
      nidn: '0315018501',
      faculty: 'Fakultas Ilmu Komputer',
      department: 'Teknik Informatika',
      academicRank: 'Lektor',
      status: 'Aktif Mengajar',
      homebase: 'S1 Teknik Informatika',
    ),
    workload: const LecturerWorkload(
      totalCourses: 3,
      totalClasses: 4,
      totalCredits: 11,
      totalStudents: 142,
      completedMeetings: 38,
      targetMeetings: 56,
      gradedClasses: 2,
      paApproved: 4,
      paTotal: 6,
      attendanceRate: 0.91,
    ),
    schedules: [
      ClassSchedule(
        code: 'IF2104',
        title: 'Struktur Data & Algoritma (Kelas A)',
        startsAt: today.add(const Duration(hours: 8)),
        endsAt: today.add(const Duration(hours: 10, minutes: 30)),
        room: 'Lab Komputer 2',
        lecturer: 'Dr. Budi Santoso, M.Kom.',
        meeting: 10,
        method: 'Tatap Muka',
      ),
      ClassSchedule(
        code: 'IF3201',
        title: 'Pemrograman Berbasis Mobile (Kelas B)',
        startsAt: today.add(const Duration(hours: 13)),
        endsAt: today.add(const Duration(hours: 15, minutes: 30)),
        room: 'Ruang R-304',
        lecturer: 'Dr. Budi Santoso, M.Kom.',
        meeting: 10,
        method: 'Tatap Muka',
      ),
      ClassSchedule(
        code: 'IF1102',
        title: 'Logika Informatika (Kelas A)',
        startsAt: today.add(const Duration(days: 1, hours: 9)),
        endsAt: today.add(const Duration(days: 1, hours: 10, minutes: 40)),
        room: 'Ruang R-201',
        lecturer: 'Dr. Budi Santoso, M.Kom.',
        meeting: 9,
        method: 'Hybrid',
      ),
    ],
    courses: const [
      LecturerCourseClass(
        code: 'IF2104',
        title: 'Struktur Data & Algoritma',
        classCode: 'A',
        credits: 3,
        studentCount: 38,
        scheduleText: 'Senin · 08:00 - 10:30',
        room: 'Lab Komputer 2',
        method: 'Tatap Muka',
        completedMeetings: 10,
        totalMeetings: 14,
        gradeSubmitted: true,
      ),
      LecturerCourseClass(
        code: 'IF2104',
        title: 'Struktur Data & Algoritma',
        classCode: 'B',
        credits: 3,
        studentCount: 36,
        scheduleText: 'Rabu · 10:30 - 13:00',
        room: 'Lab Komputer 1',
        method: 'Tatap Muka',
        completedMeetings: 9,
        totalMeetings: 14,
        gradeSubmitted: false,
      ),
      LecturerCourseClass(
        code: 'IF3201',
        title: 'Pemrograman Berbasis Mobile',
        classCode: 'B',
        credits: 3,
        studentCount: 34,
        scheduleText: 'Senin · 13:00 - 15:30',
        room: 'Ruang R-304',
        method: 'Tatap Muka',
        completedMeetings: 10,
        totalMeetings: 14,
        gradeSubmitted: true,
      ),
      LecturerCourseClass(
        code: 'IF1102',
        title: 'Logika Informatika',
        classCode: 'A',
        credits: 2,
        studentCount: 34,
        scheduleText: 'Selasa · 09:00 - 10:40',
        room: 'Ruang R-201',
        method: 'Hybrid',
        completedMeetings: 9,
        totalMeetings: 14,
        gradeSubmitted: false,
      ),
    ],
    paAdvisees: const [
      AcademicAdvisee(
        nim: '20240801001',
        name: 'Reifan Ardissa',
        semester: 5,
        gpa: 3.73,
        takenCredits: 21,
        krsStatus: KrsApprovalStatus.approved,
        note: 'KRS semester ganjil telah disetujui.',
      ),
      AcademicAdvisee(
        nim: '20240801002',
        name: 'Nadia Putri Maharani',
        semester: 5,
        gpa: 3.64,
        takenCredits: 22,
        krsStatus: KrsApprovalStatus.pending,
        note: 'Menunggu validasi mata kuliah pilihan.',
      ),
      AcademicAdvisee(
        nim: '20240801014',
        name: 'Bagas Prakoso',
        semester: 3,
        gpa: 3.18,
        takenCredits: 20,
        krsStatus: KrsApprovalStatus.revision,
        note: 'Diminta mengganti jadwal bentrok.',
      ),
      AcademicAdvisee(
        nim: '20230801029',
        name: 'Siti Aulia Rahma',
        semester: 7,
        gpa: 3.81,
        takenCredits: 18,
        krsStatus: KrsApprovalStatus.approved,
        note: 'Siap mengambil mata kuliah KKP.',
      ),
      AcademicAdvisee(
        nim: '20250801008',
        name: 'Dimas Pratama',
        semester: 1,
        gpa: 3.45,
        takenCredits: 20,
        krsStatus: KrsApprovalStatus.approved,
        note: 'Paket semester 1 lengkap.',
      ),
      AcademicAdvisee(
        nim: '20240801031',
        name: 'Kevin Wijaya',
        semester: 5,
        gpa: 2.95,
        takenCredits: 19,
        krsStatus: KrsApprovalStatus.pending,
        note: 'Konsultasi pengulangan mata kuliah wajib.',
      ),
    ],
    announcements: [
      CampusNotice(
        title: 'Batas Akhir Pengisian Nilai UTS Semester Ganjil',
        publishedAt: today.subtract(const Duration(days: 1)),
        body:
            'Dimohon kepada seluruh dosen pengampu mata kuliah untuk melengkapi komponen nilai UTS dan berita acara perkuliahan paling lambat Jumat pekan ini pukul 17:00 WIB.',
      ),
      CampusNotice(
        title: 'Periode Validasi KRS Mahasiswa Bimbingan PA',
        publishedAt: today.subtract(const Duration(days: 4)),
        body:
            'Dosen Pembimbing Akademik (PA) diharapkan meninjau pengajuan KRS mahasiswa bimbingan yang masih berstatus Menunggu ACC melalui menu Perwalian PA.',
      ),
    ],
    news: [
      CampusNotice(
        title: 'Workshop Kurikulum OBE & Evaluasi RPS Fasilkom',
        publishedAt: today.subtract(const Duration(days: 2)),
        body:
            'Fakultas Ilmu Komputer menyelenggarakan workshop penyelarasan RPS berbasis Outcome-Based Education (OBE) di Aula Gedung C.',
      ),
      CampusNotice(
        title: 'Pembaruan Sistem Izin Online Mahasiswa ke Dosen',
        publishedAt: today.subtract(const Duration(days: 6)),
        body:
            'Hasil keputusan izin sakit/dispensasi yang sudah diverifikasi BAP kini diteruskan langsung ke kotak masuk Hasil Izin masing-masing dosen pengampu.',
      ),
    ],
    guides: const [
      CampusGuide(
        title: 'Panduan Pengisian Presensi & BAP Perkuliahan',
        content:
            '1. Pastikan jadwal mengajar hari ini sesuai ruang dan metode.\n'
            '2. Catat materi pertemuan setiap selesai perkuliahan.\n'
            '3. Periksa kotak masuk Hasil Izin untuk melihat surat izin resmi dari BAP sebelum merekap presensi akhir.',
      ),
      CampusGuide(
        title: 'Prosedur Validasi KRS Mahasiswa PA',
        content:
            '1. Periksa IPK semester terakhir dan batas maksimal SKS mahasiswa.\n'
            '2. Pastikan tidak ada bentrok jadwal atau prasyarat yang belum lulus.\n'
            '3. Berikan catatan revisi jika mahasiswa perlu menyesuaikan rencana studi.',
      ),
    ],
  );

  LecturerDashboardData _buildAdvisorAndAcademic(DateTime today) =>
      LecturerDashboardData(
        profile: const LecturerProfile(
          code: 'DOS002',
          type: LecturerType.academicAndThesis,
          name: 'Dr. Ir. Ratna Sari, S.T., M.T.',
          nidn: '0312058702',
          faculty: 'Fakultas Ilmu Komputer',
          department: 'Teknik Informatika',
          academicRank: 'Lektor Kepala',
          status: 'Aktif Mengajar',
          homebase: 'S1 Teknik Informatika',
        ),
        workload: const LecturerWorkload(
          totalCourses: 3,
          totalClasses: 3,
          totalCredits: 9,
          totalStudents: 108,
          completedMeetings: 31,
          targetMeetings: 42,
          gradedClasses: 2,
          paApproved: 4,
          paTotal: 5,
          attendanceRate: 0.94,
          thesisActive: 5,
          thesisCapacity: 8,
          thesisPendingReviews: 3,
          thesisReadyDefense: 1,
        ),
        schedules: [
          ClassSchedule(
            code: 'IF3105',
            title: 'Rekayasa Perangkat Lunak (Kelas A)',
            startsAt: today.add(const Duration(hours: 9)),
            endsAt: today.add(const Duration(hours: 11, minutes: 30)),
            room: 'Ruang R-402',
            lecturer: 'Dr. Ir. Ratna Sari, S.T., M.T.',
            meeting: 11,
            method: 'Tatap Muka',
          ),
          ClassSchedule(
            code: 'IF4101',
            title: 'Metodologi Penelitian Informatika (Kelas A)',
            startsAt: today.add(const Duration(hours: 13, minutes: 30)),
            endsAt: today.add(const Duration(hours: 15, minutes: 10)),
            room: 'Ruang Seminar B',
            lecturer: 'Dr. Ir. Ratna Sari, S.T., M.T.',
            meeting: 10,
            method: 'Hybrid',
          ),
          ClassSchedule(
            code: 'IF3302',
            title: 'Manajemen Proyek TI (Kelas B)',
            startsAt: today.add(const Duration(days: 1, hours: 10)),
            endsAt: today.add(const Duration(days: 1, hours: 12, minutes: 30)),
            room: 'Ruang R-305',
            lecturer: 'Dr. Ir. Ratna Sari, S.T., M.T.',
            meeting: 10,
            method: 'Tatap Muka',
          ),
        ],
        courses: const [
          LecturerCourseClass(
            code: 'IF3105',
            title: 'Rekayasa Perangkat Lunak',
            classCode: 'A',
            credits: 3,
            studentCount: 38,
            scheduleText: 'Senin · 09:00 - 11:30',
            room: 'Ruang R-402',
            method: 'Tatap Muka',
            completedMeetings: 11,
            totalMeetings: 14,
            gradeSubmitted: true,
          ),
          LecturerCourseClass(
            code: 'IF4101',
            title: 'Metodologi Penelitian Informatika',
            classCode: 'A',
            credits: 3,
            studentCount: 36,
            scheduleText: 'Senin · 13:30 - 15:10',
            room: 'Ruang Seminar B',
            method: 'Hybrid',
            completedMeetings: 10,
            totalMeetings: 14,
            gradeSubmitted: true,
          ),
          LecturerCourseClass(
            code: 'IF3302',
            title: 'Manajemen Proyek TI',
            classCode: 'B',
            credits: 3,
            studentCount: 34,
            scheduleText: 'Selasa · 10:00 - 12:30',
            room: 'Ruang R-305',
            method: 'Tatap Muka',
            completedMeetings: 10,
            totalMeetings: 14,
            gradeSubmitted: false,
          ),
        ],
        paAdvisees: const [
          AcademicAdvisee(
            nim: '20230801012',
            name: 'Fajar Ramadhan',
            semester: 7,
            gpa: 3.79,
            takenCredits: 16,
            krsStatus: KrsApprovalStatus.approved,
            note: 'Mengambil Tugas Akhir & 3 mata kuliah pilihan.',
          ),
          AcademicAdvisee(
            nim: '20240801025',
            name: 'Clarissa Wijaya',
            semester: 5,
            gpa: 3.88,
            takenCredits: 22,
            krsStatus: KrsApprovalStatus.approved,
            note: 'Berprestasi akademik, disetujui 22 SKS.',
          ),
          AcademicAdvisee(
            nim: '20240801040',
            name: 'Rizky Maulana',
            semester: 5,
            gpa: 3.21,
            takenCredits: 20,
            krsStatus: KrsApprovalStatus.pending,
            note: 'Menunggu persetujuan KRS.',
          ),
          AcademicAdvisee(
            nim: '20230801055',
            name: 'Putri Handayani',
            semester: 7,
            gpa: 3.67,
            takenCredits: 14,
            krsStatus: KrsApprovalStatus.approved,
            note: 'Fokus penyelesaian skripsi.',
          ),
          AcademicAdvisee(
            nim: '20250801019',
            name: 'Alvin Nugroho',
            semester: 1,
            gpa: 3.52,
            takenCredits: 20,
            krsStatus: KrsApprovalStatus.approved,
            note: 'Paket semester awal lengkap.',
          ),
        ],
        thesisAdvisees: const [
          ThesisAdvisee(
            nim: '20230801012',
            name: 'Fajar Ramadhan',
            title:
                'Implementasi Deteksi Anomali Lalu Lintas Jaringan Kampus Berbasis Random Forest',
            roleInThesis: 'Pembimbing 1',
            stage: ThesisStage.readyDefense,
            progress: 0.92,
            lastGuidanceDate: '2 hari lalu',
            pendingAction: 'ACC Pendaftaran Sidang',
          ),
          ThesisAdvisee(
            nim: '20230801055',
            name: 'Putri Handayani',
            title:
                'Optimasi Penjadwalan Ruang Kuliah Menggunakan Algoritma Genetika',
            roleInThesis: 'Pembimbing 1',
            stage: ThesisStage.finalDraft,
            progress: 0.78,
            lastGuidanceDate: '4 hari lalu',
            pendingAction: 'Review Bab 4',
          ),
          ThesisAdvisee(
            nim: '20230801063',
            name: 'Hendra Kusuma',
            title:
                'Sistem Rekomendasi Pemilihan Topik Skripsi Berbasis Semantic Similarity',
            roleInThesis: 'Pembimbing 2',
            stage: ThesisStage.research,
            progress: 0.58,
            lastGuidanceDate: '1 minggu lalu',
            pendingAction: 'Review Hasil Uji Model',
          ),
          ThesisAdvisee(
            nim: '20230801071',
            name: 'Tania Salsabila',
            title:
                'Analisis Sentimen Ulasan Layanan Akademik Mahasiswa Menggunakan IndoBERT',
            roleInThesis: 'Pembimbing 1',
            stage: ThesisStage.chapter1To3,
            progress: 0.40,
            lastGuidanceDate: '5 hari lalu',
            pendingAction: 'Revisi Bab 2',
          ),
          ThesisAdvisee(
            nim: '20230801084',
            name: 'Muhammad Ilham',
            title:
                'Rancang Bangun Aplikasi Monitoring Bimbingan TA Terintegrasi Notifikasi',
            roleInThesis: 'Pembimbing 1',
            stage: ThesisStage.proposal,
            progress: 0.22,
            lastGuidanceDate: 'Hari ini',
            pendingAction: 'ACC Seminar Proposal',
          ),
        ],
        thesisSchedules: const [
          ThesisScheduleItem(
            studentName: 'Muhammad Ilham',
            nim: '20230801084',
            type: 'Seminar Proposal',
            topic: 'Rancang Bangun Aplikasi Monitoring Bimbingan TA',
            dateLabel: 'Besok',
            timeLabel: '10:00 - 11:00',
            location: 'Ruang Sidang Fasilkom 1',
          ),
          ThesisScheduleItem(
            studentName: 'Putri Handayani',
            nim: '20230801055',
            type: 'Bimbingan TA',
            topic: 'Pembahasan evaluasi Bab 4 & pengujian skenario',
            dateLabel: 'Rabu',
            timeLabel: '14:00 - 14:45',
            location: 'Ruang Dosen R-208',
          ),
          ThesisScheduleItem(
            studentName: 'Fajar Ramadhan',
            nim: '20230801012',
            type: 'Sidang Skripsi',
            topic: 'Sidang Akhir TA & Validasi Revisi Penguji',
            dateLabel: 'Jumat',
            timeLabel: '09:00 - 10:30',
            location: 'Ruang Sidang Utama',
          ),
          ThesisScheduleItem(
            studentName: 'Tania Salsabila',
            nim: '20230801071',
            type: 'Bimbingan TA',
            topic: 'Konsultasi metodologi pelabelan dataset IndoBERT',
            dateLabel: 'Jumat',
            timeLabel: '13:30 - 14:15',
            location: 'Online (Google Meet)',
          ),
        ],
        announcements: [
          CampusNotice(
            title: 'Batas Pendaftaran Sidang Skripsi Gelombang II',
            publishedAt: today.subtract(const Duration(days: 1)),
            body:
                'Mahasiswa bimbingan TA yang telah mendapat persetujuan Pembimbing 1 & Pembimbing 2 dapat mendaftar Sidang Skripsi Gelombang II hingga akhir bulan ini.',
          ),
          CampusNotice(
            title: 'Jadwal Seminar Proposal Periode Bulan Ini',
            publishedAt: today.subtract(const Duration(days: 3)),
            body:
                'Daftar penguji dan ruang seminar proposal telah diterbitkan pada portal TA Fasilkom.',
          ),
        ],
        news: [
          CampusNotice(
            title: 'Peningkatan Kuota Hibah Riset Dosen & Mahasiswa TA',
            publishedAt: today.subtract(const Duration(days: 2)),
            body:
                'LPPM membuka pengajuan pendanaan riset kolaborasi dosen pembimbing dan mahasiswa tingkat akhir.',
          ),
          CampusNotice(
            title: 'Template Penulisan Laporan Skripsi Terbaru 2026',
            publishedAt: today.subtract(const Duration(days: 5)),
            body:
                'Prodi Teknik Informatika merilis pembaruan format sitasi dan lampiran kode sumber untuk laporan TA.',
          ),
        ],
        guides: const [
          CampusGuide(
            title: 'Pedoman Pembimbingan Tugas Akhir & Skripsi',
            content:
                '1. Minimal 8 kali bimbingan tercatat sebelum pengajuan Seminar Proposal/Sidang.\n'
                '2. Pembimbing 1 berwenang memberikan ACC kelayakan sidang setelah Bab 1-5 lengkap.\n'
                '3. Catat setiap hasil revisi agar riwayat bimbingan terdokumentasi.',
          ),
          CampusGuide(
            title: 'Rubrik Penilaian Seminar Proposal & Sidang',
            content:
                'Penilaian meliputi: Rumusan masalah & kebaruan (25%), Metodologi & implementasi (35%), Analisis hasil (25%), dan Presentasi/tanya jawab (15%).',
          ),
        ],
      );
}

