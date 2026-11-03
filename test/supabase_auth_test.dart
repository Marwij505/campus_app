// Periksa implementasi Auth produksi dengan SDK nyata dan respons HTTP terkendali.
import 'dart:async';
import 'dart:convert';

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
      expect(server.requests.last.url.path, endsWith('/password-reset'));
      await expectLater(
        auth.changePassword('strong-test-password'),
        throwsA(isA<AuthException>()),
      );
    },
  );

  test('OTP dinormalisasi dan tidak mengembalikan sesi login', () async {
    await auth.confirmReset(
      email: ' STUDENT@EXAMPLE.TEST ',
      code: ' ab3c4d ',
      password: 'strong-test-password',
    );
    expect(jsonDecode(server.requests.last.body), {
      'action': 'confirm',
      'email': 'student@example.test',
      'code': 'AB3C4D',
      'password': 'strong-test-password',
    });
    expect(server.client.auth.currentSession, isNull);
    expect(auth.hasSession, isFalse);
  });
  test('Format email, OTP, dan password ditolak sebelum jaringan', () async {
    await expectLater(
      auth.requestReset('invalid'),
      throwsA(isA<AuthException>()),
    );
    for (final code in ['123456', 'ABCDEF', 'A1', 'AB3C4!', 'AB3C4D7']) {
      await expectLater(
        auth.confirmReset(
          email: 'student@example.test',
          code: code,
          password: 'strong-test-password',
        ),
        throwsA(isA<AuthException>()),
      );
    }
    await expectLater(
      auth.confirmReset(
        email: 'student@example.test',
        code: 'AB3C4D',
        password: 'short',
      ),
      throwsA(isA<AuthException>()),
    );
    expect(server.requests, isEmpty);
  });
  for (final status in [400, 429, 503]) {
    test('HTTP OTP $status tidak dianggap sukses', () async {
      server.resetStatus = status;
      await expectLater(
        auth.confirmReset(
          email: 'student@example.test',
          code: 'AB3C4D',
          password: 'strong-test-password',
        ),
        throwsA(isA<AuthException>()),
      );
      expect(auth.hasSession, isFalse);
    });
  }
}
