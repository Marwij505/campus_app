import 'package:flutter/material.dart';

import '../../core/app_motion.dart';
import '../../core/app_theme.dart';
import '../../data/auth_service.dart';
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

  bool _loading = false;
  bool _success = false;
  String? _message;

  Future<void> _submit() async {
    if (_loading) return;

    FocusScope.of(context).unfocus();

    if (!_form.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _success = false;
      _message = null;
    });

    try {
      await widget.service.requestReset(_email.text.trim());

      if (!mounted) return;

      setState(() {
        _success = true;

        // Jangan mengklaim email sudah dikirim pada layanan demo.
        _message =
            'Simulasi berhasil. Email belum dikirim dan password belum diubah.';
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _message = 'Permintaan gagal. Silakan coba lagi.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AuthLayout(
    // Transisi halaman sudah ditangani AppMotion.route().
    child: AuthWindow(
      fileName: 'RESET_PASSWORD.EXE',
      subtitle: 'PEMULIHAN AKUN',
      title: 'LUPA PASSWORD?',
      onBack: () => Navigator.of(context).pop(),

      child: Form(
        key: _form,

        // Pesan lama dihapus ketika email diperbaiki.
        onChanged: () {
          if (_message != null) {
            setState(() {
              _message = null;
              _success = false;
            });
          }
        },

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan email yang terdaftar pada akun akademikmu.',
              style: TextStyle(fontSize: 12, color: AppTheme.muted),
            ),

            const SizedBox(height: 22),

            PixelField(
              label: 'EMAIL AKADEMIK',
              hint: 'nama@student.kampus.ac.id',
              controller: _email,
              icon: Icons.mail_outline,
              enabled: !_loading,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              action: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              validator: (value) {
                final email = value?.trim() ?? '';

                if (email.isEmpty) {
                  return 'Email wajib diisi.';
                }

                final valid = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                    .hasMatch(email);

                if (!valid) {
                  return 'Alamat email belum valid.';
                }

                return null;
              },
            ),

            const SizedBox(height: 22),

            PixelButton(
              label: 'KIRIM LINK RESET',
              loading: _loading,
              onPressed: _submit,
            ),

            AnimatedSize(
              duration: AppMotion.duration(context, 220),
              child: _message == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(top: 18),
                      child: StatusMessage(
                        message: _message!,
                        success: _success,
                      ),
                    ),
            ),

            const SizedBox(height: 14),

            Center(
              child: TextButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Kembali ke login'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
