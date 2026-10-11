// Titik awal aplikasi dan pengatur perpindahan login/beranda.
//
// AuthService menentukan apakah sesi masih valid.
// AuthGate mengatur timer dan memperbarui tampilan ketika sesi habis.

import 'dart:async';

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

void main() {
  // Siapkan Flutter sebelum menggunakan layanan dan aset.
  WidgetsFlutterBinding.ensureInitialized();

  // Daftarkan lisensi font untuk halaman lisensi standar Flutter.
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Press Start 2P',
    ], await rootBundle.loadString('assets/fonts/PressStart2P-OFL.txt'));

    yield LicenseEntryWithLineBreaks([
      'Space Mono',
    ], await rootBundle.loadString('assets/fonts/SpaceMono-OFL.txt'));
  });

  // Mulai aplikasi dari widget utama.
  runApp(const CampusApp());
}

/// Menetapkan tema, nama aplikasi, dan halaman pembuka.
class CampusApp extends StatelessWidget {
  const CampusApp({
    super.key,
    this.dashboardRepository = const EmptyDashboardRepository(),
  });

  // Sumber data beranda masih mengembalikan data kosong.
  // Nantinya dapat diganti dengan repository yang memanggil API.
  final DashboardRepository dashboardRepository;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'campus_app',
    theme: AppTheme.data,
    home: AuthGate(repository: dashboardRepository),
  );
}

/// Memilih halaman login atau beranda berdasarkan sesi pengguna.
class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    this.repository = const EmptyDashboardRepository(),
  });

  // Teruskan sumber data ke dashboard setelah login.
  final DashboardRepository repository;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

/// Menyimpan profil dan mengatur logout otomatis.
///
/// WidgetsBindingObserver mendengarkan perubahan status aplikasi,
/// termasuk ketika aplikasi kembali aktif dari background.
class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  // Satu layanan digunakan bersama untuk login, reset, dan logout.
  final _service = AuthService();

  // null berarti pengguna belum login atau sudah keluar.
  StudentProfile? _student;

  // Timer untuk memeriksa sesi saat batas waktu tercapai.
  Timer? _sessionTimer;

  @override
  void initState() {
    super.initState();

    // Mulai mendengarkan perubahan status aplikasi.
    WidgetsBinding.instance.addObserver(this);
  }

  /// Menerima profil dari halaman login.
  void _onLogin(StudentProfile student) {
    // Jangan memperbarui widget yang sudah ditutup.
    if (!mounted) return;

    // Tolak pembukaan dashboard jika sesi sudah tidak valid.
    if (!_service.hasSession) {
      _service.logout();
      return;
    }

    // Simpan profil agar build menampilkan dashboard.
    setState(() {
      _student = student;
    });

    // Mulai menghitung sisa waktu menuju kedaluwarsa.
    _scheduleSessionCheck();
  }

  /// Memasang timer berdasarkan sisa waktu yang sebenarnya.
  void _scheduleSessionCheck() {
    // Hindari beberapa timer aktif bersamaan.
    _sessionTimer?.cancel();

    // Tidak perlu timer jika widget ditutup atau pengguna belum login.
    if (!mounted || _student == null) return;

    final remaining = _service.remainingSession;

    // Jika waktunya sudah habis, keluar sekarang.
    if (remaining <= Duration.zero) {
      _logout();
      return;
    }

    // Timer sekali jalan; durasinya tidak memperpanjang sesi.
    _sessionTimer = Timer(remaining, _checkSession);
  }

  /// Memeriksa ulang sesi berdasarkan waktu kedaluwarsa.
  void _checkSession() {
    if (!mounted || _student == null) return;

    if (!_service.hasSession) {
      _logout();
      return;
    }

    // Jadwalkan ulang hanya untuk waktu sesi yang masih tersisa.
    _scheduleSessionCheck();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Timer dapat tertunda ketika aplikasi berada di background.
      // Periksa kembali saat pengguna membuka aplikasi.
      _checkSession();
    }
  }

  /// Menangani tombol Keluar maupun kedaluwarsa otomatis.
  void _logout() {
    // Hentikan timer dan hapus referensinya.
    _sessionTimer?.cancel();
    _sessionTimer = null;

    // Hapus sesi pada layanan.
    _service.logout();

    // Tidak perlu memperbarui halaman jika sudah ditutup/belum login.
    if (!mounted || _student == null) return;

    // Tutup halaman atau dialog tambahan di atas halaman utama.
    // Pengguna tidak ditinggalkan pada halaman yang memerlukan login.
    Navigator.of(context).popUntil((route) => route.isFirst);

    // Mengosongkan profil membuat build memilih halaman login.
    setState(() {
      _student = null;
    });
  }

  @override
  void dispose() {
    // Bersihkan timer agar tidak berjalan setelah widget ditutup.
    _sessionTimer?.cancel();

    // Hentikan pemantauan perubahan status aplikasi.
    WidgetsBinding.instance.removeObserver(this);

    // Hapus sesi ketika AuthGate dibuang.
    _service.logout();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    // Pertahankan transisi halus dari desain sebelumnya.
    duration: AppMotion.duration(context, 420),
    switchInCurve: Curves.easeOutCubic,
    switchOutCurve: Curves.easeInCubic,

    // Gabungkan fade dengan perubahan skala kecil.
    transitionBuilder: (child, animation) => FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: animation.drive(Tween<double>(begin: .985, end: 1)),
        child: child,
      ),
    ),

    // Tanpa profil: tampilkan login.
    // Dengan profil: tampilkan dashboard.
    child: _student == null
        ? LoginPage(
            key: const ValueKey('login'),
            service: _service,
            onLogin: _onLogin,
          )
        : DashboardPage(
            key: const ValueKey('dashboard'),
            student: _student!,
            repository: widget.repository,
            onLogout: _logout,
          ),
  );
}
