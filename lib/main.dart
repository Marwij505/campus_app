import 'package:flutter/material.dart';

import 'core/app_motion.dart';
import 'core/app_theme.dart';
import 'data/auth_service.dart';
import 'data/demo_data.dart';
import 'features/auth/login_page.dart';
import 'features/dashboard/dashboard_page.dart';

void main() => runApp(const CampusApp());

class CampusApp extends StatelessWidget {
  const CampusApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'SIAKAD Fasilkom',
    theme: AppTheme.data,
    home: const AuthGate(),
  );
}

/// Satu tempat menentukan pengguna sedang di login atau di beranda.
///
/// Setelah berhasil masuk, halaman utama diganti menjadi Dashboard.
/// Dengan demikian, tombol Back tidak membuka halaman login sebelumnya.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

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
            onLogout: _logout,
          ),
  );
}
