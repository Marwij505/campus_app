// Potret pixel buatan proyek, digambar lokal tanpa foto orang lain atau layanan AI.
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class StudentProfileAvatar extends StatelessWidget {
  const StudentProfileAvatar({
    super.key,
    required this.variant,
    this.photo,
    this.size = 64,
  });
  final String variant;
  final Uint8List? photo;
  final double size;
  @override
  Widget build(BuildContext context) {
    final fallback = CustomPaint(painter: _PortraitPainter(variant));
    return Semantics(
      label: photo == null
          ? 'Ilustrasi avatar $variant'
          : 'Foto profil pribadi',
      image: true,
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.ink, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: ClipRect(
              child: photo == null
                  ? fallback
                  : Image.memory(
                      photo!,
                      key: ValueKey(photo),
                      fit: BoxFit.cover,
                      gaplessPlayback: false,
                      errorBuilder: (_, error, stack) => fallback,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// Grid 64 × 64 menjaga kontur tajam dan detail yang sama untuk semua pilihan.
class _PortraitPainter extends CustomPainter {
  const _PortraitPainter(this.variant);
  final String variant;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 64, size.height / 64);
    final paint = Paint()..isAntiAlias = false;
    void block(double x, double y, double w, double h, Color color) {
      paint.color = color;
      canvas.drawRect(Rect.fromLTWH(x, y, w, h), paint);
    }

    const skin = Color(0xFFE9B994),
        light = Color(0xFFFFD9B6),
        shade = Color(0xFFC5876F);
    const hair = Color(0xFF182235), hairLight = Color(0xFF35465B);
    block(0, 0, 64, 64, AppTheme.paper);
    block(5, 5, 54, 54, const Color(0xFFD1E3EE));
    block(8, 8, 2, 12, Colors.white);
    block(8, 8, 12, 2, Colors.white);
    block(53, 45, 2, 10, const Color(0xFFAAC9DD));
    block(45, 53, 10, 2, const Color(0xFFAAC9DD));
    if (!['male', 'female'].contains(variant)) {
      // Monogram buku netral memakai shading dan bingkai setara kedua potret.
      block(11, 18, 42, 32, AppTheme.ink);
      block(14, 15, 17, 32, Colors.white);
      block(33, 15, 17, 32, const Color(0xFFC2D7ED));
      block(31, 18, 2, 33, AppTheme.blue);
      for (var y = 22.0; y <= 38; y += 8) {
        block(18, y, 9, 2, AppTheme.blue);
        block(37, y, 9, 2, AppTheme.blue);
      }
      block(39, 12, 5, 15, AppTheme.red);
      block(19, 51, 28, 3, AppTheme.blue);
      return;
    }
    if (variant == 'female') {
      // Potret perempuan punya kontur wajah, mata, senyum, dan busana sendiri.
      // Bukan potret pria yang hanya ditambah rambut panjang.
      block(22, 8, 20, 3, hair);
      block(17, 11, 30, 6, hair);
      block(14, 17, 36, 31, hair);
      block(17, 20, 3, 25, hairLight);
      block(44, 18, 3, 27, hairLight);
      block(23, 17, 18, 17, skin);
      block(21, 20, 22, 10, skin);
      block(24, 31, 16, 5, skin);
      block(27, 35, 10, 3, shade);
      block(24, 18, 12, 6, light);
      block(22, 23, 2, 7, light);
      block(40, 23, 3, 8, shade);
      block(20, 13, 19, 5, hairLight);
      block(20, 16, 12, 4, hair);
      block(20, 19, 6, 3, hair);
      block(39, 16, 5, 7, hair);
      block(24, 23, 5, 1, hair);
      block(35, 23, 5, 1, hair);
      block(23, 26, 7, 1, hair);
      block(35, 26, 7, 1, hair);
      block(24, 27, 6, 3, Colors.white);
      block(35, 27, 6, 3, Colors.white);
      block(27, 27, 2, 3, hair);
      block(36, 27, 2, 3, hair);
      block(32, 29, 2, 3, shade);
      block(23, 31, 4, 2, const Color(0xFFE49E91));
      block(38, 31, 4, 2, const Color(0xFFE49E91));
      block(29, 34, 7, 1, const Color(0xFFA64860));
      block(30, 35, 5, 1, const Color(0xFFD67980));
      block(28, 38, 8, 6, skin);
      block(25, 42, 14, 4, light);
      block(21, 44, 22, 4, AppTheme.blue);
      block(15, 48, 34, 16, AppTheme.blue);
      block(12, 53, 3, 11, AppTheme.ink);
      block(49, 53, 3, 11, AppTheme.ink);
      block(25, 45, 14, 19, const Color(0xFFF3E5EB));
      block(24, 44, 5, 6, Colors.white);
      block(35, 44, 5, 6, Colors.white);
      block(19, 49, 4, 10, const Color(0xFF3975B6));
      block(41, 49, 4, 10, const Color(0xFF12355F));
      block(31, 51, 2, 2, AppTheme.blue);
      block(31, 57, 2, 2, AppTheme.blue);
      return;
    }
    // Rambut, telinga, leher, dan wajah memakai bayangan bertingkat tanpa blur.
    block(20, 9, 24, 3, hair);
    block(17, 12, 30, 22, hair);
    block(26, 35, 12, 13, shade);
    block(28, 36, 8, 10, skin);
    block(17, 23, 4, 8, shade);
    block(43, 23, 4, 8, shade);
    block(21, 17, 22, 17, skin);
    block(23, 32, 18, 5, skin);
    block(26, 37, 12, 3, shade);
    block(22, 18, 17, 6, light);
    block(21, 23, 3, 9, light);
    block(40, 24, 3, 10, shade);
    // Belahan rambut dan sorotan dibuat dalam blok, bukan garis lengkung.
    block(19, 13, 25, 5, hairLight);
    block(19, 16, 12, 5, hair);
    block(21, 19, 7, 3, hair);
    block(38, 16, 6, 8, hair);
    block(22, 11, 15, 2, hairLight);
    block(24, 23, 6, 2, hair);
    block(35, 23, 5, 2, hair);
    block(24, 26, 6, 3, Colors.white);
    block(35, 26, 6, 3, Colors.white);
    block(27, 26, 2, 3, AppTheme.ink);
    block(36, 26, 2, 3, AppTheme.ink);
    block(32, 27, 2, 5, shade);
    block(30, 32, 4, 1, const Color(0xFFAD6F5A));
    block(28, 35, 9, 1, const Color(0xFF8C4D45));
    block(30, 36, 5, 1, light);
    // Jaket, kerah, dan lipatan selalu berada dalam area aman bingkai.
    block(17, 45, 30, 4, AppTheme.ink);
    block(12, 49, 40, 15, AppTheme.ink);
    block(16, 49, 32, 15, AppTheme.blue);
    block(19, 46, 26, 4, AppTheme.blue);
    block(24, 44, 7, 7, Colors.white);
    block(34, 44, 7, 7, Colors.white);
    block(28, 49, 9, 15, const Color(0xFFDFEAF2));
    block(31, 49, 3, 15, AppTheme.red);
    block(19, 51, 5, 3, const Color(0xFF3975B6));
    block(21, 54, 5, 3, const Color(0xFF3975B6));
    block(40, 51, 4, 3, const Color(0xFF12355F));
    block(38, 54, 4, 3, const Color(0xFF12355F));
    block(18, 59, 2, 5, const Color(0xFF3975B6));
    block(44, 59, 2, 5, const Color(0xFF12355F));
  }

  @override
  bool shouldRepaint(_PortraitPainter oldDelegate) =>
      variant != oldDelegate.variant;
}
