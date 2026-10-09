import 'package:flutter/material.dart';

/// Palet warna disimpan di satu tempat, seperti variabel warna dalam CSS.
abstract final class RetroTheme {
  static const ink = Color(0xFF0D1931);
  static const red = Color(0xFFBF2135);
  static const blue = Color(0xFF1E5196);
  static const titleBar = Color(0xFF197CAD);
  static const paper = Color(0xFFEEF9FC);
  static const green = Color(0xFF18D465);
  static const muted = Color(0xFF62798B);

  /// Font pixel digunakan pada judul saja agar form tetap nyaman dibaca.
  static TextStyle pixel(double size, {Color color = ink}) => TextStyle(
    fontFamily: 'CampusPixel',
    fontSize: size,
    height: 1.35,
    color: color,
  );

  static ThemeData get data => ThemeData(
    useMaterial3: true,
    fontFamily: 'monospace',
    scaffoldBackgroundColor: ink,
    colorScheme: ColorScheme.fromSeed(seedColor: blue).copyWith(
      primary: blue,
      onPrimary: Colors.white,
      surface: paper,
      onSurface: ink,
      error: red,
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: ink),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: ink,
      behavior: SnackBarBehavior.floating,
      contentTextStyle: TextStyle(color: Colors.white, fontSize: 14),
      shape: RoundedRectangleBorder(),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: const RoundedRectangleBorder(),
      side: const BorderSide(color: ink, width: 2),
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return blue;
        return Colors.white;
      }),
    ),
  );
}
