import 'package:flutter_test/flutter_test.dart';

import 'package:campus_app/data/auth_service.dart';

void main() {
  test('Akun salah ditolak dan sesi demo dapat dihapus', () async {
    final service = AuthService();

    await expectLater(
      service.login(
        identity: 'salah',
        password: 'salah',
        rememberSession: false,
      ),
      throwsA(isA<AuthException>()),
    );

    expect(service.hasSession, isFalse);

    final student = await service.login(
      identity: '20240801002',
      password: '123456',
      rememberSession: true,
    );

    expect(student.nim, '20240801002');
    expect(service.hasSession, isTrue);

    service.logout();

    expect(service.hasSession, isFalse);
  });
}
