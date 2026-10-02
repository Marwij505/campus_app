import 'package:flutter/material.dart';

/// ============================================================
/// DASHBOARD PAGE - SEMENTARA
/// ============================================================
///
/// Ini BELUM dashboard final SIAKAD.
///
/// Untuk sekarang halaman ini hanya dipakai untuk:
///
/// - Test login.
/// - Test transition.
/// - Menyiapkan flow navigation.
///
/// Nanti isi halaman ini akan kita desain ulang.
/// ============================================================
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),

      body: SafeArea(
        child: Center(
          child: TweenAnimationBuilder<double>(
            // ==================================================
            // ANIMASI KONTEN DASHBOARD
            // ==================================================
            tween: Tween(
              begin: 0,
              end: 1,
            ),

            duration: const Duration(
              milliseconds: 650,
            ),

            curve: Curves.easeOutCubic,

            builder: (
              context,
              value,
              child,
            ) {
              return Opacity(
                opacity: value,

                child: Transform.translate(
                  // Dari bawah 20px menuju posisi normal.
                  offset: Offset(
                    0,
                    20 * (1 - value),
                  ),

                  child: child,
                ),
              );
            },

            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: [
                Container(
                  width: 90,
                  height: 90,

                  decoration: const BoxDecoration(
                    color: Color(0xFF167FE8),
                    shape: BoxShape.circle,
                  ),

                  child: const Icon(
                    Icons.dashboard_rounded,
                    size: 44,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 26),

                const Text(
                  'Dashboard',

                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF071A42),
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'Login berhasil.\n'
                  'Dashboard SIAKAD akan dibangun di sini.',

                  textAlign: TextAlign.center,

                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: Color(0xFF7A849B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}