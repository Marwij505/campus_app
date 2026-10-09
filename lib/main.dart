import 'package:flutter/material.dart';
import 'core/theme/retro_theme.dart';
import 'features/auth/login_page.dart';

void main() => runApp(const CampusApp());

/// Titik masuk aplikasi. Halaman dan tema dipisahkan agar mudah dirawat.
class CampusApp extends StatelessWidget {
  const CampusApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'SIAKAD Fasilkom',
    theme: RetroTheme.data,
    home: const LoginPage(),
  );
}
