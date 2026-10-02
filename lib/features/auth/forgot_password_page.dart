import 'package:flutter/material.dart';

/// ============================================================
/// FORGOT PASSWORD PAGE
/// ============================================================
///
/// Untuk sekarang masih frontend.
///
/// Flow backend nantinya:
///
/// Flutter
///   ↓
/// POST /api/forgot-password
///   ↓
/// Laravel
///   ↓
/// Database / User
///   ↓
/// Email reset password
///
/// Halaman ini memiliki entrance animation.
/// Saat kembali ke Login, Navigator.pop() akan memainkan
/// reverse transition dari AppPageRoute yang dipakai Login.
/// ============================================================
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() =>
      _ForgotPasswordPageState();
}

class _ForgotPasswordPageState
    extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _identityController = TextEditingController();

  bool _isLoading = false;

  /// ==========================================================
  /// SEND RESET LINK
  /// ==========================================================
  Future<void> _sendResetLink() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // BACKEND DUMMY
    // Nanti:
    // POST /api/forgot-password
    await Future.delayed(
      const Duration(milliseconds: 900),
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Link reset password akan dikirim jika akun ditemukan.',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _identityController.dispose();
    super.dispose();
  }

  /// ==========================================================
  /// ROOT UI
  /// ==========================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      body: TweenAnimationBuilder<double>(
        // Entrance animation halaman Forgot Password.
        tween: Tween<double>(
          begin: 0,
          end: 1,
        ),
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
        builder: (
          context,
          value,
          child,
        ) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(
                0,
                16 * (1 - value),
              ),
              child: child,
            ),
          );
        },
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 470,
                ),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.07),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // BACK BUTTON
                        IconButton(
                          tooltip: 'Kembali',
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                          ),
                        ),

                        const SizedBox(height: 18),

                        // ICON
                        Center(
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(
                              begin: 0.85,
                              end: 1,
                            ),
                            duration: const Duration(
                              milliseconds: 600,
                            ),
                            curve: Curves.easeOutBack,
                            builder: (
                              context,
                              value,
                              child,
                            ) {
                              return Transform.scale(
                                scale: value,
                                child: child,
                              );
                            },
                            child: Container(
                              width: 82,
                              height: 82,
                              decoration: BoxDecoration(
                                color: const Color(0xFF167FE8)
                                    .withValues(alpha: 0.10),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.lock_reset_rounded,
                                size: 48,
                                color: Color(0xFF167FE8),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        const Center(
                          child: Text(
                            'Lupa Password',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF071A42),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        const Center(
                          child: Text(
                            'Masukkan NIM, NIDN, atau email '
                            'akun akademik Anda.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: Color(0xFF7A849B),
                            ),
                          ),
                        ),

                        const SizedBox(height: 34),

                        // INPUT
                        TextFormField(
                          controller: _identityController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _inputDecoration(),
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'NIM / NIDN / Email wajib diisi.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 24),

                        // SEND BUTTON
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF32AEF5),
                                  Color(0xFF147DE8),
                                  Color(0xFF075BE3),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF147DE8)
                                      .withValues(alpha: 0.20),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : _sendResetLink,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(
                                  milliseconds: 220,
                                ),
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
                                        key: ValueKey(
                                          'forgot-loading',
                                        ),
                                        width: 23,
                                        height: 23,
                                        child:
                                            CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Row(
                                        key: ValueKey(
                                          'forgot-button',
                                        ),
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Kirim Link Reset',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight:
                                                  FontWeight.w700,
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // KEMBALI KE LOGIN
                        Center(
                          child: TextButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              size: 18,
                            ),
                            label: const Text(
                              'Kembali ke Login',
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
        ),
      ),
    );
  }

  /// ==========================================================
  /// INPUT STYLE
  /// ==========================================================
  InputDecoration _inputDecoration() {
    return InputDecoration(
      hintText: 'NIM / NIDN / Email',
      hintStyle: const TextStyle(
        color: Color(0xFF8A94A9),
        fontSize: 15,
      ),
      prefixIcon: const Icon(
        Icons.person_outline_rounded,
        color: Color(0xFF667287),
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
