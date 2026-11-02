// Cetakan data identitas mahasiswa yang dipakai alur aplikasi saat ini.
// Objek ini menyimpan data, bukan menggambar tampilan atau mengambil data server.
// final berarti kolom tidak dapat diisi ulang setelah objek dibuat; tanda ?
// berarti informasi tersebut boleh belum tersedia.

// Data identitas mahasiswa. null berarti server belum menyediakan nilainya.
// Jangan isi angka 0 untuk menggantikan IPK yang belum diketahui.
// Satu objek mewakili identitas dan ringkasan nilai seorang mahasiswa.
import 'dart:typed_data';

enum UserRole { student, bap, lecturer }

class StudentProfile {
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
  const StudentProfile({
    required this.nim,
    this.role = UserRole.student,
    this.name,
    this.faculty,
    this.major,
    this.status,
    this.entryYear,
    this.semester,
    this.advisor,
    this.gpa,
    this.latestGpa,
    this.passedCredits,
    this.id,
    this.preferredName,
    this.university,
    this.email,
    this.campusEmail,
    this.advisorCode,
    this.enrollmentPeriod,
    this.studyBasis,
    this.admissionWave,
    this.admissionStatus,
    this.phone,
    this.campus,
    this.avatarPath,
    this.avatarBytes,
    this.updatedAt,
    this.avatarVariant = 'neutral',
    this.verificationStatus = 'unverified',
  });

  // NIM berasal dari baris students milik akun; bukan tebakan dari input login.
  final String nim;
  // Peran resmi ditentukan server; peran staf juga dipakai tes alur izin lokal.
  final UserRole role;
  // Nama, fakultas, program studi, status mahasiswa, dan dosen pembimbing akademik.
  final String? name, faculty, major, status, advisor;
  // Tahun masuk, semester saat ini, dan jumlah SKS yang sudah lulus.
  final int? entryYear, semester, passedCredits;
  // IPK kumulatif dan IPS terakhir dapat memiliki angka di belakang koma.
  final double? gpa, latestGpa;
  // UUID menghubungkan akun Auth; NIM tetap nomor akademik, bukan rahasia.
  final String? id, preferredName, university, email, phone, campus, avatarPath;
  // Email kampus adalah informasi akademik; email Auth tetap dipakai pemulihan.
  final String? campusEmail,
      advisorCode,
      enrollmentPeriod,
      studyBasis,
      admissionWave,
      admissionStatus;
  final String avatarVariant, verificationStatus;
  final DateTime? updatedAt;
  // Foto privat hanya berada di memori sesi, bukan URL publik atau cache disk.
  final Uint8List? avatarBytes;
  String get greetingName => preferredName ?? name ?? 'Mahasiswa';

  /// Gabungkan dua baris yang kepemilikannya telah diperiksa database.
  factory StudentProfile.fromRows(
    Map<String, dynamic> p,
    Map<String, dynamic> s, {
    String? email,
    Uint8List? avatarBytes,
  }) {
    if (p['id'] != s['user_id'] ||
        p['role'] != 'student' ||
        p['is_enabled'] != true) {
      throw const FormatException('Profil akun tidak sesuai.');
    }
    final variant = p['avatar_variant'];
    return StudentProfile(
      id: p['id'] as String,
      nim: s['nim'] as String,
      name: p['full_name'] as String,
      preferredName: p['preferred_name'] as String?,
      email: email,
      campusEmail: s['campus_email'] as String?,
      advisor: s['advisor_name'] as String?,
      advisorCode: s['advisor_code'] as String?,
      enrollmentPeriod: s['enrollment_period'] as String?,
      studyBasis: s['study_basis'] as String?,
      admissionWave: s['admission_wave'] as String?,
      admissionStatus: s['admission_status'] as String?,
      phone: p['phone'] as String?,
      university: s['university'] as String?,
      faculty: s['faculty'] as String?,
      major: s['program'] as String?,
      campus: s['campus'] as String?,
      entryYear: s['entry_year'] as int?,
      semester: s['current_semester'] as int?,
      status: s['academic_status'] as String?,
      avatarPath: p['avatar_path'] as String?,
      avatarBytes: avatarBytes,
      avatarVariant: ['male', 'female', 'neutral'].contains(variant)
          ? variant as String
          : 'neutral',
      verificationStatus: p['verification_status'] as String,
      updatedAt: DateTime.tryParse(p['updated_at'] as String? ?? ''),
    );
  }
}
