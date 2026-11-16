// Halaman beranda khusus dosen dengan dua varian peran:
// 1) Dosen Akademik (DOS001 / LecturerType.academic)
// 2) Dosen Akademik + Pembimbing TA (DOS002 / LecturerType.academicAndThesis)
// Mengikuti tema retro pixel dan pola responsif dashboard mahasiswa.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_motion.dart';
import '../../core/app_theme.dart';
import '../../core/responsive_layout.dart';
import '../../data/dashboard_models.dart';
import '../../data/lecturer_models.dart';
import '../../data/lecturer_repository.dart';
import '../../data/student_profile.dart';
import '../../shared/pixel_widgets.dart';
import '../chatbot/chat_controller.dart';
import '../chatbot/chat_launcher.dart';
import '../leave/leave_page.dart';
import '../leave/leave_repository.dart';
import 'dashboard_detail_page.dart';
import 'dashboard_widgets.dart';
import 'information_panels.dart';
import 'lecturer_panels.dart';

/// Beranda khusus dosen yang menyesuaikan fitur untuk Dosen Akademik
/// maupun Dosen Akademik + Pembimbing Tugas Akhir (TA).
class LecturerDashboardPage extends StatefulWidget {
  const LecturerDashboardPage({
    super.key,
    required this.lecturer,
    required this.onLogout,
    this.repository = const DemoLecturerRepository(),
    this.clock,
    this.leaveRepository,
  });

  final StudentProfile lecturer;
  final VoidCallback onLogout;
  final LecturerRepository repository;
  final DateTime Function()? clock;
  final LeaveRepository? leaveRepository;

  @override
  State<LecturerDashboardPage> createState() => _LecturerDashboardPageState();
}

class _LecturerDashboardPageState extends State<LecturerDashboardPage> {
  final _chat = ChatController();
  late final LeaveRepository _leaves;
  final _profileKey = GlobalKey();
  final _scheduleKey = GlobalKey();
  final _academicKey = GlobalKey();
  final _thesisKey = GlobalKey();
  final _scroll = ScrollController();

  LecturerDashboardData _data = const LecturerDashboardData();
  bool _loading = true;
  String? _error;
  int _navIndex = 0;
  int _requestId = 0;
  Timer? _clockTimer;
  late DateTime _now;

  bool get _isThesisAdvisor =>
      (_data.profile?.type ?? widget.lecturer.lecturerType) ==
      LecturerType.academicAndThesis;

  @override
  void initState() {
    super.initState();
    _leaves =
        widget.leaveRepository ??
        LeaveRepository(session: () => widget.lecturer);
    _chat.openLeave = _openLeave;
    _now = (widget.clock ?? DateTime.now)().toLocal();
    _load();
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() => _now = (widget.clock ?? DateTime.now)().toLocal());
      }
    });
  }

  @override
  void didUpdateWidget(covariant LecturerDashboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository ||
        oldWidget.lecturer.nim != widget.lecturer.nim) {
      _load();
    }
  }

  Future<void> _load() async {
    final request = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.repository.load(
        widget.lecturer.nim,
        now: _now,
      );
      if (!mounted || request != _requestId) return;
      setState(() {
        _data = result;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || request != _requestId) return;
      setState(() {
        _error = 'Data beranda dosen gagal dimuat. Silakan coba lagi.';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _chat.dispose();
    if (widget.leaveRepository == null) _leaves.dispose();
    _clockTimer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  void _navigate(int index) {
    setState(() => _navIndex = index);
    if (index == 0) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          0,
          duration: AppMotion.duration(context, 420),
          curve: Curves.easeInOutCubic,
        );
      }
      return;
    }
    final thirdKey = _isThesisAdvisor ? _thesisKey : _academicKey;
    final key = [_profileKey, _scheduleKey, thirdKey, _profileKey][index];
    final target = key.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: AppMotion.duration(context, 420),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _message(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  void _details(String title, Widget child) {
    Navigator.of(context).push(
      AppMotion.route(
        DashboardDetailPage(title: title, chat: _chat, child: child),
      ),
    );
  }

  void _openLeave() => Navigator.of(
    context,
  ).push(AppMotion.route(LeavePage(repository: _leaves, chat: _chat)));

  void _openNotice(CampusNotice item) => _details(
    item.title,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          campusDate(item.publishedAt.toLocal()),
          style: const TextStyle(color: AppTheme.muted),
        ),
        const SizedBox(height: 16),
        SelectableText(item.body),
      ],
    ),
  );

  void _allNotices(String title, List<CampusNotice> items) => _details(
    title,
    items.isEmpty
        ? DashboardEmpty(title: 'Belum ada ${title.toLowerCase()}')
        : Column(
            children: [
              for (final item in items)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.title),
                  subtitle: Text(campusDate(item.publishedAt.toLocal())),
                  onTap: () => _openNotice(item),
                ),
            ],
          ),
  );

  void _allSchedules() {
    final items = [..._data.schedules]
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    _details(
      'Jadwal Mengajar',
      items.isEmpty
          ? const DashboardEmpty(
              title: 'Belum ada jadwal mengajar',
              icon: Icons.calendar_month_outlined,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final item in items) ...[
                  Text(campusDate(item.startsAt.toLocal())),
                  const SizedBox(height: 8),
                  ClassScheduleCard(
                    item: item,
                    now: _now,
                    onTap: () => _classDetails(item),
                  ),
                ],
              ],
            ),
    );
  }

  void _classDetails(ClassSchedule item) => _details(
    'Detail Kelas Mengajar',
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(campusDate(item.startsAt.toLocal())),
        const SizedBox(height: 12),
        ClassScheduleCard(item: item, now: _now, onTap: () {}),
      ],
    ),
  );

  void _courseDetails(LecturerCourseClass course) => _details(
    '${course.code} · Kelas ${course.classCode}',
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          course.title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            InfoChip('${course.credits} SKS'),
            InfoChip('${course.studentCount} Mahasiswa'),
            InfoChip(
              'Pertemuan ${course.completedMeetings}/${course.totalMeetings}',
            ),
            InfoChip(
              course.gradeSubmitted ? 'Nilai Terisi' : 'Belum Input Nilai',
              color: course.gradeSubmitted
                  ? const Color(0xFF198754)
                  : const Color(0xFFED7D21),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Jadwal: ${course.scheduleText}'),
        const SizedBox(height: 6),
        Text('Ruang: ${course.room} (${course.method})'),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            DashboardAction(
              'Catat Presensi Pertemuan',
              () {
                setState(() {
                  final nextMeetings =
                      (course.completedMeetings + 1).clamp(0, course.totalMeetings);
                  final delta = nextMeetings - course.completedMeetings;
                  final updatedCourses = [
                    for (final c in _data.courses)
                      if (c.code == course.code && c.classCode == course.classCode)
                        LecturerCourseClass(
                          code: c.code,
                          title: c.title,
                          classCode: c.classCode,
                          credits: c.credits,
                          studentCount: c.studentCount,
                          scheduleText: c.scheduleText,
                          room: c.room,
                          method: c.method,
                          completedMeetings: nextMeetings,
                          totalMeetings: c.totalMeetings,
                          gradeSubmitted: c.gradeSubmitted,
                        )
                      else
                        c,
                  ];
                  _data = _copyData(
                    courses: updatedCourses,
                    workload: _copyWorkload(
                      completedMeetings: _data.workload.completedMeetings + delta,
                    ),
                  );
                });
                Navigator.of(context).pop();
                _message(
                  'Presensi pertemuan ${course.code} Kelas ${course.classCode} tercatat.',
                );
              },
              icon: Icons.how_to_reg_outlined,
            ),
            DashboardAction(
              course.gradeSubmitted ? 'Perbarui Nilai' : 'Tandai Nilai Terisi',
              () {
                setState(() {
                  final wasSubmitted = course.gradeSubmitted;
                  final updatedCourses = [
                    for (final c in _data.courses)
                      if (c.code == course.code && c.classCode == course.classCode)
                        LecturerCourseClass(
                          code: c.code,
                          title: c.title,
                          classCode: c.classCode,
                          credits: c.credits,
                          studentCount: c.studentCount,
                          scheduleText: c.scheduleText,
                          room: c.room,
                          method: c.method,
                          completedMeetings: c.completedMeetings,
                          totalMeetings: c.totalMeetings,
                          gradeSubmitted: true,
                        )
                      else
                        c,
                  ];
                  _data = _copyData(
                    courses: updatedCourses,
                    workload: _copyWorkload(
                      gradedClasses: _data.workload.gradedClasses +
                          (wasSubmitted ? 0 : 1),
                    ),
                  );
                });
                Navigator.of(context).pop();
                _message(
                  'Nilai ${course.code} Kelas ${course.classCode} berhasil disimpan.',
                );
              },
              icon: Icons.grading_outlined,
            ),
          ],
        ),
      ],
    ),
  );

  void _paDetails(AcademicAdvisee advisee) => _details(
    'Perwalian PA · ${advisee.name}',
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${advisee.name} (${advisee.nim})',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            InfoChip('Semester ${advisee.semester}'),
            InfoChip('IPK ${advisee.gpa.toStringAsFixed(2)}'),
            InfoChip('${advisee.takenCredits} SKS'),
          ],
        ),
        const SizedBox(height: 14),
        Text('Catatan Perwalian: ${advisee.note}'),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            DashboardAction(
              'Setujui KRS',
              () {
                _updatePaStatus(
                  advisee,
                  KrsApprovalStatus.approved,
                  'KRS disetujui oleh Dosen PA.',
                );
                Navigator.of(context).pop();
                _message('KRS ${advisee.name} (${advisee.nim}) disetujui.');
              },
              icon: Icons.check_circle_outline,
            ),
            DashboardAction(
              'Minta Revisi',
              () async {
                final note = await _promptNote(
                  title: 'Catatan Revisi KRS',
                  hint: 'Contoh: Jadwal praktikum masih bentrok.',
                );
                if (!mounted || note == null) return;
                _updatePaStatus(
                  advisee,
                  KrsApprovalStatus.revision,
                  note.isEmpty ? 'Diminta revisi oleh Dosen PA.' : note,
                );
                Navigator.of(context).pop();
                _message('Permintaan revisi KRS dikirim ke ${advisee.name}.');
              },
              icon: Icons.edit_note,
            ),
          ],
        ),
      ],
    ),
  );

  void _thesisDetails(ThesisAdvisee advisee) => _details(
    'Bimbingan TA · ${advisee.name}',
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${advisee.name} (${advisee.nim})',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            InfoChip(advisee.roleInThesis),
            InfoChip('Progres ${(advisee.progress * 100).round()}%'),
            InfoChip(advisee.pendingAction, color: const Color(0xFFED7D21)),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          'Judul Tugas Akhir:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        SelectableText(advisee.title),
        const SizedBox(height: 10),
        Text(
          'Bimbingan terakhir: ${advisee.lastGuidanceDate}',
          style: const TextStyle(color: AppTheme.muted),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            DashboardAction(
              'Catat Log Bimbingan',
              () async {
                final note = await _promptNote(
                  title: 'Log Bimbingan TA',
                  hint: 'Contoh: Perbaiki metodologi pada Bab 3.',
                );
                if (!mounted || note == null) return;
                _updateThesisAdvisee(
                  advisee,
                  lastGuidanceDate: 'Baru saja',
                  pendingAction: note.isEmpty ? advisee.pendingAction : note,
                );
                Navigator.of(context).pop();
                _message('Log bimbingan TA ${advisee.name} tersimpan.');
              },
              icon: Icons.note_add_outlined,
            ),
            DashboardAction(
              'ACC Tahap Berikutnya',
              () {
                final nextStage = switch (advisee.stage) {
                  ThesisStage.proposal => ThesisStage.chapter1To3,
                  ThesisStage.chapter1To3 => ThesisStage.research,
                  ThesisStage.research => ThesisStage.finalDraft,
                  ThesisStage.finalDraft => ThesisStage.readyDefense,
                  ThesisStage.readyDefense => ThesisStage.readyDefense,
                };
                final nextProgress = (advisee.progress + 0.15).clamp(0.0, 1.0);
                _updateThesisAdvisee(
                  advisee,
                  stage: nextStage,
                  progress: nextProgress,
                  lastGuidanceDate: 'Baru saja',
                  pendingAction: nextStage == ThesisStage.readyDefense
                      ? 'Terjadwal Sidang'
                      : 'Lanjut Tahap Berikutnya',
                );
                Navigator.of(context).pop();
                _message('Tahap TA ${advisee.name} berhasil di-ACC.');
              },
              icon: Icons.verified_outlined,
            ),
          ],
        ),
      ],
    ),
  );

  Future<String?> _promptNote({
    required String title,
    required String hint,
  }) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  void _updatePaStatus(
    AcademicAdvisee target,
    KrsApprovalStatus status,
    String note,
  ) {
    setState(() {
      final updated = [
        for (final item in _data.paAdvisees)
          if (item.nim == target.nim)
            AcademicAdvisee(
              nim: item.nim,
              name: item.name,
              semester: item.semester,
              gpa: item.gpa,
              takenCredits: item.takenCredits,
              krsStatus: status,
              note: note,
            )
          else
            item,
      ];
      final approvedCount =
          updated.where((a) => a.krsStatus == KrsApprovalStatus.approved).length;
      _data = _copyData(
        paAdvisees: updated,
        workload: _copyWorkload(paApproved: approvedCount),
      );
    });
  }

  void _updateThesisAdvisee(
    ThesisAdvisee target, {
    ThesisStage? stage,
    double? progress,
    String? lastGuidanceDate,
    String? pendingAction,
  }) {
    setState(() {
      final updated = [
        for (final item in _data.thesisAdvisees)
          if (item.nim == target.nim)
            ThesisAdvisee(
              nim: item.nim,
              name: item.name,
              title: item.title,
              roleInThesis: item.roleInThesis,
              stage: stage ?? item.stage,
              progress: progress ?? item.progress,
              lastGuidanceDate: lastGuidanceDate ?? item.lastGuidanceDate,
              pendingAction: pendingAction ?? item.pendingAction,
            )
          else
            item,
      ];
      final readyCount =
          updated.where((a) => a.stage == ThesisStage.readyDefense).length;
      _data = _copyData(
        thesisAdvisees: updated,
        workload: _copyWorkload(
          thesisReadyDefense: readyCount,
          thesisPendingReviews: (_data.workload.thesisPendingReviews - 1)
              .clamp(0, updated.length),
        ),
      );
    });
  }

  LecturerWorkload _copyWorkload({
    int? completedMeetings,
    int? gradedClasses,
    int? paApproved,
    int? thesisPendingReviews,
    int? thesisReadyDefense,
  }) => LecturerWorkload(
    totalCourses: _data.workload.totalCourses,
    totalClasses: _data.workload.totalClasses,
    totalCredits: _data.workload.totalCredits,
    totalStudents: _data.workload.totalStudents,
    completedMeetings: completedMeetings ?? _data.workload.completedMeetings,
    targetMeetings: _data.workload.targetMeetings,
    gradedClasses: gradedClasses ?? _data.workload.gradedClasses,
    paApproved: paApproved ?? _data.workload.paApproved,
    paTotal: _data.workload.paTotal,
    attendanceRate: _data.workload.attendanceRate,
    thesisActive: _data.workload.thesisActive,
    thesisCapacity: _data.workload.thesisCapacity,
    thesisPendingReviews:
        thesisPendingReviews ?? _data.workload.thesisPendingReviews,
    thesisReadyDefense:
        thesisReadyDefense ?? _data.workload.thesisReadyDefense,
  );

  LecturerDashboardData _copyData({
    LecturerWorkload? workload,
    List<LecturerCourseClass>? courses,
    List<AcademicAdvisee>? paAdvisees,
    List<ThesisAdvisee>? thesisAdvisees,
  }) => LecturerDashboardData(
    profile: _data.profile,
    workload: workload ?? _data.workload,
    schedules: _data.schedules,
    courses: courses ?? _data.courses,
    paAdvisees: paAdvisees ?? _data.paAdvisees,
    thesisAdvisees: thesisAdvisees ?? _data.thesisAdvisees,
    thesisSchedules: _data.thesisSchedules,
    announcements: _data.announcements,
    news: _data.news,
    guides: _data.guides,
  );

  void _allThesisSchedules() => _details(
    'Jadwal Bimbingan & Sidang TA',
    _data.thesisSchedules.isEmpty
        ? const DashboardEmpty(
            title: 'Belum ada jadwal TA',
            icon: Icons.event_available_outlined,
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < _data.thesisSchedules.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.school_outlined,
                    color: AppTheme.blue,
                  ),
                  title: Text(
                    '${_data.thesisSchedules[i].type} · ${_data.thesisSchedules[i].studentName}',
                  ),
                  subtitle: Text(
                    '${_data.thesisSchedules[i].topic}\n'
                    '${_data.thesisSchedules[i].dateLabel} · ${_data.thesisSchedules[i].timeLabel} · ${_data.thesisSchedules[i].location}',
                  ),
                ),
              ],
            ],
          ),
  );

  void _quickAction(String label) {
    switch (label) {
      case 'Smart Chatbot':
        openSmartChat(context, _chat);
      case 'Hasil Izin':
        _openLeave();
      case 'Jadwal Mengajar':
        _allSchedules();
      case 'Input Nilai':
      case 'Presensi Kelas':
        _details(
          label,
          LecturerCoursesPanel(
            courses: _data.courses,
            onOpen: _courseDetails,
          ),
        );
      case 'Perwalian PA':
        _details(
          'Perwalian Mahasiswa (PA)',
          AcademicAdviseesPanel(
            advisees: _data.paAdvisees,
            onOpen: _paDetails,
          ),
        );
      case 'Bimbingan TA':
        _details(
          'Mahasiswa Bimbingan TA',
          ThesisAdviseesPanel(
            advisees: _data.thesisAdvisees,
            onOpen: _thesisDetails,
          ),
        );
      case 'Jadwal Sidang':
        _allThesisSchedules();
      default:
        _details(
          label,
          DashboardEmpty(
            title: 'Modul $label',
            message: 'Layanan $label dosen siap disambungkan ke backend.',
          ),
        );
    }
  }

  List<_LecturerMenuEntry> get _quickEntries => [
    const _LecturerMenuEntry(
      'Smart Chatbot',
      Icons.smart_toy_outlined,
      Color(0xFF873DD1),
    ),
    const _LecturerMenuEntry(
      'Jadwal Mengajar',
      Icons.calendar_month_outlined,
    ),
    const _LecturerMenuEntry(
      'Input Nilai',
      Icons.grading_outlined,
      Color(0xFFED7D21),
    ),
    const _LecturerMenuEntry(
      'Presensi Kelas',
      Icons.how_to_reg_outlined,
      Color(0xFF198754),
    ),
    const _LecturerMenuEntry(
      'Perwalian PA',
      Icons.supervisor_account_outlined,
    ),
    if (_isThesisAdvisor) ...[
      const _LecturerMenuEntry(
        'Bimbingan TA',
        Icons.school_outlined,
        Color(0xFF873DD1),
      ),
      const _LecturerMenuEntry(
        'Jadwal Sidang',
        Icons.event_available_outlined,
        Color(0xFFBD2134),
      ),
    ],
    const _LecturerMenuEntry(
      'Hasil Izin',
      Icons.description_outlined,
      Color(0xFF198754),
    ),
  ];

  List<_LecturerMenuEntry> get _destinations => [
    const _LecturerMenuEntry('Beranda', Icons.home_outlined),
    const _LecturerMenuEntry('Mengajar', Icons.calendar_month_outlined),
    _LecturerMenuEntry(
      _isThesisAdvisor ? 'Bimbingan TA' : 'Perwalian',
      _isThesisAdvisor
          ? Icons.school_outlined
          : Icons.supervisor_account_outlined,
    ),
    const _LecturerMenuEntry('Profil', Icons.person_outline),
  ];

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final desktop = bounds.maxWidth >= ResponsiveLayout.desktop;
      final compact = bounds.maxWidth < ResponsiveLayout.tablet;
      final pagePadding = (bounds.maxWidth * .025).clamp(16.0, 24.0);
      final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
      return Scaffold(
        floatingActionButton: ChatLauncher(controller: _chat),
        appBar: AppBar(
          backgroundColor: AppTheme.red,
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          elevation: 0,
          toolbarHeight: 72,
          automaticallyImplyLeading: false,
          titleSpacing: 12,
          title: Row(
            children: [
              if (!largeText) ...[
                const FacultyMark(compact: true),
                const SizedBox(width: 10),
              ],
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SIAKAD',
                    style: AppTheme.pixel(11, color: Colors.white),
                  ),
                  Text(
                    _isThesisAdvisor
                        ? 'DOSEN & PEMBIMBING TA'
                        : 'DOSEN AKADEMIK',
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFFFFD6BD),
                    ),
                  ),
                ],
              ),
              if (desktop) ...[
                const SizedBox(width: 22),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _topMenu(
                          'Beranda',
                          Icons.home_outlined,
                          () => _navigate(0),
                        ),
                        _topMenu(
                          'Jadwal Mengajar',
                          Icons.calendar_month_outlined,
                          () => _quickAction('Jadwal Mengajar'),
                        ),
                        _topMenu(
                          'Perwalian PA',
                          Icons.supervisor_account_outlined,
                          () => _quickAction('Perwalian PA'),
                        ),
                        if (_isThesisAdvisor)
                          _topMenu(
                            'Bimbingan TA',
                            Icons.school_outlined,
                            () => _quickAction('Bimbingan TA'),
                          ),
                        _topMenu(
                          'Hasil Izin',
                          Icons.description_outlined,
                          () => _quickAction('Hasil Izin'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Muat ulang beranda',
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh, size: 21),
            ),
            if (!desktop)
              Builder(
                builder: (context) => IconButton(
                  tooltip: 'Buka menu',
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  icon: const Icon(Icons.menu),
                ),
              ),
            IconButton(
              tooltip: 'Keluar',
              onPressed: widget.onLogout,
              icon: const Icon(Icons.logout, size: 21),
            ),
            const SizedBox(width: 4),
          ],
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(4),
            child: ColoredBox(
              color: AppTheme.ink,
              child: SizedBox(height: 4, width: double.infinity),
            ),
          ),
        ),
        drawer: Drawer(
          child: SafeArea(
            child: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Text('MENU DOSEN', style: AppTheme.pixel(11)),
                ),
                ListTile(
                  leading: const Icon(Icons.home_outlined),
                  title: const Text('Beranda'),
                  onTap: () {
                    Navigator.pop(context);
                    _navigate(0);
                  },
                ),
                for (final entry in _quickEntries)
                  ListTile(
                    leading: Icon(entry.icon),
                    title: Text(entry.label),
                    onTap: () {
                      Navigator.pop(context);
                      _quickAction(entry.label);
                    },
                  ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Keluar'),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onLogout();
                  },
                ),
              ],
            ),
          ),
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            const RepaintBoundary(child: CampusBackground(dashboard: true)),
            SafeArea(
              top: false,
              child: RefreshIndicator(
                onRefresh: _load,
                child: Scrollbar(
                  controller: _scroll,
                  thumbVisibility: !compact,
                  child: SingleChildScrollView(
                    controller: _scroll,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(pagePadding),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: ResponsiveLayout.maxContentWidth,
                        ),
                        child: _content(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: compact
            ? Material(
                color: Colors.white,
                child: SafeArea(
                  top: false,
                  child: Container(
                    key: const ValueKey('lecturer-phone-navigation'),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppTheme.ink, width: 3),
                      ),
                    ),
                    child: Row(
                      children: [
                        for (var i = 0; i < _destinations.length; i++)
                          Expanded(child: _navButton(i)),
                      ],
                    ),
                  ),
                ),
              )
            : null,
      );
    },
  );

  Widget _topMenu(String label, IconData icon, VoidCallback onTap) =>
      TextButton.icon(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 48),
          shape: const RoundedRectangleBorder(),
        ),
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontSize: 11)),
      );

  Widget _navButton(int index) {
    final entry = _destinations[index];
    final selected = _navIndex == index;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: () => _navigate(index),
        child: AnimatedContainer(
          duration: AppMotion.duration(context, 180),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          color: selected ? const Color(0xFFEAF2FC) : Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                entry.icon,
                size: 23,
                color: selected ? AppTheme.blue : AppTheme.muted,
              ),
              const SizedBox(height: 6),
              Text(
                entry.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? AppTheme.blue : AppTheme.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final hour = _now.hour;
    final salutation = hour < 11
        ? 'Selamat pagi'
        : hour < 15
        ? 'Selamat siang'
        : hour < 18
        ? 'Selamat sore'
        : 'Selamat malam';
    final name = _data.profile?.name;
    return name == null ? '$salutation!' : '$salutation, $name';
  }

  Widget _priorityBar() {
    final pendingPa = _data.paAdvisees
        .where((a) => a.krsStatus != KrsApprovalStatus.approved)
        .length;
    final pendingGrades =
        _data.courses.where((c) => !c.gradeSubmitted).length;
    final readyDefense = _data.thesisAdvisees
        .where((a) => a.stage == ThesisStage.readyDefense)
        .length;
    final chips = <Widget>[
      if (pendingPa > 0)
        _PriorityChip(
          label: '$pendingPa KRS PA Menunggu ACC',
          icon: Icons.supervisor_account_outlined,
          color: const Color(0xFFED7D21),
          onTap: () => _quickAction('Perwalian PA'),
        ),
      if (pendingGrades > 0)
        _PriorityChip(
          label: '$pendingGrades Kelas Belum Input Nilai',
          icon: Icons.grading_outlined,
          color: AppTheme.blue,
          onTap: () => _quickAction('Input Nilai'),
        ),
      if (_isThesisAdvisor && _data.workload.thesisPendingReviews > 0)
        _PriorityChip(
          label: '${_data.workload.thesisPendingReviews} Review TA Menunggu',
          icon: Icons.rate_review_outlined,
          color: const Color(0xFF873DD1),
          onTap: () => _quickAction('Bimbingan TA'),
        ),
      if (_isThesisAdvisor && readyDefense > 0)
        _PriorityChip(
          label: '$readyDefense Mahasiswa Siap Sidang',
          icon: Icons.verified_outlined,
          color: const Color(0xFF198754),
          onTap: () => _quickAction('Jadwal Sidang'),
        ),
    ];
    if (chips.isEmpty) {
      return PixelPanel(
        color: const Color(0xFFF1FBF4),
        child: Row(
          children: const [
            Icon(Icons.check_circle_outline, color: Color(0xFF198754)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Semua tugas perwalian dan penilaian kelas sudah tuntas!',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }
    return PixelPanel(
      color: const Color(0xFFFFFBF2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PRIORITAS HARI INI · Ketuk untuk tindak lanjut cepat',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppTheme.muted,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: chips),
        ],
      ),
    );
  }

  Widget _content() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        _isThesisAdvisor
            ? 'BERANDA DOSEN & PEMBIMBING TA'
            : 'BERANDA DOSEN AKADEMIK',
        style: AppTheme.pixel(9, color: AppTheme.blue),
      ),
      const SizedBox(height: 8),
      Text(
        _greeting(),
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 4),
      Text(
        _isThesisAdvisor
            ? 'Kelola perkuliahan, perwalian PA, dan bimbingan Tugas Akhir dalam satu beranda.'
            : 'Kelola jadwal mengajar, nilai, presensi, dan perwalian PA dalam satu beranda.',
        style: const TextStyle(fontSize: 11, color: AppTheme.muted),
      ),
      const SizedBox(height: 20),
      if (_loading) ...[
        const LinearProgressIndicator(minHeight: 3),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text('Memuat beranda dosen…'),
        ),
      ],
      if (_error != null) ...[
        PixelPanel(
          color: const Color(0xFFFFF0F0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_error!),
              const SizedBox(height: 10),
              DashboardAction('Coba lagi', _load),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
      if (!_loading && _error == null) ...[
        _agendaBanner(),
        const SizedBox(height: 14),
        _priorityBar(),
        const SizedBox(height: 20),
      ],
      Entrance(
        child: LecturerProfilePanel(
          key: _profileKey,
          profile: _data.profile,
          workload: _data.workload,
          fallbackCode: widget.lecturer.nim,
        ),
      ),
      const SizedBox(height: 24),
      Text('AKSES CEPAT', style: AppTheme.pixel(9, color: AppTheme.blue)),
      const SizedBox(height: 14),
      Entrance(delay: 60, child: _quickGrid()),
      const SizedBox(height: 24),
      if (!_loading && _error == null) _responsivePanels(),
      const SizedBox(height: 28),
      const Text(
        'CAMPUS APP · SIAKAD FASILKOM',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 10, color: AppTheme.muted),
      ),
      const SizedBox(height: 88),
    ],
  );

  Widget _agendaBanner() {
    final next = activeOrNextClass(_data.schedules, _now);
    final ongoing = next != null && !next.startsAt.isAfter(_now);
    return PixelPanel(
      color: const Color(0xFFF2F8FF),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            next == null
                ? Icons.event_note_outlined
                : Icons.co_present_outlined,
            color: AppTheme.blue,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  next == null
                      ? 'Belum ada jadwal mengajar terdekat'
                      : ongoing
                      ? 'Sesi mengajar sedang berlangsung'
                      : 'Jadwal mengajar berikutnya',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  next == null
                      ? 'Jadwal mengajar akan tampil setelah data semester tersedia.'
                      : '${next.code} · ${next.title}\n${campusDate(next.startsAt.toLocal())} · ${campusTime(next.startsAt)} – ${campusTime(next.endsAt)} · ${next.room}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.muted),
                ),
                if (next != null) ...[
                  const SizedBox(height: 12),
                  DashboardAction('Lihat detail', () => _classDetails(next)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickGrid() => LayoutBuilder(
    builder: (context, bounds) {
      final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
      final columns = scale >= 1.8 && bounds.maxWidth < 430
          ? 1
          : ResponsiveLayout.quickColumns(bounds.maxWidth / scale);
      final width = (bounds.maxWidth - (columns - 1) * 12) / columns;
      final entries = _quickEntries;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final entry in entries)
            SizedBox(
              width: width,
              child: PixelTapSurface(
                label: entry.label,
                onTap: () => _quickAction(entry.label),
                borderColor: AppTheme.ink,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 16,
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      color: entry.color.withValues(alpha: .1),
                      child: Icon(entry.icon, color: entry.color, size: 26),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      entry.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    },
  );

  Widget _responsivePanels() => LayoutBuilder(
    builder: (context, bounds) {
      final schedule = SchedulePanel(
        key: _scheduleKey,
        title: 'JADWAL MENGAJAR HARI INI',
        items: todayClasses(_data.schedules, _now),
        now: _now,
        next: activeOrNextClass(_data.schedules, _now),
        onAll: _allSchedules,
        onOpen: _classDetails,
      );
      final workload = LecturerWorkloadPanel(
        workload: _data.workload,
        isThesisAdvisor: _isThesisAdvisor,
      );
      final courses = LecturerCoursesPanel(
        courses: _data.courses,
        onOpen: _courseDetails,
      );
      final pa = AcademicAdviseesPanel(
        key: _academicKey,
        advisees: _data.paAdvisees,
        onOpen: _paDetails,
      );
      final thesis = ThesisAdviseesPanel(
        key: _thesisKey,
        advisees: _data.thesisAdvisees,
        onOpen: _thesisDetails,
      );
      final thesisSchedules = ThesisSchedulePanel(
        items: _data.thesisSchedules,
        onAll: _allThesisSchedules,
      );
      final announcements = NoticePanel(
        title: 'PENGUMUMAN',
        emptyTitle: 'Belum ada pengumuman',
        items: _data.announcements,
        icon: Icons.campaign_outlined,
        onOpen: _openNotice,
        onAll: () => _allNotices('Pengumuman', _data.announcements),
      );
      final news = NoticePanel(
        title: 'BERITA',
        emptyTitle: 'Belum ada berita',
        items: _data.news,
        icon: Icons.newspaper_outlined,
        onOpen: _openNotice,
        onAll: () => _allNotices('Berita', _data.news),
      );
      final guides = GuidesPanel(
        items: _data.guides,
        onOpen: (guide) => _details(guide.title, SelectableText(guide.content)),
      );

      final mainStack = _isThesisAdvisor
          ? [workload, thesis, thesisSchedules, courses, pa]
          : [workload, courses, pa];
      final sideStack = [schedule, announcements, news, guides];

      final scale = MediaQuery.textScalerOf(context).scale(1);
      if (bounds.maxWidth >= 1100 && scale <= 1.3) {
        return Row(
          key: const ValueKey('lecturer-desktop-panels'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 7, child: _stack(mainStack)),
            const SizedBox(width: 24),
            Expanded(flex: 3, child: _stack(sideStack)),
          ],
        );
      }
      if (bounds.maxWidth >= 680 && scale <= 1.3) {
        return Column(
          key: const ValueKey('lecturer-tablet-panels'),
          children: [
            ResponsiveCards(
              minWidth: 300,
              maximum: 2,
              children: sideStack,
            ),
            const SizedBox(height: 24),
            _stack(mainStack),
          ],
        );
      }
      return _stack(
        [...sideStack, ...mainStack],
        key: const ValueKey('lecturer-phone-panels'),
      );
    },
  );

  Widget _stack(List<Widget> items, {Key? key}) => Column(
    key: key,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < items.length; i++) ...[
        if (i > 0) const SizedBox(height: 24),
        items[i],
      ],
    ],
  );
}

class _LecturerMenuEntry {
  const _LecturerMenuEntry(this.label, this.icon, [this.color = AppTheme.blue]);
  final String label;
  final IconData icon;
  final Color color;
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    ),
  );
}
