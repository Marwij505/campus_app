import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/app_motion.dart';
import '../../core/app_theme.dart';

/// Grafik masih merupakan visual demo dari App.tsx.
///
/// Belum membaca nilai akademik dari database.
class AcademicCharts extends StatelessWidget {
  const AcademicCharts({super.key});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        padding: const EdgeInsets.all(12),
        color: const Color(0xFFF5F8FA),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('PERJALANAN KULIAH', style: AppTheme.pixel(7)),
                ),
                Text('5 / 8', style: AppTheme.pixel(9, color: AppTheme.blue)),
              ],
            ),

            const SizedBox(height: 12),

            // Empat semester selesai, semester kelima sedang berjalan.
            Row(
              children: List.generate(
                8,
                (index) => Expanded(
                  child: Container(
                    height: 16,
                    margin: const EdgeInsets.only(right: 2),
                    color: index < 4
                        ? AppTheme.blue
                        : index == 4
                        ? const Color(0xFFEF781D)
                        : const Color(0xFFDBE3E8),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 7),

            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Semester 1', style: TextStyle(fontSize: 8)),
                Text('Saat ini', style: TextStyle(fontSize: 8)),
                Text('Semester 8', style: TextStyle(fontSize: 8)),
              ],
            ),
          ],
        ),
      ),

      const SizedBox(height: 10),

      // Wrap mengizinkan tinggi kartu mengikuti isi dan ukuran teks.
      LayoutBuilder(
        builder: (context, bounds) => Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(
            4,
            (index) => SizedBox(
              width: (bounds.maxWidth - 8) / 2,
              child: _ChartCard(index: index),
            ),
          ),
        ),
      ),
    ],
  );
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    const titles = [
      'TREN IPK',
      'IPS / SEMESTER',
      'BEBAN SKS',
      'KOMPOSISI NILAI',
    ];

    const values = ['3.73', '3.68', '86', ''];

    return Container(
      constraints: const BoxConstraints(minHeight: 164),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFC),
        border: Border.all(color: const Color(0xFFD7E1E6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titles[index], style: AppTheme.pixel(6)),
          const SizedBox(height: 6),
          Text(values[index], style: AppTheme.pixel(9, color: AppTheme.blue)),
          const SizedBox(height: 8),

          if (index < 3) ...[
            SizedBox(
              height: 88,
              width: double.infinity,
              child: _AnimatedPlot(index: index),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                4,
                (i) => Text(
                  index == 2 ? ['20', '18', '24', '24'][i] : '${i + 1}',
                  style: const TextStyle(fontSize: 9, color: AppTheme.muted),
                ),
              ),
            ),
          ] else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: Stack(
                    children: [
                      const Positioned.fill(child: _AnimatedPlot(index: 3)),
                      const Center(
                        child: Text(
                          '30\nMK',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'A   50%',
                      style: TextStyle(fontSize: 9, color: Color(0xFF2867B2)),
                    ),
                    Text(
                      'A-  30%',
                      style: TextStyle(fontSize: 9, color: Color(0xFFEF781D)),
                    ),
                    Text(
                      'B+  20%',
                      style: TextStyle(fontSize: 9, color: Color(0xFF6E42D4)),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Nilai progress bergerak dari 0 menuju 1.
/// Painter membaca progress tersebut untuk menampilkan grafik bertahap.
class _AnimatedPlot extends StatelessWidget {
  const _AnimatedPlot({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: AppMotion.duration(context, 700),
    curve: Curves.easeOutCubic,
    builder: (context, progress, child) =>
        CustomPaint(painter: _ChartPainter(index, progress)),
  );
}

/// CustomPainter hanya digunakan untuk grafik akademik.
class _ChartPainter extends CustomPainter {
  _ChartPainter(this.index, this.progress);

  final int index;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;

    // Grafik komposisi nilai berbentuk donut.
    if (index == 3) {
      final center = size.center(Offset.zero);
      final radius = math.min(size.width, size.height) / 2 - 7;
      final rect = Rect.fromCircle(center: center, radius: radius);

      const fractions = [.5, .3, .2];
      const colors = [Color(0xFF2867B2), Color(0xFFEF781D), Color(0xFF6E42D4)];

      var start = -math.pi / 2;

      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 13;

      for (var i = 0; i < 3; i++) {
        paint.color = colors[i];

        final sweep = fractions[i] * math.pi * 2 * progress;

        canvas.drawArc(rect, start, sweep, false, paint);

        start += sweep;
      }

      return;
    }

    // Garis bantu horizontal.
    paint
      ..color = const Color(0xFFDBE4E8)
      ..strokeWidth = 1;

    for (final y in [.18, .49, .8]) {
      canvas.drawLine(
        Offset(0, size.height * y),
        Offset(size.width, size.height * y),
        paint,
      );
    }

    if (index == 0) {
      // Koordinat mengikuti path SVG contoh Figma.
      // Ini bukan data IPK hasil perhitungan.
      const x = [12.0, 54.0, 96.0, 138.0];
      const y = [48.0, 40.0, 42.0, 39.0];

      final points = List.generate(
        4,
        (i) => Offset(
          x[i] / 150 * size.width,
          (66 - (66 - y[i]) * progress) / 78 * size.height,
        ),
      );

      final line = Path()..addPolygon(points, false);

      paint
        ..color = const Color(0xFF286CBA)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      canvas.drawPath(line, paint);

      for (final point in points) {
        canvas.drawCircle(point, 3, paint);
      }
    } else {
      // Tinggi batang mengikuti contoh visual pada App.tsx.
      final heights = index == 1
          ? [.78, .9, .83, .86]
          : [20 / 30, 18 / 30, 24 / 30, 24 / 30];

      paint
        ..style = PaintingStyle.fill
        ..color = index == 1
            ? const Color(0xFFF3791D)
            : const Color(0xFF27A654);

      final slot = size.width / 4;

      for (var i = 0; i < 4; i++) {
        final h = size.height * heights[i] * progress;

        canvas.drawRect(
          Rect.fromLTWH(slot * i + slot * .2, size.height - h, slot * .6, h),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.index != index;
}
