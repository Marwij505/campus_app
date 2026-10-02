import 'package:flutter/material.dart';

/// ============================================================
/// APP PAGE ROUTE
/// ============================================================
///
/// File ini menangani animasi perpindahan halaman aplikasi.
///
/// ANALOGI WEB:
///
/// Navigator.push()
/// ≈ pindah URL / halaman.
///
/// AppPageRoute.slideFade()
/// ≈ CSS transition + JavaScript navigation.
///
/// Tujuan dibuat satu helper:
///
/// - Animasi seluruh aplikasi konsisten.
/// - Tidak copy-paste PageRouteBuilder di setiap halaman.
/// - Tetap sesuai konsep 50:50 hybrid kita.
/// ============================================================
class AppPageRoute {
  /// ==========================================================
  /// SLIDE + FADE + SEDIKIT SCALE
  /// ==========================================================
  ///
  /// Cocok untuk:
  ///
  /// Login → Forgot Password
  /// Forgot Password → halaman lain
  /// Detail page
  ///
  static Route<T> slideFade<T>({
    required Widget page,

    // Default halaman masuk sedikit dari kanan.
    Offset beginOffset = const Offset(0.08, 0),

    Duration duration = const Duration(
      milliseconds: 420,
    ),

    Duration reverseDuration = const Duration(
      milliseconds: 340,
    ),
  }) {
    return PageRouteBuilder<T>(
      transitionDuration: duration,
      reverseTransitionDuration: reverseDuration,

      // Halaman tujuan.
      pageBuilder: (
        context,
        animation,
        secondaryAnimation,
      ) {
        return page;
      },

      // ========================================================
      // ANIMATION
      // ========================================================
      transitionsBuilder: (
        context,
        animation,
        secondaryAnimation,
        child,
      ) {
        /// CurvedAnimation membuat animasi tidak terasa linear
        /// dan kaku.
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        /// Fade:
        ///
        /// opacity 0 → 1
        final fadeAnimation = Tween<double>(
          begin: 0,
          end: 1,
        ).animate(curvedAnimation);

        /// Slide:
        ///
        /// sedikit dari kanan → posisi normal.
        final slideAnimation = Tween<Offset>(
          begin: beginOffset,
          end: Offset.zero,
        ).animate(curvedAnimation);

        /// Scale:
        ///
        /// 98.5% → 100%
        ///
        /// Sangat tipis supaya terasa premium,
        /// bukan seperti efek zoom berlebihan.
        final scaleAnimation = Tween<double>(
          begin: 0.985,
          end: 1,
        ).animate(curvedAnimation);

        return FadeTransition(
          opacity: fadeAnimation,

          child: SlideTransition(
            position: slideAnimation,

            child: ScaleTransition(
              scale: scaleAnimation,
              child: child,
            ),
          ),
        );
      },
    );
  }

  /// ==========================================================
  /// FADE + SCALE
  /// ==========================================================
  ///
  /// Cocok untuk perpindahan besar seperti:
  ///
  /// Login → Dashboard
  ///
  /// Karena Dashboard dianggap masuk ke bagian utama aplikasi,
  /// kita tidak perlu slide terlalu terlihat.
  ///
  static Route<T> fadeScale<T>({
    required Widget page,

    Duration duration = const Duration(
      milliseconds: 500,
    ),

    Duration reverseDuration = const Duration(
      milliseconds: 350,
    ),
  }) {
    return PageRouteBuilder<T>(
      transitionDuration: duration,
      reverseTransitionDuration: reverseDuration,

      pageBuilder: (
        context,
        animation,
        secondaryAnimation,
      ) {
        return page;
      },

      transitionsBuilder: (
        context,
        animation,
        secondaryAnimation,
        child,
      ) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutQuart,
          reverseCurve: Curves.easeInQuart,
        );

        final fadeAnimation = Tween<double>(
          begin: 0,
          end: 1,
        ).animate(curvedAnimation);

        final scaleAnimation = Tween<double>(
          begin: 0.96,
          end: 1,
        ).animate(curvedAnimation);

        return FadeTransition(
          opacity: fadeAnimation,

          child: ScaleTransition(
            scale: scaleAnimation,
            child: child,
          ),
        );
      },
    );
  }
}