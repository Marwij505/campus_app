// Usulan AI ditinjau sebelum diterapkan. Teks asli tetap ada bila gagal/dibatalkan.
import 'package:flutter/material.dart';

import 'chat_connection.dart';
import 'draft_language.dart';
import 'ollama_service.dart';

class DraftEditor extends StatefulWidget {
  const DraftEditor({
    super.key,
    required this.readText,
    required this.onApply,
    this.service,
  });
  final String Function() readText;
  final ValueChanged<String> onApply;
  final DraftEditorService? service;
  @override
  State<DraftEditor> createState() => _DraftEditorState();
}

class _DraftEditorState extends State<DraftEditor> {
  late final DraftEditorService _service =
      widget.service ?? OllamaService(addresses: ChatConnection.candidates);
  bool _busy = false;
  String? _notice;
  int _request = 0;

  Future<void> _polish() async {
    if (_busy) return;
    final original = widget.readText();
    if (original.trim().isEmpty) {
      setState(() => _notice = 'Isi alasan atau kronologi terlebih dahulu.');
      return;
    }
    final request = ++_request;
    setState(() {
      _busy = true;
      _notice = null;
    });
    try {
      final revised = await _service.polish(original);
      if (!mounted || request != _request) return;
      if (widget.readText() != original) {
        setState(
          () => _notice = 'Teks sudah berubah. Jalankan penyuntingan lagi untuk teks terbaru.',
        );
        return;
      }
      if (revised == original) {
        setState(
          () => _notice = 'Tidak ada perbaikan bahasa terbatas yang perlu diterapkan. Teks asli tetap digunakan.',
        );
        return;
      }
      final approved = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Tinjau usulan bahasa'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Teks asli',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SelectableText(original),
                  const SizedBox(height: 16),
                  const Text(
                    'Usulan perbaikan',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SelectableText(revised),
                  const SizedBox(height: 16),
                  const Text(
                    'Periksa kembali maknanya. Ini isian manual dan belum dikirim; bukti tetap wajib sebelum pratinjau surat.',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Tetap gunakan asli'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Terapkan usulan'),
            ),
          ],
        ),
      );
      if (!mounted || request != _request) return;
      if (approved == true && widget.readText() == original) {
        widget.onApply(revised);
      }
    } on ChatServiceException catch (e) {
      if (mounted && request == _request) {
        setState(
          () =>
              _notice = '${e.message} Anda tetap dapat memakai template draf.',
        );
      }
    } finally {
      if (mounted && request == _request) setState(() => _busy = false);
    }
  }

  void _cancel() {
    _request++;
    _service.cancel();
    setState(() {
      _busy = false;
      _notice = 'Penyuntingan dibatalkan. Teks asli tetap digunakan.';
    });
  }

  @override
  void dispose() {
    _request++;
    _service.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        'Saat tombol ditekan, hanya teks alasan/kronologi dikirim ke AI lokal untuk perbaikan bahasa terbatas. Identitas, tanggal formulir, dan lampiran tidak ikut dikirim.',
        style: TextStyle(fontSize: 11),
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: _busy ? null : _polish,
        icon: const Icon(Icons.auto_fix_high),
        label: Text(_busy ? 'Menyiapkan usulan…' : 'Rapikan bahasa dengan AI'),
      ),
      if (_busy)
        TextButton(
          onPressed: _cancel,
          child: const Text('Batalkan penyuntingan'),
        ),
      if (_notice != null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(_notice!, style: const TextStyle(fontSize: 11)),
        ),
      const SizedBox(height: 16),
    ],
  );
}
