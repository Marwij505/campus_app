import 'package:flutter/material.dart';
import '../theme/retro_theme.dart';

/// Ilustrasi laboratorium orisinal, terinspirasi gaya isometrik referensi.
/// CustomPainter adalah "kanvas": dekorasi digambar tanpa file gambar besar.
/// Koordinat memakai bidang 360 × 800, lalu diperbesar sesuai layar.
class PixelLabPainter extends CustomPainter {
  const PixelLabPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Mengisi layar seperti BoxFit.cover, tanpa meregangkan ilustrasi.
    final scale = (size.width / 360 > size.height / 800)
        ? size.width / 360 : size.height / 800;
    canvas.save();
    canvas.translate((size.width - 360 * scale) / 2,
        (size.height - 800 * scale) / 2);
    canvas.scale(scale);
    final paint = Paint()..isAntiAlias = false;

    void box(double x, double y, double w, double h, Color color,
        {bool border = false}) {
      paint.color = color;
      paint.style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTWH(x, y, w, h), paint);
      if (border) {
        paint.color = RetroTheme.ink;
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 2;
        canvas.drawRect(Rect.fromLTWH(x, y, w, h), paint);
        paint.style = PaintingStyle.fill;
      }
    }

    void polygon(List<Offset> points, Color color, {bool border = true}) {
      final path = Path()..addPolygon(points, true);
      paint.color = color;
      paint.style = PaintingStyle.fill;
      canvas.drawPath(path, paint);
      if (border) {
        paint.color = RetroTheme.ink;
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 2;
        canvas.drawPath(path, paint);
        paint.style = PaintingStyle.fill;
      }
    }

    // Lantai ubin: ubah koordinat kisi menjadi bentuk isometrik/berlian.
    box(0, 0, 360, 800, const Color(0xFFAFCEDB));
    Offset tile(double u, double v) => Offset(180 + (u - v) * 36,
        180 + (u + v) * 20);
    for (var u = -12; u < 24; u++) {
      for (var v = -12; v < 24; v++) {
        polygon([tile(u.toDouble(), v.toDouble()),
          tile(u + 1.0, v.toDouble()), tile(u + 1.0, v + 1.0),
          tile(u.toDouble(), v + 1.0)],
          (u + v).isEven ? const Color(0xFFB9D6E0) : const Color(0xFFD1E5EC),
          border: false);
      }
    }
    paint..color = const Color(0xFF82AFBF)..strokeWidth = 1;
    for (var i = -12; i < 24; i++) {
      canvas.drawLine(tile(i.toDouble(), -12), tile(i.toDouble(), 24), paint);
      canvas.drawLine(tile(-12, i.toDouble()), tile(24, i.toDouble()), paint);
    }

    // Dua dinding merah dan papan pengumuman seperti sebuah lab kampus.
    polygon([const Offset(0, 0), const Offset(360, 0),
      const Offset(360, 98), const Offset(180, 170), const Offset(0, 90)],
      const Color(0xFFD0A580));
    polygon([const Offset(0, 90), const Offset(180, 170),
      const Offset(180, 223), const Offset(0, 143)], const Color(0xFFB9413B));
    polygon([const Offset(180, 170), const Offset(360, 98),
      const Offset(360, 151), const Offset(180, 223)], const Color(0xFF923C3E));
    box(18, 26, 142, 61, const Color(0xFFF1E5CB), border: true);
    final banner = TextPainter(
      text: TextSpan(text: 'SELAMAT DATANG\nMAHASISWA!',
        style: RetroTheme.pixel(10)),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: 130);
    banner.paint(canvas, const Offset(24, 41));
    box(228, 17, 106, 55, const Color(0xFF153D65), border: true);
    for (var i = 0; i < 4; i++) {
      box(235 + i * 24.0, 24, 17, 18, const Color(0xFF7FC0D0));
      box(235 + i * 24.0, 47, 17, 12, const Color(0xFFE8D6A4));
    }

    // Satu meja terdiri dari kaki, permukaan kayu, monitor, dan keyboard.
    void desk(double x, double y) {
      box(x - 14, y + 24, 8, 49, const Color(0xFF754945), border: true);
      box(x + 59, y + 36, 8, 49, const Color(0xFF754945), border: true);
      polygon([Offset(x - 26, y + 13), Offset(x + 52, y + 37),
        Offset(x + 52, y + 47), Offset(x - 26, y + 23)],
        const Color(0xFF985849));
      polygon([Offset(x + 52, y + 37), Offset(x + 81, y + 20),
        Offset(x + 81, y + 30), Offset(x + 52, y + 47)],
        const Color(0xFF633B3C));
      polygon([Offset(x, y), Offset(x + 81, y + 20),
        Offset(x + 52, y + 37), Offset(x - 26, y + 13)],
        const Color(0xFFD5996A));
      box(x + 13, y - 9, 5, 14, const Color(0xFF626C81), border: true);
      box(x - 1, y - 36, 39, 30, const Color(0xFFD7D8CB), border: true);
      box(x + 4, y - 31, 29, 19, const Color(0xFF19365B), border: true);
      box(x + 7, y - 28, 23, 3, const Color(0xFF73BAD9));
      box(x + 7, y - 22, 15, 2, const Color(0xFF558EB4));
      polygon([Offset(x + 10, y + 10), Offset(x + 39, y + 17),
        Offset(x + 27, y + 24), Offset(x - 2, y + 17)],
        const Color(0xFFE3E0CE));
      for (var i = 0; i < 4; i++) {
        box(x + 7 + i * 5.0, y + 14 + i, 3, 2, RetroTheme.muted);
      }
    }
    desk(82, 142);
    desk(214, 154);
    desk(315, 188);
    desk(23, 338);
    desk(329, 380);
    desk(24, 568);
    desk(316, 615);
    desk(100, 704);

    // Karakter sengaja menggunakan potongan persegi untuk kesan pixel.
    void student(double x, double y, Color shirt) {
      box(x + 4, y + 30, 7, 17, const Color(0xFF23334F), border: true);
      box(x + 17, y + 30, 7, 17, const Color(0xFF23334F), border: true);
      box(x + 1, y + 46, 12, 5, RetroTheme.ink);
      box(x + 16, y + 46, 12, 5, RetroTheme.ink);
      box(x, y + 13, 28, 21, shirt, border: true);
      box(x - 5, y + 16, 6, 16, const Color(0xFFD8986D), border: true);
      box(x + 27, y + 16, 6, 16, const Color(0xFFD8986D), border: true);
      box(x + 3, y - 6, 22, 22, const Color(0xFFE5AB7C), border: true);
      box(x + 1, y - 10, 26, 10, const Color(0xFF503132), border: true);
      box(x + 1, y - 1, 5, 9, const Color(0xFF503132));
      box(x + 17, y + 3, 3, 3, RetroTheme.ink);
    }
    student(154, 128, const Color(0xFF318ABC));
    student(284, 94, const Color(0xFF296C9B));
    student(40, 211, const Color(0xFFDC9461));
    student(330, 463, const Color(0xFFB74F48));
    student(207, 727, const Color(0xFF418CA6));

    // Rak server dan tanaman: detail terlihat di sisi kartu login.
    for (final origin in [const Offset(4, 460), const Offset(302, 255)]) {
      box(origin.dx, origin.dy, 48, 72, const Color(0xFF596578), border: true);
      for (var i = 0; i < 5; i++) {
        box(origin.dx + 5, origin.dy + 6 + i * 12.0, 36, 9,
            const Color(0xFF24374E), border: true);
        box(origin.dx + 32, origin.dy + 9 + i * 12.0, 4, 3, RetroTheme.green);
      }
    }
    box(308, 743, 30, 24, const Color(0xFFB77954), border: true);
    box(319, 709, 7, 35, const Color(0xFF3B744F));
    box(304, 709, 20, 12, const Color(0xFF559B61), border: true);
    box(322, 696, 19, 14, const Color(0xFF72AE6B), border: true);
    canvas.restore();
  }

  // Ilustrasi statis: tidak perlu digambar ulang pada setiap frame animasi.
  @override
  bool shouldRepaint(covariant PixelLabPainter oldDelegate) => false;
}
