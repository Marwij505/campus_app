// AI hanya memilih perbaikan bahasa yang diizinkan, bukan menulis fakta baru.
// Identitas, tanggal, diagnosis, dan lampiran tidak menjadi bahan penyuntingan ini.
import 'dart:convert';

abstract interface class DraftEditorService {
  Future<String> polish(String source);
  void cancel();
}

class DraftLanguage {
  static const replacements = {
    'gak bisa': 'tidak dapat',
    'nggak bisa': 'tidak dapat',
    'ga bisa': 'tidak dapat',
    'tidak bisa': 'tidak dapat',
    'aku': 'saya',
    'saya mau': 'saya ingin',
    'pengen': 'ingin',
    'ijin': 'izin',
    'soalnya': 'karena',
    'makasih': 'terima kasih',
    'terimakasih': 'terima kasih',
    'tolong bantu': 'mohon bantuan',
    'ngasih': 'memberikan',
    'udah': 'sudah',
    'belom': 'belum',
    'nggak': 'tidak',
    'gak': 'tidak',
  };

  static RegExp pattern(String phrase) =>
      RegExp('\\b${RegExp.escape(phrase)}\\b', caseSensitive: false);
  static List<String> choices(String source) => replacements.keys
      .where((phrase) => pattern(phrase).hasMatch(source))
      .toList();
  static Map<String, Object> schema(List<String> choices) => {
    'type': 'object',
    'additionalProperties': false,
    'required': ['edits'],
    'properties': {
      'edits': {
        'type': 'array',
        'maxItems': choices.length,
        'uniqueItems': true,
        'items': {'type': 'string', 'enum': choices},
      },
    },
  };

  static String apply(String source, String result) {
    final decoded = jsonDecode(result);
    final allowed = choices(source);
    if (decoded is! Map || decoded.length != 1 || decoded['edits'] is! List) {
      throw const FormatException('Usulan bahasa tidak valid.');
    }
    final edits = decoded['edits'] as List;
    if (edits.length != edits.toSet().length ||
        edits.any((e) => e is! String || !allowed.contains(e))) {
      throw const FormatException(
        'AI mengusulkan perubahan di luar batas bahasa.',
      );
    }
    var revised = source;
    // Frasa panjang didahulukan agar penggantian tidak tumpang tindih.
    final ordered = edits.cast<String>().toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final phrase in ordered) {
      revised = revised.replaceAllMapped(
        pattern(phrase),
        (_) => replacements[phrase]!,
      );
    }
    return revised;
  }
}
