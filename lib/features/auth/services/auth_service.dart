// Kontrak dan layanan autentikasi alternatif dari versi demo sebelumnya.
// Alur login saat ini mengimpor lib/data/auth_service.dart, bukan berkas ini.
// Di sini login hanya menyatakan selesai atau gagal dan tidak mengembalikan profil.
// Memahami perbedaan ini membantu saat memilih layanan yang akan dihubungkan ke API.

/// Halaman hanya mengenal kontrak ini. Saat backend siap, implementasinya
/// dapat diganti ke HTTP API tanpa mengganti desain halaman.
// Daftar kemampuan yang wajib disediakan layanan autentikasi alternatif.
abstract interface class AuthService {
  // Terima identitas, password, dan pilihan sesi; selesaikan proses atau lempar kesalahan.
  Future<void> login({
    required String identity,
    required String password,
    required bool rememberSession,
  });
  // Kontrak permintaan pemulihan; implementasi demo di bawah hanya menunggu.
  Future<void> requestPasswordReset(String email);
}

/// Kesalahan yang aman ditampilkan kepada pengguna.
// Kesalahan khusus yang membawa pesan gagal autentikasi.
class AuthException implements Exception {
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
  const AuthException(this.message);
  // Isi pesan kesalahan yang bisa dibaca pengguna.
  final String message;
}

/// IMPLEMENTASI DEMO, bukan autentikasi sungguhan atau koneksi MySQL.
/// Akun demo sama dengan kode login yang diunggah oleh pengguna.
// Pelaksana kontrak dengan pemeriksaan akun tetap di dalam memori.
class DemoAuthService implements AuthService {
  // Satu objek bersama yang bisa digunakan tanpa membuat layanan baru setiap kali.
  static final instance = DemoAuthService();
  // Identitas uji yang diterima implementasi alternatif ini.
  static const demoIdentity = '20240801001';
  // Password uji tetap untuk demonstrasi, bukan mekanisme penyimpanan akun produksi.
  static const demoPassword = '123456';

  // Sesi ini hanya berada di RAM: akan hilang saat proses aplikasi ditutup.
  // rememberSession menentukan masa sesi demo, bukan penyimpanan permanen.
  DateTime? _expiresAt;
  // Periksa apakah waktu kedaluwarsa masih di masa depan; tidak ada sesi berarti false.
  bool get hasSession => _expiresAt?.isAfter(DateTime.now()) ?? false;
  // Hapus penanda sesi dari memori.
  void logout() => _expiresAt = null;

  @override
  // Terima identitas, password, dan pilihan sesi; selesaikan proses atau lempar kesalahan.
  Future<void> login({
    required String identity,
    required String password,
    required bool rememberSession,
  }) async {
    // Tiru jeda respons layanan agar layar punya waktu menampilkan indikator tunggu.
    await Future<void>.delayed(const Duration(milliseconds: 850));
    // Tolak bila identitas atau password tidak sama dengan pasangan akun demo.
    if (identity != demoIdentity || password != demoPassword) {
      throw const AuthException('NIM / NIP atau password salah.');
    }
    // Tentukan masa sesi tujuh hari bila diingat, atau satu jam bila tidak.
    _expiresAt = DateTime.now().add(
      rememberSession ? const Duration(days: 7) : const Duration(hours: 1),
    );
  }

  @override
  // Kontrak permintaan pemulihan; implementasi demo di bawah hanya menunggu.
  Future<void> requestPasswordReset(String email) async {
    // Simulasi selesai tanpa mengirim email maupun mengubah password.
    // Backend kelak: token sekali pakai, kedaluwarsa, dan layanan email.
    // Tiru jeda respons layanan agar layar punya waktu menampilkan indikator tunggu.
    await Future<void>.delayed(const Duration(milliseconds: 850));
  }
}
