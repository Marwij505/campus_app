// Pengaturan animasi yang dipakai halaman utama dan form autentikasi.
// Animasi mengubah tampilan sedikit demi sedikit dari nilai awal ke nilai akhir.
// Jika pengguna memilih mengurangi animasi, konten langsung ditampilkan.

import 'dart:async';

import 'package:flutter/material.dart';

// Pilihan durasi dan perpindahan halaman yang digunakan bersama.
abstract final class AppMotion {
  /// Hormati pengaturan pengguna yang mengurangi animasi.
  // Kembalikan lama animasi, atau nol agar perpindahan berlangsung seketika.
  static Duration duration(BuildContext context, [int milliseconds = 380]) =>
      MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : Duration(milliseconds: milliseconds);

  /// Transisi untuk membuka halaman lupa password.
  ///
  /// Navigator.pop() otomatis menjalankan transisi dalam arah sebaliknya.
  // Bungkus halaman tujuan dengan efek muncul perlahan dan geser dari kanan.
  static Route<void> route(Widget page) => PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 280),

    pageBuilder: (context, animation, secondaryAnimation) => page,

    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.disableAnimationsOf(context)) {
        return child;
      }

      // Kurva mengatur kecepatan perubahan: gerak melambat saat mendekati akhir.
      final curved = animation.drive(CurveTween(curve: Curves.easeOutCubic));

      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: curved.drive(
            Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero),
          ),
          child: child,
        ),
      );
    },
  );
}

/// Konten muncul bertahap dengan fade + pergeseran 10 px.
/// Controller dan timer selalu dilepas saat halaman ditutup.
// Pembungkus agar sebuah bagian layar muncul perlahan dengan waktu tunda opsional.
class Entrance extends StatefulWidget {
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
  const Entrance({super.key, required this.child, this.delay = 0});
  // Isi tampilan yang akan diberi efek muncul; pembungkus tidak menentukan isi tersebut.
  final Widget child;
  // Waktu tunggu sebelum animasi mulai, dalam milidetik, untuk kemunculan bertahap.
  final int delay;
  @override
  // Hubungkan konfigurasi widget dengan objek State yang menyimpan perubahan selama tampil.
  State<Entrance> createState() => _EntranceState();
}

// Menyimpan pengendali dan timer selama animasi komponen berlangsung.
class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  // Pengendali waktu animasi. late berarti akan diisi saat inisialisasi, bukan sekarang.
  late final AnimationController _controller;
  // Mengubah kemajuan pengendali menjadi gerakan yang terasa halus.
  late final CurvedAnimation _curve;
  // Pengingat sekali jalan untuk memulai animasi setelah waktu tunda.
  Timer? _timer;
  // Penanda agar perubahan pengaturan tidak memulai animasi yang sama berulang kali.
  bool _started = false;

  @override
  // Dijalankan sekali saat komponen hadir; vsync mengikuti irama pembaruan layar.
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _curve = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
  }

  @override
  // Baca ulang pengaturan animasi saat lingkungan widget berubah.
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.duration = AppMotion.duration(context, 420);
    if (MediaQuery.disableAnimationsOf(context)) {
      _timer?.cancel();
      // Nilai 1 adalah keadaan akhir: konten langsung terlihat penuh.
      _controller.value = 1;
      _started = true;
    } else if (!_started) {
      _started = true;
      if (widget.delay == 0) {
        _controller.forward();
      } else {
        _timer = Timer(Duration(milliseconds: widget.delay), () {
          // Jalankan hanya jika komponen masih terpasang saat waktu tunggu selesai.
          if (mounted) {
            _controller.forward();
          }
        });
      }
    }
  }

  @override
  // Batalkan timer dan lepaskan alat animasi ketika komponen dibuang dari layar.
  void dispose() {
    _timer?.cancel();
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  // build menyusun tampilan ketika Flutter memintanya.
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _curve,
    child: widget.child,
    builder: (context, child) => Opacity(
      opacity: _curve.value,
      child: Transform.translate(
        // Saat nilai mendekati 1, jarak geser mengecil hingga posisi normal.
        offset: Offset(0, 10 * (1 - _curve.value)),
        child: child,
      ),
    ),
  );
}
