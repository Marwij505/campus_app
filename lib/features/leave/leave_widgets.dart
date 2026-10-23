// Komponen bersama izin: kerangka pixel, kalender, dan bukti pendukung.
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../core/app_theme.dart';
import '../../shared/pixel_widgets.dart';
import '../chatbot/chat_controller.dart';
import '../chatbot/chat_launcher.dart';
import '../chatbot/chat_models.dart';
import 'leave_models.dart';

class LeaveShell extends StatelessWidget {
  const LeaveShell({
    super.key,
    required this.title,
    required this.child,
    this.chat,
    this.onLogout,
  });
  final String title;
  final Widget child;
  final ChatController? chat;
  final VoidCallback? onLogout;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(title, style: const TextStyle(fontSize: 14)),
      backgroundColor: AppTheme.red,
      foregroundColor: Colors.white,
      actions: [
        if (onLogout != null)
          IconButton(
            tooltip: 'Keluar',
            onPressed: onLogout,
            icon: const Icon(Icons.logout),
          ),
      ],
    ),
    floatingActionButton: chat == null ? null : ChatLauncher(controller: chat!),
    body: Stack(
      fit: StackFit.expand,
      children: [
        const CampusBackground(dashboard: true),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: child,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class LeaveNotice extends StatelessWidget {
  const LeaveNotice({super.key});
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(bottom: 20),
    child: Text(
      'SIMULASI LOKAL · Belum terhubung ke kampus. Pengajuan tersimpan dalam proses aplikasi ini, '
      'tetap ada saat berganti akun, tetapi hilang setelah refresh/restart. Tidak terkirim antarperangkat.',
      style: TextStyle(fontSize: 12, color: AppTheme.blue),
    ),
  );
}

class LeaveDateField extends StatelessWidget {
  const LeaveDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label, value;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => TextFormField(
    key: ValueKey('$label:$value'),
    initialValue: value,
    readOnly: true,
    decoration: InputDecoration(
      labelText: '$label *',
      hintText: 'Pilih tanggal dari kalender',
      suffixIcon: const Icon(Icons.calendar_month),
      border: const OutlineInputBorder(),
    ),
    onTap: () async {
      final selected = await showDatePicker(
        context: context,
        initialDate: StudentDraft.parseDate(value) ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (selected != null && context.mounted) onChanged(leaveDate(selected));
    },
  );
}

class LeaveAttachments extends StatefulWidget {
  const LeaveAttachments({super.key, required this.files, this.onChanged});
  final List<DraftAttachment> files;
  final VoidCallback? onChanged;
  @override
  State<LeaveAttachments> createState() => _LeaveAttachmentsState();
}

class _LeaveAttachmentsState extends State<LeaveAttachments> {
  bool _busy = false;
  String? _error;
  Future<void> _pick() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final files = await openFiles(
        acceptedTypeGroups: [
          const XTypeGroup(
            label: 'Bukti izin',
            extensions: ['pdf', 'png', 'jpg', 'jpeg'],
            mimeTypes: ['application/pdf', 'image/png', 'image/jpeg'],
            uniformTypeIdentifiers: [
              'com.adobe.pdf',
              'public.png',
              'public.jpeg',
            ],
          ),
        ],
      );
      for (final file in files) {
        if (!mounted) return;
        if (widget.files.length >= 3) throw StateError('Maksimal 3 bukti.');
        if (await file.length() > 5 * 1024 * 1024) {
          throw StateError('Maksimal 5 MB per bukti.');
        }
        final bytes = await file.readAsBytes();
        if (!mounted) return;
        final error = DraftAttachment.validate(file.name, bytes);
        if (error != null) throw StateError(error);
        widget.files.add(DraftAttachment(file.name, bytes));
        widget.onChanged?.call();
      }
    } catch (error) {
      if (mounted) {
        _error = error is StateError
            ? error.message
            : 'Berkas belum dapat dibaca.';
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _view(DraftAttachment file) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(file.name, style: const TextStyle(fontSize: 12)),
      content: SizedBox(
        width: 650,
        height: 450,
        child: file.isImage
            ? Image.memory(
                file.bytes,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Text(
                  'Bukti tidak dapat dibaca. Minta pengganti dari mahasiswa.',
                ),
              )
            : PdfPreview(
                build: (_) async => file.bytes,
                allowPrinting: false,
                canChangePageFormat: false,
                canChangeOrientation: false,
                allowSharing: false,
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        'Bukti pendukung',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      const Text(
        'PDF/JPG/PNG · 1–3 berkas · maksimal 5 MB/berkas. Keabsahan diperiksa BAP, bukan AI.',
        style: TextStyle(fontSize: 11),
      ),
      for (final file in widget.files)
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => _view(file),
                child: Text(file.name),
              ),
            ),
            if (widget.onChanged != null)
              IconButton(
                tooltip: 'Hapus ${file.name}',
                icon: const Icon(Icons.delete_outline),
                onPressed: _busy
                    ? null
                    : () {
                        setState(() => widget.files.remove(file));
                        widget.onChanged!();
                      },
              ),
          ],
        ),
      if (widget.onChanged != null)
        OutlinedButton.icon(
          onPressed: _busy ? null : _pick,
          icon: const Icon(Icons.attach_file),
          label: Text(_busy ? 'Membaca bukti…' : 'Tambah bukti'),
        ),
      if (_error != null)
        Text(_error!, style: const TextStyle(color: AppTheme.red)),
    ],
  );
}
