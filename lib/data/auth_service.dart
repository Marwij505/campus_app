// Kontrak autentikasi. Akun simulasi hanya berada pada fake di folder test.
import 'package:flutter/foundation.dart';

import 'profile_repository.dart';
import 'student_profile.dart';

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
}

abstract class AuthService extends ChangeNotifier {
  static const sessionDuration = Duration(minutes: 30);
  StudentProfile? get currentUser;
  bool get hasSession;
  Duration get remainingSession;
  bool get recovering => false;
  ProfileRepository? get profiles => null;
  Future<StudentProfile> login({
    required String identity,
    required String password,
  });
  Future<void> requestReset(String email);
  Future<void> changePassword(String password);
  Future<void> logout();
  Future<void> checkSession();
  void acceptProfile(StudentProfile profile);
}
