// Cetakan data identitas mahasiswa yang dipakai alur aplikasi saat ini.
// Objek ini menyimpan data, bukan menggambar tampilan atau mengambil data server.
// final berarti kolom tidak dapat diisi ulang setelah objek dibuat; tanda ?
// berarti informasi tersebut boleh belum tersedia.

/// Data identitas mahasiswa. null berarti server belum menyediakan nilainya.
/// Jangan isi angka 0 untuk menggantikan IPK yang belum diketahui.
// Satu objek mewakili identitas dan ringkasan nilai seorang mahasiswa.
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
  });

  // Saat demo, hanya NIM yang berasal dari form login.
  // NIM wajib ada karena menjadi identitas akun untuk permintaan data beranda.
  final String nim;
  // Identitas login tetap stabil; untuk staf nilainya berupa kode akun demo.
  final UserRole role;
  // Nama, fakultas, program studi, status mahasiswa, dan dosen pembimbing akademik.
  final String? name, faculty, major, status, advisor;
  // Tahun masuk, semester saat ini, dan jumlah SKS yang sudah lulus.
  final int? entryYear, semester, passedCredits;
  // IPK kumulatif dan IPS terakhir dapat memiliki angka di belakang koma.
  final double? gpa, latestGpa;
}
