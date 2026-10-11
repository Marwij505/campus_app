// Pengujian aturan login dan sesi tanpa membuka tampilan.
//
// expect membandingkan hasil dengan harapan.
// expectLater menunggu hasil asynchronous sebelum membandingkannya.

import 'package:flutter_test/flutter_test.dart';

import 'package:campus_app/data/auth_service.dart';

void main() {
  test('Akun salah ditolak dan tidak membuat sesi', () async {
    // Gunakan layanan baru agar test tidak berbagi sesi.
    final service = AuthService();

    // Akun salah harus menghasilkan AuthException.
    await expectLater(
      service.login(identity: 'salah', password: 'salah'),
      throwsA(isA<AuthException>()),
    );

    // Kegagalan login tidak boleh membuat sesi aktif.
    expect(service.hasSession, isFalse);
    expect(service.remainingSession, Duration.zero);
  });

  test('Kedua akun demo dapat login', () async {
    // Jalankan pemeriksaan untuk masing-masing NIM demo.
    for (final nim in ['20240801001', '20240801002']) {
      final service = AuthService();

      final student = await service.login(identity: nim, password: '123456');

      // Profil harus berisi NIM yang dipakai saat login.
      expect(student.nim, nim);

      // Login berhasil membuat sesi aktif.
      expect(service.hasSession, isTrue);

      // Bersihkan sesi setelah pemeriksaan akun ini.
      service.logout();
    }
  });

  test('Logout menghapus sesi', () async {
    final service = AuthService();

    await service.login(identity: '20240801002', password: '123456');

    expect(service.hasSession, isTrue);

    // Meniru tindakan tombol Keluar.
    service.logout();

    // Setelah logout, tidak ada sesi atau waktu yang tersisa.
    expect(service.hasSession, isFalse);
    expect(service.remainingSession, Duration.zero);
  });

  test('Sesi berakhir tepat setelah 30 menit', () async {
    // Waktu buatan yang dapat dimajukan oleh test.
    var currentTime = DateTime.utc(2026, 10, 11, 8);

    // Layanan membaca currentTime setiap kali memeriksa waktu.
    final service = AuthService(now: () => currentTime);

    await service.login(identity: '20240801001', password: '123456');

    // Pada awal sesi, waktunya tepat 30 menit.
    expect(service.remainingSession, const Duration(minutes: 30));

    // Majukan waktu hingga satu detik sebelum kedaluwarsa.
    currentTime = currentTime.add(const Duration(minutes: 29, seconds: 59));

    expect(service.hasSession, isTrue);
    expect(service.remainingSession, const Duration(seconds: 1));

    // Majukan satu detik lagi: tepat mencapai batas 30 menit.
    currentTime = currentTime.add(const Duration(seconds: 1));

    expect(service.hasSession, isFalse);
    expect(service.remainingSession, Duration.zero);

    // Setelah lewat batas, durasi tetap nol, bukan negatif.
    currentTime = currentTime.add(const Duration(minutes: 5));

    expect(service.hasSession, isFalse);
    expect(service.remainingSession, Duration.zero);
  });
}
