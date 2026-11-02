// Riwayat keuangan hanya dibaca. Berkas selalu diambil dengan sesi pengguna.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/biodata_repository.dart';
import '../../data/profile_repository.dart';
import '../dashboard/dashboard_detail_page.dart';
import '../chatbot/chat_controller.dart';

class ProfileRecords extends StatefulWidget {
  const ProfileRecords({
    super.key,
    required this.repository,
    required this.documents,
    this.chat,
  });
  final BiodataRepository repository;
  final bool documents;
  final ChatController? chat;
  @override
  State<ProfileRecords> createState() => _ProfileRecordsState();
}

class _ProfileRecordsState extends State<ProfileRecords> {
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true, _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = widget.documents
          ? await widget.repository.documents()
          : await widget.repository.finance();
      if (mounted) _rows = rows;
    } catch (_) {
      if (mounted) _error = 'Data belum dapat dimuat. Periksa koneksi atau masuk ulang bila sesi habis.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _action(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      if (mounted) await _load();
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is ProfileException
              ? e.message
              : 'Operasi gagal. Periksa koneksi lalu coba lagi.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _upload(String kind, Map<String, dynamic>? previous) async {
    final file = await openFile(
      acceptedTypeGroups: [
        const XTypeGroup(
          label: 'Berkas persyaratan',
          extensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc'],
          mimeTypes: [
            'application/pdf',
            'image/jpeg',
            'image/png',
            'application/msword',
          ],
          uniformTypeIdentifiers: ['public.data'],
        ),
      ],
    );
    if (file == null || !mounted) return;
    if (await file.length() > 512 * 1024) {
      throw const ProfileException('Berkas maksimal 0,5 MB.');
    }
    await widget.repository.uploadDocument(
      kind,
      file.name,
      await file.readAsBytes(),
      previous,
    );
  }

  Future<void> _download(Map<String, dynamic> row) async {
    final bytes = await widget.repository.downloadDocument(row);
    final name = BiodataRepository.safeDocumentName(
      row['file_name'] as String,
      row['mime_type'] as String,
    );
    final file = XFile.fromData(
      bytes,
      name: name,
      mimeType: row['mime_type'] as String,
    );
    // Browser memakai unduhan native; desktop menampilkan pemilih lokasi simpan.
    if (kIsWeb) {
      await file.saveTo(name);
      return;
    }
    // Android/iOS tidak memiliki getSaveLocation. Pengguna memilih tujuan sendiri.
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox;
      await SharePlus.instance.share(
        ShareParams(
          files: [file],
          fileNameOverrides: [name],
          sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
        ),
      );
      return;
    }
    final location = await getSaveLocation(suggestedName: name);
    if (location != null) await file.saveTo(location.path);
  }

  Future<void> _delete(Map<String, dynamic> row) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus berkas?'),
        content: Text(row['file_name'] as String),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (yes == true) await widget.repository.deleteDocument(row);
  }

  Widget _documents() => LayoutBuilder(
    builder: (context, bounds) {
      final two =
          bounds.maxWidth >= 650 &&
          MediaQuery.textScalerOf(context).scale(1) < 1.5;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final entry in BiodataRepository.documentKinds.entries)
            SizedBox(
              width: two ? (bounds.maxWidth - 16) / 2 : bounds.maxWidth,
              child: Builder(
                builder: (context) {
                  final row = _rows
                      .where((r) => r['kind'] == entry.key)
                      .firstOrNull;
                  return Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FBFD),
                      border: Border(
                        left: BorderSide(
                          width: 4,
                          color: row == null ? Colors.orange : Colors.green,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.value,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          row == null ? 'Belum ada' : 'Terunggah',
                          style: TextStyle(
                            color: row == null
                                ? Colors.blueGrey
                                : const Color(0xFF08773C),
                          ),
                        ),
                        const Text(
                          'PDF, JPG, PNG, DOC · maksimal 0,5 MB',
                          style: TextStyle(fontSize: 11),
                        ),
                        if (entry.key == 'passport')
                          const Text(
                            'Paspor bagi WNA.',
                            style: TextStyle(fontSize: 11),
                          ),
                        if (entry.key == 'payment_statement')
                          const Text(
                            'Template resmi belum disediakan kampus.',
                            style: TextStyle(fontSize: 11),
                          ),
                        if (row != null) ...[
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () => _action(() => _download(row)),
                            child: Text(row['file_name'] as String),
                          ),
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () => _action(() => _delete(row)),
                            child: const Text(
                              'Hapus file',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                        OutlinedButton.icon(
                          onPressed: _busy
                              ? null
                              : () => _action(() => _upload(entry.key, row)),
                          icon: const Icon(Icons.upload_file),
                          label: Text(
                            row == null ? 'Pilih berkas' : 'Ganti berkas',
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      );
    },
  );

  String _money(num value) =>
      'Rp ${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.')}';
  Widget _totals(List<Map<String, dynamic>> rows) {
    final total = rows.fold<num>(0, (s, r) => s + (r['amount'] as num));
    final paid = rows.fold<num>(0, (s, r) => s + (r['paid'] as num));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 24,
          runSpacing: 12,
          children: [
            for (final pair in [
              ('Total tagihan', total),
              ('Sudah dibayar', paid),
              ('Sisa tagihan', total - paid),
            ])
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pair.$1, style: const TextStyle(fontSize: 11)),
                  Text(
                    _money(pair.$2),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 14),
        LinearProgressIndicator(
          value: total == 0 ? 0 : paid / total,
          color: const Color(0xFF0C9A4C),
        ),
      ],
    );
  }

  Widget _finance() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        'Halaman ini menampilkan riwayat tagihan. Pembayaran dilakukan melalui menu Pembayaran.',
      ),
      const SizedBox(height: 20),
      if (_rows.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Text(
            'Belum ada riwayat keuangan. Tagihan akan tampil setelah diterbitkan kampus.',
          ),
        )
      else ...[
        _totals(_rows),
        const SizedBox(height: 24),
        for (final period in _rows.map((r) => r['period'] as String).toSet())
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFDFE6EF)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  period,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF155BC0),
                  ),
                ),
                const Divider(),
                for (final category
                    in _rows
                        .where((r) => r['period'] == period)
                        .map((r) => r['category'])
                        .toSet()) ...[
                  for (final row in _rows.where(
                    (r) => r['period'] == period && r['category'] == category,
                  ))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row['description'] as String,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${(row['paid'] as num) >= (row['amount'] as num) ? 'Lunas' : 'Belum lunas'} · Tagihan ${row['billed_on']}',
                          ),
                          if (row['due_on'] != null)
                            Text('Jatuh tempo ${row['due_on']}'),
                          if (row['paid_on'] != null)
                            Text('Dibayar ${row['paid_on']}'),
                          Text(_money(row['amount'] as num)),
                        ],
                      ),
                    ),
                  Text(
                    'Subtotal $category',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  _totals(
                    _rows
                        .where(
                          (r) =>
                              r['period'] == period &&
                              r['category'] == category,
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
      ],
      Align(
        alignment: Alignment.centerRight,
        child: FilledButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) =>
                  DashboardDetailPage.empty('Pembayaran', chat: widget.chat),
            ),
          ),
          icon: const Icon(Icons.payments_outlined),
          label: const Text('Buka Pembayaran'),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            widget.documents ? 'Berkas persyaratan' : 'Riwayat keuangan',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextButton.icon(
            onPressed: _loading || _busy ? null : _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Muat ulang'),
          ),
        ],
      ),
      const Divider(height: 30),
      if (widget.documents)
        const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: Text(
            'Berkas langsung disimpan setelah dipilih. Mengganti berkas hanya menghapus versi lama setelah unggahan baru berhasil.',
          ),
        ),
      if (_loading || _busy) const LinearProgressIndicator(),
      if (_error != null)
        Text(_error!, style: const TextStyle(color: Colors.red)),
      if (!_loading && _error == null)
        widget.documents ? _documents() : _finance(),
    ],
  );
}
