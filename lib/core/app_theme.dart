import 'package:flutter/material.dart';

/// Warna dan font mengikuti index.css Figma.
abstract final class AppTheme {
  static const ink = Color(0xFF08142A);
  static const red = Color(0xFFBD2134);
  static const blue = Color(0xFF174C8A);
  static const green = Color(0xFF22D866);
  static const paper = Color(0xFFEEF9FB);
  static const muted = Color(0xFF697581);

  static const backgroundAsset = 'assets/images/pixel-campus.png';

  /// Font pixel digunakan untuk judul dan label retro.
  ///
  /// Isi form menggunakan Space Mono supaya mudah dibaca.
  static TextStyle pixel(double size, {Color color = ink}) => TextStyle(
    fontFamily: 'PressStart2P',
    fontSize: size,
    height: 1.5,
    color: color,
  );

  static ThemeData get data => ThemeData(
    useMaterial3: true,
    fontFamily: 'SpaceMono',
    scaffoldBackgroundColor: paper,

    colorScheme: ColorScheme.fromSeed(seedColor: blue)
        .copyWith(primary: blue, surface: paper, onSurface: ink, error: red),

    textTheme: const TextTheme(
      bodyMedium: TextStyle(fontSize: 12, height: 1.5, color: ink),
    ),

    snackBarTheme: const SnackBarThemeData(
      backgroundColor: ink,
      behavior: SnackBarBehavior.floating,
    ),

    // Gaya input diterapkan otomatis pada seluruh TextFormField.
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
      hintStyle: const TextStyle(fontSize: 13, color: muted),
      border: _border(ink),
      enabledBorder: _border(ink),
      focusedBorder: _border(green),
      errorBorder: _border(red),
      focusedErrorBorder: _border(red),
      errorMaxLines: 3,
    ),
  );

  static OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.zero,
    borderSide: BorderSide(color: color, width: 3),
  );
}
