// Kerangka bersama untuk halaman detail dan halaman menu yang masih kosong.
// Satu berkas menampung tampilan yang sama agar setiap menu tidak menyalin kode.
import 'package:flutter/material.dart';

import '../../core/app_motion.dart';
import '../../core/app_theme.dart';
import '../../shared/pixel_widgets.dart';
import '../chatbot/chat_controller.dart';
import '../chatbot/chat_launcher.dart';
import 'dashboard_widgets.dart';

class DashboardDetailPage extends StatelessWidget {
  // Isi dapat diganti dengan fitur lengkap saat modulnya sudah siap.
  const DashboardDetailPage({
    super.key,
    required this.title,
    required this.child,
    this.chat,
  });

  // Halaman kosong tetap punya judul, pesan penjelas, dan tombol kembali.
  // Tidak ada data contoh atau formulir yang seolah-olah sudah dapat dipakai.
  factory DashboardDetailPage.empty(String title, {ChatController? chat}) =>
      DashboardDetailPage(
        title: title,
        chat: chat,
        child: DashboardEmpty(
          title: 'Belum ada data $title',
          message:
              'Halaman $title lengkap akan disambungkan pada tahap berikutnya.',
        ),
      );

  final String title;
  final Widget child;
  // Semua halaman detail menerima sesi chat yang sama dari dashboard.
  final ChatController? chat;

  @override
  Widget build(BuildContext context) => Scaffold(
    floatingActionButton: chat == null ? null : ChatLauncher(controller: chat!),
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
            padding: EdgeInsets.fromLTRB(20, 20, 20, chat == null ? 20 : 96),
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
