import 'package:flutter/material.dart';

abstract final class AppMotion {
  /// Hormati pengaturan pengguna yang mengurangi animasi.
  static Duration duration(BuildContext context, [int milliseconds = 380]) =>
      MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : Duration(milliseconds: milliseconds);

  /// Transisi untuk membuka halaman lupa password.
  ///
  /// Navigator.pop() otomatis menjalankan transisi dalam arah sebaliknya.
  static Route<void> route(Widget page) => PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 280),

    pageBuilder: (context, animation, secondaryAnimation) => page,

    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.disableAnimationsOf(context)) {
        return child;
      }

      final curved = animation.drive(CurveTween(curve: Curves.easeOutCubic));

      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: curved.drive(
            Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero),
          ),
          child: child,
        ),
      );
    },
  );
}

/// Animasi kemunculan konten.
///
/// child tetap sama pada setiap frame agar animasinya lebih ringan.
class Entrance extends StatelessWidget {
  const Entrance({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return child;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.duration(context, 500),
      curve: Curves.easeOutCubic,

      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - value)),
          child: child,
        ),
      ),

      child: child,
    );
  }
}
