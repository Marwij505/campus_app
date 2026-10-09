import 'package:flutter/material.dart';
import '../../core/navigation/app_page_route.dart';
import '../../core/theme/retro_theme.dart';
import '../../core/widgets/retro_auth_widgets.dart';
import '../dashboard/dashboard_page.dart';
import 'forgot_password_page.dart';
import 'services/auth_service.dart';

/// StatefulWidget dipakai karena isi form, checkbox, dan loading dapat berubah.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.authService});
  // Opsional: backend atau layanan test bisa dimasukkan dari luar halaman.
  final AuthService? authService;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _identity = TextEditingController();
  final _password = TextEditingController();
  bool _hidden = true;
  bool _remember = false;
  bool _loading = false;
  String? _error;
  AuthService get _service => widget.authService ?? DemoAuthService.instance;

  Future<void> _login() async {
    // Cegah dua permintaan sekaligus, termasuk dari tombol "done" keyboard.
    if (_loading) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      // Halaman tidak memeriksa database: semua akses data melalui service.
      await _service.login(identity: _identity.text.trim(),
        password: _password.text, rememberSession: _remember);
      // Pengguna mungkin telah meninggalkan halaman selama await.
      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.of(context).pushReplacement(
        AppPageRoute.fadeScale(page: DashboardPage(authService: _service)),
      );
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      // Jangan tampilkan error internal server atau data sensitif ke layar.
      if (mounted) setState(() => _error = 'Tidak dapat masuk. Silakan coba lagi.');
    } finally {
      if (mounted && _loading) setState(() => _loading = false);
    }
  }

  void _openForgotPassword() {
    if (_loading) return;
    Navigator.of(context).push(AppPageRoute.slideFade(
      page: ForgotPasswordPage(authService: _service),
    ));
  }

  @override
  void dispose() {
    // Controller harus dibuang agar tidak terus memakai memori.
    _identity.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RetroAuthScaffold(
    child: RetroEntrance(
      child: RetroWindow(
        fileName: 'SIAKAD.EXE', subtitle: 'SISTEM AKADEMIK',
        title: 'SIAKAD\nFASILKOM',
        child: AutofillGroup(
          child: Form(
            key: _formKey,
            // Hapus error server lama ketika pengguna memperbaiki isian.
            onChanged: () {
              if (_error != null) setState(() => _error = null);
            },
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, children: [
              RetroField(
                label: 'NIM / NIP', hint: 'Masukkan NIM / NIP',
                controller: _identity, icon: Icons.person_outline,
                enabled: !_loading,
                // Text menjaga nol di awal dan mendukung NIP berformat khusus.
                keyboardType: TextInputType.text,
                autofillHints: const [AutofillHints.username],
                validator: (value) => value == null || value.trim().isEmpty
                  ? 'NIM / NIP wajib diisi.' : null,
              ),
              const SizedBox(height: 20),
              RetroField(
                label: 'PASSWORD', hint: 'Masukkan password',
                controller: _password, icon: Icons.lock_outline,
                obscureText: _hidden, enabled: !_loading,
                enableSuggestions: false,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _login(),
                validator: (value) => value == null || value.isEmpty
                  ? 'Password wajib diisi.' : null,
                suffix: IconButton(
                  tooltip: _hidden ? 'Tampilkan password' : 'Sembunyikan password',
                  onPressed: _loading ? null : () => setState(() => _hidden = !_hidden),
                  icon: AnimatedSwitcher(
                    duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero : const Duration(milliseconds: 180),
                    child: Icon(_hidden ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                      key: ValueKey(_hidden), color: RetroTheme.blue, size: 21),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Seluruh baris bisa ditekan: lebih mudah daripada kotak kecil.
              InkWell(
                onTap: _loading ? null : () => setState(() => _remember = !_remember),
                child: Row(children: [
                  Checkbox(value: _remember,
                    onChanged: _loading ? null
                      : (value) => setState(() => _remember = value ?? false)),
                  const Expanded(child: Text('Simpan sesi masuk',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                ]),
              ),
              _buildError(),
              const SizedBox(height: 12),
              RetroButton(label: 'MASUK', loading: _loading, onPressed: _login),
              const SizedBox(height: 19),
              Center(child: TextButton(
                onPressed: _loading ? null : _openForgotPassword,
                style: TextButton.styleFrom(foregroundColor: RetroTheme.ink,
                  minimumSize: const Size(48, 48)),
                child: const Text('Lupa password?', style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                  decorationThickness: 2)),
              )),
              if (_service is DemoAuthService)
                const Center(child: Text('PRATINJAU • AKUN DEMO',
                  style: TextStyle(fontSize: 10, color: RetroTheme.muted))),
            ]),
          ),
        ),
      ),
    ),
  );

  Widget _buildError() => AnimatedSize(
    duration: MediaQuery.disableAnimationsOf(context)
      ? Duration.zero : const Duration(milliseconds: 220),
    curve: Curves.easeOutCubic,
    child: _error == null ? const SizedBox.shrink()
      : Padding(padding: const EdgeInsets.only(top: 10),
          child: RetroNotice(message: _error!)),
  );
}
