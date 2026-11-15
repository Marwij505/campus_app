// Operasi bertahap tidak boleh dilanjutkan memakai sesi akun berikutnya.
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'profile_repository.dart';

class AccountOperation {
  AccountOperation(this.client, this.generation)
    : userId = client.auth.currentUser?.id,
      _session = _sessionId(client),
      _generation = generation?.call() {
    check();
  }

  final SupabaseClient client;
  final int Function()? generation;
  final String? userId, _session;
  final int? _generation;

  static String? _sessionId(SupabaseClient client) {
    final token = client.auth.currentSession?.accessToken;
    if (token == null) return null;
    try {
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(token.split('.')[1]))),
      ) as Map;
      return payload['session_id'] as String?;
    } catch (_) {
      return null;
    }
  }

  void check() {
    if (userId == null ||
        _session == null ||
        client.auth.currentUser?.id != userId ||
        _sessionId(client) != _session ||
        generation?.call() != _generation) {
      throw const ProfileException(
        'Sesi berubah. Silakan masuk ulang dan muat ulang data.',
      );
    }
  }

  // ID acak tidak bergantung pada jam perangkat atau timestamp dua unggahan.
  static String newId() {
    final random = Random.secure();
    return List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  // Hanya penolakan transaksi yang pasti boleh memicu penghapusan unggahan.
  // Timeout, koneksi putus, dan galat 5xx bukan bukti transaksi dibatalkan.
  static bool rejected(Object error) =>
      error is ProfileConflict ||
      error is PostgrestException &&
          const {'42501', '23505', '23514', '22P02'}.contains(error.code);

  Future<void> cleanup(String bucket, String path) async {
    try {
      check();
      await client.storage.from(bucket).remove([path]);
    } catch (_) {
      // Sisa objek tetap privat. Jangan mengubah hasil metadata yang sudah sah.
    }
  }

  Future<Uint8List> download(String bucket, String path) async {
    check();
    final FunctionResponse response;
    try {
      response = await client.functions
          .invoke('private-file', body: {'bucket': bucket, 'path': path})
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      check();
      throw const ProfileException(
        'Berkas tidak tersedia atau sesi berakhir. Silakan muat ulang.',
      );
    }
    check();
    if (response.data is! Uint8List) {
      throw const ProfileException(
        'Berkas tidak tersedia. Silakan muat ulang.',
      );
    }
    return response.data as Uint8List;
  }
}
