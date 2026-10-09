import 'package:flutter/material.dart';

/// Navigator menentukan tujuan; helper ini menentukan cara halaman bergerak.
abstract final class AppPageRoute {
  static Route<T> slideFade<T>({
    required Widget page,
    Offset beginOffset = const Offset(0.06, 0),
    Duration duration = const Duration(milliseconds: 380),
    Duration reverseDuration = const Duration(milliseconds: 280),
  }) => _route<T>(page, beginOffset, 0.99, duration, reverseDuration);

  static Route<T> fadeScale<T>({
    required Widget page,
    Duration duration = const Duration(milliseconds: 420),
    Duration reverseDuration = const Duration(milliseconds: 280),
  }) => _route<T>(page, Offset.zero, 0.97, duration, reverseDuration);

  static Route<T> _route<T>(
    Widget page,
    Offset offset,
    double scale,
    Duration duration,
    Duration reverseDuration,
  ) => PageRouteBuilder<T>(
    transitionDuration: duration,
    reverseTransitionDuration: reverseDuration,
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Hormati pengaturan aksesibilitas pengguna yang mengurangi gerakan.
      if (MediaQuery.disableAnimationsOf(context)) return child;
      final curved = animation.drive(CurveTween(curve: Curves.easeOutCubic));
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: curved.drive(Tween(begin: offset, end: Offset.zero)),
          child: ScaleTransition(
            scale: curved.drive(Tween<double>(begin: scale, end: 1)),
            child: child,
          ),
        ),
      );
    },
  );
}
