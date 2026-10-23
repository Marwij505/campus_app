// Form mahasiswa dengan pratinjau sebelum diajukan. Data mata kuliah masih manual.
import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../shared/pixel_widgets.dart';
import '../chatbot/chat_controller.dart';
import '../chatbot/draft_editor.dart';
import 'leave_models.dart';
import 'leave_repository.dart';
import 'leave_widgets.dart';

class LeaveForm extends StatefulWidget {
  const LeaveForm({
    super.key,
    required this.repository,
    this.revisionId,
    this.chat,
  });
  final LeaveRepository repository;
  final String? revisionId;
  final ChatController? chat;
  @override
  State<LeaveForm> createState() => _LeaveFormState();
}

class _LeaveFormState extends State<LeaveForm> {
  late final LeaveDraft draft = widget.repository.draft;
  String? _error;
  bool _busy = false;
  int _textVersion = 0;
  Widget _field(String label, {bool multiline = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      key: ValueKey('leave-$label-$_textVersion'),
      initialValue: draft.value(label),
      decoration: InputDecoration(
        labelText: '$label *',
        border: const OutlineInputBorder(),
      ),
      maxLength: multiline ? 2000 : 150,
      minLines: multiline ? 3 : 1,
      maxLines: multiline ? 6 : 2,
      onChanged: (text) => draft.fields[label] = text,
    ),
  );

  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _error = draft.validate(widget.repository.lecturers);
      _busy = _error == null;
    });
    if (!_busy) return;
    try {
      // Bekukan salinan yang diperlihatkan agar sesuai dengan pengajuan yang disimpan.
      final preview = draft.copy();
      final approved = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            'Periksa sebelum diajukan',
            style: TextStyle(fontSize: 14),
          ),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tujuan: BAP (unit pemeriksa izin) · simulasi lokal',
                  ),
                  Text(
                    '${preview.value('Nama')} · ${widget.repository.actor.nim}\n${preview.value('Program studi')}',
                  ),
                  Text(
                    '${preview.value('Tanggal mulai')} s.d. ${preview.value('Tanggal akhir')}\n${preview.value('Jenis izin')}',
                  ),
                  const Divider(),
                  Text(preview.value('Alasan')),
                  for (final item in preview.classes)
                    Text(
                      '${item.course} · ${item.classCode}\n${item.date} → ${item.lecturerCode}',
                    ),
                  Text(
                    'Bukti: ${preview.attachments.map((f) => f.name).join(', ')}',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'BAP memeriksa bukti dan menentukan keputusan. Hasil PDF tersedia bagi mahasiswa dan dosen sesuai kode setelah keputusan final; presensi tidak otomatis diubah.',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Kembali edit'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ajukan ke BAP (simulasi)'),
            ),
          ],
        ),
      );
      if (!mounted || approved != true) return;
      widget.repository.submit(
        draft,
        revisionId: widget.revisionId,
        preview: preview,
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is StateError
              ? error.message
              : 'Pengajuan belum berhasil. Silakan coba lagi.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.repository.session() == null) return const SizedBox.shrink();
    return LeaveShell(
      title: widget.revisionId == null
          ? 'Form Izin Online'
          : 'Perbaikan Izin ${widget.revisionId}',
      chat: widget.chat,
      child: PixelPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const LeaveNotice(),
            Text(
              'NIM akun: ${widget.repository.actor.nim}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text(
              'Nama, program studi, dan perkuliahan diisi manual; belum diverifikasi dari data akademik.',
              style: TextStyle(fontSize: 11),
            ),
            const SizedBox(height: 20),
            _field('Nama'),
            _field('Program studi'),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: draft.value('Jenis izin').isEmpty
                  ? null
                  : draft.value('Jenis izin'),
              decoration: const InputDecoration(
                labelText: 'Jenis izin *',
                border: OutlineInputBorder(),
              ),
              items: [
                'Sakit',
                'Keperluan keluarga',
                'Kegiatan resmi',
                'Lainnya',
              ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (value) => draft.fields['Jenis izin'] = value ?? '',
            ),
            const SizedBox(height: 16),
            for (final label in ['Tanggal mulai', 'Tanggal akhir'])
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: LeaveDateField(
                  label: label,
                  value: draft.value(label),
                  onChanged: (value) =>
                      setState(() => draft.fields[label] = value),
                ),
              ),
            _field('Alasan', multiline: true),
            DraftEditor(
              readText: () => draft.value('Alasan'),
              onApply: (text) => setState(() {
                draft.fields['Alasan'] = text;
                _textVersion++;
              }),
            ),
            const Text(
              'Perkuliahan yang terdampak',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text(
              'Pilih kode dosen yang tepat meskipun namanya sama. Daftar saat ini berisi akun penerima uji.',
              style: TextStyle(fontSize: 11),
            ),
            for (final item in draft.classes)
              Padding(
                key: ObjectKey(item),
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: _classFields(item),
              ),
            OutlinedButton.icon(
              onPressed: draft.classes.length >= 8
                  ? null
                  : () => setState(() => draft.classes.add(LeaveClass())),
              icon: const Icon(Icons.add),
              label: const Text('Tambah perkuliahan'),
            ),
            const SizedBox(height: 20),
            LeaveAttachments(
              files: draft.attachments,
              onChanged: () => setState(() => _error = null),
            ),
            const SizedBox(height: 20),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: AppTheme.red)),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: const Text('Periksa & ajukan izin'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _classFields(LeaveClass item) => Column(
    // Kunci mengikuti perkuliahan, sehingga menghapus baris tidak menukar isi kolom.
    key: ObjectKey(item),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextFormField(
        initialValue: item.course,
        maxLength: 150,
        decoration: const InputDecoration(
          labelText: 'Mata kuliah (kode/nama) *',
          border: OutlineInputBorder(),
        ),
        onChanged: (value) => item.course = value,
      ),
      const SizedBox(height: 12),
      TextFormField(
        initialValue: item.classCode,
        maxLength: 150,
        decoration: const InputDecoration(
          labelText: 'Kode kelas *',
          border: OutlineInputBorder(),
        ),
        onChanged: (value) => item.classCode = value,
      ),
      const SizedBox(height: 12),
      LeaveDateField(
        label: 'Tanggal perkuliahan',
        value: item.date,
        onChanged: (value) => setState(() => item.date = value),
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        initialValue: item.lecturerCode.isEmpty ? null : item.lecturerCode,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Dosen penerima hasil *',
          border: OutlineInputBorder(),
        ),
        items: widget.repository.lecturers
            .map((r) => DropdownMenuItem(value: r.code, child: Text(r.label)))
            .toList(),
        onChanged: (value) => item.lecturerCode = value ?? '',
      ),
      if (draft.classes.length > 1)
        TextButton(
          onPressed: () => setState(() => draft.classes.remove(item)),
          child: const Text('Hapus perkuliahan'),
        ),
      const Divider(),
    ],
  );
}
