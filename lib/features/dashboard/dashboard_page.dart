import 'package:flutter/material.dart';
import '../../core/navigation/app_page_route.dart';
import '../../core/theme/retro_theme.dart';
import '../auth/login_page.dart';
import '../auth/services/auth_service.dart';

/// Placeholder dari proyek awal untuk menguji keberhasilan login.
/// Dashboard akademik sesungguhnya belum dikerjakan dalam revisi UI ini.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, this.authService});
  final AuthService? authService;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: RetroTheme.paper,
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.dashboard_outlined, size: 68, color: RetroTheme.blue),
            const SizedBox(height: 24),
            Text('Dashboard', style: RetroTheme.pixel(26)),
            const SizedBox(height: 12),
            const Text('Login berhasil.\nDashboard SIAKAD akan dibangun di sini.',
              textAlign: TextAlign.center),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                final service = authService ?? DemoAuthService.instance;
                if (service is DemoAuthService) service.logout();
                Navigator.of(context).pushReplacement(AppPageRoute.fadeScale(
                  page: LoginPage(authService: service)));
              },
              icon: const Icon(Icons.logout), label: const Text('Keluar'),
            ),
          ]),
        ),
      ),
    ),
  );
}
