// Satu kotak masuk dengan isi sesuai akun: milik mahasiswa, antrean BAP,
// atau hasil final yang ditujukan ke kode dosen tersebut.
import 'package:flutter/material.dart';

import '../../core/app_motion.dart';
import '../../data/student_profile.dart';
import '../../shared/pixel_widgets.dart';
import '../chatbot/chat_controller.dart';
import 'leave_detail.dart';
import 'leave_form.dart';
import 'leave_repository.dart';
import 'leave_widgets.dart';

class LeavePage extends StatefulWidget {
  const LeavePage({
    super.key,
    required this.repository,
    this.chat,
    this.onLogout,
  });
  final LeaveRepository repository;
  final ChatController? chat;
  final VoidCallback? onLogout;
  @override
  State<LeavePage> createState() => _LeavePageState();
}

class _LeavePageState extends State<LeavePage> {
  late final ChatController chat = widget.chat ?? ChatController();
  @override
  void initState() {
    super.initState();
    if (widget.chat == null) {
      chat.openLeave = () =>
          Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  void dispose() {
    if (widget.chat == null) chat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.repository,
    builder: (context, _) {
      final user = widget.repository.session();
      if (user == null) return const SizedBox.shrink();
      final rows = widget.repository.inbox;
      final title = switch (user.role) {
        UserRole.student => 'Izin Online',
        UserRole.bap => 'BAP · Pemeriksaan Izin',
        UserRole.lecturer => 'Dosen · Hasil Izin',
      };
      return LeaveShell(
        title: title,
        chat: chat,
        onLogout: widget.onLogout,
        child: PixelPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const LeaveNotice(),
              Text('Akun: ${user.nim}'),
              const SizedBox(height: 8),
              Text(switch (user.role) {
                UserRole.student => 'Ajukan izin ke BAP, pantau pemeriksaan, lalu unduh hasil PDF untuk diteruskan manual. Hasil final juga tersedia bagi dosen sesuai kode.',
                UserRole.bap => 'BAP adalah unit pemeriksa izin. Tinjau bukti, rentang tanggal, dan kode dosen sebelum memutuskan. Berita Acara Perkuliahan merupakan dokumen kegiatan, bukan akun penerima.',
                UserRole.lecturer => 'Hanya hasil final yang ditujukan ke kode akunmu ditampilkan. Hasil tersedia tidak berarti presensi sudah berubah.',
              }),
              const SizedBox(height: 16),
              if (user.role == UserRole.student)
                FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    AppMotion.route(
                      LeaveForm(repository: widget.repository, chat: chat),
                    ),
                  ),
                  icon: const Icon(Icons.note_add_outlined),
                  label: const Text('Buat pengajuan izin'),
                ),
              const SizedBox(height: 20),
              if (rows.isEmpty)
                const Text('Belum ada pengajuan di kotak masuk ini.'),
              for (final row in rows)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: OutlinedButton(
                    onPressed: () => Navigator.push(
                      context,
                      AppMotion.route(
                        LeaveDetail(
                          repository: widget.repository,
                          id: row.id,
                          chat: chat,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${row.id} · versi ${row.version}\n${row.draft.value('Nama')} · ${row.studentId}\n${row.status.label}',
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}
