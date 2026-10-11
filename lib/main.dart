// Titik awal aplikasi: menyiapkan Flutter, mendaftarkan lisensi font,
// lalu memilih layar login atau beranda sesuai hasil masuk pengguna.
// Cara membaca: widget adalah bagian tampilan; State menyimpan kondisi yang
// bisa berubah; setState meminta Flutter memperbarui tampilan setelah perubahan.
// class adalah cetakan objek; constructor mengisi pengaturan awal objek itu.
// required berarti parameter wajib diisi; const dipakai untuk nilai/objek konstan.
// import membawa alat dari berkas lain; @override menandai fungsi pengganti
// dari kelas induk, misalnya build untuk menentukan susunan tampilan sendiri.
// context menunjukkan posisi widget dalam pohon tampilan untuk mencari tema,
// navigasi, atau pengaturan layar yang disediakan oleh pembungkusnya.

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'core/app_motion.dart';
import 'core/app_theme.dart';
import 'data/auth_service.dart';
import 'data/dashboard_repository.dart';
import 'data/student_profile.dart';
import 'features/auth/login_page.dart';
import 'features/dashboard/dashboard_page.dart';

// Fungsi pertama yang dijalankan saat aplikasi dibuka.
void main() {
  // Siapkan penghubung Flutter dengan perangkat sebelum membaca aset font.
  WidgetsFlutterBinding.ensureInitialized();
  // Lisensi font ikut tersedia melalui halaman lisensi standar Flutter.
  // async* menghasilkan entri lisensi satu per satu lewat yield.
  // await menunggu teks lisensi selesai dibaca dari berkas aset.
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Press Start 2P',
    ], await rootBundle.loadString('assets/fonts/PressStart2P-OFL.txt'));
    yield LicenseEntryWithLineBreaks([
      'Space Mono',
    ], await rootBundle.loadString('assets/fonts/SpaceMono-OFL.txt'));
  });
  // Pasang CampusApp sebagai akar seluruh tampilan di layar.
  runApp(const CampusApp());
}

// Wadah utama yang menetapkan tema dan halaman pembuka aplikasi.
class CampusApp extends StatelessWidget {
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
  const CampusApp({
    super.key,
    this.dashboardRepository = const EmptyDashboardRepository(),
  });

  // Ganti repository saat API backend siap; komponen UI tetap sama.
  // Repository ibarat petugas pengambil data. Versi bawaan mengembalikan data kosong.
  final DashboardRepository dashboardRepository;

  @override
  // build menyusun tampilan ketika Flutter memintanya.
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'campus_app',
    theme: AppTheme.data,
    home: AuthGate(repository: dashboardRepository),
  );
}

/// Satu tempat menentukan pengguna sedang di login atau di beranda.
///
/// Setelah berhasil masuk, halaman utama diganti menjadi Dashboard.
/// Dengan demikian, tombol Back tidak membuka halaman login sebelumnya.
// Penjaga pintu: menampilkan login jika belum ada profil, atau beranda jika sudah masuk.
class AuthGate extends StatefulWidget {
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
  const AuthGate({
    super.key,
    this.repository = const EmptyDashboardRepository(),
  });
  // Teruskan sumber data yang sama ke beranda setelah pengguna berhasil masuk.
  final DashboardRepository repository;

  @override
  // Hubungkan konfigurasi widget dengan objek State yang menyimpan perubahan selama tampil.
  State<AuthGate> createState() => _AuthGateState();
}

// Menyimpan hasil login dan mengatur perubahan layar tanpa menumpuk halaman login.
class _AuthGateState extends State<AuthGate> {
  // Satu layanan ini dipakai bersama untuk masuk dan keluar selama AuthGate hidup.
  final _service = AuthService();

  // null berarti pengguna belum masuk.
  // Tanda ? mengizinkan nilai null, yaitu belum ada profil pengguna yang masuk.
  StudentProfile? _student;

  // Hapus sesi di layanan, lalu hapus profil agar build memilih layar login lagi.
  void _logout() {
    _service.logout();

    setState(() {
      _student = null;
    });
  }

  @override
  // build menyusun tampilan ketika Flutter memintanya.
  Widget build(BuildContext context) => AnimatedSwitcher(
    // Durasi mengatur lama perpindahan; kurva di bawah membuat gerak lebih halus.
    duration: AppMotion.duration(context, 420),
    switchInCurve: Curves.easeOutCubic,
    switchOutCurve: Curves.easeInCubic,

    // Pergantian login dan dashboard menggunakan fade + sedikit scale.
    transitionBuilder: (child, animation) => FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: animation.drive(Tween<double>(begin: .985, end: 1)),
        child: child,
      ),
    ),

    // Key membantu Flutter mengenali bahwa kedua halaman berbeda.
    child: _student == null
        ? LoginPage(
            key: const ValueKey('login'),
            service: _service,
            // Callback adalah fungsi balasan: halaman login mengirim profil ke induknya.
            onLogin: (student) {
              setState(() {
                _student = student;
              });
            },
          )
        : DashboardPage(
            key: const ValueKey('dashboard'),
            // Tanda ! dipakai karena cabang ini hanya dijalankan saat profil bukan null.
            student: _student!,
            repository: widget.repository,
            onLogout: _logout,
          ),
  );
}
