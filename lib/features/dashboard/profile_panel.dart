// Menampilkan identitas dan ringkasan prestasi mahasiswa di bagian atas beranda.
// Nilai diambil dari StudentProfile yang diberikan halaman induk.
// Tanda ?? memilih teks pengganti saat data null; tanda ?. menjalankan format
// hanya jika nilai tersedia, sehingga data yang hilang tidak dianggap nol.

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../data/student_profile.dart';
import 'dashboard_widgets.dart';

/// Profil tidak memakai nama atau foto contoh dari referensi.
/// Nilai null ditampilkan sebagai tanda — hingga backend mengirim data.
// Kartu profil yang menyesuaikan susunan identitas dan statistik dengan lebar layar.
class ProfilePanel extends StatelessWidget {
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
  const ProfilePanel({super.key, required this.student});
  // Seluruh isi panel berasal dari satu profil ini.
  final StudentProfile student;

  @override
  // build menyusun tampilan ketika Flutter memintanya.
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      // Campurkan dua warna biru sebagai latar, lalu beri bingkai dan bayangan pixel.
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
        // Bagian identitas memuat ikon orang, nama, NIM, fakultas, dan program studi.
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
                        // Gunakan judul umum ketika nama asli belum diterima.
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
                // Label-label berikut menampilkan status, angkatan, semester, dan pembimbing akademik.
                InfoChip('Status: ${student.status ?? '—'}', onDark: true),
                InfoChip('Angkatan: ${student.entryYear ?? '—'}', onDark: true),
                InfoChip('Semester: ${student.semester ?? '—'}', onDark: true),
                InfoChip('DPA: ${student.advisor ?? '—'}', onDark: true),
              ],
            ),
            // Berikan penjelasan tambahan ketika data profil belum lengkap.
            if (student.name == null) ...[
              const SizedBox(height: 12),
              const Text(
                'Data profil belum tersedia.',
                style: TextStyle(color: Color(0xFFCFE4FB), fontSize: 10),
              ),
            ],
          ],
        );
        // Tiga kartu ringkas: IPK kumulatif, IPS terakhir, dan total SKS lulus.
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
        // Tablet landscape dapat menaruh statistik di samping identitas.
        // Saat ruang menyempit atau teks diperbesar, keduanya kembali bertumpuk.
        if (bounds.maxWidth >= 880 &&
            MediaQuery.textScalerOf(context).scale(1) <= 1.3) {
          return Row(
            children: [
              Expanded(child: identity),
              const SizedBox(width: 24),
              SizedBox(width: 390, child: stats),
            ],
          );
        }
        // Pada ruang lebih kecil, susun identitas di atas statistik agar isi tetap terbaca.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [identity, const SizedBox(height: 20), stats],
        );
      },
    ),
  );

  // Buat satu kotak angka dengan judul dan keterangan; data hilang ditampilkan sebagai —.
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
