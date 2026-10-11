import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/app_motion.dart';
import '../../core/app_theme.dart';
import '../../data/dashboard_models.dart';
import 'dashboard_widgets.dart';

/// Enam tempat grafik disiapkan. Tidak menggambar garis/donut ketika datanya kosong.
/// Setelah repository mengirim data, grafik yang sesuai muncul secara otomatis.
class AcademicCharts extends StatelessWidget {
  const AcademicCharts({super.key, required this.data});
  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final p = data.progress;
    final hasJourney =
        p.completedSemesters != null &&
        p.currentSemester != null &&
        p.plannedSemesters != null;
    final journey = hasJourney
        ? <String, double>{
            'Selesai': p.completedSemesters!.toDouble(),
            'Ditempuh': (p.currentSemester! > p.completedSemesters! ? 1 : 0)
                .toDouble(),
            'Belum': math
                .max(
                  0,
                  p.plannedSemesters! -
                      math.max(p.currentSemester!, p.completedSemesters!),
                )
                .toDouble(),
          }
        : <String, double>{};

    List<_Point> points(double? Function(SemesterResult) select) =>
        (data.semesters
                .where((s) => select(s) != null && select(s)!.isFinite)
                .toList()
              ..sort((a, b) => a.semester.compareTo(b.semester)))
            .map((s) => _Point('S${s.semester}', select(s)!))
            .toList();

    return ResponsiveCards(
      minWidth: 310,
      maximum: 2,
      children: [
        _chart(
          context,
          'Perjalanan Perkuliahan Anda',
          _ChartKind.journey,
          groups: journey,
        ),
        _chart(
          context,
          'Status Mata Kuliah Kurikulum',
          _ChartKind.donut,
          groups: data.courseStatus.map((k, v) => MapEntry(k, v.toDouble())),
        ),
        _chart(
          context,
          'Tren IPK',
          _ChartKind.line,
          points: points((s) => s.gpa),
          maxValue: 4,
        ),
        _chart(
          context,
          'IPS per Semester',
          _ChartKind.bar,
          points: points((s) => s.ips),
          maxValue: 4,
        ),
        _chart(
          context,
          'Beban SKS per Semester',
          _ChartKind.credits,
          points: points((s) => s.credits?.toDouble()),
          secondary: points((s) => s.cumulativeCredits?.toDouble()),
        ),
        _chart(
          context,
          'Komposisi Nilai Huruf',
          _ChartKind.donut,
          groups: data.gradeComposition.map(
            (k, v) => MapEntry(k, v.toDouble()),
          ),
        ),
      ],
    );
  }

  Widget _chart(
    BuildContext context,
    String title,
    _ChartKind kind, {
    List<_Point> points = const [],
    List<_Point> secondary = const [],
    Map<String, double> groups = const {},
    double? maxValue,
  }) {
    // Hapus kategori bernilai negatif/tidak valid; 0 bukan irisan donut.
    final validGroups = Map<String, double>.fromEntries(
      groups.entries.where((e) => e.value.isFinite && e.value > 0),
    );
    final hasData =
        points.isNotEmpty || secondary.isNotEmpty || validGroups.isNotEmpty;
    final labels = validGroups.keys.toList();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        border: Border.all(color: const Color(0xFFD5E0ED), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.blue,
            ),
          ),
          const SizedBox(height: 12),
          if (!hasData)
            DashboardEmpty(
              title: 'Grafik belum tersedia',
              message: 'Menunggu data akademik.',
              icon: Icons.bar_chart_outlined,
            )
          else ...[
            Semantics(
              label: '$title. Ketuk untuk membaca nilai dalam bentuk teks.',
              button: true,
              child: InkWell(
                onTap: () =>
                    _showValues(context, title, points, secondary, validGroups),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: AppMotion.duration(context, 600),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) => SizedBox(
                    height: 190,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _AcademicPainter(
                        kind: kind,
                        points: points,
                        secondary: secondary,
                        groups: validGroups,
                        progress: value,
                        maxValue: maxValue,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (labels.isNotEmpty)
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < labels.length; i++)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 9,
                          height: 9,
                          color: _colors[i % _colors.length],
                        ),
                        const SizedBox(width: 5),
                        Text(labels[i], style: const TextStyle(fontSize: 10)),
                      ],
                    ),
                ],
              )
            else
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 8,
                children: [
                  for (final point in points)
                    Text(
                      '${point.label}: ${point.value.toStringAsFixed(kind == _ChartKind.line || maxValue == 4 ? 2 : 0)}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.muted,
                      ),
                    ),
                  if (kind == _ChartKind.credits && secondary.isNotEmpty)
                    const Text(
                      'Garis biru: SKS kumulatif (skala relatif)',
                      style: TextStyle(fontSize: 10),
                    ),
                ],
              ),
            const SizedBox(height: 10),
            const Text(
              'Ketuk grafik untuk detail angka.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 9, color: AppTheme.muted),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showValues(
    BuildContext context,
    String title,
    List<_Point> points,
    List<_Point> secondary,
    Map<String, double> groups,
  ) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final p in points) Text('${p.label}: ${p.value}'),
              if (secondary.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'SKS kumulatif:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                for (final p in secondary) Text('${p.label}: ${p.value}'),
              ],
              for (final entry in groups.entries)
                Text('${entry.key}: ${entry.value.toStringAsFixed(0)}'),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
      ],
    ),
  );
}

enum _ChartKind { journey, donut, line, bar, credits }

class _Point {
  const _Point(this.label, this.value);
  final String label;
  final double value;
}

const _colors = [
  AppTheme.blue,
  Color(0xFFED7D21),
  Color(0xFF1AA95A),
  Color(0xFFB2C1D4),
  AppTheme.red,
  Color(0xFF873DD1),
];

/// Painter hanya menggambar data dari repository. Tidak mengandung angka contoh.
class _AcademicPainter extends CustomPainter {
  _AcademicPainter({
    required this.kind,
    required this.points,
    required this.secondary,
    required this.groups,
    required this.progress,
    this.maxValue,
  });
  final _ChartKind kind;
  final List<_Point> points, secondary;
  final Map<String, double> groups;
  final double progress;
  final double? maxValue;

  @override
  void paint(Canvas canvas, Size size) {
    if (kind == _ChartKind.donut) {
      final total = groups.values.fold<double>(0, (a, b) => a + b);
      if (total <= 0) {
        return;
      }
      final radius = math.min(size.width, size.height) * .35;
      final rect = Rect.fromCircle(
        center: size.center(Offset.zero),
        radius: radius,
      );
      var start = -math.pi / 2;
      var index = 0;
      for (final value in groups.values) {
        final sweep = value / total * math.pi * 2 * progress;
        canvas.drawArc(
          rect,
          start,
          sweep,
          false,
          Paint()
            ..color = _colors[index++ % _colors.length]
            ..style = PaintingStyle.stroke
            ..strokeWidth = radius * .42,
        );
        start += sweep;
      }
      return;
    }
    if (kind == _ChartKind.journey) {
      final total = groups.values.fold<double>(0, (a, b) => a + b);
      if (total <= 0) {
        return;
      }
      var x = 12.0;
      var index = 0;
      for (final value in groups.values) {
        final width = (size.width - 24) * value / total * progress;
        canvas.drawRect(
          Rect.fromLTWH(x, 65, width, 54),
          Paint()..color = _colors[index++ % _colors.length],
        );
        x += width;
      }
      return;
    }
    final rect = Rect.fromLTWH(
      30,
      10,
      math.max(1.0, size.width - 40),
      size.height - 34,
    );
    final largest = points.fold<double>(0, (a, b) => math.max(a, b.value));
    final ceiling = math.max(1.0, maxValue ?? largest * 1.15);
    final grid = Paint()
      ..color = const Color(0xFFDFE6EF)
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = rect.bottom - rect.height * i / 4;
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), grid);
      final text = TextPainter(
        text: TextSpan(
          text: (ceiling * i / 4).toStringAsFixed(ceiling <= 4 ? 1 : 0),
          style: const TextStyle(
            color: AppTheme.muted,
            fontSize: 9,
            fontFamily: 'SpaceMono',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, Offset(0, y - 5));
    }
    void line(List<_Point> series, double max, Color color) {
      final path = Path();
      for (var i = 0; i < series.length; i++) {
        final x = rect.left + rect.width * (i + .5) / series.length;
        final y =
            rect.bottom -
            rect.height * (series[i].value / max).clamp(0.0, 1.0) * progress;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
        canvas.drawCircle(Offset(x, y), 3, Paint()..color = color);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }

    if (kind == _ChartKind.line) {
      line(points, ceiling, AppTheme.blue);
    } else {
      for (var i = 0; i < points.length; i++) {
        final slot = rect.width / points.length;
        final height =
            rect.height *
            (points[i].value / ceiling).clamp(0.0, 1.0) *
            progress;
        canvas.drawRect(
          Rect.fromLTWH(
            rect.left + slot * (i + .18),
            rect.bottom - height,
            slot * .64,
            height,
          ),
          Paint()..color = kind == _ChartKind.credits ? _colors[2] : _colors[1],
        );
      }
      if (kind == _ChartKind.credits && secondary.isNotEmpty) {
        final peak = secondary.fold<double>(1, (a, b) => math.max(a, b.value));
        // Menyamakan semester pada posisi batang; jangan menggeser titik bila
        // server belum mengirim SKS kumulatif salah satu semester.
        final path = Path();
        var started = false;
        for (var i = 0; i < points.length; i++) {
          final matches = secondary.where((s) => s.label == points[i].label);
          if (matches.isEmpty) {
            continue;
          }
          final x = rect.left + rect.width * (i + .5) / points.length;
          final y =
              rect.bottom - rect.height * matches.first.value / peak * progress;
          if (!started) {
            path.moveTo(x, y);
            started = true;
          } else {
            path.lineTo(x, y);
          }
          canvas.drawCircle(Offset(x, y), 3, Paint()..color = AppTheme.blue);
        }
        canvas.drawPath(
          path,
          Paint()
            ..color = AppTheme.blue
            ..strokeWidth = 3
            ..style = PaintingStyle.stroke,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AcademicPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.points != points ||
      oldDelegate.secondary != secondary ||
      oldDelegate.groups != groups ||
      oldDelegate.kind != kind;
}
