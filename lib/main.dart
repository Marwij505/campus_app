import 'package:flutter/material.dart';
import 'features/auth/login_page.dart';

void main() {
  runApp(const CampusApp());
}

/// ============================================================
/// ROOT APPLICATION
/// ============================================================
///
/// ANALOGI WEB:
///
/// CampusApp
/// ≈ kerangka utama aplikasi / root website.
///
/// MaterialApp
/// ≈ konfigurasi global aplikasi.
///
/// LoginPage
/// ≈ halaman pertama yang dibuka.
///
class CampusApp extends StatelessWidget {
  const CampusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Menghilangkan tulisan DEBUG.
      debugShowCheckedModeBanner: false,

      // Nama aplikasi.
      title: 'SIAKAD Fasilkom',

      // ========================================================
      // CSS GLOBAL / GLOBAL THEME
      // ========================================================
      theme: ThemeData(
        useMaterial3: true,

        // Kita gunakan default font Flutter supaya
        // kompatibel di Android, iOS, Web, dan Desktop.
        scaffoldBackgroundColor: const Color(0xFFF5F8FC),

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1478E8),
          brightness: Brightness.light,
        ),

        inputDecorationTheme: const InputDecorationTheme(
          border: InputBorder.none,
        ),
      ),

      // Halaman pertama aplikasi.
      home: const LoginPage(),
    );
  }
}