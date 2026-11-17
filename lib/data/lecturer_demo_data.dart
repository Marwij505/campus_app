// Data dummy komprehensif untuk Dosen Akademik dan Dosen Pembimbing SIAKAD FASILKOM.
// Disediakan dua profil dosen uji:
// 1. DOS001: Dr. Ir. Hendra Gunawan, S.Kom., M.T. (Dosen Akademik / Pengampu Mata Kuliah)
// 2. DOS002: Prof. Dr. Sri Wahyuni, M.Kom., Ph.D. (Dosen Akademik & Pembimbing Akademik / DPA & Skripsi)

import 'lecturer_models.dart';

abstract final class LecturerDemoData {
  // ==========================================
  // PROFIL DOSEN
  // ==========================================

  static const profileDos001 = LecturerProfileData(
    nip: 'DOS001',
    nidn: '0312048001',
    nameWithTitle: 'Dr. Ir. Hendra Gunawan, S.Kom., M.T.',
    faculty: 'Fakultas Ilmu Komputer',
    department: 'Teknik Informatika',
    functionalRole: 'Lektor Kepala',
    status: 'Aktif Mengajar',
    activeSemester: 'Ganjil 2026/2027',
    email: 'hendra.gunawan@esaunggul.ac.id',
    roomOffice: 'Ruang Dosen FASILKOM Lt. 2 (R.204)',
    roleType: LecturerRoleType.academic,
  );

  static const profileDos002 = LecturerProfileData(
    nip: 'DOS002',
    nidn: '0328097502',
    nameWithTitle: 'Prof. Dr. Sri Wahyuni, M.Kom., Ph.D.',
    faculty: 'Fakultas Ilmu Komputer',
    department: 'Teknik Informatika & Sistem Informasi',
    functionalRole: 'Guru Besar / Lektor Kepala',
    status: 'Aktif Mengajar & Membimbing',
    activeSemester: 'Ganjil 2026/2027',
    email: 'sri.wahyuni@esaunggul.ac.id',
    roomOffice: 'Ruang DPA & Kaprodi TI Lt. 3 (R.310)',
    roleType: LecturerRoleType.both,
  );

  static LecturerProfileData getProfile(String nip) {
    if (nip == 'DOS002') return profileDos002;
    return profileDos001;
  }

  // ==========================================
  // STATISTIK DASHBOARD
  // ==========================================

  static const statsDos001 = LecturerDashboardStats(
    totalClasses: 4,
    totalCredits: 12,
    totalStudentsTaught: 148,
    averageAttendance: 92.4,
    bapCompletionRate: 87.5,
    totalAdvisees: 0,
    pendingKrsCount: 0,
    activeThesisCount: 0,
    studentsWarningCount: 0,
  );

  static const statsDos002 = LecturerDashboardStats(
    totalClasses: 3,
    totalCredits: 9,
    totalStudentsTaught: 116,
    averageAttendance: 95.8,
    bapCompletionRate: 94.0,
    totalAdvisees: 28,
    pendingKrsCount: 5,
    activeThesisCount: 6,
    studentsWarningCount: 2,
  );

  static LecturerDashboardStats getStats(String nip) {
    if (nip == 'DOS002') return statsDos002;
    return statsDos001;
  }

  // ==========================================
  // JADWAL MENGAJAR DOSEN
  // ==========================================

  static List<TeachingScheduleItem> getTeachingSchedules(String nip) {
    if (nip == 'DOS002') {
      return [
        const TeachingScheduleItem(
          id: 'SCH-0201',
          courseCode: 'TIF302',
          courseName: 'Basis Data Lanjut',
          classSection: 'KJ001',
          credits: 3,
          day: 'Senin',
          time: '08:00 - 10:30 WIB',
          room: 'Lab Basis Data (R.604)',
          currentMeeting: 6,
          totalMeetings: 14,
          enrolledStudents: 38,
          attendedStudents: 36,
          bapSubmitted: true,
          bapTopic: 'Normalisasi Database & Query Optimization',
          status: 'Selesai',
        ),
        const TeachingScheduleItem(
          id: 'SCH-0202',
          courseCode: 'TIF408',
          courseName: 'Algoritma & Pemrograman Lanjut',
          classSection: 'CR002',
          credits: 3,
          day: 'Selasa',
          time: '10:45 - 13:15 WIB',
          room: 'Lab Komputer 3 (R.603)',
          currentMeeting: 6,
          totalMeetings: 14,
          enrolledStudents: 42,
          attendedStudents: 40,
          bapSubmitted: false,
          bapTopic: 'Graf & Algoritma Lintasan Terpendek (Dijkstra)',
          status: 'Berlangsung',
        ),
        const TeachingScheduleItem(
          id: 'SCH-0203',
          courseCode: 'TIF501',
          courseName: 'Metodologi Penelitian & Seminar Proposal',
          classSection: 'KJ003',
          credits: 3,
          day: 'Kamis',
          time: '13:30 - 16:00 WIB',
          room: 'Ruang Teori 401',
          currentMeeting: 6,
          totalMeetings: 14,
          enrolledStudents: 36,
          attendedStudents: 35,
          bapSubmitted: false,
          bapTopic: 'Penyusunan Tinjauan Pustaka & Matriks Literatur',
          status: 'Akan Datang',
        ),
      ];
    }

    // Default DOS001
    return [
      const TeachingScheduleItem(
        id: 'SCH-0101',
        courseCode: 'TIF305',
        courseName: 'Pemrograman Mobile Berbasis Framework',
        classSection: 'CR001',
        credits: 3,
        day: 'Senin',
        time: '08:00 - 10:30 WIB',
        room: 'Lab Rekayasa Perangkat Lunak (R.601)',
        currentMeeting: 7,
        totalMeetings: 14,
        enrolledStudents: 38,
        attendedStudents: 36,
        bapSubmitted: true,
        bapTopic: 'State Management & Responsive Layout di Flutter',
        status: 'Berlangsung',
      ),
      const TeachingScheduleItem(
        id: 'SCH-0102',
        courseCode: 'TIF204',
        courseName: 'Pemrograman Berorientasi Objek (OOP)',
        classSection: 'KJ001',
        credits: 3,
        day: 'Senin',
        time: '13:00 - 15:30 WIB',
        room: 'Lab Komputer 2 (R.602)',
        currentMeeting: 7,
        totalMeetings: 14,
        enrolledStudents: 40,
        attendedStudents: 37,
        bapSubmitted: false,
        bapTopic: 'Polymorphism, Interface, & Abstract Class',
        status: 'Akan Datang',
      ),
      const TeachingScheduleItem(
        id: 'SCH-0103',
        courseCode: 'TIF401',
        courseName: 'Kecerdasan Buatan & Machine Learning',
        classSection: 'CR003',
        credits: 3,
        day: 'Rabu',
        time: '09:00 - 11:30 WIB',
        room: 'Lab Kecerdasan Komputasional (R.605)',
        currentMeeting: 6,
        totalMeetings: 14,
        enrolledStudents: 35,
        attendedStudents: 33,
        bapSubmitted: true,
        bapTopic: 'Supervised Learning & Klasifikasi Dataset',
        status: 'Akan Datang',
      ),
      const TeachingScheduleItem(
        id: 'SCH-0104',
        courseCode: 'TIF405',
        courseName: 'Rekayasa Perangkat Lunak',
        classSection: 'CR002',
        credits: 3,
        day: 'Kamis',
        time: '10:00 - 12:30 WIB',
        room: 'Ruang Teori 302',
        currentMeeting: 6,
        totalMeetings: 14,
        enrolledStudents: 35,
        attendedStudents: 32,
        bapSubmitted: false,
        bapTopic: 'Pemodelan Arsitektur Sistem dengan UML & Use Case',
        status: 'Akan Datang',
      ),
    ];
  }

  // ==========================================
  // RINGKASAN KELAS KULIAH & NILAI
  // ==========================================

  static List<TeachingClassSummary> getTeachingClasses(String nip) {
    if (nip == 'DOS002') {
      return const [
        TeachingClassSummary(
          courseCode: 'TIF302',
          courseName: 'Basis Data Lanjut',
          classSection: 'KJ001',
          credits: 3,
          totalStudents: 38,
          averageAttendance: 96.2,
          gradeInputStatus: 'Tugas 1-3 Terisi, Menunggu Nilai UTS',
          semester: 'Ganjil 2026/2027',
        ),
        TeachingClassSummary(
          courseCode: 'TIF408',
          courseName: 'Algoritma & Pemrograman Lanjut',
          classSection: 'CR002',
          credits: 3,
          totalStudents: 42,
          averageAttendance: 95.0,
          gradeInputStatus: 'Kuis & Praktikum Terisi 100%',
          semester: 'Ganjil 2026/2027',
        ),
        TeachingClassSummary(
          courseCode: 'TIF501',
          courseName: 'Metodologi Penelitian & Seminar Proposal',
          classSection: 'KJ003',
          credits: 3,
          totalStudents: 36,
          averageAttendance: 97.1,
          gradeInputStatus: 'Draf Proposal Bab 1-3 Masuk (85%)',
          semester: 'Ganjil 2026/2027',
        ),
      ];
    }

    return const [
      TeachingClassSummary(
        courseCode: 'TIF305',
        courseName: 'Pemrograman Mobile Berbasis Framework',
        classSection: 'CR001',
        credits: 3,
        totalStudents: 38,
        averageAttendance: 94.7,
        gradeInputStatus: 'Tugas Proyek 1 Selesai, Menunggu UTS',
        semester: 'Ganjil 2026/2027',
      ),
      TeachingClassSummary(
        courseCode: 'TIF204',
        courseName: 'Pemrograman Berorientasi Objek (OOP)',
        classSection: 'KJ001',
        credits: 3,
        totalStudents: 40,
        averageAttendance: 92.5,
        gradeInputStatus: 'Kuis 1 & Tugas 1 Terinput',
        semester: 'Ganjil 2026/2027',
      ),
      TeachingClassSummary(
        courseCode: 'TIF401',
        courseName: 'Kecerdasan Buatan & Machine Learning',
        classSection: 'CR003',
        credits: 3,
        totalStudents: 35,
        averageAttendance: 94.3,
        gradeInputStatus: 'Praktikum Python & Preprocessing Terisi',
        semester: 'Ganjil 2026/2027',
      ),
      TeachingClassSummary(
        courseCode: 'TIF405',
        courseName: 'Rekayasa Perangkat Lunak',
        classSection: 'CR002',
        credits: 3,
        totalStudents: 35,
        averageAttendance: 91.4,
        gradeInputStatus: 'Dokumen SRS Kelompok 1-7 Diperiksa',
        semester: 'Ganjil 2026/2027',
      ),
    ];
  }

  // ==========================================
  // PERSETUJUAN KRS MAHASISWA (APPROVAL KRS)
  // ==========================================

  static List<KrsApprovalRequest> getKrsApprovals(String nip) {
    return [
      KrsApprovalRequest(
        id: 'KRS-001',
        studentNim: '20240801001',
        studentName: 'Reifan Ardissa',
        major: 'Teknik Informatika',
        entryYear: 2024,
        semester: 5,
        gpa: 3.73,
        maxCredits: 24,
        proposedCredits: 21,
        submissionDate: '15 Agu 2026, 09:30 WIB',
        status: KrsStatus.pending,
        courses: const [
          KrsCourseItem(
            code: 'TIF305',
            name: 'Pemrograman Mobile Berbasis Framework',
            credits: 3,
            classSection: 'CR001',
            schedule: 'Senin, 08:00 - 10:30',
            room: 'Lab RPL',
          ),
          KrsCourseItem(
            code: 'TIF401',
            name: 'Kecerdasan Buatan & Machine Learning',
            credits: 3,
            classSection: 'CR003',
            schedule: 'Rabu, 09:00 - 11:30',
            room: 'Lab Komputasi',
          ),
          KrsCourseItem(
            code: 'TIF405',
            name: 'Rekayasa Perangkat Lunak',
            credits: 3,
            classSection: 'CR002',
            schedule: 'Kamis, 10:00 - 12:30',
            room: 'R.302',
          ),
          KrsCourseItem(
            code: 'TIF302',
            name: 'Basis Data Lanjut',
            credits: 3,
            classSection: 'KJ001',
            schedule: 'Senin, 10:45 - 13:15',
            room: 'Lab Basis Data',
          ),
          KrsCourseItem(
            code: 'TIF310',
            name: 'Jaringan Komputer & Keamanan Siber',
            credits: 3,
            classSection: 'CR001',
            schedule: 'Selasa, 13:30 - 16:00',
            room: 'Lab Jaringan',
          ),
          KrsCourseItem(
            code: 'TIF315',
            name: 'Interaksi Manusia dan Komputer (UI/UX)',
            credits: 3,
            classSection: 'KJ002',
            schedule: 'Jumat, 08:00 - 10:30',
            room: 'R.401',
          ),
          KrsCourseItem(
            code: 'UNI201',
            name: 'Kewirausahaan Berbasis Teknologi',
            credits: 3,
            classSection: 'CR005',
            schedule: 'Sabtu, 09:00 - 11:30',
            room: 'Daring / Zoom',
          ),
        ],
        advisorNotes: 'Rencana studi seimbang. Peminatan Mobile & AI relevan.',
      ),
      KrsApprovalRequest(
        id: 'KRS-002',
        studentNim: '20240803067',
        studentName: 'Salsabila Hamka',
        major: 'Sistem Informasi',
        entryYear: 2024,
        semester: 5,
        gpa: 3.82,
        maxCredits: 24,
        proposedCredits: 24,
        submissionDate: '15 Agu 2026, 11:15 WIB',
        status: KrsStatus.pending,
        courses: const [
          KrsCourseItem(
            code: 'TIF305',
            name: 'Pemrograman Mobile Berbasis Framework',
            credits: 3,
            classSection: 'CR001',
            schedule: 'Senin, 08:00 - 10:30',
            room: 'Lab RPL',
          ),
          KrsCourseItem(
            code: 'TIF401',
            name: 'Kecerdasan Buatan & Machine Learning',
            credits: 3,
            classSection: 'CR003',
            schedule: 'Rabu, 09:00 - 11:30',
            room: 'Lab Komputasi',
          ),
          KrsCourseItem(
            code: 'TIF405',
            name: 'Rekayasa Perangkat Lunak',
            credits: 3,
            classSection: 'CR002',
            schedule: 'Kamis, 10:00 - 12:30',
            room: 'R.302',
          ),
          KrsCourseItem(
            code: 'TIF302',
            name: 'Basis Data Lanjut',
            credits: 3,
            classSection: 'KJ001',
            schedule: 'Senin, 10:45 - 13:15',
            room: 'Lab Basis Data',
          ),
          KrsCourseItem(
            code: 'TIF310',
            name: 'Jaringan Komputer & Keamanan Siber',
            credits: 3,
            classSection: 'CR001',
            schedule: 'Selasa, 13:30 - 16:00',
            room: 'Lab Jaringan',
          ),
          KrsCourseItem(
            code: 'TIF315',
            name: 'Interaksi Manusia dan Komputer (UI/UX)',
            credits: 3,
            classSection: 'KJ002',
            schedule: 'Jumat, 08:00 - 10:30',
            room: 'R.401',
          ),
          KrsCourseItem(
            code: 'TIF320',
            name: 'Cloud Computing & DevOps',
            credits: 3,
            classSection: 'CR001',
            schedule: 'Rabu, 13:30 - 16:00',
            room: 'Lab Server',
          ),
          KrsCourseItem(
            code: 'UNI201',
            name: 'Kewirausahaan Berbasis Teknologi',
            credits: 3,
            classSection: 'CR005',
            schedule: 'Sabtu, 09:00 - 11:30',
            room: 'Daring / Zoom',
          ),
        ],
        advisorNotes: 'Mengambil batas maksimal 24 SKS, IPK memenuhi syarat.',
      ),
      KrsApprovalRequest(
        id: 'KRS-003',
        studentNim: '20230801041',
        studentName: 'Dimas Wahyu Pratama',
        major: 'Teknik Informatika',
        entryYear: 2023,
        semester: 7,
        gpa: 3.51,
        maxCredits: 24,
        proposedCredits: 12,
        submissionDate: '14 Agu 2026, 14:20 WIB',
        status: KrsStatus.approved,
        courses: const [
          KrsCourseItem(
            code: 'TIF699',
            name: 'Tugas Akhir / Skripsi',
            credits: 6,
            classSection: 'TA01',
            schedule: 'Fleksibel Mandiri',
            room: 'Bimbingan PA',
          ),
          KrsCourseItem(
            code: 'TIF601',
            name: 'Kerja Praktik / Magang Industri',
            credits: 3,
            classSection: 'KP02',
            schedule: 'Mitra Industri',
            room: 'Lapangan',
          ),
          KrsCourseItem(
            code: 'TIF605',
            name: 'Etika Profesi & Hukum Siber',
            credits: 3,
            classSection: 'CR001',
            schedule: 'Jumat, 14:00 - 16:30',
            room: 'R.304',
          ),
        ],
        advisorNotes: 'Disetujui. Fokus pada penyelesaian bab 4 skripsi.',
      ),
      KrsApprovalRequest(
        id: 'KRS-004',
        studentNim: '20250801018',
        studentName: 'Amanda Putri Lestari',
        major: 'Teknik Informatika',
        entryYear: 2025,
        semester: 3,
        gpa: 2.85,
        maxCredits: 20,
        proposedCredits: 22,
        submissionDate: '13 Agu 2026, 16:45 WIB',
        status: KrsStatus.revision,
        courses: const [
          KrsCourseItem(
            code: 'TIF201',
            name: 'Struktur Data & Algoritma',
            credits: 4,
            classSection: 'KJ001',
            schedule: 'Selasa, 08:00 - 11:20',
            room: 'Lab Komputer 1',
          ),
          KrsCourseItem(
            code: 'TIF204',
            name: 'Pemrograman Berorientasi Objek',
            credits: 3,
            classSection: 'CR002',
            schedule: 'Rabu, 10:00 - 12:30',
            room: 'Lab RPL',
          ),
        ],
        advisorNotes: 'SKS diajukan (22 SKS) melebihi jatah IPK (maksimal 20 SKS). Kurangi 1 mata kuliah pilihan.',
      ),
      KrsApprovalRequest(
        id: 'KRS-005',
        studentNim: '20240801089',
        studentName: 'Budi Santoso',
        major: 'Teknik Informatika',
        entryYear: 2024,
        semester: 5,
        gpa: 3.42,
        maxCredits: 24,
        proposedCredits: 20,
        submissionDate: '16 Agu 2026, 08:10 WIB',
        status: KrsStatus.pending,
        courses: const [
          KrsCourseItem(
            code: 'TIF305',
            name: 'Pemrograman Mobile Berbasis Framework',
            credits: 3,
            classSection: 'CR001',
            schedule: 'Senin, 08:00 - 10:30',
            room: 'Lab RPL',
          ),
          KrsCourseItem(
            code: 'TIF401',
            name: 'Kecerdasan Buatan & Machine Learning',
            credits: 3,
            classSection: 'CR003',
            schedule: 'Rabu, 09:00 - 11:30',
            room: 'Lab Komputasi',
          ),
          KrsCourseItem(
            code: 'TIF405',
            name: 'Rekayasa Perangkat Lunak',
            credits: 3,
            classSection: 'CR002',
            schedule: 'Kamis, 10:00 - 12:30',
            room: 'R.302',
          ),
          KrsCourseItem(
            code: 'TIF302',
            name: 'Basis Data Lanjut',
            credits: 3,
            classSection: 'KJ001',
            schedule: 'Senin, 10:45 - 13:15',
            room: 'Lab Basis Data',
          ),
        ],
        advisorNotes: 'Pilihan mata kuliah sesuai kurikulum.',
      ),
    ];
  }

  // ==========================================
  // DAFTAR MAHASISWA BIMBINGAN (ANAK WALI)
  // ==========================================

  static List<AdvisedStudent> getAdvisedStudents(String nip) {
    return const [
      AdvisedStudent(
        nim: '20240801002',
        name: 'Reifan Ardissa',
        major: 'Teknik Informatika',
        entryYear: 2024,
        currentSemester: 5,
        gpa: 3.73,
        ipsLatest: 3.85,
        passedCredits: 86,
        targetCredits: 144,
        krsStatusText: 'Menunggu ACC (21 SKS)',
        academicStatus: 'Aktif Berprestasi',
        hasWarning: false,
        lastConsultation: '12 Agu 2026',
        phone: '0812-3456-7890',
        email: 'reifan.ardissa@student.esaunggul.ac.id',
        notes: 'Mahasiswa sangat aktif. Berencana mengambil skripsi di semester 7 dengan topik Mobile AI.',
      ),
      AdvisedStudent(
        nim: '20240803067',
        name: 'Salsabila Hamka',
        major: 'Sistem Informasi',
        entryYear: 2024,
        currentSemester: 5,
        gpa: 3.82,
        ipsLatest: 3.90,
        passedCredits: 88,
        targetCredits: 144,
        krsStatusText: 'Menunggu ACC (24 SKS)',
        academicStatus: 'Aktif Berprestasi',
        hasWarning: false,
        lastConsultation: '14 Agu 2026',
        phone: '0813-9876-5432',
        email: 'salsabila.hamka@student.esaunggul.ac.id',
        notes: 'Mahasiswa sangat aktif. Berencana mengambil skripsi di semester 7 dengan topik Manajemen Proyek.',
      ),
      AdvisedStudent(
        nim: '20230801041',
        name: 'Dimas Wahyu Pratama',
        major: 'Teknik Informatika',
        entryYear: 2023,
        currentSemester: 7,
        gpa: 3.51,
        ipsLatest: 3.60,
        passedCredits: 126,
        targetCredits: 144,
        krsStatusText: 'Disetujui (12 SKS)',
        academicStatus: 'Aktif Skripsi',
        hasWarning: false,
        lastConsultation: '10 Agu 2026',
        phone: '0857-1122-3344',
        email: 'dimas.pratama@student.esaunggul.ac.id',
        notes: 'Sedang menyelesaikan penyusunan Bab 4 Skripsi. Menargetkan lulus 3.5 tahun.',
      ),
      AdvisedStudent(
        nim: '20240801089',
        name: 'Budi Santoso',
        major: 'Teknik Informatika',
        entryYear: 2024,
        currentSemester: 5,
        gpa: 3.42,
        ipsLatest: 3.35,
        passedCredits: 78,
        targetCredits: 144,
        krsStatusText: 'Menunggu ACC (20 SKS)',
        academicStatus: 'Aktif Normal',
        hasWarning: false,
        lastConsultation: '08 Agu 2026',
        phone: '0878-5566-7788',
        email: 'budi.santoso@student.esaunggul.ac.id',
        notes: 'Performa stabil. Disarankan memperbanyak portofolio proyek terapan.',
      ),
      AdvisedStudent(
        nim: '20250801018',
        name: 'Amanda Putri Lestari',
        major: 'Teknik Informatika',
        entryYear: 2025,
        currentSemester: 3,
        gpa: 2.85,
        ipsLatest: 2.70,
        passedCredits: 38,
        targetCredits: 144,
        krsStatusText: 'Perlu Revisi (22 SKS)',
        academicStatus: 'Perlu Perhatian',
        hasWarning: true,
        lastConsultation: '05 Agu 2026',
        phone: '0821-4433-2211',
        email: 'amanda.putri@student.esaunggul.ac.id',
        notes: 'IPK semester 2 mengalami penurunan. Disarankan fokus mengulang kalkulus dan algoritma.',
      ),
      AdvisedStudent(
        nim: '20220801012',
        name: 'Fikri Haikal',
        major: 'Teknik Informatika',
        entryYear: 2022,
        currentSemester: 9,
        gpa: 2.68,
        ipsLatest: 2.45,
        passedCredits: 110,
        targetCredits: 144,
        krsStatusText: 'Belum Mengajukan',
        academicStatus: 'Peringatan Masa Studi',
        hasWarning: true,
        lastConsultation: '22 Jul 2026',
        phone: '0819-3322-1100',
        email: 'fikri.haikal@student.esaunggul.ac.id',
        notes: 'Mendekati batas masa studi. Wajib segera menghadap DPA untuk percepatan proposal skripsi.',
      ),
      AdvisedStudent(
        nim: '20240801099',
        name: 'Zahra Aulia',
        major: 'Teknik Informatika',
        entryYear: 2024,
        currentSemester: 5,
        gpa: 3.65,
        ipsLatest: 3.70,
        passedCredits: 84,
        targetCredits: 144,
        krsStatusText: 'Disetujui (21 SKS)',
        academicStatus: 'Aktif Normal',
        hasWarning: false,
        lastConsultation: '11 Agu 2026',
        phone: '0812-8877-6655',
        email: 'zahra.aulia@student.esaunggul.ac.id',
        notes: 'Mengikuti program magang studi independen bersertifikat (MSIB).',
      ),
    ];
  }

  // ==========================================
  // BIMBINGAN TUGAS AKHIR / SKRIPSI
  // ==========================================

  static List<ThesisAdvisee> getThesisAdvisees(String nip) {
    // Hanya Dosen Pembimbing (DOS002) yang memiliki mahasiswa bimbingan skripsi / tugas akhir.
    // Dosen Akademik (DOS001) fokus pada pengajaran mata kuliah.
    if (nip != 'DOS002') {
      return const [];
    }

    return const [
      ThesisAdvisee(
        id: 'TA-01',
        studentNim: '20230801041',
        studentName: 'Dimas Wahyu Pratama',
        title: 'Penerapan Arsitektur Microservices pada Sistem Informasi Akademik Terdistribusi',
        stage: 'Bab 4 - Pengujian & Analisis Sistem',
        progress: 0.80,
        lastLogbookDate: '14 Agu 2026',
        totalConsultations: 8,
        status: 'Aktif Bimbingan',
        nextTarget: 'Finalisasi Bab 5 dan Simulasi Beban Sistem (Load Testing)',
      ),
      ThesisAdvisee(
        id: 'TA-02',
        studentNim: '20220801019',
        studentName: 'Rian Hidayat',
        title: 'Deteksi Kerentanan Aplikasi Web Menggunakan Pendekatan Static Application Security Testing (SAST)',
        stage: 'Bab 3 - Metodologi Penelitian & Perancangan',
        progress: 0.55,
        lastLogbookDate: '10 Agu 2026',
        totalConsultations: 5,
        status: 'Aktif Bimbingan',
        nextTarget: 'Pengumpulan Dataset CVE dan Pengujian Rule Engine',
      ),
      ThesisAdvisee(
        id: 'TA-03',
        studentNim: '20220801033',
        studentName: 'Nadia Safitri',
        title: 'Klasifikasi Sentimen Ulasan Mahasiswa pada SIAKAD Menggunakan Algoritma IndoBERT',
        stage: 'Bab 5 - Kesimpulan & Rekomendasi (Pra-Sidang)',
        progress: 0.95,
        lastLogbookDate: '15 Agu 2026',
        totalConsultations: 11,
        status: 'Siap Daftar Sidang',
        nextTarget: 'Pendaftaran Sidang Skripsi & Pengesahan Dosen Pembimbing',
      ),
      ThesisAdvisee(
        id: 'TA-04',
        studentNim: '20220801077',
        studentName: 'Taufiqurrahman',
        title: 'Implementasi Algoritma YOLOv8 untuk Pengawasan Kehadiran Mahasiswa Berbasis Citra',
        stage: 'Bab 2 - Landasan Teori & Kajian Pustaka',
        progress: 0.35,
        lastLogbookDate: '01 Agu 2026',
        totalConsultations: 3,
        status: 'Perlu Revisi Teori',
        nextTarget: 'Perbaikan Matriks Penelitian Sejenis & Algoritma Pendeteksi Wajah',
      ),
      ThesisAdvisee(
        id: 'TA-05',
        studentNim: '20220801090',
        studentName: 'Farhan Maulana',
        title: 'Pengembangan Chatbot Konsultasi Akademik Berbasis Large Language Model Terlokalisasi',
        stage: 'Bab 4 - Implementasi & Evaluasi Model',
        progress: 0.70,
        lastLogbookDate: '12 Agu 2026',
        totalConsultations: 7,
        status: 'Aktif Bimbingan',
        nextTarget: 'Uji Akurasi Respon Menggunakan Metrik ROUGE dan BLEU',
      ),
    ];
  }
}
