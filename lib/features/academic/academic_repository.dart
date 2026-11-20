import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/dashboard_models.dart';
import '../../data/dashboard_repository.dart';
import '../../data/account_operation.dart';
import '../../data/profile_repository.dart';

typedef Json = Map<String, dynamic>;

List<Json> rows(dynamic value) => (value as List? ?? const [])
    .map((v) => Map<String, dynamic>.from(v as Map))
    .toList();

DateTime wib(DateTime time) => time.toUtc().add(const Duration(hours: 7));
String academicTime(dynamic value) {
  if (value == null) return 'Belum ditetapkan';
  final d = wib(DateTime.parse(value.toString()));
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)} WIB';
}

class AcademicSnapshot {
  AcademicSnapshot(this.data);
  final Json data;
  Json get registration =>
      Map<String, dynamic>.from(data['registration'] as Map? ?? {});
  Json get period => Map<String, dynamic>.from(data['period'] as Map? ?? {});
  Json get krs => Map<String, dynamic>.from(data['krs'] as Map? ?? {});
  String? get periodId => period['id'] as String?;
  bool get demo => data['demo'] == true;
  DateTime get now => DateTime.parse(data['server_now'] as String).toUtc();
  String get stage =>
      data['stage'] as String? ??
      data['message'] as String? ??
      'Belum ada periode';
  List<Json> get events => rows(data['events']);
  List<Json> get notifications => rows(data['notifications']);
  List<Json> get invoices => rows(data['invoices']);
  int get unread => notifications.where((n) => n['read_at'] == null).length;
  bool get liveSchedule =>
      registration['status'] == 'active' &&
      period.isNotEmpty &&
      !now.isBefore(DateTime.parse(period['starts_at'])) &&
      now.isBefore(DateTime.parse(period['ends_at']));
  bool get canRegister =>
      period.isNotEmpty &&
      !now.isBefore(DateTime.parse(period['registration_opens'])) &&
      now.isBefore(DateTime.parse(period['registration_closes'])) &&
      ![
        'auto_leave',
        'leave_pending',
        'leave_approved',
      ].contains(registration['status']);
  bool get canEditKrs =>
      registration['status'] == 'active' &&
      period.isNotEmpty &&
      !now.isBefore(DateTime.parse(period['krs_opens'])) &&
      now.isBefore(DateTime.parse(period['krs_closes'])) &&
      !['approved', 'submitted'].contains(krs['status']);
  List<Json> get activeBills => invoices
      .where(
        (v) =>
            v['cancelled'] != true &&
            (v['paid'] as num) < (v['principal'] as num),
      )
      .toList();
  List<String> get alerts => [
    if (registration['status'] == 'auto_leave') 'Tenggat pembayaran terlewat. Hubungi petugas akademik untuk rekonsiliasi.',
    if (registration['status'] == 'leave_pending')
      'Pengajuan cuti menahan aktivasi dan KRS sampai keputusan petugas.',
    if (registration['first_due'] != null &&
        registration['initial_paid_at'] == null)
      'Pembayaran pertama: ${academicTime(registration['first_due'])}.',
    for (final v in activeBills)
      'Sisa tagihan Rp${(v['principal'] as num) - (v['paid'] as num)}. ${registration['status'] == 'active' ? 'Semester tetap aktif.' : 'Pembayaran terverifikasi diperlukan.'}',
    if (krs['status'] == 'revision') 'KRS perlu revisi: ${krs['reason'] ?? ''}',
    if (events.any((e) => e['revision'] > 1 || e['cancelled'] == true))
      'Jadwal berubah. Perbarui atau hapus salinan lama di kalender perangkat.',
  ];
}

abstract class AcademicRepository implements DashboardRepository {
  Future<AcademicSnapshot> snapshot([String? period]);
  Future<Json> command(String action, String period, Json data);
  Future<Json> review(String studentId, String period);
  AcademicSnapshot? latest;
  int _loadVersion = 0;

  @override
  Future<DashboardData> load(String nim) async {
    final version = ++_loadVersion;
    latest = null;
    final s = await snapshot();
    if (version == _loadVersion) latest = s;
    return DashboardData(
      progress: StudyProgress(
        currentSemester: s.registration['semester'] as int?,
      ),
      outstandingBillCount: s.activeBills.length,
      classes: s.liveSchedule
          ? [
              for (final e in s.events)
                if (e['kind'] == 'class' && e['cancelled'] != true)
                  ClassSchedule(
                    code: e['course_code'],
                    title: e['title'],
                    startsAt: DateTime.parse(e['starts_at']),
                    endsAt: DateTime.parse(e['ends_at']),
                    room: e['room'],
                    lecturer: e['lecturer'],
                    meeting: e['meeting'],
                    method: e['mode'],
                  ),
            ]
          : [],
    );
  }
}

class SupabaseAcademicRepository extends AcademicRepository {
  SupabaseAcademicRepository(this.client);
  final SupabaseClient client;

  Future<Json> _rpc(String name, Json params) async {
    try {
      final operation = AccountOperation(client, null);
      final response = await client
          .rpc(name, params: params)
          .timeout(const Duration(seconds: 25));
      operation.check();
      return Map<String, dynamic>.from(response as Map);
    } on ProfileException catch (e) {
      latest = null;
      throw AcademicException(e.message);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST202' || e.code == '42883') {
        throw const AcademicException(
          'Backend M2 belum diterapkan. Migrasi development memerlukan persetujuan. Fitur M1 tetap tersedia.',
        );
      }
      if (e.code == '42501') {
        throw const AcademicException(
          'Sesi berakhir atau akses tidak diizinkan.',
        );
      }
      throw const AcademicException('Data akademik gagal dimuat. Coba lagi.');
    }
  }

  @override
  Future<AcademicSnapshot> snapshot([String? period]) async =>
      AcademicSnapshot(await _rpc('m2_snapshot', {'p_period': period}));

  @override
  Future<Json> command(String action, String period, Json data) async {
    final result = await _rpc('m2_command', {
      'p_action': action,
      'p_period': period,
      'p_data': data,
    });
    if (result['ok'] != true) {
      throw AcademicException(
        result['error'] as String? ?? 'Operasi ditolak. Muat ulang.',
      );
    }
    return result;
  }

  @override
  Future<Json> review(String studentId, String period) =>
      _rpc('m2_review_student', {'p_identity': studentId, 'p_period': period});
}

class AcademicException implements Exception {
  const AcademicException(this.message);
  final String message;
  @override
  String toString() => message;
}
