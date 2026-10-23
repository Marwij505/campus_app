// Penyimpanan simulasi satu proses aplikasi. Tidak memakai jaringan/database.
// Kelak implementasi backend harus memeriksa sesi dan hak akses di server juga.

import 'package:flutter/foundation.dart';

import '../../data/student_profile.dart';
import 'leave_models.dart';
import 'leave_pdf.dart';

typedef LeavePdfBuilder = Future<Uint8List> Function(LeaveRequest request);

class LeaveRepository extends ChangeNotifier {
  LeaveRepository({required this.session, LeavePdfBuilder? pdfBuilder})
    : _pdfBuilder = pdfBuilder ?? LeavePdf.build;
  final StudentProfile? Function() session;
  final LeavePdfBuilder _pdfBuilder;
  final _records = <String, LeaveRequest>{};
  final _drafts = <String, LeaveDraft>{};
  final _reviewing = <String>{};
  int _sequence = 0;
  bool _disposed = false;
  List<LecturerRecipient> get lecturers => demoLecturers;

  StudentProfile get actor {
    final user = session();
    if (_disposed || user == null) {
      throw StateError('Sesi berakhir. Silakan login kembali.');
    }
    return user;
  }

  void _role(UserRole role) {
    if (actor.role != role) {
      throw StateError('Akun ini tidak berhak menjalankan tindakan tersebut.');
    }
  }

  LeaveDraft get draft {
    _role(UserRole.student);
    return _drafts.putIfAbsent(actor.nim, LeaveDraft.new);
  }

  void clearDraft(String identity) => _drafts.remove(identity);

  bool _canRead(LeaveRequest row, StudentProfile user) => switch (user.role) {
    UserRole.bap => true,
    UserRole.student => row.studentId == user.nim,
    UserRole.lecturer => row.decided && row.recipients.contains(user.nim),
  };

  List<LeaveRequest> get inbox {
    final user = actor;
    return _records.values
        .where((row) => _canRead(row, user))
        .map((row) => _snapshot(row, user))
        .toList()
        .reversed
        .toList();
  }

  LeaveRequest read(String id) {
    final row = _records[id];
    final user = actor;
    if (row == null || !_canRead(row, user)) {
      throw StateError('Pengajuan tidak tersedia untuk akun ini.');
    }
    return _snapshot(row, user);
  }

  LeaveRequest _snapshot(LeaveRequest row, StudentProfile user) {
    final data = row.draft.copy();
    // Dosen menerima hasil keputusan, bukti pendukung hanya untuk mahasiswa/BAP.
    if (user.role == UserRole.lecturer) data.attachments.clear();
    return LeaveRequest(
      id: row.id,
      studentId: row.studentId,
      draft: data,
      submittedAt: row.submittedAt,
      version: row.version,
      status: row.status,
      note: row.note,
      reviewer: row.reviewer,
      reviewedAt: row.reviewedAt,
      resultPdf: row.resultPdf == null
          ? null
          : Uint8List.fromList(row.resultPdf!),
      events: List.unmodifiable(row.events),
      readBy: Set.unmodifiable(row.readBy),
    );
  }

  // Submit hanya menerima isian milik sesi aktif; NIM tidak diambil dari kolom bebas.
  String submit(LeaveDraft input, {String? revisionId, LeaveDraft? preview}) {
    _role(UserRole.student);
    final user = actor;
    final submitted = preview ?? input;
    final error = submitted.validate(lecturers);
    if (error != null) throw StateError(error);
    final previous = revisionId == null ? null : _records[revisionId];
    if (revisionId != null &&
        (previous == null ||
            previous.studentId != user.nim ||
            previous.status != LeaveStatus.revision)) {
      throw StateError(
        'Hanya pengajuan milikmu yang diminta diperbaiki dapat dikirim ulang.',
      );
    }
    // Identitas objek draf direset sesudah submit: klik ganda tidak membuat surat kedua.
    if (!identical(_drafts[user.nim], input)) {
      throw StateError('Draf sudah diajukan atau bukan draf sesi ini.');
    }
    final now = DateTime.now();
    final id = previous?.id ?? 'IZIN-${++_sequence}';
    _records[id] = LeaveRequest(
      id: id,
      studentId: user.nim,
      draft: submitted.copy(),
      submittedAt: now,
      version: (previous?.version ?? 0) + 1,
      events: [
        ...?previous?.events,
        LeaveEvent(
          now,
          user.nim,
          previous == null
              ? 'Diajukan ke antrean BAP (simulasi)'
              : 'Perbaikan diajukan ulang (simulasi)',
        ),
      ],
    );
    _drafts.remove(user.nim);
    notifyListeners();
    return id;
  }

  LeaveDraft revise(String id) {
    _role(UserRole.student);
    final row = read(id);
    if (row.status != LeaveStatus.revision) {
      throw StateError('Pengajuan ini tidak dalam tahap perbaikan.');
    }
    return _drafts[actor.nim] = row.draft.copy();
  }

  // PDF dan penerusan menjadi satu hasil: bila PDF gagal, keputusan belum disimpan.
  Future<void> review(
    String id,
    LeaveStatus decision,
    String note, {
    required bool evidenceChecked,
  }) async {
    _role(UserRole.bap);
    final user = actor;
    final row = _records[id];
    if (row == null ||
        row.status != LeaveStatus.pending ||
        _reviewing.contains(id)) {
      throw StateError('Pengajuan sudah diproses atau sedang diperiksa.');
    }
    if (decision == LeaveStatus.pending ||
        note.trim().isEmpty ||
        note.length > 2000 ||
        !evidenceChecked) {
      throw StateError(
        'Periksa bukti dan penerima, pilih keputusan, serta isi catatan pemeriksaan.',
      );
    }
    _reviewing.add(id);
    try {
      final now = DateTime.now();
      final reviewed = LeaveRequest(
        id: id,
        studentId: row.studentId,
        draft: row.draft.copy(),
        submittedAt: row.submittedAt,
        version: row.version,
        status: decision,
        note: note.trim(),
        reviewer: user.nim,
        reviewedAt: now,
        events: [...row.events, LeaveEvent(now, user.nim, decision.label)],
      );
      final bytes = reviewed.decided ? await _pdfBuilder(reviewed) : null;
      if (!identical(actor, user) || actor.role != UserRole.bap) {
        throw StateError('Sesi pemeriksa berubah. Keputusan belum disimpan.');
      }
      _records[id] = LeaveRequest(
        id: id,
        studentId: row.studentId,
        draft: row.draft,
        submittedAt: row.submittedAt,
        version: row.version,
        status: decision,
        note: reviewed.note,
        reviewer: user.nim,
        reviewedAt: now,
        resultPdf: bytes,
        events: [
          ...reviewed.events,
          if (reviewed.decided)
            LeaveEvent(
              now,
              user.nim,
              'PDF tersedia bagi mahasiswa dan kotak masuk ${row.recipients.join(', ')} (simulasi)',
            ),
        ],
      );
      notifyListeners();
    } finally {
      _reviewing.remove(id);
    }
  }

  // Dibaca hanya setelah tombol dosen ditekan; tersedia bukan berarti sudah dibaca.
  void markRead(String id) {
    _role(UserRole.lecturer);
    read(id);
    final row = _records[id]!;
    if (row.readBy.contains(actor.nim)) return;
    _records[id] = LeaveRequest(
      id: row.id,
      studentId: row.studentId,
      draft: row.draft,
      submittedAt: row.submittedAt,
      version: row.version,
      status: row.status,
      note: row.note,
      reviewer: row.reviewer,
      reviewedAt: row.reviewedAt,
      resultPdf: row.resultPdf,
      readBy: {...row.readBy, actor.nim},
      events: [
        ...row.events,
        LeaveEvent(DateTime.now(), actor.nim, 'Hasil dibaca dosen (simulasi)'),
      ],
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _records.clear();
    _drafts.clear();
    super.dispose();
  }
}
