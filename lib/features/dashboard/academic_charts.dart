// Mengubah data akademik menjadi enam tampilan grafik beserta detail angkanya.
// Bagian atas menyiapkan data; _AcademicPainter di bagian bawah menggambarnya.
// Canvas seperti kertas gambar, Paint seperti kuas, dan Offset seperti posisi titik.
// Grafik yang belum memiliki data menampilkan pesan kosong, bukan angka contoh.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/app_motion.dart';
import '../../core/app_theme.dart';
import '../../data/dashboard_models.dart';
import 'dashboard_widgets.dart';

/// Enam tempat grafik disiapkan. Tidak menggambar garis/donut ketika datanya kosong.
/// Setelah repository mengirim data, grafik yang sesuai muncul secara otomatis.
// Menyiapkan data dan kartu untuk semua grafik akademik.
class AcademicCharts extends StatelessWidget {
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
  const AcademicCharts({super.key, required this.data});
  // Paket beranda yang menyediakan statistik, kategori, dan riwayat semester.
  final DashboardData data;

  @override
  // build menyusun tampilan ketika Flutter memintanya.
  Widget build(BuildContext context) {
    // Ambil ringkasan studi agar perhitungan perjalanan kuliah lebih ringkas.
    final p = data.progress;
    // Grafik perjalanan membutuhkan semester selesai, saat ini, dan rencana total sekaligus.
    final hasJourney =
        p.completedSemesters != null &&
        p.currentSemester != null &&
        p.plannedSemesters != null;
    // Kelompokkan semester menjadi selesai, sedang ditempuh, dan belum ditempuh.
    // math.max(0, ...) mencegah jumlah sisa semester menjadi negatif.
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

    // Pilih satu ukuran seperti IPK, buang nilai kosong/tidak valid, urutkan semester,
    // lalu ubah menjadi pasangan label dan angka yang siap digambar.
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
          // Grafik pembagian tahap studi menggunakan tiga kategori perjalanan.
          'Perjalanan Perkuliahan Anda',
          _ChartKind.journey,
          groups: journey,
        ),
        _chart(
          context,
          // Grafik cincin menunjukkan perbandingan jumlah mata kuliah per status.
          'Status Mata Kuliah Kurikulum',
          _ChartKind.donut,
          groups: data.courseStatus.map((k, v) => MapEntry(k, v.toDouble())),
        ),
        _chart(
          context,
          // Grafik garis menunjukkan perubahan IPK dengan skala acuan 4.
          'Tren IPK',
          _ChartKind.line,
          points: points((s) => s.gpa),
          maxValue: 4,
        ),
        _chart(
          context,
          // Grafik batang membandingkan IPS tiap semester pada skala yang sama.
          'IPS per Semester',
          _ChartKind.bar,
          points: points((s) => s.ips),
          maxValue: 4,
        ),
        _chart(
          context,
          // Batang menunjukkan SKS tiap semester; garis tambahan menunjukkan SKS kumulatif.
          'Beban SKS per Semester',
          _ChartKind.credits,
          points: points((s) => s.credits?.toDouble()),
          secondary: points((s) => s.cumulativeCredits?.toDouble()),
        ),
        _chart(
          context,
          // Grafik cincin membandingkan banyaknya mata kuliah untuk setiap nilai huruf.
          'Komposisi Nilai Huruf',
          _ChartKind.donut,
          groups: data.gradeComposition.map(
            (k, v) => MapEntry(k, v.toDouble()),
          ),
        ),
      ],
    );
  }

  // Buat kartu grafik: judul, kondisi kosong, gambar, legenda, dan aksi melihat angka.
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
    // Gambar hanya disiapkan jika ada titik, data tambahan, atau kategori yang sah.
    final hasData =
        points.isNotEmpty || secondary.isNotEmpty || validGroups.isNotEmpty;
    // Nama kategori menjadi legenda dengan warna yang sesuai irisan grafik.
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
            // Berikan keterangan bahwa gambar dapat diketuk untuk membaca angka dalam teks.
            Semantics(
              label: '$title. Ketuk untuk membaca nilai dalam bentuk teks.',
              button: true,
              child: InkWell(
                onTap: () =>
                    _showValues(context, title, points, secondary, validGroups),
                // Ubah kemajuan gambar dari 0 ke 1 agar grafik muncul bertahap.
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
                          // Operator % mengulang pilihan warna saat kategori lebih banyak daripada palet.
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

  // Buka kotak rincian angka supaya pengguna tidak harus menebak nilai dari bentuk grafik.
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

// Daftar pilihan bentuk grafik; setiap pilihan memiliki cara menggambar berbeda.
enum _ChartKind { journey, donut, line, bar, credits }

// Satu pasangan label dan nilai, yaitu bahan dasar deret grafik.
class _Point {
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
  const _Point(this.label, this.value);
  // Nama titik, misalnya S1 untuk semester satu.
  final String label;
  // Angka yang diwakili titik grafik.
  final double value;
}

// Palet yang dipakai bersama oleh gambar grafik dan penjelasan warnanya.
const _colors = [
  AppTheme.blue,
  Color(0xFFED7D21),
  Color(0xFF1AA95A),
  Color(0xFFB2C1D4),
  AppTheme.red,
  Color(0xFF873DD1),
];

/// Painter hanya menggambar data dari repository. Tidak mengandung angka contoh.
// Penggambar grafik yang menerjemahkan angka menjadi posisi dan ukuran bentuk.
class _AcademicPainter extends CustomPainter {
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
  _AcademicPainter({
    required this.kind,
    required this.points,
    required this.secondary,
    required this.groups,
    required this.progress,
    this.maxValue,
  });
  // Menentukan apakah kanvas menggambar cincin, batang perjalanan, garis, atau batang nilai.
  final _ChartKind kind;
  // Deret utama dan deret tambahan; tambahan digunakan untuk garis SKS kumulatif.
  final List<_Point> points, secondary;
  // Nama kategori beserta besarnya, untuk grafik cincin atau perjalanan.
  final Map<String, double> groups;
  // Kemajuan animasi: 0 belum tergambar, 1 sudah tampil penuh.
  final double progress;
  // Batas skala pilihan, misalnya 4 untuk IPK; jika kosong dihitung dari data.
  final double? maxValue;

  @override
  // Flutter memanggil fungsi ini untuk menggambar grafik sesuai ukuran ruang yang diberikan.
  void paint(Canvas canvas, Size size) {
    // Cabang grafik cincin: besar bagian lingkaran sebanding dengan nilai kategorinya.
    if (kind == _ChartKind.donut) {
      // Jumlahkan semua kategori sebagai pembagi untuk menghitung porsinya.
      final total = groups.values.fold<double>(0, (a, b) => a + b);
      if (total <= 0) {
        return;
      }
      // Ambil sisi terpendek agar lingkaran muat di area gambar.
      final radius = math.min(size.width, size.height) * .35;
      final rect = Rect.fromCircle(
        center: size.center(Offset.zero),
        radius: radius,
      );
      // Mulai dari arah atas lingkaran; sudut pada kanvas memakai radian.
      var start = -math.pi / 2;
      var index = 0;
      for (final value in groups.values) {
        // Nilai dibagi total menentukan bagian dari satu putaran penuh, yaitu 2 × pi.
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
    // Cabang perjalanan: setiap kategori menjadi potongan batang mendatar.
    if (kind == _ChartKind.journey) {
      // Jumlahkan semua kategori sebagai pembagi untuk menghitung porsinya.
      final total = groups.values.fold<double>(0, (a, b) => a + b);
      if (total <= 0) {
        return;
      }
      var x = 12.0;
      var index = 0;
      for (final value in groups.values) {
        // Lebar potongan mengikuti porsi kategori dan kemajuan animasi.
        final width = (size.width - 24) * value / total * progress;
        canvas.drawRect(
          Rect.fromLTWH(x, 65, width, 54),
          Paint()..color = _colors[index++ % _colors.length],
        );
        x += width;
      }
      return;
    }
    // Sisakan tepi untuk angka skala. LTWH berarti kiri, atas, lebar, dan tinggi.
    final rect = Rect.fromLTWH(
      30,
      10,
      math.max(1.0, size.width - 40),
      size.height - 34,
    );
    // Cari nilai terbesar pada deret utama untuk menentukan batas skala otomatis.
    final largest = points.fold<double>(0, (a, b) => math.max(a, b.value));
    // Beri ruang 15 persen di atas nilai terbesar jika skala tetap tidak ditentukan.
    // Batas minimal 1 mencegah pembagian dengan nol.
    final ceiling = math.max(1.0, maxValue ?? largest * 1.15);
    final grid = Paint()
      ..color = const Color(0xFFDFE6EF)
      ..strokeWidth = 1;
    // Gambar lima garis bantu dari nol sampai batas atas beserta angka skalanya.
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
    // Hubungkan titik-titik nilai dengan garis. Indeks menentukan posisi mendatar,
    // rasio nilai menentukan ketinggian; titik lebih tinggi memiliki koordinat y lebih kecil.
    void line(List<_Point> series, double max, Color color) {
      final path = Path();
      for (var i = 0; i < series.length; i++) {
        final x = rect.left + rect.width * (i + .5) / series.length;
        final y =
            rect.bottom -
            rect.height * (series[i].value / max).clamp(0.0, 1.0) * progress;
        // Titik pertama memulai jalur; titik berikutnya disambungkan ke jalur tersebut.
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
        // Bagi lebar bidang menjadi tempat yang sama besar untuk setiap batang.
        final slot = rect.width / points.length;
        // Ubah nilai menjadi tinggi batang; clamp menjaga batang tetap dalam bidang grafik.
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
        // Garis SKS kumulatif memakai skala relatif sendiri berdasarkan nilai puncaknya.
        final peak = secondary.fold<double>(1, (a, b) => math.max(a, b.value));
        // Menyamakan semester pada posisi batang; jangan menggeser titik bila
        // server belum mengirim SKS kumulatif salah satu semester.
        final path = Path();
        var started = false;
        for (var i = 0; i < points.length; i++) {
          // Cocokkan label semester agar titik kumulatif sejajar dengan batang semester yang sama.
          final matches = secondary.where((s) => s.label == points[i].label);
          // Lewati semester yang belum punya nilai kumulatif tanpa menciptakan titik palsu.
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
  // Minta gambar diperbarui saat kemajuan animasi, deret, kategori, atau jenis grafik berubah.
  bool shouldRepaint(covariant _AcademicPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.points != points ||
      oldDelegate.secondary != secondary ||
      oldDelegate.groups != groups ||
      oldDelegate.kind != kind;
}
