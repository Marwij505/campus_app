// Model data untuk fitur-fitur BAP (Biro Administrasi Perkuliahan) FASILKOM.
// Menyimpan struktur data master kurikulum, jadwal, KRS, presensi, ujian,
// status akademik mahasiswa, dan laporan PDDikti.

// ─────────────────────────── KURIKULUM ───────────────────────────

class Coursemaster {
  const Coursemaster({
    required this.code,
    required this.name,
    required this.credits,
    required this.semester,
    required this.programStudy,
    this.prerequisite,
    this.type = 'Wajib',
  });

  final String code;
  final String name;
  final int credits;
  final int semester; // semester penempatan di kurikulum
  final String programStudy;
  final String? prerequisite; // kode MK prasyarat
  final String type; // Wajib / Pilihan

  Coursemaster copyWith({
    String? code,
    String? name,
    int? credits,
    int? semester,
    String? programStudy,
    String? prerequisite,
    String? type,
  }) {
    return Coursemaster(
      code: code ?? this.code,
      name: name ?? this.name,
      credits: credits ?? this.credits,
      semester: semester ?? this.semester,
      programStudy: programStudy ?? this.programStudy,
      prerequisite: prerequisite ?? this.prerequisite,
      type: type ?? this.type,
    );
  }
}

// ─────────────────────────── JADWAL KULIAH ───────────────────────────

class ClassSchedule {
  const ClassSchedule({
    required this.id,
    required this.courseCode,
    required this.courseName,
    required this.classSection,
    required this.lecturerName,
    required this.day,
    required this.time,
    required this.room,
    required this.credits,
    required this.enrolledCount,
    required this.capacity,
    this.isConflict = false,
  });

  final String id;
  final String courseCode;
  final String courseName;
  final String classSection; // A, B, C
  final String lecturerName;
  final String day;
  final String time; // '08:00 – 09:40'
  final String room;
  final int credits;
  final int enrolledCount;
  final int capacity;
  final bool isConflict; // bentrok ruang/dosen

  ClassSchedule copyWith({
    String? courseCode,
    String? courseName,
    String? classSection,
    String? lecturerName,
    String? room,
    String? day,
    String? time,
    int? credits,
    int? enrolledCount,
    int? capacity,
    bool? isConflict,
  }) => ClassSchedule(
    id: id,
    courseCode: courseCode ?? this.courseCode,
    courseName: courseName ?? this.courseName,
    classSection: classSection ?? this.classSection,
    lecturerName: lecturerName ?? this.lecturerName,
    day: day ?? this.day,
    time: time ?? this.time,
    room: room ?? this.room,
    credits: credits ?? this.credits,
    enrolledCount: enrolledCount ?? this.enrolledCount,
    capacity: capacity ?? this.capacity,
    isConflict: isConflict ?? this.isConflict,
  );
}

// ─────────────────────────── KRS OVERRIDE ───────────────────────────

enum KrsOverrideReason {
  transfer, // mahasiswa pindahan
  systemError, // kendala sistem
  late, // pengisian terlambat
  correction, // perbaikan data
}

class KrsOverrideRequest {
  const KrsOverrideRequest({
    required this.id,
    required this.studentNim,
    required this.studentName,
    required this.major,
    required this.semester,
    required this.reason,
    required this.submittedAt,
    this.isResolved = false,
  });

  final String id;
  final String studentNim;
  final String studentName;
  final String major;
  final int semester;
  final KrsOverrideReason reason;
  final String submittedAt;
  final bool isResolved;

  KrsOverrideRequest copyWith({bool? isResolved}) => KrsOverrideRequest(
    id: id,
    studentNim: studentNim,
    studentName: studentName,
    major: major,
    semester: semester,
    reason: reason,
    submittedAt: submittedAt,
    isResolved: isResolved ?? this.isResolved,
  );

  String get reasonLabel => switch (reason) {
    KrsOverrideReason.transfer => 'Mahasiswa Pindahan',
    KrsOverrideReason.systemError => 'Kendala Sistem',
    KrsOverrideReason.late => 'Pengisian Terlambat',
    KrsOverrideReason.correction => 'Koreksi Data',
  };
}

class KrsPeriod {
  const KrsPeriod({
    required this.semester,
    required this.openDate,
    required this.closeDate,
    required this.revisionOpen,
    required this.revisionClose,
    required this.isActive,
  });

  final String semester; // '2026/2027 Genap'
  final String openDate;
  final String closeDate;
  final String revisionOpen;
  final String revisionClose;
  final bool isActive;

  KrsPeriod copyWith({
    String? semester,
    String? openDate,
    String? closeDate,
    String? revisionOpen,
    String? revisionClose,
    bool? isActive,
  }) => KrsPeriod(
    semester: semester ?? this.semester,
    openDate: openDate ?? this.openDate,
    closeDate: closeDate ?? this.closeDate,
    revisionOpen: revisionOpen ?? this.revisionOpen,
    revisionClose: revisionClose ?? this.revisionClose,
    isActive: isActive ?? this.isActive,
  );
}

// ─────────────────────────── PRESENSI & BAP ───────────────────────────

class AttendanceSummary {
  const AttendanceSummary({
    required this.courseCode,
    required this.courseName,
    required this.classSection,
    required this.lecturerName,
    required this.totalMeetings,
    required this.conductedMeetings,
    required this.averageStudentAttendance,
    required this.pendingBapCount,
  });

  final String courseCode;
  final String courseName;
  final String classSection;
  final String lecturerName;
  final int totalMeetings; // sesuai kurikulum (16 pertemuan)
  final int conductedMeetings; // yang sudah terlaksana
  final double averageStudentAttendance; // dalam persen
  final int pendingBapCount; // BAP belum diisi dosen
}

class MakeupClassRequest {
  const MakeupClassRequest({
    required this.id,
    required this.lecturerName,
    required this.courseName,
    required this.classSection,
    required this.originalDate,
    required this.proposedDate,
    required this.room,
    this.isApproved = false,
  });

  final String id;
  final String lecturerName;
  final String courseName;
  final String classSection;
  final String originalDate;
  final String proposedDate;
  final String room;
  final bool isApproved;

  MakeupClassRequest copyWith({bool? isApproved}) => MakeupClassRequest(
    id: id,
    lecturerName: lecturerName,
    courseName: courseName,
    classSection: classSection,
    originalDate: originalDate,
    proposedDate: proposedDate,
    room: room,
    isApproved: isApproved ?? this.isApproved,
  );
}

// ─────────────────────────── UJIAN ───────────────────────────

enum ExamType { uts, uas }

class ExamSchedule {
  const ExamSchedule({
    required this.id,
    required this.courseCode,
    required this.courseName,
    required this.classSection,
    required this.examType,
    required this.date,
    required this.time,
    required this.room,
    required this.capacity,
    required this.registeredCount,
    this.gradeInputOpen = false,
  });

  final String id;
  final String courseCode;
  final String courseName;
  final String classSection;
  final ExamType examType;
  final String date;
  final String time;
  final String room;
  final int capacity;
  final int registeredCount;
  final bool gradeInputOpen;

  ExamSchedule copyWith({
    String? courseCode,
    String? courseName,
    String? classSection,
    ExamType? examType,
    String? date,
    String? time,
    String? room,
    int? capacity,
    int? registeredCount,
    bool? gradeInputOpen,
  }) => ExamSchedule(
    id: id,
    courseCode: courseCode ?? this.courseCode,
    courseName: courseName ?? this.courseName,
    classSection: classSection ?? this.classSection,
    examType: examType ?? this.examType,
    date: date ?? this.date,
    time: time ?? this.time,
    room: room ?? this.room,
    capacity: capacity ?? this.capacity,
    registeredCount: registeredCount ?? this.registeredCount,
    gradeInputOpen: gradeInputOpen ?? this.gradeInputOpen,
  );

  String get typeLabel => examType == ExamType.uts ? 'UTS' : 'UAS';
}

// ─────────────────────────── STATUS AKADEMIK MAHASISWA ───────────────────────────

enum AcademicStatusType {
  active,
  leave, // Cuti Akademik
  inactive, // Non-Aktif
  transfer, // Pindah Prodi
  resigned, // Mengundurkan Diri
  graduated, // Lulus / Yudisium
}

class StudentAcademicStatus {
  const StudentAcademicStatus({
    required this.nim,
    required this.name,
    required this.major,
    required this.entryYear,
    required this.currentSemester,
    required this.status,
    required this.gpa,
    required this.passedCredits,
    this.note,
  });

  final String nim;
  final String name;
  final String major;
  final int entryYear;
  final int currentSemester;
  final AcademicStatusType status;
  final double gpa;
  final int passedCredits;
  final String? note;

  StudentAcademicStatus copyWith({
    String? name,
    String? major,
    int? currentSemester,
    AcademicStatusType? status,
    double? gpa,
    int? passedCredits,
    String? note,
  }) => StudentAcademicStatus(
    nim: nim,
    name: name ?? this.name,
    major: major ?? this.major,
    entryYear: entryYear,
    currentSemester: currentSemester ?? this.currentSemester,
    status: status ?? this.status,
    gpa: gpa ?? this.gpa,
    passedCredits: passedCredits ?? this.passedCredits,
    note: note ?? this.note,
  );

  String get statusLabel => switch (status) {
    AcademicStatusType.active => 'Aktif',
    AcademicStatusType.leave => 'Cuti Akademik',
    AcademicStatusType.inactive => 'Non-Aktif',
    AcademicStatusType.transfer => 'Pindah Prodi',
    AcademicStatusType.resigned => 'Mengundurkan Diri',
    AcademicStatusType.graduated => 'Lulus / Yudisium',
  };
}

// ─────────────────────────── STATISTIK RINGKASAN ───────────────────────────

class BapDashboardStats {
  const BapDashboardStats({
    required this.totalCourses,
    required this.totalClasses,
    required this.totalActiveStudents,
    required this.pendingKrsOverride,
    required this.pendingMakeupClass,
    required this.pendingBapFill,
    required this.openExamSchedules,
    required this.upcomingDeadlines,
  });

  final int totalCourses;
  final int totalClasses;
  final int totalActiveStudents;
  final int pendingKrsOverride;
  final int pendingMakeupClass;
  final int pendingBapFill;
  final int openExamSchedules;
  final int upcomingDeadlines;
}
