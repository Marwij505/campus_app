// Jalankan sebagai target web terpisah untuk memeriksa codec di browser nyata.
// Tidak memakai akun, Supabase, atau gambar pribadi. Hasil tersedia di DOM dan JS.
// flutter build web -t tool/verify_profile_photo.dart --output build/photo-probe --no-web-resources-cdn
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:campus_app/data/profile_photo.dart';
import 'package:campus_app/data/profile_repository.dart';

@JS('profilePhotoProbeResult')
external set probeResult(JSString result);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(home: Scaffold(body: Text('Memeriksa foto…'))));
  final results = <String, String>{};
  final original = img.Image(width: 16, height: 24, numChannels: 4);
  img.fill(original, color: img.ColorRgba8(12, 80, 180, 128));
  final fixtures = <String, Uint8List>{
    'JPG': img.encodeJpg(original), 'PNG': img.encodePng(original),
    'GIF': img.encodeGif(original), 'BMP': img.encodeBmp(original),
    'TIFF': img.encodeTiff(original), 'ICO': img.encodeIco(original),
    // WebP 1x1 lossless dari fixture kecil, tanpa data pengguna.
    'WebP': base64Decode(
      'UklGRiIAAABXRUJQVlA4TBUAAAAvAAAAAAfQ//73v/+BiOh/AAA=',
    ),
  };
  for (final entry in fixtures.entries) {
    try {
      final result = img.decodeJpg(await ProfilePhoto.prepare(entry.value));
      if (result == null || result.width <= 0 || result.height <= 0) {
        throw StateError('JPEG tidak terbaca');
      }
      results[entry.key] = 'PASS ${result.width}x${result.height}';
    } catch (e) {
      results[entry.key] = 'FAIL $e';
    }
  }
  try {
    await ProfilePhoto.prepare(Uint8List.fromList([1, 2, 3]));
    results['invalid'] = 'FAIL diterima';
  } on ProfileException {
    results['invalid'] = 'PASS ditolak';
  }
  final output = jsonEncode(results);
  probeResult = output.toJS;
  runApp(MaterialApp(home: Scaffold(body: SelectableText(output))));
}
