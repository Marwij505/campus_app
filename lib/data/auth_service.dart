// Layanan login yang saat ini dipakai aplikasi utama.
// Tugasnya memeriksa akun demo, membuat penanda sesi di memori, dan logout.
// Future berarti hasil baru tersedia nanti; async/await membuat proses tunggu
// tidak menghentikan tampilan aplikasi.

import 'student_profile.dart';

// Bentuk khusus kesalahan login yang membawa pesan untuk pengguna.
class AuthException implements Exception {
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
  const AuthException(this.message);

  // Pesan kesalahan yang boleh ditampilkan pada form login.
  final String message;
}

/// Memisahkan proses autentikasi dari tampilan.
///
/// Ini masih layanan demo.
/// Nantinya proses di sini diganti pemanggilan HTTPS API ke backend.
// Memisahkan pemeriksaan akun dari kode yang menggambar layar login.
class AuthService {
  // Batas waktu sesi; null berarti belum ada sesi atau pengguna sudah keluar.
  DateTime? _expiresAt;

  // Periksa apakah batas sesi masih di masa depan. ?? false dipakai saat sesi belum ada.
  // Ini hanya pemeriksaan saat dibaca, bukan pengatur logout otomatis.
  bool get hasSession => _expiresAt?.isAfter(DateTime.now()) ?? false;

  // Masukan: NIM/NIP, password, dan pilihan ingat sesi.
  // Keluaran: profil berisi NIM jika benar; lempar AuthException jika salah.
  Future<StudentProfile> login({
    required String identity,
    required String password,
    required bool rememberSession,
  }) async {
    // Meniru waktu tunggu server supaya indikator loading dapat diuji.
    await Future<void>.delayed(const Duration(milliseconds: 800));

    // Dua akun uji tetap tersedia untuk membuka UI.
    // Tidak ada profil mahasiswa nyata pada autentikasi simulasi ini.
    final validIdentity = ['20240801001', '20240801002'].contains(identity);

    // Salah satu syarat gagal sudah cukup untuk menolak login.
    if (!validIdentity || password != '123456') {
      throw const AuthException('NIM / NIP atau password salah.');
    }

    // Sesi hanya berada di RAM.
    // Belum tersimpan permanen ketika proses aplikasi ditutup.
    _expiresAt = DateTime.now().add(
      rememberSession ? const Duration(days: 7) : const Duration(hours: 1),
    );

    // Kembalikan identitas yang diketahui saja; data akademik belum tersedia di layanan ini.
    return StudentProfile(nim: identity);
  }

  // Menerima email untuk simulasi permintaan reset; void berarti tanpa nilai hasil.
  Future<void> requestReset(String email) async {
    // Simulasi saja:
    // tidak mengirim email dan tidak mengubah password.
    await Future<void>.delayed(const Duration(milliseconds: 800));
  }

  // Mengosongkan batas sesi agar hasSession kembali bernilai false.
  void logout() {
    _expiresAt = null;
  }
}
