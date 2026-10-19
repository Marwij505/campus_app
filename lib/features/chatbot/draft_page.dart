// Form lokal untuk surat izin dan kendala. Keduanya memakai satu kerangka agar ringkas.
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_theme.dart';
import '../../shared/pixel_widgets.dart';
import 'chat_models.dart';
import 'chat_controller.dart';
import 'chat_launcher.dart';

typedef AttachmentPicker = Future<List<XFile>> Function();

class DraftPage extends StatefulWidget {
  const DraftPage({super.key, required this.draft, this.picker, this.chat});
  final StudentDraft draft;
  final ChatController? chat;
  // Pengujian dapat mengganti pemilih berkas tanpa membuka dialog sistem operasi.
  final AttachmentPicker? picker;
  @override
  State<DraftPage> createState() => _DraftPageState();
}

class _DraftPageState extends State<DraftPage> {
  StudentDraft get draft => widget.draft;
  final _preview = TextEditingController();
  final _scroll = ScrollController();
  final _previewKey = GlobalKey();
  String? _error;
  bool _picking = false;

  @override
  void initState() {
    super.initState();
    _preview.text = draft.preview ?? '';
  }

  @override
  void dispose() {
    _preview.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // Pratinjau lama tidak boleh dianggap lengkap setelah isian/lampiran diubah.
  void _invalidate() {
    draft.preview = null;
    _error = null;
  }

  Future<void> _attach() async {
    if (_picking) return;
    setState(() {
      _picking = true;
      _error = null;
    });
    try {
      final files =
          await (widget.picker?.call() ??
              openFiles(
                acceptedTypeGroups: [
                  const XTypeGroup(
                    label: 'Bukti PDF atau gambar',
                    extensions: ['pdf', 'jpg', 'jpeg', 'png'],
                    mimeTypes: ['application/pdf', 'image/jpeg', 'image/png'],
                    uniformTypeIdentifiers: [
                      'com.adobe.pdf',
                      'public.jpeg',
                      'public.png',
                    ],
                  ),
                ],
              ));
      if (!mounted) return;
      for (final file in files) {
        if (draft.attachments.length >= 3) {
          _error = 'Maksimal 3 lampiran per draf.';
          break;
        }
        // Ukuran diperiksa sebelum membaca isi agar berkas besar tidak memenuhi RAM.
        if (await file.length() > 5 * 1024 * 1024) {
          if (!mounted) return;
          _error = 'Ukuran lampiran maksimal 5 MB per berkas.';
          break;
        }
        final bytes = await file.readAsBytes();
        if (!mounted) return;
        final error = DraftAttachment.validate(file.name, bytes);
        if (error != null) {
          _error = error;
          break;
        }
        draft.attachments.add(DraftAttachment(file.name, bytes));
        draft.preview = null;
      }
    } catch (_) {
      if (mounted) _error = 'Berkas belum dapat dibaca. Silakan pilih kembali.';
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _compose() {
    setState(() {
      _error = draft.validate();
      if (_error == null) {
        draft.preview = draft.compose();
        _preview.text = draft.preview!;
      }
    });
    if (_error == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _previewKey.currentContext != null) {
          Scrollable.ensureVisible(_previewKey.currentContext!);
        }
      });
    }
  }

  void _showAttachment(DraftAttachment file) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(file.name, style: const TextStyle(fontSize: 12)),
      content: SizedBox(
        width: 500,
        child: file.isImage
            ? Image.memory(
                file.bytes,
                cacheWidth: 1000,
                fit: BoxFit.contain,
                errorBuilder: (_, error, stack) => const Text(
                  'Gambar tidak dapat ditampilkan. Ganti dengan berkas yang dapat dibaca.',
                ),
              )
            : Text(
                'PDF dipilih (${(file.bytes.length / 1024).ceil()} KB). Isi PDF dan keaslian bukti belum diperiksa.',
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
  Widget build(BuildContext context) {
    final fields = draft.kind == DraftKind.letter
        ? [
            'Nama',
            'NIM',
            'Penerima',
            'Tanggal mulai',
            'Tanggal akhir',
            'Alasan',
          ]
        : ['Nama', 'NIM', 'Kategori', 'Ringkasan', 'Kronologi'];
    return Scaffold(
      floatingActionButton: widget.chat == null
          ? null
          : ChatLauncher(controller: widget.chat!),
      appBar: AppBar(
        title: Text(draft.title, style: const TextStyle(fontSize: 14)),
        backgroundColor: AppTheme.red,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const CampusBackground(dashboard: true),
          SafeArea(
            child: SingleChildScrollView(
              controller: _scroll,
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                widget.chat == null ? 16 : 96,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 850),
                  child: PixelPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'DRAF LOKAL · BELUM DIKIRIM',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.blue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Identitas diisi manual dan belum diverifikasi kampus. Draf hanya tersimpan selama sesi login. Lampiran tidak diunggah ke AI atau kampus.',
                          style: TextStyle(fontSize: 11),
                        ),
                        const SizedBox(height: 20),
                        for (final field in fields)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: TextFormField(
                              key: ValueKey('draft-$field'),
                              initialValue: draft.fields[field],
                              minLines:
                                  field == 'Alasan' || field == 'Kronologi'
                                  ? 3
                                  : 1,
                              maxLines:
                                  field == 'Alasan' || field == 'Kronologi'
                                  ? 6
                                  : 2,
                              maxLength:
                                  field == 'Alasan' || field == 'Kronologi'
                                  ? 2000
                                  : 150,
                              decoration: InputDecoration(
                                labelText: '$field *',
                                hintText: field.startsWith('Tanggal')
                                    ? 'YYYY-MM-DD'
                                    : null,
                                border: const OutlineInputBorder(),
                              ),
                              onChanged: (value) => setState(() {
                                draft.fields[field] = value;
                                _invalidate();
                              }),
                            ),
                          ),
                        Text(
                          draft.kind == DraftKind.letter
                              ? 'Bukti wajib sebelum pratinjau surat'
                              : 'Lampiran pendukung (opsional)',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'PDF, JPG, PNG · maksimal 5 MB/berkas · 3 berkas. Batas teknis prototipe, bukan ketentuan resmi kampus.',
                          style: TextStyle(fontSize: 11),
                        ),
                        for (final file in draft.attachments)
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => _showAttachment(file),
                                  child: Text(file.name),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Hapus ${file.name}',
                                onPressed: () => setState(() {
                                  draft.attachments.remove(file);
                                  _invalidate();
                                }),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        OutlinedButton.icon(
                          onPressed: _picking ? null : _attach,
                          icon: const Icon(Icons.attach_file),
                          label: Text(
                            _picking ? 'Membaca berkas…' : 'Tambah lampiran',
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              _error!,
                              style: const TextStyle(color: AppTheme.red),
                            ),
                          ),
                        FilledButton(
                          onPressed: _picking ? null : _compose,
                          child: const Text('Buat pratinjau draf'),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Kembali ke chat'),
                        ),
                        if (draft.preview != null) ...[
                          const SizedBox(height: 24),
                          TextField(
                            key: _previewKey,
                            controller: _preview,
                            minLines: 8,
                            maxLines: null,
                            decoration: const InputDecoration(
                              labelText: 'Pratinjau draf · dapat diedit',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) => draft.preview = value,
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(text: _preview.text),
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Draf disalin. Belum dikirim.',
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.copy),
                            label: const Text('Salin draf'),
                          ),
                          const Text(
                            'Pengiriman dan persetujuan kampus belum tersedia.',
                            style: TextStyle(fontSize: 11),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
