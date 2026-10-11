import 'package:flutter/material.dart';

import '../../core/app_motion.dart';
import '../../core/app_theme.dart';
import '../../data/auth_service.dart';
import '../../data/student_profile.dart';
import '../../shared/pixel_widgets.dart';
import 'forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.service, required this.onLogin});

  final AuthService service;
  final ValueChanged<StudentProfile> onLogin;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _identity = TextEditingController();
  final _password = TextEditingController();

  bool _hidden = true;
  bool _remember = false;
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    // Cegah submit ganda dari tombol maupun keyboard.
    if (_loading) return;

    FocusScope.of(context).unfocus();

    if (!_form.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final student = await widget.service.login(
        identity: _identity.text.trim(),
        password: _password.text,
        rememberSession: _remember,
      );

      // Halaman mungkin sudah ditutup ketika proses async selesai.
      if (!mounted) return;

      widget.onLogin(student);
    } on AuthException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Tidak dapat masuk. Coba lagi.';
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
    // Lepaskan controller agar tidak terus menggunakan memori.
    _identity.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AuthLayout(
    child: Entrance(
      child: AuthWindow(
        fileName: 'SIAKAD.EXE',
        subtitle: 'SISTEM AKADEMIK',
        title: 'SIAKAD FASILKOM',

        child: AutofillGroup(
          child: Form(
            key: _form,

            // Hapus pesan server lama ketika pengguna memperbaiki isian.
            onChanged: () {
              if (_error != null) {
                setState(() {
                  _error = null;
                });
              }
            },

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PixelField(
                  label: 'NIM / NIP',
                  hint: 'Masukkan NIM / NIP',
                  controller: _identity,
                  icon: Icons.person_outline,
                  enabled: !_loading,
                  autofillHints: const [AutofillHints.username],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'NIM / NIP wajib diisi.';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                PixelField(
                  label: 'PASSWORD',
                  hint: 'Masukkan password',
                  controller: _password,
                  obscure: _hidden,
                  enabled: !_loading,
                  autofillHints: const [AutofillHints.password],
                  action: TextInputAction.done,
                  onSubmitted: (_) => _login(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password wajib diisi.';
                    }
                    return null;
                  },

                  suffix: IconButton(
                    tooltip: _hidden
                        ? 'Tampilkan password'
                        : 'Sembunyikan password',
                    onPressed: _loading
                        ? null
                        : () {
                            setState(() {
                              _hidden = !_hidden;
                            });
                          },
                    icon: AnimatedSwitcher(
                      duration: AppMotion.duration(context, 160),
                      child: Icon(
                        _hidden
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        key: ValueKey(_hidden),
                        color: AppTheme.blue,
                        size: 20,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                // Area sentuh tetap cukup besar, meski checkbox tampil kecil.
                InkWell(
                  onTap: _loading
                      ? null
                      : () => setState(() => _remember = !_remember),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 32,
                        height: 44,
                        child: Checkbox(
                          value: _remember,
                          activeColor: const Color(0xFF19BD5C),
                          shape: const RoundedRectangleBorder(),
                          onChanged: _loading
                              ? null
                              : (value) =>
                                    setState(() => _remember = value ?? false),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'Simpan sesi masuk',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Tinggi area pesan berubah secara halus.
                AnimatedSize(
                  duration: AppMotion.duration(context, 220),
                  child: _error == null
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: StatusMessage(message: _error!),
                        ),
                ),

                const SizedBox(height: 8),

                PixelButton(
                  label: 'MASUK',
                  loading: _loading,
                  onPressed: _login,
                ),

                const SizedBox(height: 14),

                Center(
                  child: TextButton(
                    onPressed: _loading
                        ? null
                        : () {
                            Navigator.of(context).push(
                              AppMotion.route(
                                ForgotPasswordPage(service: widget.service),
                              ),
                            );
                          },
                    child: const Text(
                      'Lupa password?',
                      style: TextStyle(
                        color: AppTheme.ink,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
