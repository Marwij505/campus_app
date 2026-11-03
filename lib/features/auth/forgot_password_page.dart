// Pemulihan di aplikasi: minta OTP, isi kode, lalu tentukan password baru.
// Email yang dipakai adalah email Auth pribadi, bukan email kampus pada biodata.
import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../data/auth_service.dart';
import '../../data/password_reset_validation.dart';
import '../../shared/pixel_widgets.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key, required this.service});
  final AuthService service;
  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  Timer? _timer;
  DateTime? _resendAt;
  int _remaining = 0;
  bool _loading = false, _requested = false, _done = false, _success = false;
  String? _message;

  // Jam nyata membuat cooldown tetap berjalan saat aplikasi masuk background.
  void _cooldown() {
    _timer?.cancel();
    _resendAt = DateTime.now().add(const Duration(seconds: 60));
    _remaining = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      final seconds =
          (_resendAt!.difference(DateTime.now()).inMilliseconds / 1000).ceil();
      setState(() => _remaining = seconds.clamp(0, 60));
      if (_remaining == 0) timer.cancel();
    });
  }

  Future<void> _request() async {
    if (_loading || _remaining > 0) return;
    if (!_requested && !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _message = null;
      _success = false;
    });
    try {
      await widget.service.requestReset(_email.text);
      if (!mounted) return;
      setState(() {
        _requested = true;
        _success = true;
        _code.clear();
        _cooldown();
        _message = 'Jika email terdaftar dan memenuhi syarat, kode akan dikirim. Periksa kotak masuk dan spam. Kode berlaku 10 menit.';
      });
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirm() async {
    if (_loading || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _success = false;
      _message = null;
    });
    try {
      await widget.service.confirmReset(
        email: _email.text,
        code: _code.text,
        password: _password.text,
      );
      if (!mounted) return;
      _timer?.cancel();
      // Hapus rahasia dari form; pengguna tetap perlu login dengan password baru.
      _code.clear();
      _password.clear();
      _confirmation.clear();
      setState(() {
        _done = true;
        _success = true;
        _message =
            'Password berhasil diganti. Silakan masuk dengan password baru.';
      });
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    setState(() {
      _success = false;
      _message = error is AuthException
          ? error.message
          : 'Permintaan gagal. Silakan coba lagi.';
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in [_email, _code, _password, _confirmation]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AuthLayout(
    child: AuthWindow(
      fileName: 'RESET_PASSWORD.EXE',
      subtitle: 'PEMULIHAN AKUN',
      title: 'LUPA PASSWORD?',
      onBack: () => Navigator.of(context).pop(),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_done) ...[
              const Text(
                'Gunakan email pribadi yang terdaftar untuk login/pemulihan akun. Email kampus pada biodata bisa berbeda.',
                style: TextStyle(fontSize: 12, color: AppTheme.muted),
              ),
              const SizedBox(height: 22),
              PixelField(
                label: 'EMAIL PRIBADI AKUN',
                hint: 'nama@example.com',
                controller: _email,
                icon: Icons.mail_outline,
                enabled: !_loading && !_requested,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                validator: PasswordResetValidation.emailError,
                onSubmitted: (_) => _request(),
              ),
              if (_requested) ...[
                const SizedBox(height: 18),
                PixelField(
                  label: 'KODE OTP',
                  hint: '6 karakter huruf dan angka',
                  controller: _code,
                  enabled: !_loading,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  validator: PasswordResetValidation.codeError,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Huruf kecil otomatis dibaca sebagai huruf besar. Maksimal 5 percobaan per kode.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                PixelField(
                  label: 'PASSWORD BARU',
                  hint: '12–256 karakter',
                  controller: _password,
                  enabled: !_loading,
                  obscure: true,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: PasswordResetValidation.passwordError,
                ),
                const SizedBox(height: 18),
                PixelField(
                  label: 'ULANGI PASSWORD',
                  hint: 'Ketik kembali password baru',
                  controller: _confirmation,
                  enabled: !_loading,
                  obscure: true,
                  action: TextInputAction.done,
                  onSubmitted: (_) => _confirm(),
                  validator: (value) => value != _password.text
                      ? 'Konfirmasi password belum sama.'
                      : null,
                ),
              ],
              const SizedBox(height: 22),
              PixelButton(
                label: _requested ? 'GANTI PASSWORD' : 'KIRIM KODE OTP',
                loading: _loading,
                onPressed: _requested ? _confirm : _request,
              ),
              if (_requested) ...[
                TextButton(
                  onPressed: _loading || _remaining > 0 ? null : _request,
                  child: Text(
                    _remaining > 0
                        ? 'Kirim ulang dalam $_remaining detik'
                        : 'Kirim ulang kode',
                  ),
                ),
                TextButton(
                  onPressed: _loading
                      ? null
                      : () => setState(() {
                          _requested = false;
                          _message = null;
                          _timer?.cancel();
                          _remaining = 0;
                          _code.clear();
                          _password.clear();
                          _confirmation.clear();
                          _form.currentState?.reset();
                        }),
                  child: const Text('Gunakan email lain'),
                ),
              ],
            ],
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(top: 18),
                child: StatusMessage(message: _message!, success: _success),
              ),
            const SizedBox(height: 14),
            Center(
              child: AuthNavigationLink(
                label: 'Kembali ke login',
                arrowRight: false,
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
