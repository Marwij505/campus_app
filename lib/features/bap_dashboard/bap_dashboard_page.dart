// Dashboard utama Biro Administrasi Perkuliahan (BAP) FASILKOM.
// Menyediakan akses terpadu ke 7 fungsi utama administrasi akademik:
// kurikulum, jadwal, KRS, presensi/BAP, ujian, status mahasiswa, dan pelaporan.

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/app_motion.dart';
import '../../core/responsive_layout.dart';
import '../../data/bap_demo_data.dart';
import '../../data/bap_models.dart';
import '../../data/student_profile.dart';
import '../../shared/pixel_widgets.dart';
import 'bap_widgets.dart';
import 'bap_curriculum_panel.dart';
import 'bap_schedule_panel.dart';
import 'bap_krs_panel.dart';
import 'bap_attendance_panel.dart';
import 'bap_exam_panel.dart';
import 'bap_student_status_panel.dart';
import 'bap_report_panel.dart';

class BapDashboardPage extends StatefulWidget {
  const BapDashboardPage({
    super.key,
    required this.staffProfile,
    required this.onLogout,
  });

  final StudentProfile staffProfile;
  final VoidCallback onLogout;

  @override
  State<BapDashboardPage> createState() => _BapDashboardPageState();
}

class _BapDashboardPageState extends State<BapDashboardPage> {
  int _tabIndex = 0;

  // Mutable state data yang bisa diubah dari panel
  late List<Coursemaster> _courses;
  late List<KrsPeriod> _periods;
  late List<KrsOverrideRequest> _krsRequests;
  late List<MakeupClassRequest> _makeupRequests;
  late List<ExamSchedule> _examSchedules;
  late List<ClassSchedule> _schedules;
  late List<StudentAcademicStatus> _studentStatuses;
  bool _sidebarExpanded = true;
  final _contentScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _courses = List.from(BapDemoData.courses);
    _periods = List.from(BapDemoData.krsPeriods);
    _krsRequests = List.from(BapDemoData.krsOverrideRequests);
    _makeupRequests = List.from(BapDemoData.makeupRequests);
    _examSchedules = List.from(BapDemoData.examSchedules);
    _schedules = List.from(BapDemoData.schedules);
    _studentStatuses = List.from(BapDemoData.studentStatuses);
  }

  @override
  void dispose() {
    _contentScroll.dispose();
    super.dispose();
  }

  void _selectTab(int index) {
    setState(() => _tabIndex = index);
    if (_contentScroll.hasClients) {
      _contentScroll.animateTo(
        0,
        duration: AppMotion.duration(context, 260),
        curve: Curves.easeOutCubic,
      );
    }
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 11) return 'Selamat Pagi';
    if (h < 15) return 'Selamat Siang';
    if (h < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  @override
  Widget build(BuildContext context) {
    final stats = BapDemoData.stats;
    final pendingTotal =
        stats.pendingKrsOverride +
        stats.pendingMakeupClass +
        stats.pendingBapFill;

    return Scaffold(
      backgroundColor: AppTheme.paper,
      drawer: Drawer(
        width: 340,
        backgroundColor: AppTheme.paper,
        child: SafeArea(
          child: Builder(
            builder: (drawerContext) => BapSideBar(
              selectedIndex: _tabIndex,
              pendingKrsCount: stats.pendingKrsOverride,
              pendingBapCount: stats.pendingBapFill,
              expanded: true,
              onToggle: () => Navigator.of(drawerContext).pop(),
              onTabSelected: (index) {
                _selectTab(index);
                Navigator.of(drawerContext).pop();
              },
            ),
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const RepaintBoundary(child: CampusBackground(dashboard: true)),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(pendingTotal),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final content = _buildDashboardScroll(stats);
                      if (constraints.maxWidth < ResponsiveLayout.tablet) {
                        return content;
                      }
                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1280),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AnimatedContainer(
                                duration: AppMotion.duration(context, 220),
                                width: _sidebarExpanded ? 232 : 64,
                                margin: const EdgeInsets.fromLTRB(
                                  12,
                                  12,
                                  0,
                                  12,
                                ),
                                child: BapSideBar(
                                  selectedIndex: _tabIndex,
                                  pendingKrsCount: stats.pendingKrsOverride,
                                  pendingBapCount: stats.pendingBapFill,
                                  expanded: _sidebarExpanded,
                                  onToggle: () => setState(
                                    () => _sidebarExpanded = !_sidebarExpanded,
                                  ),
                                  onTabSelected: _selectTab,
                                ),
                              ),
                              Expanded(child: content),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardScroll(BapDashboardStats stats) =>
      SingleChildScrollView(
        controller: _contentScroll,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeroBanner(stats),
                const SizedBox(height: 14),
                _buildStatBar(stats),
                const SizedBox(height: 14),
                AnimatedSwitcher(
                  duration: AppMotion.duration(context, 240),
                  child: _buildActivePanel(),
                ),
                const SizedBox(height: 28),
                _buildFooter(),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      );

  // ─────────────────────── HEADER ───────────────────────
  Widget _buildHeader(int pendingTotal) {
    final isCompact =
        MediaQuery.of(context).size.width < ResponsiveLayout.tablet;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF0F4C81),
        border: Border(bottom: BorderSide(color: AppTheme.ink, width: 4)),
      ),
      child: Row(
        children: [
          const FacultyMark(compact: true),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SIAKAD · PORTAL BAP FASILKOM',
                  style: AppTheme.pixel(8, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                const Text(
                  'Biro Administrasi Perkuliahan · Semester 2026/2027 Ganjil',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFFBAD6F5),
                    fontFamily: 'SpaceMono',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (pendingTotal > 0)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.notifications_active,
                    color: Colors.white,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isCompact ? '$pendingTotal' : '$pendingTotal Perlu Tindakan',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'SpaceMono',
                    ),
                  ),
                ],
              ),
            ),
          if (isCompact)
            Builder(
              builder: (context) => IconButton(
                tooltip: 'Buka menu navigasi',
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: const Icon(Icons.menu, color: Colors.white, size: 24),
              ),
            ),
          OutlinedButton.icon(
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout, size: 13),
            label: const Text('Keluar', style: TextStyle(fontSize: 10.5)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white, width: 1.5),
              shape: const RoundedRectangleBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────── HERO BANNER ───────────────────────
  Widget _buildHeroBanner(BapDashboardStats stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 640;
        final chips = [
          _infoChip(
            Icons.school,
            '${stats.totalActiveStudents} Mahasiswa Aktif',
            const Color(0xFF60A5FA),
          ),
          const SizedBox(height: 6),
          _infoChip(
            Icons.class_,
            '${stats.totalClasses} Kelas Terdaftar',
            const Color(0xFF34D399),
          ),
        ];

        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0A2E52),
            border: Border(left: BorderSide(color: Color(0xFF3B82F6), width: 4)),
            boxShadow: [
              BoxShadow(
                color: Color(0x25000000),
                offset: Offset(3, 4),
                blurRadius: 0,
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A5F),
                      border: Border.all(color: const Color(0xFF3B82F6), width: 2),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Text(
                              _greeting(),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF93C5FD),
                                fontFamily: 'SpaceMono',
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16A34A).withValues(alpha: 0.2),
                                border: Border.all(
                                  color: const Color(0xFF16A34A),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF22C55E),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'ONLINE · BAP',
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF86EFAC),
                                      fontFamily: 'SpaceMono',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.staffProfile.name ?? 'Staff BAP',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontFamily: 'SpaceMono',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.staffProfile.major ?? 'BAP'} · ${widget.staffProfile.faculty ?? 'FASILKOM'}',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFF93C5FD),
                            fontFamily: 'SpaceMono',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (!isNarrow) ...[
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: chips,
                    ),
                  ],
                ],
              ),
              if (isNarrow) ...[
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFF1E3A5F)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  children: [
                    _infoChip(
                      Icons.school,
                      '${stats.totalActiveStudents} Mahasiswa Aktif',
                      const Color(0xFF60A5FA),
                    ),
                    _infoChip(
                      Icons.class_,
                      '${stats.totalClasses} Kelas Terdaftar',
                      const Color(0xFF34D399),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _infoChip(IconData icon, String text, Color color) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 12, color: color),
      const SizedBox(width: 5),
      Text(
        text,
        style: TextStyle(fontSize: 10, color: color, fontFamily: 'SpaceMono'),
      ),
    ],
  );

  // ─────────────────────── STAT BAR ───────────────────────
  Widget _buildStatBar(BapDashboardStats stats) {
    return LayoutBuilder(
      builder: (context, c) {
        final columns = c.maxWidth < 600 ? 2 : (c.maxWidth < 860 ? 2 : 4);
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: columns == 4 ? 2.3 : 2.5,
          children: [
            _statCard(
              'MK Override KRS',
              '${stats.pendingKrsOverride}',
              'Menunggu',
              const Color(0xFFDC2626),
              Icons.pending_actions_outlined,
            ),
            _statCard(
              'Kuliah Pengganti',
              '${stats.pendingMakeupClass}',
              'Belum Disetujui',
              const Color(0xFFD97706),
              Icons.swap_horiz_outlined,
            ),
            _statCard(
              'BAP Belum Terisi',
              '${stats.pendingBapFill}',
              'Pertemuan',
              const Color(0xFF7C3AED),
              Icons.edit_note_outlined,
            ),
            _statCard(
              'Jadwal Ujian',
              '${stats.openExamSchedules}',
              'Aktif Semester Ini',
              const Color(0xFF0369A1),
              Icons.quiz_outlined,
            ),
          ],
        );
      },
    );
  }

  Widget _statCard(
    String label,
    String value,
    String sub,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            offset: Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            color: color.withValues(alpha: 0.1),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppTheme.muted,
                    fontFamily: 'SpaceMono',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontFamily: 'SpaceMono',
                  ),
                ),
                Text(
                  sub,
                  style: const TextStyle(fontSize: 8.5, color: AppTheme.muted),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────── ACTIVE PANEL ───────────────────────
  Widget _buildActivePanel() {
    return switch (_tabIndex) {
      0 => BapCurriculumPanel(
        key: const ValueKey('curriculum'),
        courses: _courses,
        onCoursesUpdated: (updated) => setState(() => _courses = updated),
      ),
      1 => BapSchedulePanel(
        key: const ValueKey('schedule'),
        schedules: _schedules,
        onScheduleUpdated: (updated) => setState(() => _schedules = updated),
      ),
      2 => BapKrsPanel(
        key: const ValueKey('krs'),
        periods: _periods,
        onPeriodsUpdated: (updated) => setState(() => _periods = updated),
        overrideRequests: _krsRequests,
        onOverrideResolved: (updated) => setState(() => _krsRequests = updated),
      ),
      3 => BapAttendancePanel(
        key: const ValueKey('attendance'),
        summaries: BapDemoData.attendance,
        makeupRequests: _makeupRequests,
        onMakeupUpdated: (updated) => setState(() => _makeupRequests = updated),
      ),
      4 => BapExamPanel(
        key: const ValueKey('exam'),
        schedules: _examSchedules,
        onScheduleUpdated: (updated) =>
            setState(() => _examSchedules = updated),
      ),
      5 => BapStudentStatusPanel(
        key: const ValueKey('status'),
        students: _studentStatuses,
        onStudentsUpdated: (updated) =>
            setState(() => _studentStatuses = updated),
      ),
      _ => BapReportPanel(
        key: const ValueKey('report'),
        stats: BapDemoData.stats,
      ),
    };
  }

  // ─────────────────────── FOOTER ───────────────────────
  Widget _buildFooter() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        color: AppTheme.ink.withValues(alpha: 0.08),
        child: Text(
          'PORTAL BAP · SIAKAD FASILKOM · UNIVERSITAS ESA UNGGUL · 2026/2027',
          style: AppTheme.pixel(6, color: AppTheme.ink),
        ),
      ),
    );
  }
}
