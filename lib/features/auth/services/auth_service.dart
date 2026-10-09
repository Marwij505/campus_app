/// Halaman hanya mengenal kontrak ini. Saat backend siap, implementasinya
/// dapat diganti ke HTTP API tanpa mengganti desain halaman.
abstract interface class AuthService {
  Future<void> login({
    required String identity,
    required String password,
    required bool rememberSession,
  });
  Future<void> requestPasswordReset(String email);
}

/// Kesalahan yang aman ditampilkan kepada pengguna.
class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
}

/// IMPLEMENTASI DEMO, bukan autentikasi sungguhan atau koneksi MySQL.
/// Akun demo sama dengan kode login yang diunggah oleh pengguna.
class DemoAuthService implements AuthService {
  static final instance = DemoAuthService();
  static const demoIdentity = '20240801001';
  static const demoPassword = '123456';

  // Sesi ini hanya berada di RAM: akan hilang saat proses aplikasi ditutup.
  // rememberSession menentukan masa sesi demo, bukan penyimpanan permanen.
  DateTime? _expiresAt;
  bool get hasSession => _expiresAt?.isAfter(DateTime.now()) ?? false;
  void logout() => _expiresAt = null;

  @override
  Future<void> login({
    required String identity,
    required String password,
    required bool rememberSession,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 850));
    if (identity != demoIdentity || password != demoPassword) {
      throw const AuthException('NIM / NIP atau password salah.');
    }
    _expiresAt = DateTime.now().add(
      rememberSession ? const Duration(days: 7) : const Duration(hours: 1),
    );
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    // Simulasi selesai tanpa mengirim email maupun mengubah password.
    // Backend kelak: token sekali pakai, kedaluwarsa, dan layanan email.
    await Future<void>.delayed(const Duration(milliseconds: 850));
  }
}
