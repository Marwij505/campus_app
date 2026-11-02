// Foto dari berbagai kamera diubah menjadi JPEG kecil sebelum dikirim ke server.
// Gambar animasi memakai bingkai pertama; metadata lokasi kamera tidak disimpan.
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import 'profile_repository.dart';

class ProfilePhoto {
  static const maxInputBytes = 20 * 1024 * 1024;
  static const maxPixels = 40 * 1000 * 1000;

  static Future<Uint8List> prepare(Uint8List bytes) async {
    if (bytes.isEmpty || bytes.length > maxInputBytes) {
      throw const ProfileException('Pilih gambar berukuran maksimal 20 MB.');
    }
    try {
      // Decoder Dart juga bekerja di web tanpa ImageDescriptor platform.
      final converted = await compute(_convertRaster, bytes);
      if (converted != null) return converted;
      // Format tambahan (misalnya HEIC) bergantung pada codec perangkat.
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 1024,
        allowUpscaling: false,
      );
      try {
        final frame = await codec.getNextFrame();
        try {
          final png = await frame.image.toByteData(
            format: ui.ImageByteFormat.png,
          );
          if (png != null) {
            final result = await compute(
              _convertRaster,
              png.buffer.asUint8List(),
            );
            if (result != null) return result;
          }
        } finally {
          frame.image.dispose();
        }
      } finally {
        codec.dispose();
      }
    } on ProfileException {
      rethrow;
    } catch (_) {
      /* Kesalahan codec diterjemahkan menjadi petunjuk yang bisa ditindaklanjuti. */
    }
    throw const ProfileException(
      'Gambar rusak atau formatnya belum didukung perangkat ini. Coba JPG, PNG, WebP, GIF, BMP, TIFF, atau ICO. Untuk HEIC/AVIF, ekspor ke JPG bila perangkat tidak mendukung.',
    );
  }

  static Uint8List? _convertRaster(Uint8List bytes) {
    var decoder = img.findDecoderForData(bytes);
    if (decoder == null) return null;
    // ICO menyimpan ukuran per bingkai, bukan di header utama. Batas decoder
    // tetap membatasi alokasi meskipun ukuran header ICO dilaporkan nol.
    final isIcon = decoder is img.IcoDecoder;
    if (isIcon) decoder = img.IcoDecoder(maxPixels: maxPixels);
    final info = decoder.startDecode(bytes);
    if (info == null) return null;
    if ((!isIcon && (info.width <= 0 || info.height <= 0)) ||
        info.width * info.height > maxPixels ||
        info.width > 16000 ||
        info.height > 16000) {
      throw const ProfileException(
        'Foto terlalu besar. Gunakan maksimal 40 megapiksel dan sisi maksimal 16000 piksel.',
      );
    }
    var image = decoder.decodeFrame(0);
    if (image == null) return null;
    if (image.width * image.height > maxPixels ||
        image.width > 16000 ||
        image.height > 16000) {
      throw const ProfileException(
        'Foto terlalu besar. Gunakan maksimal 40 megapiksel dan sisi maksimal 16000 piksel.',
      );
    }
    image = img.bakeOrientation(image);
    if (image.width > 1024 || image.height > 1024) {
      image = img.copyResize(
        image,
        width: image.width >= image.height ? 1024 : null,
        height: image.height > image.width ? 1024 : null,
      );
    }
    // Kanvas baru membuang EXIF dan memberi latar putih untuk transparansi.
    final clean = img.Image(width: image.width, height: image.height);
    img.fill(clean, color: img.ColorRgb8(255, 255, 255));
    img.compositeImage(clean, image);
    return img.encodeJpg(clean, quality: 88);
  }
}
