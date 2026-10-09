import 'package:flutter/material.dart';
import '../../core/theme/retro_theme.dart';
import '../../core/widgets/retro_auth_widgets.dart';
import 'services/auth_service.dart';

/// Mengikuti gaya login karena halaman kedua PDF belum terlampir.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key, this.authService});
  final AuthService? authService;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _loading = false;
  bool _success = false;
  String? _message;
  AuthService get _service => widget.authService ?? DemoAuthService.instance;

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email wajib diisi.';
    // Pemeriksaan sederhana untuk UI. Server tetap harus memvalidasi ulang.
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Masukkan alamat email yang valid.';
    }
    return null;
  }

  Future<void> _sendResetLink() async {
    if (_loading) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _message = null; _success = false; });
    try {
      await _service.requestPasswordReset(_email.text.trim());
      if (!mounted) return;
      setState(() {
        _success = true;
        // Jangan mengklaim email telah dikirim pada implementasi demo.
        _message = _service is DemoAuthService
          ? 'Simulasi selesai. Email belum dikirim dan password belum diubah.'
          : 'Jika email terdaftar, instruksi reset akan dikirim. Periksa inbox dan spam.';
      });
    } on AuthException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } catch (_) {
      if (mounted) setState(() => _message = 'Permintaan gagal. Silakan coba lagi.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RetroAuthScaffold(
    child: RetroEntrance(
      child: RetroWindow(
        fileName: 'RESET_PASSWORD.EXE', subtitle: 'PEMULIHAN AKUN',
        title: 'LUPA\nPASSWORD?',
        // Navigator.pop memainkan transisi masuk dalam arah sebaliknya.
        onBack: () => Navigator.of(context).pop(),
        child: Form(
          key: _formKey,
          // Pesan lama tidak ikut terbawa ketika alamat email diperbaiki.
          onChanged: () {
            if (_message != null) {
              setState(() { _message = null; _success = false; });
            }
          },
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, children: [
            const Text('Tenang, aksesmu bisa dipulihkan.', style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Masukkan email yang terdaftar pada akun akademikmu '
              'untuk meminta tautan reset password.',
              style: TextStyle(fontSize: 13, height: 1.6, color: RetroTheme.muted)),
            const SizedBox(height: 22),
            RetroField(
              label: 'EMAIL AKADEMIK', hint: 'nama@student.kampus.ac.id',
              controller: _email, validator: _validateEmail,
              icon: Icons.mail_outline, enabled: !_loading,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _sendResetLink(),
            ),
            const SizedBox(height: 22),
            RetroButton(label: 'KIRIM LINK RESET', icon: Icons.send_outlined,
              loading: _loading, onPressed: _sendResetLink),
            const SizedBox(height: 18),
            AnimatedSize(
              duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero : const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              child: _message == null ? const SizedBox.shrink()
                : Padding(padding: const EdgeInsets.only(bottom: 8),
                    child: RetroNotice(message: _message!, success: _success)),
            ),
            Center(child: TextButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(foregroundColor: RetroTheme.ink,
                minimumSize: const Size(48, 48)),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Kembali ke login', style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700)),
            )),
          ]),
        ),
      ),
    ),
  );
}
