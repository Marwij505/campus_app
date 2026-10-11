// Kumpulan data contoh dari versi demo sebelumnya.
// Berkas ini tidak diimpor oleh alur utama saat ini. Profil yang aktif berada
// di student_profile.dart, sedangkan beranda memakai DashboardRepository.
// Nama dan angka di bawah adalah contoh tetap, bukan hasil pengambilan data mahasiswa.

import 'package:flutter/material.dart';

// Profil contoh lama; berbeda dengan StudentProfile di student_profile.dart.
class StudentProfile {
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
  const StudentProfile({required this.nim});

  // Identitas yang diberikan ketika membuat profil contoh.
  final String nim;

  // Getter mengembalikan nilai saat dibaca; semua getter berikut berisi contoh tetap.
  String get name => 'Reifan Ardissa';
  String get major => 'Teknik Informatika';
  int get semester => 5;
  double get gpa => 3.73;
}

/// Satu kartu kemajuan belajar.
// Data untuk satu kartu statistik demo.
class StudyStat {
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
  const StudyStat(
    this.label,
    this.value,
    this.suffix,
    this.progress,
    this.color,
  );

  // Nama ukuran yang ditampilkan pada kartu, misalnya SKS LULUS.
  final String label;
  // Angka disimpan sebagai teks yang siap ditampilkan.
  final String value;
  // Keterangan setelah angka, misalnya /144 atau tanda persen.
  final String suffix;

  // Nilai 0 sampai 1 untuk panjang progress bar.
  final double progress;

  // Warna untuk membedakan jenis statistik pada tampilan.
  final Color color;
}

/// Satu pengumuman atau berita.
// Judul dan tanggal informasi demo.
class NoticeData {
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
  const NoticeData(this.title, this.date);

  // Judul berita/pengumuman contoh.
  final String title;
  // Tanggal contoh berupa teks; tidak dihitung dari jam perangkat.
  final String date;
}

/// Satu jadwal konseling.
// Isi satu baris jadwal konseling demo.
class CounselingData {
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
  const CounselingData(this.day, this.date, this.name, this.mode);

  // Singkatan hari pada jadwal konseling contoh.
  final String day;
  // Tanggal contoh berupa teks; tidak dihitung dari jam perangkat.
  final String date;
  // Nama petugas pada contoh jadwal konseling.
  final String name;
  // Metode pertemuan yang tertulis pada contoh, misalnya Online.
  final String mode;
}

// Wadah daftar contoh yang dapat diakses tanpa membuat objek.
abstract final class DemoData {
  // Daftar statistik contoh; static const berarti milik kelas dan nilainya tetap.
  static const stats = [
    StudyStat('MASA STUDI', '5', '/14 smt', 5 / 14, Color(0xFF2776CC)),
    StudyStat('SKS LULUS', '86', '/144', 86 / 144, Color(0xFF1AA95A)),
    StudyStat('INDEKS PRESTASI', '3.73', '/4.00', 3.73 / 4, Color(0xFFED7D21)),
    StudyStat('NILAI A', '80', '%', 0.8, Color(0xFF873DD1)),
  ];

  // Contoh judul dan tanggal pengumuman untuk tampilan versi demo.
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

  // Contoh berita kampus, tanpa permintaan jaringan.
  static const news = [
    NoticeData('Tata Cara Pembayaran', '17 Agu 2026'),
    NoticeData('Festival Isyarat UEU 2026', '30 Jun 2026'),
    NoticeData('Beasiswa BSI', '22 Jun 2026'),
  ];

  // Contoh tiga jadwal konseling untuk rancangan tampilan lama.
  static const counseling = [
    CounselingData('KAM', '15', 'Maryana Widiastuti, S.Psi.', 'Offline'),
    CounselingData('SEN', '19', 'Dra. Safitri M., M.Si.', 'Offline'),
    CounselingData('SAB', '24', 'Levianti, S.Psi., M.Si.', 'Online'),
  ];
}
