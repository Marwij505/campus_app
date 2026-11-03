// Form dan service berbagi validasi; server tetap memeriksa ulang semua masukan.
class PasswordResetValidation {
  static String email(String value) => value.trim().toLowerCase();
  static String code(String value) => value.trim().toUpperCase();
  static String? emailError(String? value) {
    final normalized = email(value ?? '');
    if (normalized.isEmpty) return 'Email wajib diisi.';
    if (normalized.length > 254 ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(normalized)) {
      return 'Alamat email belum valid.';
    }
    return null;
  }

  static String? codeError(String? value) {
    final normalized = code(value ?? '');
    if (!RegExp(r'^[A-Z0-9]{6}$').hasMatch(normalized) ||
        !RegExp(r'[A-Z]').hasMatch(normalized) ||
        !RegExp(r'[0-9]').hasMatch(normalized)) {
      return 'Kode harus 6 karakter, gabungan huruf besar dan angka.';
    }
    return null;
  }

  static String? passwordError(String? value) {
    final length = (value ?? '').length;
    return length < 12 || length > 256
        ? 'Password baru harus 12–256 karakter.'
        : null;
  }
}
