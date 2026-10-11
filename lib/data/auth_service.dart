import 'student_profile.dart';

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;
}

/// Memisahkan proses autentikasi dari tampilan.
///
/// Ini masih layanan demo.
/// Nantinya proses di sini diganti pemanggilan HTTPS API ke backend.
class AuthService {
  DateTime? _expiresAt;

  bool get hasSession => _expiresAt?.isAfter(DateTime.now()) ?? false;

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

    if (!validIdentity || password != '123456') {
      throw const AuthException('NIM / NIP atau password salah.');
    }

    // Sesi hanya berada di RAM.
    // Belum tersimpan permanen ketika proses aplikasi ditutup.
    _expiresAt = DateTime.now().add(
      rememberSession ? const Duration(days: 7) : const Duration(hours: 1),
    );

    return StudentProfile(nim: identity);
  }

  Future<void> requestReset(String email) async {
    // Simulasi saja:
    // tidak mengirim email dan tidak mengubah password.
    await Future<void>.delayed(const Duration(milliseconds: 800));
  }

  void logout() {
    _expiresAt = null;
  }
}
