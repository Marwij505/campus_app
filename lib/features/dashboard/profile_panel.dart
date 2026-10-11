import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../data/student_profile.dart';
import 'dashboard_widgets.dart';

/// Profil tidak memakai nama atau foto contoh dari referensi.
/// Nilai null ditampilkan sebagai tanda — hingga backend mengirim data.
class ProfilePanel extends StatelessWidget {
  const ProfilePanel({super.key, required this.student});
  final StudentProfile student;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF123C80), Color(0xFF166AB1)],
      ),
      border: Border.all(color: AppTheme.ink, width: 3),
      boxShadow: const [
        BoxShadow(color: Color(0xFFB9C3C4), offset: Offset(4, 4)),
      ],
    ),
    child: LayoutBuilder(
      builder: (context, bounds) {
        final identity = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .12),
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name ?? 'Profil mahasiswa',
                        style: AppTheme.pixel(10, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'NIM: ${student.nim}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${student.faculty ?? 'Fakultas: —'} · ${student.major ?? 'Program studi: —'}',
                        style: const TextStyle(
                          color: Color(0xFFCFE4FB),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                InfoChip('Status: ${student.status ?? '—'}', onDark: true),
                InfoChip('Angkatan: ${student.entryYear ?? '—'}', onDark: true),
                InfoChip('Semester: ${student.semester ?? '—'}', onDark: true),
                InfoChip('DPA: ${student.advisor ?? '—'}', onDark: true),
              ],
            ),
            if (student.name == null) ...[
              const SizedBox(height: 12),
              const Text(
                'Data profil belum tersedia.',
                style: TextStyle(color: Color(0xFFCFE4FB), fontSize: 10),
              ),
            ],
          ],
        );
        final stats = ResponsiveCards(
          minWidth: 92,
          maximum: 3,
          children: [
            _stat('IPK', student.gpa?.toStringAsFixed(2), 'kumulatif'),
            _stat(
              'IPS TERAKHIR',
              student.latestGpa?.toStringAsFixed(2),
              'semester terakhir',
            ),
            _stat('SKS LULUS', student.passedCredits?.toString(), 'total SKS'),
          ],
        );
        if (bounds.maxWidth >= 1000 &&
            MediaQuery.textScalerOf(context).scale(1) <= 1.3) {
          return Row(
            children: [
              Expanded(child: identity),
              const SizedBox(width: 24),
              SizedBox(width: 390, child: stats),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [identity, const SizedBox(height: 20), stats],
        );
      },
    ),
  );

  Widget _stat(String label, String? value, String caption) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .12),
      border: Border.all(color: Colors.white.withValues(alpha: .24)),
    ),
    child: Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFFCFE4FB), fontSize: 9),
        ),
        const SizedBox(height: 10),
        Text(value ?? '—', style: AppTheme.pixel(17, color: Colors.white)),
        const SizedBox(height: 6),
        Text(
          caption,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFFCFE4FB), fontSize: 9),
        ),
      ],
    ),
  );
}
