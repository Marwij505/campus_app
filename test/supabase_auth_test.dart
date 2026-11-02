// Periksa implementasi Auth produksi dengan SDK nyata dan respons HTTP terkendali.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:campus_app/data/auth_service.dart';
import 'package:campus_app/data/supabase_auth_service.dart';

import 'support/supabase_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SupabaseFixture server;
  late SupabaseAuthService auth;
  setUp(() {
    server = SupabaseFixture();
    auth = SupabaseAuthService(server.client);
  });
  tearDown(() async {
    auth.dispose();
    await server.dispose();
  });
  Future<void> login() async {
    await auth.login(identity: '20240801001', password: 'test-only-password');
  }

  test('Fixture SDK dapat membaca profil melalui Data API', () async {
    await server.client.auth.setSession('test-refresh');
    expect((await auth.profiles.load()).nim, '20240801001');
  });

  test(
    'Login memuat profil asli dan mempertahankan data akademik null',
    () async {
      await login();
      expect(auth.currentUser!.greetingName, 'Dante');
      expect(auth.currentUser!.semester, isNull);
      expect(auth.currentUser!.entryYear, isNull);
      expect(auth.currentUser!.gpa, isNull);
      expect(auth.currentUser!.verificationStatus, 'unverified');
      expect(auth.hasSession, isTrue);
      expect(auth.remainingSession <= AuthService.sessionDuration, isTrue);
      expect(server.requests.first.url.path, endsWith('/login-with-nim'));
    },
  );
  for (final status in [401, 429, 503]) {
    test('HTTP $status tidak memberi akun demo atau sesi', () async {
      server.loginStatus = status;
      await expectLater(login(), throwsA(isA<AuthException>()));
      expect(auth.currentUser, isNull);
      expect(
        server.requests.where((r) => r.url.path.endsWith('/profiles')),
        isEmpty,
      );
    });
  }
  test('Profil hilang membatalkan sesi dan menghapus token', () async {
    server.profileMissing = true;
    await expectLater(login(), throwsA(isA<AuthException>()));
    expect(auth.currentUser, isNull);
    expect(server.client.auth.currentSession, isNull);
  });
  test(
    'Logout membersihkan state sebelum jaringan selesai dan menahan login baru',
    () async {
      await login();
      server.logoutGate = Completer<void>();
      final pending = auth.logout();
      expect(auth.currentUser, isNull);
      await expectLater(login(), throwsA(isA<AuthException>()));
      server.logoutGate!.complete();
      await pending;
      await login();
      expect(auth.hasSession, isTrue);
    },
  );
  test(
    'Respons login terlambat tidak menghidupkan sesi yang dibatalkan',
    () async {
      server.loginGate = Completer<void>();
      final pending = expectLater(login(), throwsA(isA<AuthException>()));
      await auth.logout();
      server.loginGate!.complete();
      await pending;
      expect(auth.currentUser, isNull);
      expect(server.client.auth.currentSession, isNull);
    },
  );
  test('Status sesi lama tidak mengeluarkan sesi login berikutnya', () async {
    await login();
    server.sessionValid = false;
    server.statusGate = Completer<void>();
    final old = auth.checkSession();
    await Future<void>.delayed(Duration.zero);
    await auth.logout();
    server.sessionValid = true;
    await login();
    server.statusGate!.complete();
    await old;
    expect(auth.hasSession, isTrue);
  });
  test('Status server memperpendek tetapi tidak memperpanjang sesi', () async {
    await login();
    server.expiry = server.serverNow.add(const Duration(minutes: 5));
    await auth.checkSession();
    expect(auth.remainingSession <= const Duration(minutes: 5), isTrue);
    server.expiry = server.serverNow.add(const Duration(days: 1));
    await auth.checkSession();
    expect(auth.remainingSession <= const Duration(minutes: 5), isTrue);
    server.sessionValid = false;
    await auth.checkSession();
    expect(auth.currentUser, isNull);
  });
  test(
    'Reset menggunakan Auth server dan menolak perubahan password tanpa sesi',
    () async {
      await auth.requestReset('student@example.test');
      expect(server.requests.last.url.path, endsWith('/recover'));
      await expectLater(
        auth.changePassword('strong-test-password'),
        throwsA(isA<AuthException>()),
      );
    },
  );
}
