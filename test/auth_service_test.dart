// Uji otomatis untuk aturan login dan sesi, tanpa membuka tampilan aplikasi.
// Tes adalah pemeriksa: siapkan kondisi, jalankan tindakan, lalu bandingkan hasil.
// expect memeriksa hasil langsung; expectLater menunggu hasil proses asynchronous.
// Jika kenyataan berbeda dari harapan, flutter test melaporkan tes gagal.

import 'package:flutter_test/flutter_test.dart';

import 'package:campus_app/data/auth_service.dart';

// Daftarkan skenario yang akan dijalankan oleh perintah flutter test.
void main() {
  // Skenario mencakup penolakan akun salah, penerimaan akun demo, dan logout.
  test('Akun salah ditolak dan sesi demo dapat dihapus', () async {
    // Buat layanan baru agar sesi dari pengujian lain tidak memengaruhi hasil.
    final service = AuthService();

    // Login dengan akun salah harus menghasilkan kesalahan, bukan profil mahasiswa.
    await expectLater(
      service.login(
        identity: 'salah',
        password: 'salah',
        rememberSession: false,
      ),
      // Pastikan jenis kegagalannya adalah AuthException yang dikenali aplikasi.
      throwsA(isA<AuthException>()),
    );

    // Pada titik ini tidak boleh ada sesi aktif: setelah login salah maupun setelah logout.
    expect(service.hasSession, isFalse);

    // Coba akun yang benar dan tunggu profilnya dikembalikan.
    final student = await service.login(
      identity: '20240801002',
      password: '123456',
      rememberSession: true,
    );

    // Pastikan layanan mengembalikan NIM yang digunakan saat masuk.
    expect(student.nim, '20240801002');
    // Login berhasil harus meninggalkan penanda sesi aktif.
    expect(service.hasSession, isTrue);

    // Jalankan aksi keluar seperti ketika pengguna menekan tombol Keluar.
    service.logout();

    // Pada titik ini tidak boleh ada sesi aktif: setelah login salah maupun setelah logout.
    expect(service.hasSession, isFalse);
  });
}
