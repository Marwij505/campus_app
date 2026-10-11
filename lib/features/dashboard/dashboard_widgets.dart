// Komponen kecil yang dipakai bersama oleh berbagai panel beranda.
// Pemisahan ini membuat judul, pesan kosong, tombol, dan jarak kartu seragam.
// Komponen menerima data lewat parameter dan menyerahkan aksi ke fungsi pemanggil.

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/responsive_layout.dart';
import '../../shared/pixel_widgets.dart';

/// Panel beranda: judul dapat pindah baris agar tidak terpotong di layar kecil.
// Bingkai panel dengan ikon, judul, isi, dan tombol tambahan bila diperlukan.
class DashboardPanel extends StatelessWidget {
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
  const DashboardPanel({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.action,
  });
  // Judul yang terlihat pada bagian atas panel.
  final String title;
  // Simbol visual untuk mengenali isi panel atau pesan.
  final IconData icon;
  // Isi panel diberikan dari luar sehingga bingkai yang sama bisa dipakai berulang.
  final Widget child;
  // Tombol tambahan bersifat opsional, misalnya Lihat semua.
  final Widget? action;

  @override
  // build menyusun tampilan ketika Flutter memintanya.
  Widget build(BuildContext context) => PixelPanel(
    padding: EdgeInsets.zero,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, bounds) {
              // Satukan ikon dan judul; Expanded membatasi judul agar tidak melewati ruang tersedia.
              final heading = Row(
                children: [
                  Icon(icon, color: AppTheme.blue, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTheme.pixel(8, color: AppTheme.blue),
                    ),
                  ),
                ],
              );
              // Tombol panjang tidak dipaksa berdampingan dengan judul pada HP.
              return bounds.maxWidth < 440 ||
                      MediaQuery.textScalerOf(context).scale(1) > 1.3
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        heading,
                        if (action != null) ...[
                          const SizedBox(height: 10),
                          action!,
                        ],
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: heading),
                        if (action != null) ...[
                          const SizedBox(width: 12),
                          action!,
                        ],
                      ],
                    );
            },
          ),
        ),
        const Divider(height: 1, color: Color(0xFFDBE4E6)),
        Padding(padding: const EdgeInsets.all(16), child: child),
      ],
    ),
  );
}

/// Kosong adalah kondisi normal: tidak ada animasi loading yang berputar selamanya.
// Pesan penjelas ketika data suatu bagian belum tersedia.
class DashboardEmpty extends StatelessWidget {
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
  const DashboardEmpty({
    super.key,
    required this.title,
    this.message = 'Data belum tersedia.',
    this.icon = Icons.inbox_outlined,
  });
  // Judul menjelaskan kondisi kosong, pesan menerangkan apa yang belum tersedia.
  final String title, message;
  // Simbol visual untuk mengenali isi panel atau pesan.
  final IconData icon;
  @override
  // build menyusun tampilan ketika Flutter memintanya.
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 8),
    child: Column(
      children: [
        Icon(icon, size: 32, color: AppTheme.blue.withValues(alpha: .45)),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: AppTheme.muted),
        ),
      ],
    ),
  );
}

/// Wrap tidak mengunci tinggi kartu. Teks besar bisa menambah tinggi secara alami.
// Penyusun kartu yang menyesuaikan jumlah kolom dan membiarkan tinggi mengikuti isinya.
class ResponsiveCards extends StatelessWidget {
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
  const ResponsiveCards({
    super.key,
    required this.children,
    this.minWidth = 220,
    this.maximum = 4,
  });
  // Daftar kartu yang akan disusun ulang sesuai ukuran ruang.
  final List<Widget> children;
  // Lebar acuan minimum tiap kartu sebelum jumlah kolom dikurangi.
  final double minWidth;
  // Batas atas jumlah kolom meskipun layar masih memiliki ruang.
  final int maximum;
  @override
  // build menyusun tampilan ketika Flutter memintanya.
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      // Perhitungkan pembesaran teks agar kartu tidak terlalu sempit untuk dibaca.
      final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
      // Minta rumus bersama menentukan jumlah kolom yang muat.
      final count = ResponsiveLayout.columns(
        bounds.maxWidth,
        minWidth * scale,
        maximum: maximum,
      );
      // Bagikan lebar setelah jarak 16 antar kartu dikurangi.
      final width = (bounds.maxWidth - 16 * (count - 1)) / count;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}

// Label kecil berwarna untuk status atau informasi singkat.
class InfoChip extends StatelessWidget {
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
  const InfoChip(
    this.label, {
    super.key,
    this.color = AppTheme.blue,
    this.onDark = false,
  });
  final String label;
  final Color color;
  // Ubah label menjadi terang bila ditempatkan di latar gelap seperti kartu profil.
  final bool onDark;
  @override
  // build menyusun tampilan ketika Flutter memintanya.
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: onDark
          ? Colors.white.withValues(alpha: .14)
          : color.withValues(alpha: .08),
      border: Border.all(
        color: onDark
            ? Colors.white.withValues(alpha: .3)
            : color.withValues(alpha: .2),
      ),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 10,
        color: onDark ? Colors.white : color,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

/// Tombol menyediakan area sentuh yang cukup untuk HP dan tablet.
// Tombol kecil dengan ukuran sentuh yang nyaman dan ikon opsional.
class DashboardAction extends StatelessWidget {
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
  const DashboardAction(this.label, this.onPressed, {super.key, this.icon});
  final String label;
  // Tindakan saat disentuh; null berarti tombol tidak dapat dijalankan.
  final VoidCallback? onPressed;
  // Ikon opsional yang hanya ditampilkan jika diberikan.
  final IconData? icon;
  @override
  // build menyusun tampilan ketika Flutter memintanya.
  Widget build(BuildContext context) => TextButton(
    style: TextButton.styleFrom(
      minimumSize: const Size(48, 44),
      foregroundColor: AppTheme.blue,
      backgroundColor: const Color(0xFFEDF3FA),
      shape: const RoundedRectangleBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 12),
    ),
    onPressed: onPressed,
    // Wrap memindahkan isi ke baris berikutnya jika ruang horizontal tidak cukup.
    child: Wrap(
      spacing: 7,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (icon != null) Icon(icon, size: 17),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}
