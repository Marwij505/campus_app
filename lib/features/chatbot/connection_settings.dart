// Form kecil untuk mengganti alamat jika komputer pindah Wi-Fi atau IP berubah.
import 'package:flutter/material.dart';

import 'chat_connection.dart';
import 'chat_controller.dart';
import 'ollama_service.dart';

Future<void> showConnectionSettings(
  BuildContext context,
  ChatController chat,
) async {
  final saved = await ChatConnection.savedAddress();
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (_) => _ConnectionSettings(chat: chat, initial: saved),
  );
}

class _ConnectionSettings extends StatefulWidget {
  const _ConnectionSettings({required this.chat, required this.initial});
  final ChatController chat;
  final String initial;
  @override
  State<_ConnectionSettings> createState() => _ConnectionSettingsState();
}

class _ConnectionSettingsState extends State<_ConnectionSettings> {
  late final _address = TextEditingController(text: widget.initial);
  String? _error;
  bool _saving = false;

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final value = _address.text.trim();
      if (value.isNotEmpty) OllamaService.validateAddress(value);
      await ChatConnection.saveAddress(value);
      if (!mounted) return;
      widget.chat.useGuided();
      widget.chat.enableAi();
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e is ChatServiceException
              ? e.message
              : 'Alamat belum dapat disimpan. Coba lagi.';
        });
      }
    }
  }

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Koneksi AI lokal'),
    content: SizedBox(
      width: 380,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kosongkan untuk otomatis. Untuk HP, gunakan Wi-Fi yang sama dengan komputer AI. Alamat komputer ditampilkan oleh start.ps1.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _address,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: 'Alamat komputer AI',
                hintText: 'http://192.168.1.10:11435',
                errorText: _error,
                errorMaxLines: 4,
              ),
            ),
            if (widget.chat.connectedAddress != null) ...[
              const SizedBox(height: 12),
              Text('Terhubung: ${widget.chat.connectedAddress}'),
            ],
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context),
        child: const Text('Batal'),
      ),
      FilledButton(
        onPressed: _saving ? null : _save,
        child: const Text('Simpan & sambungkan'),
      ),
    ],
  );
}
