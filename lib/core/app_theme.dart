// Pusat pengaturan tampilan yang dipakai CampusApp.
// Warna, font, kotak input, dan pesan singkat didefinisikan sekali agar seragam.
// Mengubah nilai di sini dapat memengaruhi banyak halaman sekaligus.

import 'package:flutter/material.dart';

/// Warna dan font mengikuti index.css Figma.
// Kumpulan aturan warna dan tulisan; tidak perlu dibuat menjadi objek.
abstract final class AppTheme {
  // Palet warna bersama. Format 0xFFRRGGBB memuat kepekatan dan komponen merah/hijau/biru.
  static const ink = Color(0xFF08142A);
  static const red = Color(0xFFBD2134);
  static const blue = Color(0xFF174C8A);
  static const green = Color(0xFF22D866);
  static const paper = Color(0xFFEEF9FB);
  static const muted = Color(0xFF697581);

  // Alamat gambar di dalam paket aplikasi, bukan alamat gambar dari internet.
  static const backgroundAsset = 'assets/images/pixel-campus.png';

  /// Font pixel digunakan untuk judul dan label retro.
  ///
  /// Isi form menggunakan Space Mono supaya mudah dibaca.
  // Buat gaya judul pixel dengan ukuran dari pemanggil dan warna bawaan bila tidak diisi.
  static TextStyle pixel(double size, {Color color = ink}) => TextStyle(
    fontFamily: 'PressStart2P',
    fontSize: size,
    height: 1.45,
    fontWeight: FontWeight.w400,
    color: color,
  );

  // Susun aturan visual bawaan yang akan diterima widget melalui MaterialApp.
  static ThemeData get data => ThemeData(
    useMaterial3: true,
    fontFamily: 'SpaceMono',
    scaffoldBackgroundColor: paper,

    // Pasangkan warna dengan perannya: utama, permukaan kartu, teks, dan kesalahan.
    colorScheme: ColorScheme.fromSeed(seedColor: blue)
        .copyWith(primary: blue, surface: paper, onSurface: ink, error: red),

    // Gaya teks isi dibuat lebih mudah dibaca daripada font pixel untuk judul.
    textTheme: const TextTheme(
      bodyMedium: TextStyle(fontSize: 12, height: 1.5, color: ink),
    ),

    // Atur pesan singkat yang muncul sementara di bagian bawah layar.
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: ink,
      behavior: SnackBarBehavior.floating,
    ),

    // Gaya input diterapkan otomatis pada seluruh TextFormField.
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      hintStyle: const TextStyle(fontSize: 12, color: muted),
      border: _border(ink),
      enabledBorder: _border(ink),
      focusedBorder: _border(green),
      errorBorder: _border(red),
      focusedErrorBorder: _border(red),
      errorMaxLines: 3,
    ),
  );

  // Buat bingkai kotak bersudut tajam; warna menunjukkan keadaan input.
  static OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.zero,
    borderSide: BorderSide(color: color, width: 4),
  );
}
