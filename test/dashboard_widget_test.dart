// Uji otomatis tampilan dan interaksi beranda pada berbagai ukuran layar.
// WidgetTester bertindak seperti pengguna: membuka halaman, mengetuk, dan menunggu.
// pumpWidget memasang tampilan; pumpAndSettle menyelesaikan pembaruan/animasi;
// find mencari elemen; expect memastikan hasil sesuai; addTearDown membersihkan kondisi uji.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_app/core/app_theme.dart';
import 'package:campus_app/data/dashboard_models.dart';
import 'package:campus_app/data/dashboard_repository.dart';
import 'package:campus_app/data/student_profile.dart';
import 'package:campus_app/features/dashboard/dashboard_page.dart';
import 'package:campus_app/features/dashboard/profile_panel.dart';

// Daftarkan persiapan bersama, pembantu, dan seluruh skenario pengujian beranda.
void main() {
  // Siapkan lingkungan Flutter khusus pengujian sebelum membaca aset dan membangun layar.
  TestWidgetsFlutterBinding.ensureInitialized();
  // Jalankan sekali sebelum semua tes untuk memuat font yang sama dengan aplikasi.
  setUpAll(() async {
    // Font asli mencegah ukuran Ahem menyamarkan masalah layout.
    final pixel = FontLoader('PressStart2P')
      ..addFont(rootBundle.load('assets/fonts/PressStart2P-Regular.ttf'));
    final mono = FontLoader('SpaceMono')
      ..addFont(rootBundle.load('assets/fonts/SpaceMono-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/SpaceMono-Bold.ttf'));
    // Tunggu kedua jenis font selesai dimuat sebelum mengukur tampilan dalam tes.
    await pixel.load();
    await mono.load();
  });

  // Pembuat aplikasi uji: sumber data dan ukuran tulisan dapat diganti per skenario.
  Widget app({
    DashboardRepository repository = const EmptyDashboardRepository(),
    double scale = 1,
  }) => MaterialApp(
    theme: AppTheme.data,
    // Sisipkan pengaturan ukuran teks khusus untuk menguji aksesibilitas.
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: DashboardPage(
      student: const StudentProfile(nim: 'akun-uji'),
      onLogout: () {},
      repository: repository,
      // Jam uji dibuat tetap supaya tanggal/status tidak berubah mengikuti waktu sebenarnya.
      clock: () => DateTime(2026, 10, 11, 10),
    ),
  );

  // Atur ukuran layar simulasi lalu daftarkan pemulihannya setelah tes berakhir.
  void viewport(WidgetTester tester, Size size) {
    // Dengan rasio 1, ukuran layar uji sama dengan satuan layout yang kita tentukan.
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
  }

  // Jalankan skenario kosong yang sama pada HP kecil, tablet, hingga monitor lebar.
  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(600, 900),
    const Size(768, 1024),
    const Size(820, 1180),
    const Size(900, 600),
    const Size(1024, 768),
    const Size(1099, 800),
    const Size(1280, 800),
    const Size(1920, 1080),
  ]) {
    // Pastikan pesan kosong, jenis navigasi, dan layout sesuai ukuran layar.
    testWidgets('Beranda kosong tanpa overflow pada $size', (tester) async {
      viewport(tester, size);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.text('AKSES CEPAT'), findsOneWidget);
      expect(find.text('Belum ada jadwal kuliah hari ini'), findsOneWidget);
      expect(find.text('Belum ada jadwal konseling'), findsOneWidget);
      expect(find.text('Belum ada pengumuman'), findsOneWidget);
      expect(find.text('Belum ada berita'), findsOneWidget);
      // Ada enam tempat grafik; semuanya harus menjelaskan bahwa data belum tersedia.
      expect(find.text('Grafik belum tersedia'), findsNWidgets(6));
      expect(
        // Kunci widget mengenali navigasi HP tanpa bergantung pada tulisan menu.
        find.byKey(const ValueKey('phone-navigation')),
        size.width < 600 ? findsOneWidget : findsNothing,
      );
      expect(
        // Jalur kiri sudah dihapus, termasuk pada tablet portrait dan landscape.
        find.byKey(const ValueKey('tablet-navigation')),
        findsNothing,
      );
      if (size.width >= 600 && size.width < 1100) {
        // Ukur kartu sebenarnya: tidak boleh tersisa ruang bekas menu kiri.
        final profile = tester.getRect(find.byType(ProfilePanel));
        expect(profile.left, lessThanOrEqualTo(24));
        expect(size.width - profile.right, closeTo(profile.left, .1));
        expect(profile.width, greaterThanOrEqualTo(size.width - 48));
        expect(find.byTooltip('Buka menu'), findsOneWidget);
        if (size.width >= 768) {
          expect(find.byKey(const ValueKey('tablet-panels')), findsOneWidget);
        }
      }
      if (size.width >= 1280) {
        expect(find.byKey(const ValueKey('desktop-panels')), findsOneWidget);
      }
      // Pastikan Flutter tidak melaporkan kesalahan tampilan, termasuk isi yang meluber (overflow).
      expect(tester.takeException(), isNull);
      // Lepas halaman agar timer menit dan controller dibersihkan.
      // Ganti halaman dengan kotak kosong agar dispose membatalkan timer dan melepas controller.
      await tester.pumpWidget(const SizedBox());
    });
  }

  // Perbesar tulisan menjadi dua kali lipat di HP kecil untuk mencari masalah keterbacaan.
  testWidgets('HP dengan ukuran teks 200 persen tetap dapat dibaca', (
    tester,
  ) async {
    viewport(tester, const Size(320, 700));
    await tester.pumpWidget(app(scale: 2));
    await tester.pumpAndSettle();
    // Pastikan Flutter tidak melaporkan kesalahan tampilan, termasuk isi yang meluber (overflow).
    expect(tester.takeException(), isNull);
    // Ganti halaman dengan kotak kosong agar dispose membatalkan timer dan melepas controller.
    await tester.pumpWidget(const SizedBox());
  });

  // Ubah ukuran saat halaman masih terbuka; identitas harus tetap ada setelah layout berganti.
  testWidgets('Resize desktop menjadi HP mempertahankan data', (tester) async {
    viewport(tester, const Size(1280, 800));
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('desktop-panels')), findsOneWidget);
    // Simulasikan jendela yang diperkecil tanpa membuat ulang seluruh aplikasi.
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('phone-navigation')), findsOneWidget);
    expect(find.text('NIM: akun-uji'), findsOneWidget);
    // Pastikan Flutter tidak melaporkan kesalahan tampilan, termasuk isi yang meluber (overflow).
    expect(tester.takeException(), isNull);
    // Ganti halaman dengan kotak kosong agar dispose membatalkan timer dan melepas controller.
    await tester.pumpWidget(const SizedBox());
  });

  // Rotasi dan pembesaran teks harus tetap menjaga identitas dan akses navigasi.
  testWidgets(
    'Tablet tanpa sidebar: rotasi, teks besar, dan menu tetap bekerja',
    (tester) async {
      viewport(tester, const Size(768, 1024));
      await tester.pumpWidget(app(repository: _ProfileRepository()));
      await tester.pumpAndSettle();
      for (final size in [const Size(1024, 768), const Size(820, 1180)]) {
        tester.view.physicalSize = size;
        await tester.pumpAndSettle();
        expect(find.text('Mahasiswa Uji Tampilan Tablet'), findsOneWidget);
        expect(
          tester.getRect(find.byType(ProfilePanel)).left,
          lessThanOrEqualTo(24),
        );
        expect(find.byKey(const ValueKey('tablet-navigation')), findsNothing);
        expect(find.byKey(const ValueKey('phone-navigation')), findsNothing);
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(app(repository: _ProfileRepository(), scale: 2));
      await tester.pumpAndSettle();
      expect(find.text('Mahasiswa Uji Tampilan Tablet'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Buka menu'));
      await tester.pumpAndSettle();
      final academic = find.descendant(
        of: find.byType(Drawer),
        matching: find.text('Akademik'),
      );
      await tester.ensureVisible(academic);
      await tester.pumpAndSettle();
      await tester.tap(academic);
      await tester.pumpAndSettle();
      final schedule = find.text('Jadwal Perkuliahan');
      await tester.ensureVisible(schedule);
      await tester.pumpAndSettle();
      await tester.tap(schedule);
      await tester.pumpAndSettle();
      expect(find.text('Belum ada jadwal kuliah'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Mahasiswa Uji Tampilan Tablet'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    // Bedakan tampilan kegagalan dengan data kosong, lalu coba memuat ulang sampai berhasil.
    'Gagal memuat bisa dicoba ulang, tanpa menyamar sebagai data kosong',
    (tester) async {
      viewport(tester, const Size(390, 844));
      // Gunakan sumber khusus yang sengaja gagal pada panggilan pertama.
      await tester.pumpWidget(app(repository: _RetryRepository()));
      await tester.pumpAndSettle();
      expect(
        find.text('Data beranda gagal dimuat. Silakan coba lagi.'),
        findsOneWidget,
      );
      expect(find.text('Belum ada jadwal kuliah hari ini'), findsNothing);
      // Gulir tombol ke area terlihat sebelum mensimulasikan ketukan pengguna.
      await tester.ensureVisible(find.text('Coba lagi'));
      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();
      expect(
        find.text('Data beranda gagal dimuat. Silakan coba lagi.'),
        findsNothing,
      );
      expect(find.text('Belum ada jadwal kuliah hari ini'), findsOneWidget);
      // Pastikan Flutter tidak melaporkan kesalahan tampilan, termasuk isi yang meluber (overflow).
      expect(tester.takeException(), isNull);
      // Ganti halaman dengan kotak kosong agar dispose membatalkan timer dan melepas controller.
      await tester.pumpWidget(const SizedBox());
    },
  );

  // Uji navigasi daftar jadwal dan tombol kembali ke beranda.
  testWidgets('Tombol semua membuka jadwal kosong dan Back kembali', (
    tester,
  ) async {
    viewport(tester, const Size(390, 844));
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Semua'));
    await tester.tap(find.text('Semua'));
    await tester.pumpAndSettle();
    expect(find.text('Belum ada jadwal kuliah'), findsOneWidget);
    // Simulasikan tombol kembali bawaan halaman, bukan mengganti layar secara manual.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('AKSES CEPAT'), findsOneWidget);
    // Pastikan Flutter tidak melaporkan kesalahan tampilan, termasuk isi yang meluber (overflow).
    expect(tester.takeException(), isNull);
    // Ganti halaman dengan kotak kosong agar dispose membatalkan timer dan melepas controller.
    await tester.pumpWidget(const SizedBox());
  });

  // Pastikan beranda tetap tampil tanpa kesalahan saat efek gerak dimatikan.
  testWidgets('Animasi dapat dimatikan dari pengaturan aksesibilitas', (
    tester,
  ) async {
    viewport(tester, const Size(900, 600));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.data,
        // Sisipkan pengaturan ukuran teks khusus untuk menguji aksesibilitas.
        builder: (context, child) => MediaQuery(
          // Tiru preferensi aksesibilitas perangkat untuk menonaktifkan animasi.
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: DashboardPage(
          student: const StudentProfile(nim: 'akun-uji'),
          onLogout: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('AKSES CEPAT'), findsOneWidget);
    // Pastikan Flutter tidak melaporkan kesalahan tampilan, termasuk isi yang meluber (overflow).
    expect(tester.takeException(), isNull);
    // Ganti halaman dengan kotak kosong agar dispose membatalkan timer dan melepas controller.
    await tester.pumpWidget(const SizedBox());
  });
}

// Sumber data uji yang memancing kegagalan sekali untuk memeriksa tombol coba lagi.
class _RetryRepository implements DashboardRepository {
  // Penghitung panggilan agar sumber uji bisa berperilaku berbeda pada percobaan ulang.
  int attempts = 0;
  @override
  // Pengganti sumber data nyata: panggilan pertama gagal, berikutnya memberi data kosong.
  Future<DashboardData> load(String nim) async {
    // Periksa nilai lama lalu naikkan penghitung; hanya percobaan pertama masuk cabang gagal.
    if (attempts++ == 0) {
      throw Exception('Koneksi uji gagal');
    }
    return const DashboardData();
  }
}

// Profil uji berisi tulisan panjang agar layout tidak hanya diuji dengan tanda kosong.
class _ProfileRepository implements DashboardRepository {
  @override
  Future<DashboardData> load(String nim) async => DashboardData(
    student: StudentProfile(
      nim: nim,
      name: 'Mahasiswa Uji Tampilan Tablet',
      faculty: 'Fakultas Ilmu Komputer',
      major: 'Teknik Informatika',
      advisor: 'Dosen Pembimbing Akademik Pengujian',
      status: 'Aktif',
      entryYear: 2024,
      semester: 5,
      gpa: 3.75,
      latestGpa: 3.8,
      passedCredits: 86,
    ),
  );
}
