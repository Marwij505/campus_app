// Data alur izin. Catatan baru dibuat dari isian pengguna, bukan data akademik contoh.
import 'dart:typed_data';

import '../chatbot/chat_models.dart';

enum LeaveStatus {
  pending('Menunggu BAP'),
  revision('Perlu perbaikan'),
  approved('Disetujui BAP'),
  rejected('Ditolak BAP');

  const LeaveStatus(this.label);
  final String label;
}

class LecturerRecipient {
  const LecturerRecipient(this.code, this.name);
  final String code, name;
  String get label => '$name · $code';
}

// Dua akun penerima uji sengaja bernama sama untuk membuktikan pengiriman
// memakai kode unik. Keduanya bukan dosen nyata dan tidak punya data perkuliahan.
const demoLecturers = [
  LecturerRecipient('DOS001', 'Dosen Uji'),
  LecturerRecipient('DOS002', 'Dosen Uji'),
];

class LeaveClass {
  LeaveClass({
    this.course = '',
    this.classCode = '',
    this.date = '',
    this.lecturerCode = '',
  });
  String course, classCode, date, lecturerCode;
  LeaveClass copy() => LeaveClass(
    course: course,
    classCode: classCode,
    date: date,
    lecturerCode: lecturerCode,
  );
}

class LeaveDraft {
  final fields = <String, String>{};
  final classes = <LeaveClass>[LeaveClass()];
  final attachments = <DraftAttachment>[];
  String value(String name) => fields[name]?.trim() ?? '';

  // Kalender UI memudahkan input; validasi tetap dilakukan pada lapisan data.
  String? validate(List<LecturerRecipient> recipients) {
    for (final name in [
      'Nama',
      'Program studi',
      'Tanggal mulai',
      'Tanggal akhir',
      'Jenis izin',
      'Alasan',
    ]) {
      if (value(name).isEmpty) return 'Lengkapi $name.';
      if (value(name).length > (name == 'Alasan' ? 2000 : 150)) {
        return '$name terlalu panjang.';
      }
    }
    final start = StudentDraft.parseDate(value('Tanggal mulai'));
    final end = StudentDraft.parseDate(value('Tanggal akhir'));
    if (start == null || end == null) return 'Pilih tanggal izin yang valid.';
    if (end.isBefore(start)) {
      return 'Tanggal akhir tidak boleh mendahului tanggal mulai.';
    }
    if (classes.isEmpty || classes.length > 8) {
      return 'Tambahkan 1–8 perkuliahan yang terdampak.';
    }
    final seen = <String>{};
    for (final item in classes) {
      if (item.course.trim().isEmpty || item.classCode.trim().isEmpty) {
        return 'Lengkapi mata kuliah dan kode kelas.';
      }
      if (item.course.length > 150 || item.classCode.length > 150) {
        return 'Nama mata kuliah atau kode kelas terlalu panjang.';
      }
      if (!recipients.any((r) => r.code == item.lecturerCode)) {
        return 'Pilih dosen dengan kode yang tersedia.';
      }
      final date = StudentDraft.parseDate(item.date);
      if (date == null || date.isBefore(start) || date.isAfter(end)) {
        return 'Tanggal perkuliahan harus berada dalam rentang izin.';
      }
      if (!seen.add(
        '${item.course.trim().toLowerCase()}|${item.classCode.trim().toLowerCase()}|${item.date}|${item.lecturerCode}',
      )) {
        return 'Perkuliahan yang sama tidak perlu ditambahkan dua kali.';
      }
    }
    if (attachments.isEmpty || attachments.length > 3) {
      return 'Lampirkan 1–3 bukti sebelum mengajukan izin.';
    }
    for (final file in attachments) {
      final error = DraftAttachment.validate(file.name, file.bytes);
      if (error != null) return error;
    }
    return null;
  }

  // Salinan memisahkan isian yang masih diedit dari berkas yang sudah diajukan.
  LeaveDraft copy() => LeaveDraft()
    ..fields.addAll(fields)
    ..classes.clear()
    ..classes.addAll(classes.map((item) => item.copy()))
    ..attachments.addAll(
      attachments.map(
        (file) => DraftAttachment(file.name, Uint8List.fromList(file.bytes)),
      ),
    );
}

class LeaveEvent {
  const LeaveEvent(this.at, this.actor, this.description);
  final DateTime at;
  final String actor, description;
}

class LeaveRequest {
  LeaveRequest({
    required this.id,
    required this.studentId,
    required this.draft,
    required this.submittedAt,
    this.version = 1,
    this.status = LeaveStatus.pending,
    this.note = '',
    this.reviewer,
    this.reviewedAt,
    this.resultPdf,
    this.events = const [],
    this.readBy = const {},
  });
  final String id, studentId;
  final LeaveDraft draft;
  final DateTime submittedAt;
  final int version;
  final LeaveStatus status;
  final String note;
  final String? reviewer;
  final DateTime? reviewedAt;
  final Uint8List? resultPdf;
  final List<LeaveEvent> events;
  final Set<String> readBy;
  Set<String> get recipients =>
      draft.classes.map((c) => c.lecturerCode).toSet();
  bool get decided =>
      status == LeaveStatus.approved || status == LeaveStatus.rejected;
}

String leaveDate(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
