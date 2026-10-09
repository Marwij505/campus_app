import 'package:flutter/material.dart';

class StudentProfile {
  const StudentProfile({required this.nim});

  final String nim;

  String get name => 'Reifan Ardissa';
  String get major => 'Teknik Informatika';
  int get semester => 5;
  double get gpa => 3.73;
}

/// Satu kartu kemajuan belajar.
class StudyStat {
  const StudyStat(
    this.label,
    this.value,
    this.suffix,
    this.progress,
    this.color,
  );

  final String label;
  final String value;
  final String suffix;

  // Nilai 0 sampai 1 untuk panjang progress bar.
  final double progress;

  final Color color;
}

/// Satu pengumuman atau berita.
class NoticeData {
  const NoticeData(this.title, this.date);

  final String title;
  final String date;
}

/// Satu jadwal konseling.
class CounselingData {
  const CounselingData(this.day, this.date, this.name, this.mode);

  final String day;
  final String date;
  final String name;
  final String mode;
}

abstract final class DemoData {
  static const stats = [
    StudyStat('MASA STUDI', '5', '/14 smt', 5 / 14, Color(0xFF2776CC)),
    StudyStat('SKS LULUS', '86', '/144', 86 / 144, Color(0xFF1AA95A)),
    StudyStat('INDEKS PRESTASI', '3.73', '/4.00', 3.73 / 4, Color(0xFFED7D21)),
    StudyStat('NILAI A', '80', '%', 0.8, Color(0xFF873DD1)),
  ];

  static const announcements = [
    NoticeData(
      'Pendaftaran susulan UTS/UAS Semester Antara Genap',
      '21 Agu 2026 · 10:09',
    ),
    NoticeData('Pendaftaran Wisuda Oktober 2026', '14 Agu 2026 · 22:10'),
    NoticeData(
      'Registrasi Semester Ganjil TA 2026/2027',
      '24 Jul 2026 · 16:21',
    ),
  ];

  static const news = [
    NoticeData('Tata Cara Pembayaran', '17 Agu 2026'),
    NoticeData('Festival Isyarat UEU 2026', '30 Jun 2026'),
    NoticeData('Beasiswa BSI', '22 Jun 2026'),
  ];

  static const counseling = [
    CounselingData('KAM', '15', 'Maryana Widiastuti, S.Psi.', 'Offline'),
    CounselingData('SEN', '19', 'Dra. Safitri M., M.Si.', 'Offline'),
    CounselingData('SAB', '24', 'Levianti, S.Psi., M.Si.', 'Online'),
  ];
}
