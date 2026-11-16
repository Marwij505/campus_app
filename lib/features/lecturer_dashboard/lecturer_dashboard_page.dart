// Halaman utama Dashboard Dosen Akademik dan Dosen Pembimbing SIAKAD.
// Mengintegrasikan modul tridharma pengajaran (Dosen Akademik)
// dan modul perwalian & skripsi (Dosen Pembimbing).

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
  late LecturerProfileData _profile;
  late LecturerDashboardStats _stats;
  late List<TeachingScheduleItem> _schedules;
  late List<TeachingClassSummary> _classes;
  late List<KrsApprovalRequest> _krsRequests;
  late List<AdvisedStudent> _advisees;
  late List<ThesisAdvisee> _thesisAdvisees;

  // Mode tampilan: 0 = Dosen Akademik (Pengajaran), 1 = Dosen Pembimbing (Perwalian & Skripsi)
  int _activeRoleIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final nip = widget.lecturerProfile.nim;
    _profile = LecturerDemoData.getProfile(nip);
    _stats = LecturerDemoData.getStats(nip);
    _schedules = LecturerDemoData.getTeachingSchedules(nip);
    _classes = LecturerDemoData.getTeachingClasses(nip);
    _krsRequests = LecturerDemoData.getKrsApprovals(nip);
    _advisees = LecturerDemoData.getAdvisedStudents(nip);
    _thesisAdvisees = LecturerDemoData.getThesisAdvisees(nip);

    // Dosen DOS002 adalah DPA utama, tampilkan tab Dosen Pembimbing secara langsung
    if (nip == 'DOS002') {
      _activeRoleIndex = 1;
    } else {
      _activeRoleIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final nip = widget.lecturerProfile.nim;
    final pendingKrsCount = _krsRequests.where((r) => r.status == KrsStatus.pending).length;

    return Scaffold(
      backgroundColor: AppTheme.paper,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const RepaintBoundary(
            child: CampusBackground(dashboard: true),
          ),
          SafeArea(
            child: Column(
              children: [
                // Header SIAKAD Dosen
                _buildHeader(context),

                // Area Konten Dashboard (Bisa Digulir)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1040),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Kartu Profil & Identitas Dosen
                            _buildProfileCard(),

                            const SizedBox(height: 16),

                            // Switcher Peran: Dosen Akademik vs Dosen Pembimbing
                            _buildRoleSwitcher(pendingKrsCount),

                            const SizedBox(height: 16),

                            // Konten Berdasarkan Tab / Mode yang Aktif
                            AnimatedSwitcher(
                              duration: AppMotion.duration(context, 280),
                              child: _activeRoleIndex == 0
                                  ? TeachingPanel(
                                      key: ValueKey('teaching-$nip'),
                                      schedules: _schedules,
                                      classes: _classes,
                                      stats: _stats,
                                      leaveRepository: widget.leaveRepository,
                                      onScheduleUpdated: (updated) => setState(() => _schedules = updated),
                                    )
                                  : AdvisorPanel(
                                      key: ValueKey('advisor-$nip'),
                                      krsRequests: _krsRequests,
                                      advisees: _advisees,
                                      thesisAdvisees: _thesisAdvisees,
                                      stats: _stats,
                                      onKrsUpdated: (updated) => setState(() => _krsRequests = updated),
                                      onThesisUpdated: (updated) => setState(() => _thesisAdvisees = updated),
                                    ),
                            ),

                            const SizedBox(height: 32),

                            // Footer SIAKAD
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                color: AppTheme.ink.withValues(alpha: 0.08),
                                child: Text(
                                  'SIAKAD FASILKOM · UNIVERSITAS ESA UNGGUL · TAHUN AJARAN 2026/2027',
                                  style: AppTheme.pixel(6.5, color: AppTheme.ink),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppTheme.blue,
        border: Border(
          bottom: BorderSide(color: AppTheme.ink, width: 4),
        ),
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
                    MediaQuery.sizeOf(context).width < ResponsiveLayout.tablet ? 8 : 10,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                const Text(
                  'Dashboard Dosen Akademik & Dosen Pembimbing',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFFDCECEF),
                    fontFamily: 'SpaceMono',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
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

  Widget _buildProfileCard() {
    return PixelPanel(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      borderWidth: 3,
      shadowOffset: 5,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 620;

          final avatar = Container(
            width: isNarrow ? 56 : 68,
            height: isNarrow ? 56 : 68,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              border: Border.all(color: AppTheme.ink, width: 2.5),
            ),
            child: const Icon(Icons.school, size: 38, color: AppTheme.blue),
          );

          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _profile.nameWithTitle,
                      style: TextStyle(
                        fontSize: isNarrow ? 14 : 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                        fontFamily: 'SpaceMono',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text('NIP: ${_profile.nip}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                  Text('·', style: const TextStyle(color: AppTheme.muted)),
                  Text('NIDN: ${_profile.nidn}', style: const TextStyle(fontSize: 11.5, color: AppTheme.muted)),
                  Text('·', style: const TextStyle(color: AppTheme.muted)),
                  Text(_profile.functionalRole, style: const TextStyle(fontSize: 11.5, color: AppTheme.blue, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${_profile.department} · ${_profile.faculty}',
                style: const TextStyle(fontSize: 11, color: AppTheme.muted),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  RoleBadgeChip(
                    label: _profile.status,
                    color: const Color(0xFF16A34A),
                    icon: Icons.check_circle_outline,
                  ),
                  RoleBadgeChip(
                    label: 'Semester: ${_profile.activeSemester}',
                    color: AppTheme.blue,
                    icon: Icons.date_range_outlined,
                  ),
                  RoleBadgeChip(
                    label: _profile.roomOffice,
                    color: AppTheme.muted,
                    icon: Icons.door_front_door_outlined,
                  ),
                ],
              ),
            ],
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    avatar,
                    const SizedBox(width: 12),
                    Expanded(child: details),
                  ],
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              avatar,
              const SizedBox(width: 16),
              Expanded(child: details),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRoleSwitcher(int pendingKrsCount) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFDCECEF),
        border: Border.all(color: AppTheme.ink, width: 3),
      ),
      child: Row(
        children: [
          // Tab 1: Dosen Akademik (Pengajaran)
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _activeRoleIndex = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: _activeRoleIndex == 0 ? AppTheme.blue : Colors.transparent,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.menu_book,
                      size: 16,
                      color: _activeRoleIndex == 0 ? Colors.white : AppTheme.ink,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'DOSEN AKADEMIK (PENGAJARAN)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _activeRoleIndex == 0 ? Colors.white : AppTheme.ink,
                          fontFamily: 'SpaceMono',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Divider garis piksel
          Container(width: 3, height: 44, color: AppTheme.ink),

          // Tab 2: Dosen Pembimbing (Perwalian & Skripsi)
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _activeRoleIndex = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: _activeRoleIndex == 1 ? AppTheme.blue : Colors.transparent,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.supervised_user_circle,
                      size: 16,
                      color: _activeRoleIndex == 1 ? Colors.white : AppTheme.ink,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _thesisAdvisees.isNotEmpty
                            ? 'DOSEN PEMBIMBING (DPA / SKRIPSI)'
                            : 'DOSEN PEMBIMBING (DPA)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _activeRoleIndex == 1 ? Colors.white : AppTheme.ink,
                          fontFamily: 'SpaceMono',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (pendingKrsCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _activeRoleIndex == 1 ? Colors.white : const Color(0xFFDC2626),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$pendingKrsCount',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _activeRoleIndex == 1 ? AppTheme.blue : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
