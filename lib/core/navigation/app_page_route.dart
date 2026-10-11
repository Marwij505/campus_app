// Pilihan efek perpindahan halaman yang disimpan sebagai helper terpisah.
// Alur utama saat ini menggunakan AppMotion.route; helper ini belum diimpor di sana.
// Route adalah aturan menampilkan halaman tujuan dan animasi ketika kembali.

import 'package:flutter/material.dart';

/// Navigator menentukan tujuan; helper ini menentukan cara halaman bergerak.
// Kumpulan pembuat transisi yang bisa dipakai oleh Navigator.
abstract final class AppPageRoute {
  // Munculkan halaman sambil menggesernya; T adalah jenis hasil yang bisa dikembalikan halaman.
  static Route<T> slideFade<T>({
    required Widget page,
    Offset beginOffset = const Offset(0.06, 0),
    Duration duration = const Duration(milliseconds: 380),
    Duration reverseDuration = const Duration(milliseconds: 280),
  }) => _route<T>(page, beginOffset, 0.99, duration, reverseDuration);

  // Munculkan halaman sambil memperbesar sedikit ukurannya, tanpa pergeseran posisi.
  static Route<T> fadeScale<T>({
    required Widget page,
    Duration duration = const Duration(milliseconds: 420),
    Duration reverseDuration = const Duration(milliseconds: 280),
  }) => _route<T>(page, Offset.zero, 0.97, duration, reverseDuration);

  // Mesin bersama untuk kedua efek: menerima halaman, posisi, skala, dan lama animasi.
  static Route<T> _route<T>(
    Widget page,
    Offset offset,
    double scale,
    Duration duration,
    Duration reverseDuration,
  ) => PageRouteBuilder<T>(
    // Lama membuka halaman; reverseTransitionDuration adalah lama menutupnya.
    transitionDuration: duration,
    reverseTransitionDuration: reverseDuration,
    // Tentukan isi tujuan, sedangkan transitionsBuilder menentukan cara isi itu bergerak.
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Hormati pengaturan aksesibilitas pengguna yang mengurangi gerakan.
      if (MediaQuery.disableAnimationsOf(context)) return child;
      // Ubah kemajuan animasi menjadi perubahan yang melambat mendekati akhir.
      final curved = animation.drive(CurveTween(curve: Curves.easeOutCubic));
      // Gabungkan transparansi, pergeseran, dan ukuran seperti tiga lapisan pembungkus.
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: curved.drive(Tween(begin: offset, end: Offset.zero)),
          child: ScaleTransition(
            scale: curved.drive(Tween<double>(begin: scale, end: 1)),
            child: child,
          ),
        ),
      );
    },
  );
}
