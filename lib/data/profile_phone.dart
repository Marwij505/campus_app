// Bentuk masukan boleh lokal. Bentuk simpan seragam agar database tetap konsisten.
String normalizeProfilePhone(String input) {
  var value = input.trim().replaceAll(RegExp(r'[\s()\-]'), '');
  if (value.startsWith('0')) value = '+62${value.substring(1)}';
  if (value.startsWith('62')) value = '+$value';
  return value;
}

bool validProfilePhone(String input) =>
    input.trim().isEmpty ||
    RegExp(r'^\+[1-9][0-9]{7,14}$').hasMatch(normalizeProfilePhone(input));
