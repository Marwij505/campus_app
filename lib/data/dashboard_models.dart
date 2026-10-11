import 'student_profile.dart';

/// Jadwal memakai tanggal sungguhan, sehingga status kelas dapat dihitung.
class ClassSchedule {
  const ClassSchedule({
    required this.code,
    required this.title,
    required this.startsAt,
    required this.endsAt,
    required this.room,
    required this.lecturer,
    this.meeting,
    this.method,
  });
  final String code, title, room, lecturer;
  final DateTime startsAt, endsAt;
  final int? meeting;
  final String? method;
}

class CampusNotice {
  const CampusNotice({
    required this.title,
    required this.publishedAt,
    required this.body,
  });
  final String title, body;
  final DateTime publishedAt;
}

class CounselingSession {
  const CounselingSession({
    required this.day,
    required this.counselor,
    required this.kind,
    required this.time,
    required this.method,
    required this.isOpen,
  });
  final String day, counselor, kind, time, method;
  final bool isOpen;
}

/// Isi panduan boleh berupa teks. URL tidak dibuka otomatis oleh aplikasi ini.
class CampusGuide {
  const CampusGuide({required this.title, required this.content});
  final String title, content;
}

/// Satu semester untuk grafik perjalanan, IPK, IPS dan SKS.
class SemesterResult {
  const SemesterResult({
    required this.semester,
    this.gpa,
    this.ips,
    this.credits,
    this.cumulativeCredits,
  });
  final int semester;
  final double? gpa, ips;
  final int? credits, cumulativeCredits;
}

/// Ringkasan dari backend. Tidak ada angka kelulusan atau predikat buatan UI.
class StudyProgress {
  const StudyProgress({
    this.currentSemester,
    this.maxSemesters,
    this.passedCredits,
    this.requiredCredits,
    this.gpa,
    this.aGrades,
    this.gradedCourses,
    this.predicate,
    this.completedSemesters,
    this.plannedSemesters,
  });
  final int? currentSemester, maxSemesters, passedCredits, requiredCredits;
  final int? aGrades, gradedCourses, completedSemesters, plannedSemesters;
  final double? gpa;
  final String? predicate;
}

/// Satu paket data beranda. Semua daftar kosong secara default.
/// Tidak ada contoh nama, nilai, dosen, berita, ataupun jumlah tagihan.
class DashboardData {
  const DashboardData({
    this.student,
    this.progress = const StudyProgress(),
    this.classes = const [],
    this.announcements = const [],
    this.news = const [],
    this.counseling = const [],
    this.guides = const [],
    this.semesters = const [],
    this.courseStatus = const {},
    this.gradeComposition = const {},
    this.outstandingBillCount,
  });
  final StudentProfile? student;
  final StudyProgress progress;
  final List<ClassSchedule> classes;
  final List<CampusNotice> announcements, news;
  final List<CounselingSession> counseling;
  final List<CampusGuide> guides;
  final List<SemesterResult> semesters;
  final Map<String, int> courseStatus, gradeComposition;
  final int? outstandingBillCount;
}

/// Penyaringan tanggal dipakai bersama oleh banner dan daftar jadwal.
bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

List<ClassSchedule> todayClasses(List<ClassSchedule> classes, DateTime now) =>
    (classes
        .where((item) => sameDay(item.startsAt.toLocal(), now.toLocal()))
        .toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt)));

ClassSchedule? activeOrNextClass(List<ClassSchedule> classes, DateTime now) {
  final upcoming = classes.where((item) => item.endsAt.isAfter(now)).toList()
    ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
  // Dahulukan kelas yang sedang berlangsung bila jadwal saling tumpang tindih.
  for (final item in upcoming) {
    if (!item.startsAt.isAfter(now)) {
      return item;
    }
  }
  return upcoming.isEmpty ? null : upcoming.first;
}

/// Nilai tidak lengkap menghasilkan null, bukan progress bar palsu.
double? safeRatio(num? value, num? target) =>
    value == null ||
        target == null ||
        !value.isFinite ||
        !target.isFinite ||
        target <= 0
    ? null
    : (value / target).clamp(0.0, 1.0).toDouble();

String campusDate(DateTime date) {
  const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
}

String campusTime(DateTime value) {
  final local = value.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}
