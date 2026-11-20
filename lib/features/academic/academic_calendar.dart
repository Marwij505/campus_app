import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'academic_repository.dart';

/// Deliberately contains no amount, bank, student name, token or private URL.
class AcademicCalendarEvent {
  const AcademicCalendarEvent({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    this.allDay = false,
    this.revision = 1,
  });
  final String id, title;
  final DateTime start, end;
  final bool allDay;
  final int revision;

  factory AcademicCalendarEvent.meeting(Json row) => AcademicCalendarEvent(
    id: row['id'],
    title:
        '${row['kind'] == 'class' ? 'Kuliah' : (row['kind'] as String).toUpperCase()}: ${row['title']}',
    start: DateTime.parse(row['starts_at']),
    end: DateTime.parse(row['ends_at']),
    revision: row['revision'] as int? ?? 1,
  );

  String ics(DateTime generatedAt) {
    String stamp(DateTime d) =>
        '${d.toUtc().toIso8601String().replaceAll(RegExp(r'[-:]'), '').split('.').first}Z';
    String date(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
    String escape(String s) => s
        .replaceAll('\\', '\\\\')
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll('\n', r'\n')
        .replaceAll(';', r'\;')
        .replaceAll(',', r'\,');
    // RFC 5545 limits physical lines to 75 UTF-8 octets (not characters).
    String fold(String value) {
      final lines = <String>[];
      var line = '';
      var length = 0;
      for (final rune in value.runes) {
        final char = String.fromCharCode(rune);
        final size = utf8.encode(char).length;
        if (length + size > 75) {
          lines.add(line);
          line = ' ';
          length = 1;
        }
        line += char;
        length += size;
      }
      lines.add(line);
      return lines.join('\r\n');
    }

    return [
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//Campus App//M2//ID',
      'CALSCALE:GREGORIAN',
      'BEGIN:VEVENT',
      'UID:${escape(id)}@campus-app.demo',
      'DTSTAMP:${stamp(generatedAt)}',
      'SEQUENCE:$revision',
      'SUMMARY:${escape(title)}',
      if (allDay) ...[
        'DTSTART;VALUE=DATE:${date(start)}',
        'DTEND;VALUE=DATE:${date(end)}',
      ] else ...[
        'DTSTART:${stamp(start)}',
        'DTEND:${stamp(end)}',
      ],
      'DESCRIPTION:Salinan jadwal SIAKAD. Perbarui atau hapus bila jadwal berubah atau kewajiban selesai.',
      'END:VEVENT',
      'END:VCALENDAR',
      '',
    ].map(fold).join('\r\n');
  }
}

Future<void> addAcademicCalendar(
  BuildContext context,
  AcademicCalendarEvent event, {
  Future<void> Function()? validate,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Tambah ke Kalender'),
      content: Text(
        '${event.title}\n${academicTime(event.start.toIso8601String())}\nSampai ${academicTime(event.end.toIso8601String())}\n\nSalinan tidak tersinkron otomatis. Pilih pengingat di aplikasi kalender. Impor .ics melalui menu Impor kalender pada PC.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Lanjut'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  // A confirmation dialog can outlive a session or a schedule revision.
  await validate?.call();
  if (!context.mounted) return;
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    try {
      final opened = await const MethodChannel('campus_app/calendar')
          .invokeMethod<bool>('insert', {
            'title': event.title,
            'start': event.start.millisecondsSinceEpoch,
            'end': event.end.millisecondsSinceEpoch,
            'allDay': event.allDay,
          });
      if (opened == true) return;
    } on PlatformException {
      /* Fallback to explicit .ics export. */
    } on MissingPluginException {
      /* Test/unsupported host. */
    }
  }
  final file = XFile.fromData(
    Uint8List.fromList(utf8.encode(event.ics(DateTime.now()))),
    name: 'jadwal-siakad.ics',
    mimeType: 'text/calendar',
  );
  if (kIsWeb) {
    await file.saveTo('jadwal-siakad.ics');
    return;
  }
  if (!context.mounted) return;
  if ([
    TargetPlatform.android,
    TargetPlatform.iOS,
  ].contains(defaultTargetPlatform)) {
    final box = context.findRenderObject() as RenderBox;
    await SharePlus.instance.share(
      ShareParams(
        files: [file],
        fileNameOverrides: ['jadwal-siakad.ics'],
        sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  } else {
    final location = await getSaveLocation(suggestedName: 'jadwal-siakad.ics');
    if (location != null) await file.saveTo(location.path);
  }
}
