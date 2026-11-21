// Halaman utama Dashboard Dosen Akademik dan Dosen Pembimbing SIAKAD.
// Dirancang mandiri dengan arsitektur retro-modern, responsif,
// dan efisien untuk mendukung beban kerja tridharma pengajaran, perwalian, skripsi, dan penilaian.

import 'package:flutter/material.dart';

import '../../core/app_motion.dart';
import '../../core/app_theme.dart';
import '../../core/responsive_layout.dart';
import '../../data/lecturer_demo_data.dart';
import '../../data/lecturer_models.dart';
import '../../data/student_profile.dart';
import '../../shared/pixel_widgets.dart';
import '../leave/leave_repository.dart';
import 'advisor_panel.dart';
import 'lecturer_widgets.dart';
import 'teaching_panel.dart';

class LecturerDashboardPage extends StatefulWidget {
  const LecturerDashboardPage({
    super.key,
    required this.lecturerProfile,
    required this.onLogout,
    this.leaveRepository,
  });

  final StudentProfile lecturerProfile;
  final VoidCallback onLogout;
  final LeaveRepository? leaveRepository;

  @override
  State<LecturerDashboardPage> createState() => _LecturerDashboardPageState();
}

class _LecturerDashboardPageState extends State<LecturerDashboardPage> {
  late String _currentNip;
  late LecturerProfileData _profile;
  late LecturerDashboardStats _stats;
  late List<TeachingScheduleItem> _schedules;
  late List<TeachingClassSummary> _classes;
  late List<KrsApprovalRequest> _krsRequests;
  late List<AdvisedStudent> _advisees;
  late List<ThesisAdvisee> _thesisAdvisees;
  bool _sidebarExpanded = true;

  // Indeks tab yang sedang aktif:
  // 0: Perkuliahan & Jadwal Mengajar
  // 1: Perwalian Mahasiswa (KRS & Evaluasi Studi)
  // 2 (jika dosen pembimbing): Bimbingan Skripsi
  // 3 (atau 2 jika dosen akademik tanpa skripsi): Rekap Nilai & Kelas
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentNip = widget.lecturerProfile.nim;
    _loadDataForNip(_currentNip);

    // Dosen DOS002 (DPA Utama) otomatis diarahkan ke tab Perwalian/Bimbingan
    if (_currentNip == 'DOS002') {
      _selectedTabIndex = 1;
    } else {
      _selectedTabIndex = 0;
    }
  }

  void _loadDataForNip(String nip) {
    _profile = LecturerDemoData.getProfile(nip);
    _stats = LecturerDemoData.getStats(nip);
    _schedules = LecturerDemoData.getTeachingSchedules(nip);
    _classes = LecturerDemoData.getTeachingClasses(nip);
    _krsRequests = LecturerDemoData.getKrsApprovals(nip);
    _advisees = LecturerDemoData.getAdvisedStudents(nip);
    _thesisAdvisees = LecturerDemoData.getThesisAdvisees(nip);

    // Validasi tab jika berpindah ke akun tanpa skripsi
    final maxTabs = _thesisAdvisees.isNotEmpty ? 5 : 4;
    if (_selectedTabIndex >= maxTabs) {
      _selectedTabIndex = maxTabs - 1;
    }
  }

  void _switchAccount() {
    setState(() {
      if (_currentNip == 'DOS001') {
        _currentNip = 'DOS002';
      } else {
        _currentNip = 'DOS001';
      }
      _loadDataForNip(_currentNip);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Beralih ke akun demo: ${_profile.nameWithTitle} (${_profile.nip})',
        ),
        backgroundColor: AppTheme.blue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingKrsCount = _krsRequests
        .where((r) => r.status == KrsStatus.pending)
        .length;
    final hasThesisTab = _thesisAdvisees.isNotEmpty;

    return Scaffold(
      backgroundColor: AppTheme.paper,
      drawer: Drawer(
        width: 280,
        backgroundColor: AppTheme.paper,
        child: SafeArea(
          child: Builder(
            builder: (drawerContext) => ModernLecturerSideBar(
              selectedIndex: _selectedTabIndex,
              hasThesisTab: hasThesisTab,
              pendingKrsCount: pendingKrsCount,
              expanded: true,
              onToggle: () => Navigator.of(drawerContext).pop(),
              onTabSelected: (index) {
                setState(() => _selectedTabIndex = index);
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
                _buildHeader(context),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact =
                          constraints.maxWidth < ResponsiveLayout.tablet;
                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1280),
                          child: isCompact
                              ? Column(
                                  children: [
                                    Expanded(
                                      child: _buildDashboardScroll(
                                        hasThesisTab,
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    AnimatedContainer(
                                      duration: AppMotion.duration(
                                        context,
                                        220,
                                      ),
                                      width: _sidebarExpanded ? 232 : 64,
                                      margin: const EdgeInsets.fromLTRB(
                                        12,
                                        12,
                                        0,
                                        12,
                                      ),
                                      child: ModernLecturerSideBar(
                                        selectedIndex: _selectedTabIndex,
                                        hasThesisTab: hasThesisTab,
                                        pendingKrsCount: pendingKrsCount,
                                        expanded: _sidebarExpanded,
                                        onToggle: () => setState(
                                          () => _sidebarExpanded =
                                              !_sidebarExpanded,
                                        ),
                                        onTabSelected: (index) => setState(
                                          () => _selectedTabIndex = index,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildDashboardScroll(
                                        hasThesisTab,
                                      ),
                                    ),
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

  Widget _buildDashboardScroll(bool hasThesisTab) => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LecturerHeroBanner(
          profile: _profile,
          onSwitchAccount: _switchAccount,
          onLogout: widget.onLogout,
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: AppMotion.duration(context, 260),
          child: _buildActiveTabContent(hasThesisTab),
        ),
        const SizedBox(height: 32),
        _buildFooter(),
        const SizedBox(height: 16),
      ],
    ),
  );

  Widget _buildActiveTabContent(bool hasThesisTab) {
    // Tab 0: Perkuliahan & Jadwal Mengajar
    if (_selectedTabIndex == 0) {
      return TeachingPanel(
        key: ValueKey('teaching-$_currentNip'),
        schedules: _schedules,
        classes: _classes,
        stats: _stats,
        leaveRepository: widget.leaveRepository,
        onScheduleUpdated: (updated) => setState(() => _schedules = updated),
      );
    }

    // Tab 1: Validasi KRS Mahasiswa
    if (_selectedTabIndex == 1) {
      return AdvisorPanel(
        key: ValueKey('advisor-$_currentNip-krs'),
        krsRequests: _krsRequests,
        advisees: _advisees,
        thesisAdvisees: _thesisAdvisees,
        stats: _stats,
        initialSubTab: 0,
        onKrsUpdated: (updated) => setState(() => _krsRequests = updated),
        onThesisUpdated: (updated) => setState(() => _thesisAdvisees = updated),
      );
    }

    // Tab 2: Daftar Mahasiswa Wali
    if (_selectedTabIndex == 2) {
      return AdvisorPanel(
        key: ValueKey('advisor-$_currentNip-advisees'),
        krsRequests: _krsRequests,
        advisees: _advisees,
        thesisAdvisees: _thesisAdvisees,
        stats: _stats,
        initialSubTab: 1,
        onKrsUpdated: (updated) => setState(() => _krsRequests = updated),
        onThesisUpdated: (updated) => setState(() => _thesisAdvisees = updated),
      );
    }

    // Tab 3 (Khusus Dosen Pembimbing yang memiliki bimbingan skripsi):
    if (hasThesisTab && _selectedTabIndex == 3) {
      return AdvisorPanel(
        key: ValueKey('advisor-$_currentNip-thesis'),
        krsRequests: _krsRequests,
        advisees: _advisees,
        thesisAdvisees: _thesisAdvisees,
        stats: _stats,
        initialSubTab: 2, // Langsung aktif ke subtab bimbingan skripsi
        onKrsUpdated: (updated) => setState(() => _krsRequests = updated),
        onThesisUpdated: (updated) => setState(() => _thesisAdvisees = updated),
      );
    }

    // Tab Terakhir: Rekap Nilai & Kelas (Index 4 untuk DOS002 atau Index 3 untuk DOS001)
    return _buildGradeOverviewPanel();
  }

  Widget _buildGradeOverviewPanel() {
    final totalCredits = _classes.fold<int>(0, (sum, c) => sum + c.credits);
    final totalStudents = _classes.fold<int>(
      0,
      (sum, c) => sum + c.totalStudents,
    );
    final avgAttendance = _classes.isNotEmpty
        ? (_classes.fold<double>(0.0, (sum, c) => sum + c.averageAttendance) /
              _classes.length)
        : 0.0;

    return Column(
      key: ValueKey('grades-$_currentNip'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Ringkasan Metrik Rekap Nilai
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 620;
            return GridView.count(
              crossAxisCount: isNarrow ? 1 : 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: isNarrow ? 2.8 : 2.0,
              children: [
                ModernStatPill(
                  label: 'TOTAL KELAS DIAMPU',
                  value: '${_classes.length}',
                  suffix: 'Kelas',
                  color: AppTheme.blue,
                  icon: Icons.class_outlined,
                  progress: 1.0,
                ),
                ModernStatPill(
                  label: 'BEBAN SKS MENGAJAR',
                  value: '$totalCredits',
                  suffix: 'SKS',
                  color: const Color(0xFF0F766E),
                  icon: Icons.assignment_outlined,
                  progress: 0.85,
                ),
                ModernStatPill(
                  label: 'KEHADIRAN RATA-RATA',
                  value: avgAttendance.toStringAsFixed(1),
                  suffix: '%',
                  color: const Color(0xFF16A34A),
                  icon: Icons.analytics_outlined,
                  progress: avgAttendance / 100,
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 16),

        // Header Panel Rekap
        PixelPanel(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          borderWidth: 2.5,
          shadowOffset: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'REKAPITULASI PENILAIAN SEMESTER',
                          style: AppTheme.pixel(9.5, color: AppTheme.blue),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Semester ${_profile.activeSemester} · Total $totalStudents mahasiswa dari ${_classes.length} kelas',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.muted,
                            fontFamily: 'SpaceMono',
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Mengunduh Berita Acara & Rekap Nilai Akademik (PDF / Excel)...',
                          ),
                          backgroundColor: Color(0xFF0F766E),
                        ),
                      );
                    },
                    icon: const Icon(Icons.file_download_outlined, size: 14),
                    label: const Text(
                      'Ekspor Rekap',
                      style: TextStyle(fontSize: 11),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.ink,
                      side: const BorderSide(color: AppTheme.ink, width: 1.5),
                      shape: const RoundedRectangleBorder(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Daftar Kelas Kuliah
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _classes.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                itemBuilder: (ctx, index) {
                  final item = _classes[index];
                  return _buildClassGradeCard(item);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClassGradeCard(TeachingClassSummary item) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: const BoxDecoration(color: AppTheme.blue),
                child: Text(
                  '${item.courseCode} · ${item.classSection}',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'SpaceMono',
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFF94A3B8), width: 1),
                ),
                child: Text(
                  '${item.credits} SKS',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.ink,
                  ),
                ),
              ),
              Text(
                '${item.totalStudents} Mahasiswa',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.ink,
                  fontFamily: 'SpaceMono',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.courseName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
              fontFamily: 'SpaceMono',
            ),
          ),
          const SizedBox(height: 10),

          // Tingkat Kehadiran
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Kehadiran Rata-rata Kelas:',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: AppTheme.muted,
                          ),
                        ),
                        Text(
                          '${item.averageAttendance}%',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: item.averageAttendance / 100,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF16A34A),
                      ),
                      minHeight: 5,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Status Pengisian Nilai & Aksi
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 14,
                    color: Color(0xFFD97706),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Status: ${item.gradeInputStatus}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF92400E),
                        fontFamily: 'SpaceMono',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () => _openGradeInputDialog(item),
                  icon: const Icon(Icons.rate_review_outlined, size: 13),
                  label: const Text(
                    'Input / Edit Nilai',
                    style: TextStyle(fontSize: 10.5),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.blue,
                    shape: const RoundedRectangleBorder(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openGradeInputDialog(TeachingClassSummary item) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.paper,
              border: Border.all(color: AppTheme.ink, width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x30000000),
                  offset: Offset(4, 5),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  color: AppTheme.blue,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.rate_review,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'INPUT NILAI · ${item.courseCode} (${item.classSection})',
                          style: AppTheme.pixel(8, color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.courseName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total ${item.totalStudents} Mahasiswa · Bobot: Tugas 20%, Kuis 15%, UTS 30%, UAS 35%',
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppTheme.muted,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: const Color(0xFFF1F5F9),
                        child: Column(
                          children: [
                            _gradeComponentRow(
                              'Tugas & Diskusi (20%)',
                              '100% Selesai Diinput',
                              const Color(0xFF16A34A),
                            ),
                            const SizedBox(height: 8),
                            _gradeComponentRow(
                              'Kuis Online (15%)',
                              '100% Selesai Diinput',
                              const Color(0xFF16A34A),
                            ),
                            const SizedBox(height: 8),
                            _gradeComponentRow(
                              'Ujian Tengah Semester (30%)',
                              'Menunggu Unggah Nilai',
                              const Color(0xFFD97706),
                            ),
                            const SizedBox(height: 8),
                            _gradeComponentRow(
                              'Ujian Akhir Semester (35%)',
                              'Jadwal UAS Belum Tiba',
                              AppTheme.muted,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppTheme.ink),
                              shape: const RoundedRectangleBorder(),
                            ),
                            child: const Text('Batal'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Komponen nilai tersimpan dan sinkron dengan pangkalan data SIAKAD.',
                                  ),
                                  backgroundColor: Color(0xFF16A34A),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.cloud_upload_outlined,
                              size: 16,
                            ),
                            label: const Text('Simpan & Sinkronisasi'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.blue,
                              shape: const RoundedRectangleBorder(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _gradeComponentRow(String title, String status, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            border: Border.all(color: color, width: 1),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppTheme.blue,
        border: Border(bottom: BorderSide(color: AppTheme.ink, width: 4)),
      ),
      child: Row(
        children: [
          const FacultyMark(compact: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SIAKAD · PORTAL DOSEN FASILKOM',
                  style: AppTheme.pixel(
                    MediaQuery.sizeOf(context).width < ResponsiveLayout.tablet
                        ? 8
                        : 10,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Sistem Informasi Akademik Terpadu · Smt ${_profile.activeSemester}',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFFDCECEF),
                    fontFamily: 'SpaceMono',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (MediaQuery.sizeOf(context).width < ResponsiveLayout.tablet)
            Builder(
              builder: (headerContext) => IconButton(
                tooltip: 'Buka menu navigasi',
                onPressed: () => Scaffold.of(headerContext).openDrawer(),
                icon: const Icon(Icons.menu, color: Colors.white),
              ),
            ),
          OutlinedButton.icon(
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout, size: 14),
            label: const Text('Keluar', style: TextStyle(fontSize: 11)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white, width: 1.5),
              shape: const RoundedRectangleBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        color: AppTheme.ink.withValues(alpha: 0.08),
        child: Text(
          'SIAKAD FASILKOM · UNIVERSITAS ESA UNGGUL · TAHUN AJARAN 2026/2027',
          style: AppTheme.pixel(6.5, color: AppTheme.ink),
        ),
      ),
    );
  }
}
