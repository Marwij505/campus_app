// Menentukan alamat komputer AI tanpa mencampurnya dengan tampilan percakapan.
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatConnection {
  static const _key = 'campus.localAi.address';
  static String? _manual;

  // Alamat pilihan pengguna tetap tersimpan di perangkat, bukan pada akun kampus.
  static Future<String> savedAddress() async {
    try {
      return _manual ??
          (await SharedPreferences.getInstance()).getString(_key) ??
          '';
    } catch (_) {
      return _manual ?? '';
    }
  }

  static Future<void> saveAddress(String address) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = address.isEmpty
        ? await prefs.remove(_key)
        : await prefs.setString(_key, address);
    if (!saved) throw StateError('Alamat belum tersimpan. Coba lagi.');
    _manual = address;
  }

  static Future<List<String>> candidates() async {
    var hosts = <String>[];
    try {
      // start.ps1 memperbarui berkas ini sebelum flutter run/build.
      final json = jsonDecode(
        await rootBundle.loadString('assets/local_ai/connection.json'),
      ) as Map;
      hosts = (json['addresses'] as List).cast<String>();
    } catch (_) {
      // Clone baru tetap dapat memakai localhost/emulator tanpa berkas buatan mesin.
    }
    return addressesFor(
      manual: await savedAddress(),
      configured: const String.fromEnvironment('OLLAMA_URL'),
      webHost: kIsWeb ? Uri.base.host : '',
      android: !kIsWeb && defaultTargetPlatform == TargetPlatform.android,
      generated: hosts,
    );
  }

  // Pilihan eksplisit tidak dialihkan diam-diam ke komputer AI yang lain.
  static List<String> addressesFor({
    String manual = '',
    String configured = '',
    String webHost = '',
    bool android = false,
    List<String> generated = const [],
  }) {
    if (manual.isNotEmpty) return [manual];
    if (configured.isNotEmpty) return [configured];
    return {
      if (webHost.isNotEmpty &&
          !['localhost', '127.0.0.1', '::1'].contains(webHost))
        Uri(scheme: 'http', host: webHost, port: 11435).toString(),
      if (android) 'http://10.0.2.2:11435',
      ...generated,
      'http://127.0.0.1:11435',
    }.toList();
  }
}
