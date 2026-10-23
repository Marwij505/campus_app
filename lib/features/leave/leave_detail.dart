// Halaman pemeriksaan dan hasil. Hak akses tetap dicek repository pada tiap aksi.
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../core/app_motion.dart';
import '../../core/app_theme.dart';
import '../../data/student_profile.dart';
import '../../shared/pixel_widgets.dart';
import '../chatbot/chat_controller.dart';
import 'leave_form.dart';
import 'leave_models.dart';
import 'leave_repository.dart';
import 'leave_widgets.dart';

class LeaveDetail extends StatefulWidget {
  const LeaveDetail({
    super.key,
    required this.repository,
    required this.id,
    this.chat,
  });
  final LeaveRepository repository;
  final String id;
  final ChatController? chat;
  @override
  State<LeaveDetail> createState() => _LeaveDetailState();
}

class _LeaveDetailState extends State<LeaveDetail> {
  final _note = TextEditingController();
  LeaveStatus? _decision;
  bool _checked = false, _busy = false;
  String? _error;
  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _review() async {
    if (_busy) return;
    if (_decision == null || !_checked || _note.text.trim().isEmpty) {
      setState(
        () => _error =
            'Pilih keputusan, periksa bukti/penerima, dan isi catatan BAP.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final decision = _decision!;
    final note = _note.text.trim();
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            'Konfirmasi keputusan BAP',
            style: TextStyle(fontSize: 14),
          ),
          content: SingleChildScrollView(
            child: Text(
              '${decision.label}\n\n$note\n\n${decision == LeaveStatus.revision ? 'Mahasiswa diminta memperbaiki; belum ada hasil final untuk dosen.' : 'PDF hasil keputusan akan tersedia bagi mahasiswa dan dosen tujuan dalam simulasi lokal.'}',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Simpan keputusan'),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;
      await widget.repository.review(
        widget.id,
        decision,
        note,
        evidenceChecked: _checked,
      );
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is StateError ? error.message : 'Hasil PDF belum berhasil dibuat. Keputusan belum disimpan; coba lagi.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _download() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final row = widget.repository.read(widget.id);
      if (row.resultPdf == null) throw StateError('Hasil PDF belum tersedia.');
      await Printing.sharePdf(
        bytes: row.resultPdf!,
        filename: '${row.id}-v${row.version}-hasil-simulasi.pdf',
      );
      // Membuka dialog berbagi bukan bukti dokumen terkirim ke pihak lain.
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'PDF belum dapat diunduh/dibagikan. Silakan coba kembali.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.repository,
    builder: (context, _) {
      final user = widget.repository.session();
      if (user == null) return const SizedBox.shrink();
      final row = widget.repository.read(widget.id);
      return LeaveShell(
        title: 'Izin ${row.id}',
        chat: widget.chat,
        child: PixelPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const LeaveNotice(),
              Text(
                '${row.status.label} · versi ${row.version}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.blue,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${row.draft.value('Nama')} · ${row.studentId}\n${row.draft.value('Program studi')}',
              ),
              Text(
                '${row.draft.value('Jenis izin')}\n${row.draft.value('Tanggal mulai')} s.d. ${row.draft.value('Tanggal akhir')}',
              ),
              const SizedBox(height: 12),
              Text(row.draft.value('Alasan')),
              const Divider(),
              for (final item in row.draft.classes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    '${item.course} · kelas ${item.classCode}\n${item.date} · dosen ${item.lecturerCode}',
                  ),
                ),
              if (user.role != UserRole.lecturer)
                LeaveAttachments(files: row.draft.attachments),
              if (row.note.isNotEmpty) ...[
                const Divider(),
                Text('Catatan BAP (${row.reviewer}):\n${row.note}'),
              ],
              if (user.role == UserRole.bap &&
                  row.status == LeaveStatus.pending) ...[
                const Divider(),
                CheckboxListTile(
                  value: _checked,
                  contentPadding: EdgeInsets.zero,
                  onChanged: _busy
                      ? null
                      : (value) => setState(() => _checked = value ?? false),
                  title: const Text(
                    'Saya sudah memeriksa bukti, tanggal, dan kode penerima dosen.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                DropdownButtonFormField<LeaveStatus>(
                  initialValue: _decision,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Keputusan BAP *',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      [
                            LeaveStatus.approved,
                            LeaveStatus.rejected,
                            LeaveStatus.revision,
                          ]
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(s.label),
                            ),
                          )
                          .toList(),
                  onChanged: _busy
                      ? null
                      : (value) => setState(() => _decision = value),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _note,
                  maxLength: 2000,
                  minLines: 3,
                  maxLines: 8,
                  enabled: !_busy,
                  decoration: const InputDecoration(
                    labelText: 'Catatan pemeriksaan / alasan keputusan *',
                    border: OutlineInputBorder(),
                  ),
                ),
                FilledButton(
                  onPressed: _busy ? null : _review,
                  child: Text(_busy ? 'Memproses…' : 'Tinjau keputusan'),
                ),
              ],
              if (user.role == UserRole.student &&
                  row.status == LeaveStatus.revision)
                FilledButton(
                  onPressed: () {
                    widget.repository.revise(row.id);
                    Navigator.push(
                      context,
                      AppMotion.route(
                        LeaveForm(
                          repository: widget.repository,
                          revisionId: row.id,
                          chat: widget.chat,
                        ),
                      ),
                    );
                  },
                  child: const Text('Perbaiki & ajukan ulang'),
                ),
              if (row.resultPdf != null) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _busy ? null : _download,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Unduh / bagikan hasil PDF'),
                ),
                const Text(
                  'Mahasiswa dapat meneruskan file secara manual. Tombol ini tidak menandai dokumen sebagai terkirim atau mengubah presensi.',
                  style: TextStyle(fontSize: 11),
                ),
                Text(
                  'Kotak masuk dosen tujuan: ${row.recipients.join(', ')}\nDibaca oleh: ${row.readBy.isEmpty ? 'Belum ditandai dibaca' : row.readBy.join(', ')}',
                ),
                if (user.role == UserRole.lecturer &&
                    !row.readBy.contains(user.nim))
                  OutlinedButton(
                    onPressed: () => widget.repository.markRead(row.id),
                    child: const Text('Tandai hasil sudah dibaca'),
                  ),
              ],
              if (_error != null)
                Text(_error!, style: const TextStyle(color: AppTheme.red)),
              const Divider(),
              const Text(
                'Riwayat proses',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              for (final event in row.events)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${event.at.toLocal()} · ${event.actor}\n${event.description}',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}
