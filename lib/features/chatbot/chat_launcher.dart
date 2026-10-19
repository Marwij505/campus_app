// Satu pintu masuk chatbot untuk semua halaman dan semua akun yang sudah login.
// Controller tetap milik sesi dashboard, sehingga riwayat tidak terpecah per halaman.
import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import 'chat_controller.dart';
import 'chat_page.dart';

// Ingat halaman chat yang terbuka untuk menghindari tumpukan percakapan duplikat.
final _chatRoutes = Expando<Route<void>>('chat-routes');

Future<void> openSmartChat(
  BuildContext context,
  ChatController controller,
) async {
  final navigator = Navigator.of(context);
  final existing = _chatRoutes[controller];
  if (existing != null && existing.isActive) {
    // Dari halaman draf, kembali ke chat sebelumnya; isian tetap di controller.
    navigator.popUntil((route) => identical(route, existing));
    return;
  }
  final route = DialogRoute<void>(
    context: context,
    barrierColor: Colors.black12,
    builder: (context) {
      final media = MediaQuery.of(context);
      final panel = media.size.width >= 700 && media.textScaler.scale(1) <= 1.3;
      final chat = ChatPage(controller: controller, showCloseButton: true);
      // HP/teks besar memakai seluruh layar agar kolom pesan tetap nyaman.
      if (!panel) return chat;
      // Layar lebar memakai jendela di kanan bawah; keyboard mengurangi tingginya.
      return Dialog(
        alignment: Alignment.bottomRight,
        insetPadding: const EdgeInsets.all(16),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppTheme.ink, width: 2),
        ),
        child: SizedBox(
          width: 440,
          height:
              (media.size.height -
                      media.viewInsets.bottom -
                      media.padding.vertical -
                      32)
                  .clamp(0.0, 640.0),
          child: chat,
        ),
      );
    },
  );
  _chatRoutes[controller] = route;
  try {
    await navigator.push(route);
  } finally {
    if (identical(_chatRoutes[controller], route)) {
      _chatRoutes[controller] = null;
    }
  }
}

class ChatLauncher extends StatelessWidget {
  const ChatLauncher({super.key, required this.controller});
  final ChatController controller;

  @override
  Widget build(BuildContext context) {
    // Saat panel/dialog menutupi halaman, jangan sisakan tombol di belakangnya.
    // Halaman draf di atas chat tetap menjadi route aktif dan tetap punya tombol.
    if (ModalRoute.of(context)?.isCurrent == false) {
      return const SizedBox.shrink();
    }
    return FloatingActionButton(
      key: const ValueKey('chat-launcher'),
      // Tiap halaman punya tombol sendiri, sehingga animasi Hero tidak dipakai.
      heroTag: null,
      tooltip: 'Buka Smart Chatbot',
      backgroundColor: AppTheme.blue,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppTheme.ink, width: 2),
      ),
      onPressed: () => openSmartChat(context, controller),
      child: const Icon(Icons.smart_toy_outlined),
    );
  }
}
