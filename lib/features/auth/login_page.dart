import 'package:flutter/material.dart';
import '../../core/navigation/app_page_route.dart';
import '../dashboard/dashboard_page.dart';
import 'forgot_password_page.dart';

/// ============================================================
/// LOGIN PAGE
/// ============================================================
///
/// Pembagian analogi:
/// - Widget / build()     ≈ HTML
/// - Decoration / Style  ≈ CSS
/// - State / Function    ≈ JavaScript
/// - AuthService nanti   ≈ Backend/API
///
/// Tetap memakai konsep 50:50 hybrid:
/// tidak semua di main.dart, tapi juga tidak memecah
/// widget kecil menjadi banyak file.
/// ============================================================
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final _identityController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;

  /// ==========================================================
  /// LOGIN
  /// ==========================================================
  /// ==========================================================
  
  Future<void> _login() async {
    // Tutup keyboard.
    FocusScope.of(context).unfocus();

    // ==========================================================
    // VALIDASI FORM
    // ==========================================================

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // ==========================================================
    // SIMULASI PROSES SERVER
    // ==========================================================
    //
    // Supaya loading animation terlihat.
    //
    // Nantinya bagian ini diganti:
    //
    // Flutter
    //    ↓
    // Laravel API
    //    ↓
    // MySQL
    //
    await Future.delayed(
      const Duration(milliseconds: 900),
    );

    if (!mounted) return;

    // ==========================================================
    // DUMMY ACCOUNT
    // ==========================================================

    const dummyNim = '20240801001';
    const dummyPassword = '123456';

    final identity =
        _identityController.text.trim();

    final password =
        _passwordController.text;

    // Cek apakah credential sesuai.
    final isLoginValid =
        identity == dummyNim &&
        password == dummyPassword;

    // ==========================================================
    // LOGIN GAGAL
    // ==========================================================

    if (!isLoginValid) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'NIM / NIDN / Email atau password salah.',
          ),

          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    // ==========================================================
    // LOGIN BERHASIL
    // ==========================================================

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    // pushReplacement:
    //
    // Login
    //    ↓
    // Dashboard
    //
    // User tidak kembali ke Login hanya dengan tombol Back.
    Navigator.of(context).pushReplacement(
      AppPageRoute.fadeScale(
        page: const DashboardPage(),
      ),
    );
  }

  /// ==========================================================
  /// FORGOT PASSWORD
  /// ==========================================================
  void _openForgotPassword() {
    Navigator.of(context).push(
      AppPageRoute.slideFade(
        page: const ForgotPasswordPage(),
        beginOffset: const Offset(0.08, 0),
      ),
    );
  }

  @override
  void dispose() {
    _identityController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// ==========================================================
  /// ROOT UI
  /// ==========================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TweenAnimationBuilder<double>(
        // Entrance animation saat Login pertama tampil.
        tween: Tween<double>(
          begin: 0,
          end: 1,
        ),
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(
                0,
                18 * (1 - value),
              ),
              child: child,
            ),
          );
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 900;

            if (isDesktop) {
              return _buildDesktopLayout();
            }

            return _buildMobileLayout();
          },
        ),
      ),
    );
  }

  /// ==========================================================
  /// MOBILE LAYOUT
  /// ==========================================================
  Widget _buildMobileLayout() {
    return Container(
      color: const Color(0xFFF5F8FC),
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildMobileHeader(),
              Transform.translate(
                offset: const Offset(0, -30),
                child: _buildMobileLoginCard(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ==========================================================
  /// MOBILE HEADER
  /// ==========================================================
  Widget _buildMobileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        24,
        48,
        24,
        72,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF32A7F5),
            Color(0xFF167EE8),
            Color(0xFF0759CF),
          ],
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.school_rounded,
              size: 52,
              color: Color(0xFF126FD6),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'SIAKAD',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Sistem Informasi Akademik',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Fakultas Ilmu Komputer',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// ==========================================================
  /// MOBILE LOGIN CARD
  /// ==========================================================
  Widget _buildMobileLoginCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(
        26,
        38,
        26,
        32,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0C3A70).withValues(alpha: 0.10),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: _buildLoginForm(
        mobile: true,
      ),
    );
  }

  /// ==========================================================
  /// DESKTOP LAYOUT
  /// ==========================================================
  Widget _buildDesktopLayout() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFF4F7FB),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1080,
            ),
            child: Container(
              constraints: const BoxConstraints(
                minHeight: 650,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 40,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: _buildDesktopBrandSection(),
                    ),
                    Expanded(
                      flex: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(58),
                        child: _buildLoginForm(
                          mobile: false,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ==========================================================
  /// DESKTOP BRAND
  /// ==========================================================
  Widget _buildDesktopBrandSection() {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 650,
      ),
      padding: const EdgeInsets.all(56),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF33AAF7),
            Color(0xFF197FE5),
            Color(0xFF0758CC),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.school_rounded,
              size: 54,
              color: Color(0xFF126FD6),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'SIAKAD',
            style: TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sistem Informasi Akademik',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Fakultas Ilmu Komputer',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 30),
          Container(
            width: 55,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 30),
          Text(
            'Satu akses untuk berbagai layanan '
            'akademik Fakultas Ilmu Komputer.',
            style: TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  /// ==========================================================
  /// LOGIN FORM
  /// ==========================================================
  ///
  /// Form yang sama dipakai Mobile + Desktop.
  /// Ini contoh 50:50 hybrid:
  /// reusable secukupnya, tidak over-splitting.
  Widget _buildLoginForm({
    required bool mobile,
  }) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: mobile
            ? MainAxisSize.min
            : MainAxisSize.max,
        children: [
          Center(
            child: Text(
              'Selamat Datang',
              style: TextStyle(
                fontSize: mobile ? 31 : 36,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF071A42),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              'Masuk untuk mengakses layanan\n'
              'akademik fakultas',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: mobile ? 15 : 16,
                height: 1.45,
                color: const Color(0xFF7A849B),
              ),
            ),
          ),
          SizedBox(
            height: mobile ? 34 : 42,
          ),

          // NIM / NIDN / EMAIL
          TextFormField(
            controller: _identityController,
            keyboardType: TextInputType.emailAddress,
            decoration: _inputDecoration(
              hint: 'NIM / NIDN / Email',
              icon: Icons.person_outline_rounded,
            ),
            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return 'NIM / NIDN / Email wajib diisi.';
              }
              return null;
            },
          ),

          const SizedBox(height: 18),

          // PASSWORD
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: _inputDecoration(
              hint: 'Password',
              icon: Icons.lock_outline_rounded,
            ).copyWith(
              suffixIcon: IconButton(
                tooltip: _obscurePassword
                    ? 'Tampilkan password'
                    : 'Sembunyikan password',
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (
                    child,
                    animation,
                  ) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: animation,
                        child: child,
                      ),
                    );
                  },
                  child: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    key: ValueKey<bool>(
                      _obscurePassword,
                    ),
                    color: const Color(0xFF647087),
                  ),
                ),
              ),
            ),
            validator: (value) {
              if (value == null ||
                  value.isEmpty) {
                return 'Password wajib diisi.';
              }

              if (value.length < 6) {
                return 'Password minimal 6 karakter.';
              }

              return null;
            },
          ),

          const SizedBox(height: 4),

          // FORGOT PASSWORD
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _openForgotPassword,
              child: const Text(
                'Lupa Password?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0874E8),
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // LOGIN BUTTON
          SizedBox(
            width: double.infinity,
            height: 58,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF32AEF5),
                    Color(0xFF147DE8),
                    Color(0xFF075BE3),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF147DE8)
                        .withValues(alpha: 0.22),
                    blurRadius: 18,
                    offset: const Offset(0, 9),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (
                    child,
                    animation,
                  ) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(
                          begin: 0.92,
                          end: 1,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: _isLoading
                      ? const SizedBox(
                          key: ValueKey('login-loading'),
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.3,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          key: ValueKey('login-button'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 12),
                            Icon(
                              Icons.arrow_forward_rounded,
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 26),

          // REMEMBER ME
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: Checkbox(
                  value: _rememberMe,
                  onChanged: (value) {
                    setState(() {
                      _rememberMe = value ?? false;
                    });
                  },
                ),
              ),
              const SizedBox(width: 9),
              const Text(
                'Ingat saya',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF778197),
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // FOOTER
          Row(
            children: [
              const Expanded(
                child: Divider(
                  color: Color(0xFFD6DEEA),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                flex: 4,
                child: Text(
                  'Akademik Lebih Mudah, '
                  'Masa Depan Lebih Cerah',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: mobile ? 11 : 12,
                    color: const Color(0xFF8992A7),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Divider(
                  color: Color(0xFFD6DEEA),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ==========================================================
  /// INPUT STYLE
  /// ==========================================================
  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF8A94A9),
        fontSize: 15,
      ),
      prefixIcon: Icon(
        icon,
        color: const Color(0xFF667287),
      ),
      filled: true,
      fillColor: const Color(0xFFF7FAFE),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 19,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFFDCE5F1),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFF1782EB),
          width: 1.6,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.5,
        ),
      ),
    );
  }
}
