// Server HTTP buatan: SDK Supabase tetap asli, jaringan dan waktunya dapat dikendalikan.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseFixture {
  static const id = '11111111-1111-4111-8111-111111111111';
  static const sessionId = '22222222-2222-4222-8222-222222222222';
  final requests = <http.Request>[];
  final profile = <String, dynamic>{
    'id': id,
    'full_name': 'Prismatine Dante Viergo',
    'preferred_name': 'Dante',
    'role': 'student',
    'is_enabled': true,
    'avatar_variant': 'male',
    'avatar_path': null,
    'phone': null,
    'verification_status': 'unverified',
    'updated_at': '2026-10-31T08:00:00Z',
  };
  final student = <String, dynamic>{
    'user_id': id,
    'nim': '20240801001',
    'university': 'Universitas Esa Unggul',
    'faculty': 'FASILKOM',
    'program': 'Teknik Informatika',
    'current_semester': null,
    'entry_year': null,
    'academic_status': null,
  };
  final sections = <String, Map<String, dynamic>>{};
  final documentRows = <Map<String, dynamic>>[];
  final financeRows = <Map<String, dynamic>>[];
  bool conflict = false, failSections = false;
  int revision = 0;
  int loginStatus = 200;
  bool profileMissing = false, failSave = false, sessionValid = true;
  Uint8List? photoBytes;
  Completer<void>? loginGate, logoutGate, statusGate;
  final serverNow = DateTime.now().toUtc();
  late DateTime expiry = serverNow.add(const Duration(minutes: 30));
  late final client = SupabaseClient(
    'https://test.supabase.co',
    'test-publishable',
    httpClient: MockClient(handle),
    authOptions: const AuthClientOptions(
      autoRefreshToken: false,
      authFlowType: AuthFlowType.implicit,
    ),
  );
  Map<String, Object> get timing => {
    'server_now': serverNow.toIso8601String(),
    'expires_at': expiry.toIso8601String(),
  };
  String get token {
    String part(Object data) =>
        base64Url.encode(utf8.encode(jsonEncode(data))).replaceAll('=', '');
    return '${part({'alg': 'HS256', 'typ': 'JWT'})}.${part({'sub': id, 'session_id': sessionId, 'role': 'authenticated', 'exp': DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000})}.test-signature';
  }

  http.Response json(Object? value, [int status = 200]) => http.Response(
    jsonEncode(value),
    status,
    headers: {'content-type': 'application/json'},
    request: requests.last,
  );
  Future<http.Response> handle(http.Request request) async {
    requests.add(request);
    final path = request.url.path;
    if (path.endsWith('/login-with-nim')) {
      await loginGate?.future;
      return loginStatus == 200
          ? json({'refresh_token': 'test-refresh', ...timing})
          : json({'message': 'Tidak dapat masuk'}, loginStatus);
    }
    if (path.endsWith('/token')) {
      return json({
        'access_token': token,
        'refresh_token': 'test-refresh',
        'token_type': 'bearer',
        'expires_in': 3600,
        'user': {
          'id': id,
          'aud': 'authenticated',
          'email': 'student@example.test',
          'created_at': serverNow.toIso8601String(),
          'app_metadata': {},
          'user_metadata': {},
        },
      });
    }
    if (path.endsWith('/rpc/revoke_profile_session')) {
      await logoutGate?.future;
      return json(null);
    }
    if (path.endsWith('/rpc/profile_session_status')) {
      final result = sessionValid ? timing : null;
      await statusGate?.future;
      return json(result);
    }
    if (path.endsWith('/logout') || path.endsWith('/recover')) return json({});
    // Storage tetap melewati SDK asli agar urutan unggah/simpan/hapus dapat diuji.
    if (path.contains('/storage/v1/object/')) {
      if (request.method == 'POST') {
        return json({'Key': path.split('/object/').last});
      }
      if (request.method == 'DELETE') return json([]);
      if (request.method == 'GET' && photoBytes != null) {
        return http.Response.bytes(photoBytes!, 200, request: request);
      }
      return json({'message': 'Foto tidak tersedia'}, 404);
    }
    if (failSections && path.split('/').last.startsWith('student_')) {
      return json({'message': 'unavailable'}, 503);
    }
    if (path.endsWith('/student_finance')) return json(financeRows);
    if (path.endsWith('/student_documents')) {
      if (request.method == 'GET') return json(documentRows);
      if (request.method == 'POST') {
        if (failSave) return json({'message': 'denied', 'code': '42501'}, 403);
        documentRows.add({
          ...jsonDecode(request.body) as Map<String, dynamic>,
          'updated_at': 'v${revision++}',
        });
        return json(null, 201);
      }
      if (request.method == 'PATCH' || request.method == 'DELETE') {
        if (conflict) return json([]);
        final kind = request.url.queryParameters['kind']!.substring(3);
        final row = documentRows.firstWhere((r) => r['kind'] == kind);
        if (request.method == 'PATCH') {
          row.addAll(jsonDecode(request.body) as Map<String, dynamic>);
          row['updated_at'] = 'v${revision++}';
          return json([row]);
        }
        documentRows.remove(row);
        return json([row]);
      }
    }
    if (path.split('/').last.startsWith('student_')) {
      final table = path.split('/').last;
      if (request.method == 'GET') {
        return json(sections.containsKey(table) ? [sections[table]] : []);
      }
      if (failSave) return json({'message': 'denied', 'code': '42501'}, 403);
      if (request.method == 'PATCH' && conflict) return json([]);
      final row = <String, dynamic>{
        'user_id': id,
        ...?sections[table],
        ...jsonDecode(request.body) as Map<String, dynamic>,
        'updated_at': 'v${revision++}',
      };
      sections[table] = row;
      if (table == 'student_biodata') profile['phone'] = row['phone'];
      return request.headers['accept']?.contains('vnd.pgrst.object') == true
          ? json(row)
          : json([row]);
    }
    if (path.endsWith('/profiles')) {
      if (request.method == 'PATCH') {
        if (failSave) {
          return json({
            'message': 'Tidak dapat menyimpan',
            'code': '42501',
          }, 403);
        }
        profile.addAll(jsonDecode(request.body) as Map<String, dynamic>);
        return json([
          {'id': id},
        ]);
      }
      if (profileMissing) return json([]);
      return request.headers['accept']?.contains('vnd.pgrst.object') == true
          ? json(profile)
          : json([profile]);
    }
    if (path.endsWith('/students')) return json([student]);
    throw StateError('Permintaan tak terduga: ${request.method} $path');
  }

  Future<void> dispose() => client.dispose();
}
