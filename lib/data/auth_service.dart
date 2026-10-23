// Mengurus pemeriksaan akun, batas sesi, dan logout.
//
// Saat ini akun masih demo dan sesi hanya berada di memori.
// Belum terhubung ke backend atau database.
// Ketika proses aplikasi ditutup, sesi ikut hilang.

import 'student_profile.dart';

/// Kesalahan login yang pesannya boleh ditampilkan kepada pengguna.
class AuthException implements Exception {
  // Simpan pesan ketika objek kesalahan dibuat.
  const AuthException(this.message);

  // final berarti pesan tidak dapat diganti setelah objek dibuat.
  final String message;
}

/// Memisahkan pemeriksaan akun dari kode tampilan login.
class AuthService {
  // Secara normal menggunakan waktu perangkat.
  // Saat test, fungsi waktu dapat diganti agar tidak menunggu 30 menit.
  AuthService({DateTime Function()? now}) : _now = now ?? DateTime.now;

  // Menyimpan fungsi pembaca waktu, bukan satu nilai waktu tetap.
  final DateTime Function() _now;

  // Semua login berhasil mendapatkan durasi yang sama.
  // static const berarti pengaturan tetap milik class ini.
  static const sessionDuration = Duration(minutes: 30);

  // Waktu kedaluwarsa sesi.
  // null berarti belum login atau sudah logout.
  DateTime? _expiresAt;
  StudentProfile? _user;
  StudentProfile? get currentUser => hasSession ? _user : null;

  /// Memeriksa apakah sesi belum mencapai waktu kedaluwarsa.
  bool get hasSession {
    // Salin nilai agar dapat diperiksa dengan aman.
    final expiresAt = _expiresAt;

    // Sesi valid hanya jika ada dan waktunya belum habis.
    // Tepat pada waktu kedaluwarsa, hasilnya sudah false.
    return expiresAt != null && _now().isBefore(expiresAt);
  }

  /// Memberikan sisa durasi untuk timer logout di main.dart.
  Duration get remainingSession {
    final expiresAt = _expiresAt;

    // Tanpa sesi, tidak ada waktu yang tersisa.
    if (expiresAt == null) return Duration.zero;

    // Hitung selisih waktu kedaluwarsa dengan waktu sekarang.
    final remaining = expiresAt.difference(_now());

    // Jangan mengembalikan durasi negatif setelah sesi habis.
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Memeriksa akun dan mengembalikan profil jika berhasil.
  ///
  /// Tidak ada lagi parameter rememberSession.
  Future<StudentProfile> login({
    // Identitas wajib diberikan oleh halaman login.
    required String identity,

    // Password wajib diberikan oleh halaman login.
    required String password,
  }) async {
    // Simulasi waktu tunggu server agar loading bisa diuji.
    // await menunggu tanpa menghentikan tampilan aplikasi.
    await Future<void>.delayed(const Duration(milliseconds: 800));

    // Akun mahasiswa, pemeriksa BAP, dan dosen khusus simulasi lokal.
    final validIdentity = [
      '20240801001',
      '20240801002',
      'BAP001',
      'DOS001',
      'DOS002',
    ].contains(identity);

    // Identitas atau password salah sudah cukup untuk menolak login.
    if (!validIdentity || password != '123456') {
      throw const AuthException('NIM / NIP atau password salah.');
    }

    // Mulai sesi 30 menit dari waktu login berhasil.
    // Aktivitas pengguna tidak memperpanjang batas ini.
    _expiresAt = _now().add(sessionDuration);

    // Hanya NIM yang diketahui; data akademik tetap kosong.
    _user = StudentProfile(
      nim: identity,
      role: switch (identity) {
        'BAP001' => UserRole.bap,
        'DOS001' || 'DOS002' => UserRole.lecturer,
        _ => UserRole.student,
      },
    );
    return _user!;
  }

  /// Simulasi permintaan pemulihan password.
  Future<void> requestReset(String email) async {
    // Belum mengirim email atau mengganti password.
    await Future<void>.delayed(const Duration(milliseconds: 800));
  }

  /// Menghapus sesi ketika pengguna keluar.
  void logout() {
    // Setelah dikosongkan, hasSession menghasilkan false.
    _expiresAt = null;
    _user = null;
  }
}
