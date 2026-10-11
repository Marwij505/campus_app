// Kumpulan cetakan data beranda dan fungsi perhitungan kecil yang dipakai bersama.
// List adalah daftar berurutan; Map memasangkan nama kategori dengan nilainya.
// Fungsi di bagian bawah memilih jadwal, menghitung kemajuan, dan merapikan tanggal.
// Data yang belum diketahui memakai null supaya berbeda dari nilai nol yang sah.

import 'student_profile.dart';

/// Jadwal memakai tanggal sungguhan, sehingga status kelas dapat dihitung.
// Satu jadwal kuliah lengkap dengan waktu dan lokasi.
class ClassSchedule {
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
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
  // Kode mata kuliah, nama mata kuliah, ruang, dan nama dosen dalam satu jadwal.
  final String code, title, room, lecturer;
  // Tanggal dan jam mulai/selesai dipakai untuk menentukan status kelas.
  final DateTime startsAt, endsAt;
  // Nomor pertemuan boleh tidak tersedia, misalnya pertemuan ke-4.
  final int? meeting;
  // Cara kuliah, misalnya daring atau tatap muka, jika disediakan sumber data.
  final String? method;
}

// Satu berita atau pengumuman yang bisa dibuka isinya.
class CampusNotice {
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
  const CampusNotice({
    required this.title,
    required this.publishedAt,
    required this.body,
  });
  // Judul singkat untuk daftar dan isi lengkap untuk halaman detail.
  final String title, body;
  // Waktu informasi diterbitkan, kemudian diformat saat ditampilkan.
  final DateTime publishedAt;
}

// Satu jadwal layanan konseling beserta status ketersediaannya.
class CounselingSession {
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
  const CounselingSession({
    required this.day,
    required this.counselor,
    required this.kind,
    required this.time,
    required this.method,
    required this.isOpen,
  });
  // Hari, petugas konseling, jenis layanan, jam, dan metode pertemuan.
  final String day, counselor, kind, time, method;
  // true berarti layanan ditandai buka; false berarti tutup.
  final bool isOpen;
}

/// Isi panduan boleh berupa teks. URL tidak dibuka otomatis oleh aplikasi ini.
// Satu pedoman atau panduan yang dibaca sebagai teks.
class CampusGuide {
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
  const CampusGuide({required this.title, required this.content});
  // Nama panduan dan teks isi yang dapat dibaca pada halaman detail.
  final String title, content;
}

/// Satu semester untuk grafik perjalanan, IPK, IPS dan SKS.
// Ringkasan hasil belajar pada satu semester.
class SemesterResult {
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
  const SemesterResult({
    required this.semester,
    this.gpa,
    this.ips,
    this.credits,
    this.cumulativeCredits,
  });
  // Nomor semester menjadi acuan urutan titik pada grafik.
  final int semester;
  // IPK adalah nilai kumulatif; IPS adalah nilai untuk semester tersebut.
  final double? gpa, ips;
  // SKS semester ini dan total SKS sampai semester ini adalah dua ukuran berbeda.
  final int? credits, cumulativeCredits;
}

/// Ringkasan dari backend. Tidak ada angka kelulusan atau predikat buatan UI.
// Angka acuan untuk membandingkan capaian belajar dengan targetnya.
class StudyProgress {
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
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
  // Semester saat ini/batas studi serta SKS lulus/syarat SKS kelulusan.
  final int? currentSemester, maxSemesters, passedCredits, requiredCredits;
  // Jumlah nilai A, mata kuliah yang dinilai, serta semester selesai dan yang direncanakan.
  final int? aGrades, gradedCourses, completedSemesters, plannedSemesters;
  final double? gpa;
  // Predikat berasal dari sumber data; UI tidak menebaknya dari IPK.
  final String? predicate;
}

/// Satu paket data beranda. Semua daftar kosong secara default.
/// Tidak ada contoh nama, nilai, dosen, berita, ataupun jumlah tagihan.
// Satu paket yang menampung semua bagian data beranda.
class DashboardData {
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
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
  // Profil dari repository, jika ada, dapat melengkapi profil awal dari login.
  final StudentProfile? student;
  // Ringkasan angka untuk kartu kemajuan belajar.
  final StudyProgress progress;
  // Seluruh jadwal tersedia; penyaringan jadwal hari ini dilakukan terpisah.
  final List<ClassSchedule> classes;
  // Pengumuman dan berita memakai bentuk data yang sama, tetapi daftar terpisah.
  final List<CampusNotice> announcements, news;
  // Daftar pilihan jadwal konseling.
  final List<CounselingSession> counseling;
  // Daftar dokumen panduan berbentuk teks.
  final List<CampusGuide> guides;
  // Riwayat nilai dan SKS per semester sebagai bahan grafik.
  final List<SemesterResult> semesters;
  // Jumlah mata kuliah per status dan per nilai huruf untuk grafik kategori.
  final Map<String, int> courseStatus, gradeComposition;
  // Jumlah tagihan belum dibayar; null berbeda dengan nol tagihan.
  final int? outstandingBillCount;
}

/// Penyaringan tanggal dipakai bersama oleh banner dan daftar jadwal.
// Bandingkan tahun, bulan, dan tanggal saja; jam tidak ikut dibandingkan.
bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

// Ambil jadwal pada tanggal lokal yang sama, lalu urutkan dari jam paling awal.
// toList membuat daftar baru; ..sort mengurutkannya tanpa mengubah daftar masukan.
List<ClassSchedule> todayClasses(List<ClassSchedule> classes, DateTime now) =>
    (classes
        .where((item) => sameDay(item.startsAt.toLocal(), now.toLocal()))
        .toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt)));

// Cari kelas yang sedang berjalan; jika tidak ada, ambil kelas berikutnya.
// Hasil null berarti semua kelas telah selesai atau daftar kosong.
ClassSchedule? activeOrNextClass(List<ClassSchedule> classes, DateTime now) {
  // Buang kelas yang sudah berakhir sebelum mencari calon kelas terdekat.
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
// Bagi nilai dengan target untuk panjang batang kemajuan. Tolak nilai tidak valid
// dan target nol/negatif; clamp membatasi hasil antara 0 (kosong) dan 1 (penuh).
double? safeRatio(num? value, num? target) =>
    value == null ||
        target == null ||
        !value.isFinite ||
        !target.isFinite ||
        target <= 0
    ? null
    : (value / target).clamp(0.0, 1.0).toDouble();

// Ubah tanggal menjadi tulisan Indonesia, misalnya Minggu, 11 Okt 2026.
// Daftar dimulai dari indeks 0, sedangkan nomor hari/bulan dimulai dari 1.
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

// Ubah waktu ke zona lokal perangkat, lalu tampilkan jam:menit dengan dua digit.
String campusTime(DateTime value) {
  final local = value.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}
