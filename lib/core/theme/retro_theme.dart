// Tema alternatif untuk kumpulan komponen Retro di core/widgets.
// CampusApp saat ini memakai AppTheme dari core/app_theme.dart.
// Nama font CampusPixel di sini belum terdaftar di pubspec.yaml; tema utama
// memakai PressStart2P dan SpaceMono yang memang tersedia sebagai aset.

import 'package:flutter/material.dart';

/// Palet warna disimpan di satu tempat, seperti variabel warna dalam CSS.
// Pengaturan visual bersama untuk komponen alternatif bergaya retro.
abstract final class RetroTheme {
  // Daftar warna bersama untuk latar, teks, garis, dan penanda status tema alternatif.
  static const ink = Color(0xFF0D1931);
  static const red = Color(0xFFBF2135);
  static const blue = Color(0xFF1E5196);
  static const titleBar = Color(0xFF197CAD);
  static const paper = Color(0xFFEEF9FC);
  static const green = Color(0xFF18D465);
  static const muted = Color(0xFF62798B);

  /// Font pixel digunakan pada judul saja agar form tetap nyaman dibaca.
  // Susun gaya tulisan berdasarkan ukuran dan warna yang diminta komponen.
  static TextStyle pixel(double size, {Color color = ink}) => TextStyle(
    fontFamily: 'CampusPixel',
    fontSize: size,
    height: 1.35,
    color: color,
  );

  // Gabungkan pilihan warna, tulisan, pesan singkat, dan kotak centang dalam satu tema.
  static ThemeData get data => ThemeData(
    useMaterial3: true,
    fontFamily: 'monospace',
    scaffoldBackgroundColor: ink,
    // Berikan peran pada warna supaya widget Material mendapat warna yang sesuai.
    colorScheme: ColorScheme.fromSeed(seedColor: blue).copyWith(
      primary: blue,
      onPrimary: Colors.white,
      surface: paper,
      onSurface: ink,
      error: red,
    ),
    // Tetapkan ukuran dan jarak antarbaris teks isi.
    textTheme: const TextTheme(
      bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: ink),
    ),
    // Atur kotak pemberitahuan sementara yang melayang di atas halaman.
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: ink,
      behavior: SnackBarBehavior.floating,
      contentTextStyle: TextStyle(color: Colors.white, fontSize: 14),
      shape: RoundedRectangleBorder(),
    ),
    // Buat kotak centang bersudut tajam dan ubah warna isinya ketika dipilih.
    checkboxTheme: CheckboxThemeData(
      shape: const RoundedRectangleBorder(),
      side: const BorderSide(color: ink, width: 2),
      // Pilih warna berdasarkan status kotak: tercentang biru, tidak tercentang putih.
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return blue;
        return Colors.white;
      }),
    ),
  );
}
