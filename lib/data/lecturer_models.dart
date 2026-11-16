// Model data khusus dashboard dosen: profil dosen, mata kuliah diampu,
// mahasiswa bimbingan akademik (PA), mahasiswa bimbingan tugas akhir (TA),
// serta jadwal bimbingan/sidang TA.

import 'dashboard_models.dart';
import 'student_profile.dart';

/// Identitas dan ringkasan beban akademik seorang dosen.
class LecturerProfile {
  const LecturerProfile({
    required this.code,
    required this.type,
    required this.name,
    required this.nidn,
    required this.faculty,
    required this.department,
    required this.academicRank,
    required this.status,
    required this.homebase,
  });

  final String code;
  final LecturerType type;
  final String name;
  final String nidn;
  final String faculty;
  final String department;
  final String academicRank;
  final String status;
  final String homebase;

  bool get isThesisAdvisor => type == LecturerType.academicAndThesis;

  String get roleLabel =>
      isThesisAdvisor ? 'Dosen Akademik + Pembimbing TA' : 'Dosen Akademik';
}

/// Ringkasan capaian & beban semester berjalan untuk panel statistik dosen.
class LecturerWorkload {
  const LecturerWorkload({
    this.totalCourses = 0,
    this.totalClasses = 0,
    this.totalCredits = 0,
    this.totalStudents = 0,
    this.completedMeetings = 0,
    this.targetMeetings = 0,
    this.gradedClasses = 0,
    this.paApproved = 0,
    this.paTotal = 0,
    this.attendanceRate = 0,
    this.thesisActive = 0,
    this.thesisCapacity = 0,
    this.thesisPendingReviews = 0,
    this.thesisReadyDefense = 0,
  });

  final int totalCourses;
  final int totalClasses;
  final int totalCredits;
  final int totalStudents;
  final int completedMeetings;
  final int targetMeetings;
  final int gradedClasses;
  final int paApproved;
  final int paTotal;
  final double attendanceRate;
  final int thesisActive;
  final int thesisCapacity;
  final int thesisPendingReviews;
  final int thesisReadyDefense;
}

/// Satu kelas mata kuliah yang diampu dosen pada semester berjalan.
class LecturerCourseClass {
  const LecturerCourseClass({
    required this.code,
    required this.title,
    required this.classCode,
    required this.credits,
    required this.studentCount,
    required this.scheduleText,
    required this.room,
    required this.method,
    required this.completedMeetings,
    required this.totalMeetings,
    required this.gradeSubmitted,
  });

  final String code;
  final String title;
  final String classCode;
  final int credits;
  final int studentCount;
  final String scheduleText;
  final String room;
  final String method;
  final int completedMeetings;
  final int totalMeetings;
  final bool gradeSubmitted;
}

/// Status persetujuan KRS mahasiswa bimbingan akademik (PA).
enum KrsApprovalStatus { approved, pending, revision }

/// Satu mahasiswa bimbingan akademik (PA).
class AcademicAdvisee {
  const AcademicAdvisee({
    required this.nim,
    required this.name,
    required this.semester,
    required this.gpa,
    required this.takenCredits,
    required this.krsStatus,
    required this.note,
  });

  final String nim;
  final String name;
  final int semester;
  final double gpa;
  final int takenCredits;
  final KrsApprovalStatus krsStatus;
  final String note;
}

/// Tahapan pengerjaan Tugas Akhir / Skripsi mahasiswa bimbingan.
enum ThesisStage { proposal, chapter1To3, research, finalDraft, readyDefense }

/// Satu mahasiswa bimbingan Tugas Akhir (khusus dosen pembimbing TA).
class ThesisAdvisee {
  const ThesisAdvisee({
    required this.nim,
    required this.name,
    required this.title,
    required this.roleInThesis,
    required this.stage,
    required this.progress,
    required this.lastGuidanceDate,
    required this.pendingAction,
  });

  final String nim;
  final String name;
  final String title;
  final String roleInThesis;
  final ThesisStage stage;
  final double progress;
  final String lastGuidanceDate;
  final String pendingAction;
}

/// Satu jadwal bimbingan, seminar proposal, atau sidang TA.
class ThesisScheduleItem {
  const ThesisScheduleItem({
    required this.studentName,
    required this.nim,
    required this.type,
    required this.topic,
    required this.dateLabel,
    required this.timeLabel,
    required this.location,
  });

  final String studentName;
  final String nim;
  final String type;
  final String topic;
  final String dateLabel;
  final String timeLabel;
  final String location;
}

/// Paket lengkap data dashboard dosen.
class LecturerDashboardData {
  const LecturerDashboardData({
    this.profile,
    this.workload = const LecturerWorkload(),
    this.schedules = const [],
    this.courses = const [],
    this.paAdvisees = const [],
    this.thesisAdvisees = const [],
    this.thesisSchedules = const [],
    this.announcements = const [],
    this.news = const [],
    this.guides = const [],
  });

  final LecturerProfile? profile;
  final LecturerWorkload workload;
  final List<ClassSchedule> schedules;
  final List<LecturerCourseClass> courses;
  final List<AcademicAdvisee> paAdvisees;
  final List<ThesisAdvisee> thesisAdvisees;
  final List<ThesisScheduleItem> thesisSchedules;
  final List<CampusNotice> announcements;
  final List<CampusNotice> news;
  final List<CampusGuide> guides;
}

