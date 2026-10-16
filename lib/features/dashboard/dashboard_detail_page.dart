// Kerangka bersama untuk halaman detail dan halaman menu yang masih kosong.
// Satu berkas menampung tampilan yang sama agar setiap menu tidak menyalin kode.
import 'package:flutter/material.dart';

import '../../core/app_motion.dart';
import '../../core/app_theme.dart';
import '../../shared/pixel_widgets.dart';
import 'dashboard_widgets.dart';

class DashboardDetailPage extends StatelessWidget {
  // Isi dapat diganti dengan fitur lengkap saat modulnya sudah siap.
  const DashboardDetailPage({
    super.key,
    required this.title,
    required this.child,
  });

  // Halaman kosong tetap punya judul, pesan penjelas, dan tombol kembali.
  // Tidak ada data contoh atau formulir yang seolah-olah sudah dapat dipakai.
  factory DashboardDetailPage.empty(String title) => DashboardDetailPage(
    title: title,
    child: DashboardEmpty(
      title: 'Belum ada data $title',
      message:
          'Halaman $title lengkap akan disambungkan pada tahap berikutnya.',
    ),
  );

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    // Tombol kembali otomatis muncul karena halaman dibuka melalui Navigator.
    appBar: AppBar(
      title: Text(title, style: const TextStyle(fontSize: 14)),
      backgroundColor: AppTheme.red,
      foregroundColor: Colors.white,
    ),
    body: Stack(
      fit: StackFit.expand,
      children: [
        const CampusBackground(dashboard: true),
        SafeArea(
          top: false,
          // Isi dapat digulir pada HP atau saat ukuran tulisan diperbesar.
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Entrance(child: PixelPanel(child: child)),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
