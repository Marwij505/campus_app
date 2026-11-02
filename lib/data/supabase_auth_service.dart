// Auth menyimpan token di memori; server menegakkan tenggat absolut setiap sesi.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'auth_service.dart';
import 'profile_repository.dart';
import 'student_profile.dart';
import 'supabase_profile_repository.dart';

class SupabaseAuthService extends AuthService {
  SupabaseAuthService(this.client) {
    _subscription = client.auth.onAuthStateChange.listen(
      (event) {
        if (event.event == sb.AuthChangeEvent.passwordRecovery) {
          _recovering = true;
          _notify();
        } else if (event.event == sb.AuthChangeEvent.signedOut) {
          ++_generation;
          _clear();
          _notify();
        }
      },
      onError: (_) {
        // Kesalahan refresh token menutup akses lokal; tidak pernah memakai akun demo.
        ++_generation;
        _clear();
        _notify();
      },
    );
  }
  final sb.SupabaseClient client;
  late final StreamSubscription<sb.AuthState> _subscription;
  @override
  late final ProfileRepository profiles = SupabaseProfileRepository(client);
  StudentProfile? _user;
  bool _recovering = false, _loggingIn = false;
  bool _disposed = false;
  Future<void>? _logoutTask;
  int _generation = 0;
  Duration _budget = Duration.zero;
  final _elapsed = Stopwatch();
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  bool get recovering => _recovering;
  @override
  StudentProfile? get currentUser => hasSession ? _user : null;
  @override
  bool get hasSession => _user != null && remainingSession > Duration.zero;
  @override
  Duration get remainingSession {
    final left = _budget - _elapsed.elapsed;
    return left.isNegative ? Duration.zero : left;
  }

  void _timing(Map<String, dynamic> data, Duration networkElapsed) {
    final duration = DateTime.parse(data['expires_at'])
        .difference(DateTime.parse(data['server_now']));
    _budget =
        (duration > AuthService.sessionDuration
            ? AuthService.sessionDuration
            : duration) -
        networkElapsed;
    _elapsed
      ..reset()
      ..start();
  }

  @override
  Future<StudentProfile> login({
    required String identity,
    required String password,
  }) async {
    if (_disposed || _loggingIn || _logoutTask != null) {
      throw const AuthException(
        'Sesi sedang diproses. Tunggu sebentar lalu coba lagi.',
      );
    }
    _loggingIn = true;
    final request = ++_generation;
    // Waktu menunggu jaringan ikut dihitung, bukan ditambahkan ke umur sesi.
    final network = Stopwatch()..start();
    try {
      final response = await client.functions
          .invoke(
            'login-with-nim',
            body: {'nim': identity, 'password': password},
          )
          .timeout(const Duration(seconds: 30));
      final data = Map<String, dynamic>.from(response.data as Map);
      if (request != _generation || _disposed) {
        throw const AuthException('Login dibatalkan. Silakan masuk ulang.');
      }
      await client.auth.setSession(data['refresh_token'] as String);
      if (request != _generation || _disposed) {
        await client.auth.signOut(scope: sb.SignOutScope.local);
        throw const AuthException('Login dibatalkan. Silakan masuk ulang.');
      }
      _timing(data, network.elapsed);
      final student = await profiles.load().timeout(
        const Duration(seconds: 30),
      );
      if (request != _generation || _disposed) {
        throw const AuthException('Login dibatalkan. Silakan masuk ulang.');
      }
      if (remainingSession <= Duration.zero) {
        await logout();
        throw const AuthException(
          'Sesi telah berakhir. Silakan masuk kembali.',
        );
      }
      _user = student;
      _notify();
      return student;
    } on sb.FunctionException catch (e) {
      throw AuthException(
        e.status == 429
            ? 'Terlalu banyak percobaan. Coba lagi setelah 15 menit.'
            : e.status == 401
            ? 'NIM / NIP atau password salah.'
            : 'Layanan login belum dapat dihubungi. Coba lagi.',
      );
    } on ProfileException catch (e) {
      await logout();
      throw AuthException(e.message);
    } on AuthException {
      rethrow;
    } catch (_) {
      await logout();
      throw const AuthException(
        'Koneksi atau pemuatan profil gagal. Coba login kembali.',
      );
    } finally {
      _loggingIn = false;
    }
  }

  @override
  void acceptProfile(StudentProfile profile) {
    if (!hasSession || profile.id != _user?.id) return;
    _user = profile;
    _notify();
  }

  @override
  Future<void> checkSession() async {
    if (_user == null) return;
    if (!hasSession) {
      await logout();
      return;
    }
    try {
      final request = _generation;
      final status = await client
          .rpc('profile_session_status')
          .timeout(const Duration(seconds: 10));
      if (request != _generation || _disposed) return;
      if (status == null) {
        await logout();
        return;
      }
      // Jam perangkat yang berubah tidak memperpanjang batas server atau stopwatch.
      final serverLeft = DateTime.parse(status['expires_at'])
          .difference(DateTime.parse(status['server_now']));
      if (serverLeft <= Duration.zero) {
        await logout();
        return;
      }
      if (serverLeft < remainingSession) {
        _budget = serverLeft;
        _elapsed
          ..reset()
          ..start();
        _notify();
      }
    } catch (_) {
      /* Gangguan sementara tidak menghentikan timer lokal; RLS tetap menjaga server. */
    }
  }

  @override
  Future<void> requestReset(String email) async {
    await client.auth
        .resetPasswordForEmail(
          email,
          redirectTo: kIsWeb ? Uri.base.origin : 'campusapp://auth-callback',
        )
        .timeout(const Duration(seconds: 30));
  }

  @override
  Future<void> changePassword(String password) async {
    if (!_recovering && !hasSession) {
      throw const AuthException('Sesi tidak tersedia.');
    }
    if (password.length < 12) {
      throw const AuthException('Password baru minimal 12 karakter.');
    }
    await client.auth.updateUser(sb.UserAttributes(password: password));
    await logout();
  }

  void _clear() {
    _user = null;
    _budget = Duration.zero;
    _elapsed.stop();
    _recovering = false;
  }

  @override
  Future<void> logout() async {
    // Serialisasi mencegah logout lama menghapus sesi login yang baru.
    if (_logoutTask != null) return _logoutTask;
    ++_generation;
    _clear();
    final task = _endRemoteSession();
    _logoutTask = task;
    _notify();
    try {
      await task;
    } finally {
      _logoutTask = null;
    }
  }

  Future<void> _endRemoteSession() async {
    try {
      await client
          .rpc('revoke_profile_session')
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      /* Saat offline, sesi server tetap berhenti pada tenggat. */
    }
    try {
      await client.auth.signOut(scope: sb.SignOutScope.local);
    } catch (_) {
      /* State privat aplikasi sudah dikosongkan. */
    }
  }

  @override
  void dispose() {
    _disposed = true;
    ++_generation;
    _subscription.cancel();
    _clear();
    super.dispose();
  }
}
