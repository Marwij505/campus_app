// Halaman dipakai oleh sesi pemulihan valid atau pengguna yang sedang login.
import 'package:flutter/material.dart';

import '../../data/password_reset_validation.dart';

import '../../data/auth_service.dart';
import '../chatbot/chat_controller.dart';
import '../dashboard/dashboard_detail_page.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key, required this.service, this.chat});
  final AuthService service;
  final ChatController? chat;
  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _password = TextEditingController(),
      _confirmation = TextEditingController();
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    final error = PasswordResetValidation.passwordError(_password.text);
    if (error != null || _password.text != _confirmation.text) {
      setState(() => _error = error ?? 'Konfirmasi password harus sama.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.service.changePassword(_password.text);
      if (mounted) {
        _password.clear();
        _confirmation.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password diperbarui. Silakan masuk kembali.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is AuthException ? e.message : 'Hasil perubahan password belum dapat dipastikan. Coba masuk dengan password baru atau gunakan pemulihan akun.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => DashboardDetailPage(
    title: 'Ubah password',
    chat: widget.chat,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Gunakan password unik 12–256 karakter. Setelah berhasil, masuk kembali dengan password baru.',
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _password,
          obscureText: true,
          enabled: !_busy,
          decoration: const InputDecoration(labelText: 'Password baru'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirmation,
          obscureText: true,
          enabled: !_busy,
          decoration: const InputDecoration(labelText: 'Konfirmasi password'),
        ),
        if (_error != null)
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: Text(_busy ? 'Memproses…' : 'Simpan password'),
        ),
        TextButton(
          onPressed: _busy ? null : widget.service.logout,
          child: const Text('Keluar'),
        ),
      ],
    ),
  );
}
