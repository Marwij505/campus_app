// Uji alur pengguna dari login sampai pemulihan akun serta kenyamanan layout form.
// Tes membuka aplikasi sungguhan dalam lingkungan simulasi tanpa perangkat fisik.
// find mencari komponen; tester meniru mengetik/mengetuk; expect memeriksa hasil.
// Waktu simulasi dimajukan dengan pump agar jeda layanan demo dan animasi dapat selesai.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_app/main.dart';
import 'package:campus_app/shared/pixel_widgets.dart';

// Daftarkan persiapan font dan semua skenario form autentikasi.
void main() {
  // Siapkan penghubung Flutter khusus tes sebelum font dan tampilan digunakan.
  TestWidgetsFlutterBinding.ensureInitialized();

  // Gunakan font produksi, bukan font Ahem bawaan test, agar ukuran teks realistis.
  // Muat font sekali untuk semua skenario agar pengukuran tulisan menyerupai aplikasi.
  setUpAll(() async {
    final pixel = FontLoader('PressStart2P')
      ..addFont(rootBundle.load('assets/fonts/PressStart2P-Regular.ttf'));
    final mono = FontLoader('SpaceMono')
      ..addFont(rootBundle.load('assets/fonts/SpaceMono-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/SpaceMono-Bold.ttf'));
    // Tunggu font siap sebelum tes pertama mulai menggambar.
    await pixel.load();
    await mono.load();
  });

  // Skenario perjalanan lengkap: salah password, masuk, keluar, lalu mencoba reset email.
  testWidgets('Login gagal, login berhasil, logout, dan pemulihan demo', (
    tester,
  ) async {
    // Samakan ukuran layar simulasi dengan satuan layout agar dimensi tes mudah dipahami.
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);

    // Kembalikan pengaturan layar setelah tes supaya tidak memengaruhi skenario berikutnya.
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    // Buka akar aplikasi seperti pengguna baru menjalankannya.
    await tester.pumpWidget(const CampusApp());
    await tester.pumpAndSettle();

    // Pembantu untuk mencari tombol berdasarkan label, menggulir ke sana, lalu menekannya.
    Future<void> submit(String label) async {
      final button = find.widgetWithText(PixelButton, label);

      // Pastikan tombol terlihat sebelum diketuk, sama seperti pengguna perlu menggulir form.
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();

      // Majukan waktu simulasi server, lalu selesaikan animasi.
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
    }

    // Isi kolom pertama (identitas) dengan akun demo yang diterima layanan.
    await tester.enterText(find.byType(TextFormField).at(0), '20240801002');
    // Sengaja masukkan password salah untuk memastikan pesan gagal benar-benar muncul.
    await tester.enterText(find.byType(TextFormField).at(1), 'salah');

    await submit('MASUK');

    expect(find.text('NIM / NIP atau password salah.'), findsOneWidget);

    // Perbaiki password lalu pastikan layar berpindah ke beranda dengan NIM yang sesuai.
    await tester.enterText(find.byType(TextFormField).at(1), '123456');

    await submit('MASUK');

    expect(find.text('Profil mahasiswa'), findsOneWidget);
    expect(find.text('NIM: 20240801002'), findsOneWidget);
    expect(find.text('AKSES CEPAT'), findsOneWidget);

    // Cari tombol dari keterangan bantuannya, lalu uji alur logout.
    await tester.tap(find.byTooltip('Keluar'));
    await tester.pumpAndSettle();

    expect(find.text('SIAKAD.EXE'), findsOneWidget);

    // Buka form pemulihan melalui tautan yang juga dipakai pengguna.
    await tester.ensureVisible(find.text('Lupa password?'));
    await tester.tap(find.text('Lupa password?'));
    await tester.pumpAndSettle();

    // Contoh bentuk alamat yang salah harus ditolak sebelum layanan reset dipanggil.
    await tester.enterText(find.byType(TextFormField), 'bukan-email');
    await submit('KIRIM LINK RESET');

    expect(find.text('Alamat email belum valid.'), findsOneWidget);

    // Alamat berbentuk valid boleh menyelesaikan simulasi, tanpa klaim email sudah terkirim.
    await tester.enterText(find.byType(TextFormField), 'demo@example.com');
    await submit('KIRIM LINK RESET');

    // Pastikan pemberitahuan menjelaskan batas simulasi dengan jujur.
    expect(find.textContaining('Email belum dikirim'), findsOneWidget);

    // Selain teks yang benar, pastikan tidak ada kesalahan layout atau Flutter selama proses.
    expect(tester.takeException(), isNull);
  });

  // Uji layout pada ponsel kecil, ukuran referensi, dan layar lebih lebar.
  // Jangan menghapus exception: overflow merupakan kegagalan UI yang perlu diperbaiki.
  // Ulangi buka login dan pemulihan pada tiga ukuran layar untuk mencari overflow.
  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(600, 900),
  ]) {
    // Buka kedua halaman lalu kembali; semuanya harus muat pada ukuran yang sedang diuji.
    testWidgets('Login dan reset tidak overflow pada $size', (tester) async {
      // Samakan ukuran layar simulasi dengan satuan layout agar dimensi tes mudah dipahami.
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      // Kembalikan pengaturan layar setelah tes supaya tidak memengaruhi skenario berikutnya.
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      // Buka akar aplikasi seperti pengguna baru menjalankannya.
      await tester.pumpWidget(const CampusApp());
      await tester.pumpAndSettle();
      // Selain teks yang benar, pastikan tidak ada kesalahan layout atau Flutter selama proses.
      expect(tester.takeException(), isNull);
      final forgot = find.text('Lupa password?');
      await tester.ensureVisible(forgot);
      await tester.tap(forgot);
      await tester.pumpAndSettle();
      expect(find.text('RESET_PASSWORD.EXE'), findsOneWidget);
      // Selain teks yang benar, pastikan tidak ada kesalahan layout atau Flutter selama proses.
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Kembali ke login'));
      await tester.tap(find.text('Kembali ke login'));
      await tester.pumpAndSettle();
      expect(find.text('SIAKAD.EXE'), findsOneWidget);
      // Selain teks yang benar, pastikan tidak ada kesalahan layout atau Flutter selama proses.
      expect(tester.takeException(), isNull);
    });
  }

  // Periksa form tetap bisa digulir dan divalidasi ketika sebagian layar tertutup keyboard.
  testWidgets('Keyboard terbuka: form tetap dapat digulir', (tester) async {
    // Samakan ukuran layar simulasi dengan satuan layout agar dimensi tes mudah dipahami.
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    // Simulasikan keyboard yang mengambil ruang setinggi 300 di bagian bawah layar.
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    // Kembalikan pengaturan layar setelah tes supaya tidak memengaruhi skenario berikutnya.
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetViewInsets);
    // Buka akar aplikasi seperti pengguna baru menjalankannya.
    await tester.pumpWidget(const CampusApp());
    await tester.pumpAndSettle();
    final button = find.widgetWithText(PixelButton, 'MASUK');
    // Pastikan tombol terlihat sebelum diketuk, sama seperti pengguna perlu menggulir form.
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    // Menekan MASUK pada form kosong harus menghasilkan pesan wajib isi yang terlihat.
    expect(find.text('NIM / NIP wajib diisi.'), findsOneWidget);
    // Selain teks yang benar, pastikan tidak ada kesalahan layout atau Flutter selama proses.
    expect(tester.takeException(), isNull);
  });
}
