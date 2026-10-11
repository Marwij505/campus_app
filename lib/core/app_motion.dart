import 'dart:async';

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

/// Konten muncul bertahap dengan fade + pergeseran 10 px.
/// Controller dan timer selalu dilepas saat halaman ditutup.
class Entrance extends StatefulWidget {
  const Entrance({super.key, required this.child, this.delay = 0});
  final Widget child;
  final int delay;
  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _curve;
  Timer? _timer;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _curve = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.duration = AppMotion.duration(context, 420);
    if (MediaQuery.disableAnimationsOf(context)) {
      _timer?.cancel();
      _controller.value = 1;
      _started = true;
    } else if (!_started) {
      _started = true;
      if (widget.delay == 0) {
        _controller.forward();
      } else {
        _timer = Timer(Duration(milliseconds: widget.delay), () {
          if (mounted) _controller.forward();
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _curve,
    child: widget.child,
    builder: (context, child) => Opacity(
      opacity: _curve.value,
      child: Transform.translate(
        offset: Offset(0, 10 * (1 - _curve.value)),
        child: child,
      ),
    ),
  );
}
