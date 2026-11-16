// Cetakan data dosen akademik dan dosen pembimbing untuk SIAKAD.
// Mendukung peran pengajaran (dosen akademik) dan bimbingan perwalian / skripsi (dosen pembimbing).

enum LecturerRoleType {
  /// Dosen Akademik (Fokus pada pengajaran mata kuliah, jadwal kelas, BAP, presensi, & nilai)
  academic,

  /// Dosen Pembimbing Akademik / DPA (Fokus pada perwalian, validasi KRS, evaluasi studi, & bimbingan skripsi)
  advisor,

  /// Memiliki kedua peran secara aktif (Pengajar sekaligus Pembimbing Akademik)
  both,
}

enum KrsStatus {
  pending, // Menunggu persetujuan / ACC dosen pembimbing
  approved, // Disetujui
  revision, // Perlu revisi oleh mahasiswa
}

/// Satu mata kuliah yang diajukan mahasiswa dalam KRS.
class KrsCourseItem {
  const KrsCourseItem({
    required this.code,
    required this.name,
    required this.credits,
    required this.classSection,
    required this.schedule,
    required this.room,
  });

  final String code;
  final String name;
  final int credits;
  final String classSection;
  final String schedule;
  final String room;
}

/// Pengajuan KRS mahasiswa perwalian yang memerlukan validasi dosen pembimbing.
class KrsApprovalRequest {
  const KrsApprovalRequest({
    required this.id,
    required this.studentNim,
    required this.studentName,
    required this.major,
    required this.entryYear,
    required this.semester,
    required this.gpa,
    required this.maxCredits,
    required this.proposedCredits,
    required this.courses,
    required this.submissionDate,
    required this.status,
    this.advisorNotes,
  });

  final String id;
  final String studentNim;
  final String studentName;
  final String major;
  final int entryYear;
  final int semester;
  final double gpa;
  final int maxCredits;
  final int proposedCredits;
  final List<KrsCourseItem> courses;
  final String submissionDate;
  final KrsStatus status;
  final String? advisorNotes;

  KrsApprovalRequest copyWith({
    KrsStatus? status,
    String? advisorNotes,
  }) => KrsApprovalRequest(
    id: id,
    studentNim: studentNim,
    studentName: studentName,
    major: major,
    entryYear: entryYear,
    semester: semester,
    gpa: gpa,
    maxCredits: maxCredits,
    proposedCredits: proposedCredits,
    courses: courses,
    submissionDate: submissionDate,
    status: status ?? this.status,
    advisorNotes: advisorNotes ?? this.advisorNotes,
  );
}

/// Data profil mahasiswa bimbingan akademik (anak wali).
class AdvisedStudent {
  const AdvisedStudent({
    required this.nim,
    required this.name,
    required this.major,
    required this.entryYear,
    required this.currentSemester,
    required this.gpa,
    required this.ipsLatest,
    required this.passedCredits,
    required this.targetCredits,
    required this.krsStatusText,
    required this.academicStatus,
    required this.hasWarning,
    required this.lastConsultation,
    required this.phone,
    required this.email,
    required this.notes,
  });

  final String nim;
  final String name;
  final String major;
  final int entryYear;
  final int currentSemester;
  final double gpa;
  final double ipsLatest;
  final int passedCredits;
  final int targetCredits;
  final String krsStatusText;
  final String academicStatus;
  final bool hasWarning;
  final String lastConsultation;
  final String phone;
  final String email;
  final String notes;

  double get creditProgress => (passedCredits / targetCredits).clamp(0.0, 1.0);
}

/// Data mahasiswa yang sedang dibimbing untuk Tugas Akhir / Skripsi.
class ThesisAdvisee {
  const ThesisAdvisee({
    required this.id,
    required this.studentNim,
    required this.studentName,
    required this.title,
    required this.stage,
    required this.progress,
    required this.lastLogbookDate,
    required this.totalConsultations,
    required this.status,
    required this.nextTarget,
  });

  final String id;
  final String studentNim;
  final String studentName;
  final String title;
  final String stage;
  final double progress; // 0.0 sampai 1.0
  final String lastLogbookDate;
  final int totalConsultations;
  final String status;
  final String nextTarget;
}

/// Jadwal mengajar dosen pada semester aktif.
class TeachingScheduleItem {
  const TeachingScheduleItem({
    required this.id,
    required this.courseCode,
    required this.courseName,
    required this.classSection,
    required this.credits,
    required this.day,
    required this.time,
    required this.room,
    required this.currentMeeting,
    required this.totalMeetings,
    required this.enrolledStudents,
    required this.attendedStudents,
    required this.bapSubmitted,
    required this.bapTopic,
    required this.status, // "Berlangsung", "Selesai", "Akan Datang"
  });

  final String id;
  final String courseCode;
  final String courseName;
  final String classSection;
  final int credits;
  final String day;
  final String time;
  final String room;
  final int currentMeeting;
  final int totalMeetings;
  final int enrolledStudents;
  final int attendedStudents;
  final bool bapSubmitted;
  final String bapTopic;
  final String status;

  double get attendancePercentage => enrolledStudents > 0
      ? (attendedStudents / enrolledStudents) * 100
      : 0.0;

  TeachingScheduleItem copyWith({
    bool? bapSubmitted,
    String? bapTopic,
    int? attendedStudents,
    String? status,
  }) => TeachingScheduleItem(
    id: id,
    courseCode: courseCode,
    courseName: courseName,
    classSection: classSection,
    credits: credits,
    day: day,
    time: time,
    room: room,
    currentMeeting: currentMeeting,
    totalMeetings: totalMeetings,
    enrolledStudents: enrolledStudents,
    attendedStudents: attendedStudents ?? this.attendedStudents,
    bapSubmitted: bapSubmitted ?? this.bapSubmitted,
    bapTopic: bapTopic ?? this.bapTopic,
    status: status ?? this.status,
  );
}

/// Ringkasan kelas mata kuliah yang diampu untuk rekap nilai & perkuliahan.
class TeachingClassSummary {
  const TeachingClassSummary({
    required this.courseCode,
    required this.courseName,
    required this.classSection,
    required this.credits,
    required this.totalStudents,
    required this.averageAttendance,
    required this.gradeInputStatus,
    required this.semester,
  });

  final String courseCode;
  final String courseName;
  final String classSection;
  final int credits;
  final int totalStudents;
  final double averageAttendance;
  final String gradeInputStatus;
  final String semester;
}

/// Ringkasan statistik performa tridharma pengajaran & perwalian dosen.
class LecturerDashboardStats {
  const LecturerDashboardStats({
    required this.totalClasses,
    required this.totalCredits,
    required this.totalStudentsTaught,
    required this.averageAttendance,
    required this.bapCompletionRate,
    required this.totalAdvisees,
    required this.pendingKrsCount,
    required this.activeThesisCount,
    required this.studentsWarningCount,
  });

  final int totalClasses;
  final int totalCredits;
  final int totalStudentsTaught;
  final double averageAttendance;
  final double bapCompletionRate;
  final int totalAdvisees;
  final int pendingKrsCount;
  final int activeThesisCount;
  final int studentsWarningCount;
}

/// Profil lengkap dosen pengampu & pembimbing akademik.
class LecturerProfileData {
  const LecturerProfileData({
    required this.nip,
    required this.nidn,
    required this.nameWithTitle,
    required this.faculty,
    required this.department,
    required this.functionalRole,
    required this.status,
    required this.activeSemester,
    required this.email,
    required this.roomOffice,
    required this.roleType,
  });

  final String nip;
  final String nidn;
  final String nameWithTitle;
  final String faculty;
  final String department;
  final String functionalRole; // e.g. Lektor Kepala, Lektor, Asisten Ahli, Guru Besar
  final String status; // Aktif Mengajar & Membimbing
  final String activeSemester; // Ganjil 2026/2027
  final String email;
  final String roomOffice;
  final LecturerRoleType roleType;
}
