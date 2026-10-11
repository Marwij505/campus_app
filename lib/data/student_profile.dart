/// Data identitas mahasiswa. null berarti server belum menyediakan nilainya.
/// Jangan isi angka 0 untuk menggantikan IPK yang belum diketahui.
class StudentProfile {
  const StudentProfile({
    required this.nim,
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
  });

  // Saat demo, hanya NIM yang berasal dari form login.
  final String nim;
  final String? name, faculty, major, status, advisor;
  final int? entryYear, semester, passedCredits;
  final double? gpa, latestGpa;
}
