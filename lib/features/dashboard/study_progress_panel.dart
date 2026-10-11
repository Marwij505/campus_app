import 'package:flutter/material.dart';

import '../../core/app_motion.dart';
import '../../core/app_theme.dart';
import '../../data/dashboard_models.dart';
import 'academic_charts.dart';
import 'dashboard_widgets.dart';

class StudyProgressPanel extends StatelessWidget {
  const StudyProgressPanel({super.key, required this.data});
  final DashboardData data;
  @override
  Widget build(BuildContext context) {
    final p = data.progress;
    final aRatio = safeRatio(p.aGrades, p.gradedCourses);
    return DashboardPanel(
      title: 'KEMAJUAN BELAJAR',
      icon: Icons.trending_up,
      action: DashboardAction(
        'Cara baca',
        () => showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cara membaca kemajuan'),
            content: const SingleChildScrollView(
              child: Text(
                'Masa studi membandingkan semester yang ditempuh dengan batas studi. '
                'SKS lulus dibandingkan syarat kelulusan. IPK memakai skala 4.00. '
                'Perolehan nilai A dihitung dari mata kuliah yang sudah dinilai. '
                'Tanda — berarti data belum tersedia, bukan nilai nol. '
                'Grafik hanya muncul ketika data pendukung sudah tersedia.',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
            ],
          ),
        ),
        icon: Icons.info_outline,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ResponsiveCards(
            minWidth: 180,
            children: [
              _ProgressCard(
                title: 'MASA STUDI',
                icon: Icons.hourglass_bottom,
                value: p.currentSemester?.toString(),
                suffix: p.maxSemesters == null
                    ? null
                    : '/${p.maxSemesters} smt',
                progress: safeRatio(p.currentSemester, p.maxSemesters),
                color: AppTheme.blue,
              ),
              _ProgressCard(
                title: 'SKS LULUS',
                icon: Icons.school_outlined,
                value: p.passedCredits?.toString(),
                suffix: p.requiredCredits == null
                    ? null
                    : '/${p.requiredCredits}',
                progress: safeRatio(p.passedCredits, p.requiredCredits),
                color: const Color(0xFF1AA95A),
              ),
              _ProgressCard(
                title: 'INDEKS PRESTASI',
                icon: Icons.star_outline,
                value: p.gpa?.toStringAsFixed(2),
                suffix: p.gpa == null ? null : '/4.00',
                progress: safeRatio(p.gpa, 4),
                color: const Color(0xFFED7D21),
                caption: p.predicate,
              ),
              _ProgressCard(
                title: 'PEROLEHAN NILAI A',
                icon: Icons.emoji_events_outlined,
                value: aRatio == null
                    ? null
                    : (aRatio * 100).toStringAsFixed(0),
                suffix: aRatio == null ? null : '%',
                progress: aRatio,
                color: const Color(0xFF873DD1),
                caption: aRatio == null
                    ? null
                    : '${p.aGrades} dari ${p.gradedCourses} mata kuliah',
              ),
            ],
          ),
          const SizedBox(height: 22),
          AcademicCharts(data: data),
        ],
      ),
    );
  }
}

/// Bar abu-abu dengan tanda — berarti belum ada nilai. Tidak dianggap nilai 0%.
class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.title,
    required this.icon,
    required this.value,
    required this.suffix,
    required this.progress,
    required this.color,
    this.caption,
  });
  final String title;
  final IconData icon;
  final String? value, suffix, caption;
  final double? progress;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FBFF),
      border: Border.all(color: const Color(0xFFD5E0ED), width: 2),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 21),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.muted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 4,
          children: [
            Text(value ?? '—', style: AppTheme.pixel(19)),
            if (suffix != null)
              Text(
                suffix!,
                style: const TextStyle(fontSize: 11, color: AppTheme.muted),
              ),
          ],
        ),
        const SizedBox(height: 15),
        Semantics(
          label: progress == null
              ? '$title: belum tersedia'
              : '$title: ${(progress! * 100).round()} persen',
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress ?? 0),
            duration: AppMotion.duration(context, 600),
            builder: (context, value, child) => LinearProgressIndicator(
              value: value,
              minHeight: 7,
              color: color,
              backgroundColor: const Color(0xFFE5EDF5),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          caption ??
              (value == null ? 'Data belum tersedia.' : 'Ringkasan akademik'),
          style: const TextStyle(fontSize: 10, color: AppTheme.muted),
        ),
      ],
    ),
  );
}
