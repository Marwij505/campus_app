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
  WidgetsFlutterBinding.ensureInitialized();
  // Lisensi font ikut tersedia melalui halaman lisensi standar Flutter.
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Press Start 2P',
    ], await rootBundle.loadString('assets/fonts/PressStart2P-OFL.txt'));
    yield LicenseEntryWithLineBreaks([
      'Space Mono',
    ], await rootBundle.loadString('assets/fonts/SpaceMono-OFL.txt'));
  });
  runApp(const CampusApp());
}

class CampusApp extends StatelessWidget {
  const CampusApp({
    super.key,
    this.dashboardRepository = const EmptyDashboardRepository(),
  });

  // Ganti repository saat API backend siap; komponen UI tetap sama.
  final DashboardRepository dashboardRepository;

  @override
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
class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    this.repository = const EmptyDashboardRepository(),
  });
  final DashboardRepository repository;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _service = AuthService();

  // null berarti pengguna belum masuk.
  StudentProfile? _student;

  void _logout() {
    _service.logout();

    setState(() {
      _student = null;
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
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
            onLogin: (student) {
              setState(() {
                _student = student;
              });
            },
          )
        : DashboardPage(
            key: const ValueKey('dashboard'),
            student: _student!,
            repository: widget.repository,
            onLogout: _logout,
          ),
  );
}
