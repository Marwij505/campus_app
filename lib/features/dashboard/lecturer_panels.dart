// Panel-panel khusus dashboard dosen dengan tema retro pixel yang seragam
// dengan dashboard mahasiswa (ProfilePanel, StudyProgressPanel, dll.).

import 'package:flutter/material.dart';

import '../../core/app_motion.dart';
import '../../core/app_theme.dart';
import '../../data/dashboard_models.dart';
import '../../data/lecturer_models.dart';
import 'dashboard_widgets.dart';

/// Kartu profil dosen di bagian atas beranda, mengikuti gaya ProfilePanel mahasiswa.
class LecturerProfilePanel extends StatelessWidget {
  const LecturerProfilePanel({
    super.key,
    required this.profile,
    required this.workload,
    required this.fallbackCode,
  });

  final LecturerProfile? profile;
  final LecturerWorkload workload;
  final String fallbackCode;

  @override
  Widget build(BuildContext context) {
    final isThesis = profile?.isThesisAdvisor ?? false;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF123C80), Color(0xFF166AB1)],
        ),
        border: Border.all(color: AppTheme.ink, width: 3),
        boxShadow: const [
          BoxShadow(color: Color(0xFFB9C3C4), offset: Offset(4, 4)),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, bounds) {
          final identity = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .12),
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: Icon(
                      isThesis ? Icons.school_outlined : Icons.badge_outlined,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InfoChip(
                          profile?.roleLabel ?? 'Dosen Akademik',
                          onDark: true,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          profile?.name ?? 'Profil Dosen',
                          style: AppTheme.pixel(10, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Kode: ${profile?.code ?? fallbackCode} · NIDN: ${profile?.nidn ?? '—'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${profile?.faculty ?? 'Fakultas: —'} · ${profile?.department ?? 'Prodi: —'}',
                          style: const TextStyle(
                            color: Color(0xFFCFE4FB),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  InfoChip('Status: ${profile?.status ?? '—'}', onDark: true),
                  InfoChip(
                    'Jabatan: ${profile?.academicRank ?? '—'}',
                    onDark: true,
                  ),
                  InfoChip(
                    'Homebase: ${profile?.homebase ?? '—'}',
                    onDark: true,
                  ),
                  InfoChip('Beban: ${workload.totalCredits} SKS', onDark: true),
                ],
              ),
            ],
          );

          final stats = ResponsiveCards(
            minWidth: 92,
            maximum: isThesis ? 4 : 3,
            children: [
              _stat('MATA KULIAH', '${workload.totalCourses}', 'diampu'),
              _stat('MAHASISWA PA', '${workload.paTotal}', 'perwalian'),
              if (isThesis) ...[
                _stat('BIMBINGAN TA', '${workload.thesisActive}', 'mahasiswa'),
                _stat(
                  'REVIEW TA',
                  '${workload.thesisPendingReviews}',
                  'menunggu',
                ),
              ] else
                _stat('KELAS', '${workload.totalClasses}', 'aktif'),
            ],
          );

          if (bounds.maxWidth < 760) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [identity, const SizedBox(height: 18), stats],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: 6, child: identity),
              const SizedBox(width: 24),
              Expanded(flex: 4, child: stats),
            ],
          );
        },
      ),
    );
  }

  Widget _stat(String label, String value, String caption) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .12),
      border: Border.all(color: Colors.white.withValues(alpha: .28), width: 2),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            color: Color(0xFFCFE4FB),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(value, style: AppTheme.pixel(13, color: Colors.white)),
        const SizedBox(height: 4),
        Text(
          caption,
          style: const TextStyle(fontSize: 9, color: Color(0xFFCFE4FB)),
        ),
      ],
    ),
  );
}

/// Panel ringkasan beban mengajar, perwalian, dan (jika pembimbing TA) progres TA.
class LecturerWorkloadPanel extends StatelessWidget {
  const LecturerWorkloadPanel({
    super.key,
    required this.workload,
    required this.isThesisAdvisor,
  });

  final LecturerWorkload workload;
  final bool isThesisAdvisor;

  @override
  Widget build(BuildContext context) => DashboardPanel(
    title: isThesisAdvisor
        ? 'RINGKASAN AKADEMIK & TA'
        : 'RINGKASAN AKADEMIK DOSEN',
    icon: Icons.trending_up,
    action: DashboardAction(
      'Cara baca',
      () => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cara membaca ringkasan dosen'),
          content: SingleChildScrollView(
            child: Text(
              isThesisAdvisor
                  ? 'Pertemuan mengajar membandingkan realisasi pertemuan terhadap target 14 pertemuan per kelas. '
                        'Persetujuan KRS PA menunjukkan jumlah mahasiswa perwalian yang sudah disetujui. '
                        'Bimbingan TA aktif dibandingkan terhadap kuota pembimbingan maksimal. '
                        'Review TA menampilkan jumlah draf/proposal yang menunggu tindak lanjut.'
                  : 'Pertemuan mengajar membandingkan realisasi pertemuan terhadap target 14 pertemuan per kelas. '
                        'Input nilai menampilkan kelas yang komponen nilainya sudah lengkap. '
                        'Persetujuan KRS PA menunjukkan mahasiswa bimbingan akademik yang sudah disetujui.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        ),
      ),
      icon: Icons.info_outline,
    ),
    child: ResponsiveCards(
      minWidth: 180,
      children: [
        _MetricCard(
          title: 'PERTEMUAN MENGAJAR',
          icon: Icons.co_present_outlined,
          value: '${workload.completedMeetings}',
          suffix: '/${workload.targetMeetings} sesi',
          progress: safeRatio(
            workload.completedMeetings,
            workload.targetMeetings,
          ),
          color: AppTheme.blue,
          caption: '${workload.totalStudents} total mahasiswa',
        ),
        _MetricCard(
          title: 'PERSETUJUAN KRS PA',
          icon: Icons.fact_check_outlined,
          value: '${workload.paApproved}',
          suffix: '/${workload.paTotal} mhs',
          progress: safeRatio(workload.paApproved, workload.paTotal),
          color: const Color(0xFF1AA95A),
          caption:
              '${workload.paTotal - workload.paApproved} menunggu tindak lanjut',
        ),
        if (isThesisAdvisor) ...[
          _MetricCard(
            title: 'KUOTA BIMBINGAN TA',
            icon: Icons.school_outlined,
            value: '${workload.thesisActive}',
            suffix: '/${workload.thesisCapacity} mhs',
            progress: safeRatio(workload.thesisActive, workload.thesisCapacity),
            color: const Color(0xFF873DD1),
            caption: '${workload.thesisReadyDefense} siap sidang',
          ),
          _MetricCard(
            title: 'REVIEW TA MENUNGGU',
            icon: Icons.rate_review_outlined,
            value: '${workload.thesisPendingReviews}',
            suffix: ' berkas',
            progress: safeRatio(
              workload.thesisPendingReviews,
              workload.thesisActive == 0 ? 1 : workload.thesisActive,
            ),
            color: const Color(0xFFED7D21),
            caption: 'Proposal & draf bab TA',
          ),
        ] else ...[
          _MetricCard(
            title: 'INPUT NILAI KELAS',
            icon: Icons.grading_outlined,
            value: '${workload.gradedClasses}',
            suffix: '/${workload.totalClasses} kelas',
            progress: safeRatio(workload.gradedClasses, workload.totalClasses),
            color: const Color(0xFFED7D21),
            caption: 'Komponen UTS & tugas',
          ),
          _MetricCard(
            title: 'KEHADIRAN KELAS',
            icon: Icons.groups_outlined,
            value: (workload.attendanceRate * 100).toStringAsFixed(0),
            suffix: '%',
            progress: workload.attendanceRate.clamp(0.0, 1.0),
            color: const Color(0xFF873DD1),
            caption: 'Rata-rata seluruh kelas',
          ),
        ],
      ],
    ),
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.icon,
    required this.value,
    required this.suffix,
    required this.progress,
    required this.color,
    this.caption,
  });

  final String title;
  final IconData icon;
  final String value;
  final String suffix;
  final double? progress;
  final Color color;
  final String? caption;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF9FCFD),
      border: Border.all(color: const Color(0xFFD5E0ED), width: 2),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.muted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 4,
          children: [
            Text(value, style: AppTheme.pixel(14, color: AppTheme.ink)),
            Text(
              suffix,
              style: const TextStyle(fontSize: 10, color: AppTheme.muted),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: progress ?? 0),
          duration: AppMotion.duration(context, 420),
          curve: Curves.easeOutCubic,
          builder: (context, val, _) => LinearProgressIndicator(
            value: val,
            minHeight: 7,
            backgroundColor: const Color(0xFFE1E9EC),
            color: color,
          ),
        ),
        if (caption != null) ...[
          const SizedBox(height: 8),
          Text(
            caption!,
            style: const TextStyle(fontSize: 10, color: AppTheme.muted),
          ),
        ],
      ],
    ),
  );
}

/// Daftar mata kuliah & kelas yang diampu dosen.
class LecturerCoursesPanel extends StatelessWidget {
  const LecturerCoursesPanel({
    super.key,
    required this.courses,
    required this.onOpen,
  });

  final List<LecturerCourseClass> courses;
  final ValueChanged<LecturerCourseClass> onOpen;

  @override
  Widget build(BuildContext context) => DashboardPanel(
    title: 'MATA KULIAH DIAMPU',
    icon: Icons.menu_book_outlined,
    child: courses.isEmpty
        ? const DashboardEmpty(
            title: 'Belum ada mata kuliah diampu',
            icon: Icons.menu_book_outlined,
          )
        : Column(
            children: [
              for (var i = 0; i < courses.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                _CourseCard(course: courses[i], onTap: () => onOpen(courses[i])),
              ],
            ],
          ),
  );
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.course, required this.onTap});

  final LecturerCourseClass course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ratio = safeRatio(course.completedMeetings, course.totalMeetings) ?? 0;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FBFF),
          border: Border.all(color: const Color(0xFFD5E0ED), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${course.code} · ${course.title} (Kelas ${course.classCode})',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InfoChip(
                  course.gradeSubmitted ? 'Nilai Terisi' : 'Belum Input Nilai',
                  color: course.gradeSubmitted
                      ? const Color(0xFF198754)
                      : const Color(0xFFED7D21),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${course.scheduleText} · ${course.room} · ${course.method}',
              style: const TextStyle(fontSize: 11, color: AppTheme.muted),
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
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: const Color(0xFFE1E9EC),
              color: AppTheme.blue,
            ),
          ],
        ),
      ),
    );
  }
}

/// Daftar mahasiswa bimbingan akademik (PA) dengan status KRS dan filter interaktif.
class AcademicAdviseesPanel extends StatefulWidget {
  const AcademicAdviseesPanel({
    super.key,
    required this.advisees,
    required this.onOpen,
  });

  final List<AcademicAdvisee> advisees;
  final ValueChanged<AcademicAdvisee> onOpen;

  @override
  State<AcademicAdviseesPanel> createState() => _AcademicAdviseesPanelState();
}

class _AcademicAdviseesPanelState extends State<AcademicAdviseesPanel> {
  KrsApprovalStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final filtered = _filter == null
        ? widget.advisees
        : widget.advisees.where((a) => a.krsStatus == _filter).toList();
    return DashboardPanel(
      title: 'MAHASISWA BIMBINGAN AKADEMIK (PA)',
      icon: Icons.supervisor_account_outlined,
      child: widget.advisees.isEmpty
          ? const DashboardEmpty(
              title: 'Belum ada mahasiswa bimbingan PA',
              icon: Icons.supervisor_account_outlined,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _FilterChipButton(
                      label: 'Semua (${widget.advisees.length})',
                      selected: _filter == null,
                      onTap: () => setState(() => _filter = null),
                    ),
                    _FilterChipButton(
                      label:
                          'Menunggu (${widget.advisees.where((a) => a.krsStatus == KrsApprovalStatus.pending).length})',
                      selected: _filter == KrsApprovalStatus.pending,
                      color: const Color(0xFFED7D21),
                      onTap: () =>
                          setState(() => _filter = KrsApprovalStatus.pending),
                    ),
                    _FilterChipButton(
                      label:
                          'Disetujui (${widget.advisees.where((a) => a.krsStatus == KrsApprovalStatus.approved).length})',
                      selected: _filter == KrsApprovalStatus.approved,
                      color: const Color(0xFF198754),
                      onTap: () =>
                          setState(() => _filter = KrsApprovalStatus.approved),
                    ),
                    _FilterChipButton(
                      label:
                          'Revisi (${widget.advisees.where((a) => a.krsStatus == KrsApprovalStatus.revision).length})',
                      selected: _filter == KrsApprovalStatus.revision,
                      color: AppTheme.red,
                      onTap: () =>
                          setState(() => _filter = KrsApprovalStatus.revision),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (filtered.isEmpty)
                  const DashboardEmpty(
                    title: 'Tidak ada mahasiswa pada filter ini',
                    message: 'Pilih filter lain untuk melihat daftar PA.',
                  )
                else
                  for (var i = 0; i < filtered.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    _PaCard(
                      advisee: filtered[i],
                      onTap: () => widget.onOpen(filtered[i]),
                    ),
                  ],
              ],
            ),
    );
  }
}

class _PaCard extends StatelessWidget {
  const _PaCard({required this.advisee, required this.onTap});

  final AcademicAdvisee advisee;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusColor) = switch (advisee.krsStatus) {
      KrsApprovalStatus.approved => ('Disetujui', const Color(0xFF198754)),
      KrsApprovalStatus.pending => ('Menunggu ACC', const Color(0xFFED7D21)),
      KrsApprovalStatus.revision => ('Perlu Revisi', AppTheme.red),
    };
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FBFF),
          border: Border.all(color: const Color(0xFFD5E0ED), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${advisee.name} (${advisee.nim})',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InfoChip(statusLabel, color: statusColor),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Semester ${advisee.semester} · IPK ${advisee.gpa.toStringAsFixed(2)} · ${advisee.takenCredits} SKS',
              style: const TextStyle(fontSize: 11, color: AppTheme.muted),
            ),
            const SizedBox(height: 4),
            Text(advisee.note, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

/// Panel khusus Dosen Pembimbing TA: daftar mahasiswa bimbingan skripsi/TA dengan filter.
class ThesisAdviseesPanel extends StatefulWidget {
  const ThesisAdviseesPanel({
    super.key,
    required this.advisees,
    required this.onOpen,
  });

  final List<ThesisAdvisee> advisees;
  final ValueChanged<ThesisAdvisee> onOpen;

  @override
  State<ThesisAdviseesPanel> createState() => _ThesisAdviseesPanelState();
}

class _ThesisAdviseesPanelState extends State<ThesisAdviseesPanel> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final filtered = switch (_filter) {
      'ready' => widget.advisees
          .where((a) => a.stage == ThesisStage.readyDefense)
          .toList(),
      'progress' => widget.advisees
          .where((a) => a.stage != ThesisStage.readyDefense)
          .toList(),
      _ => widget.advisees,
    };

    return DashboardPanel(
      title: 'MAHASISWA BIMBINGAN TUGAS AKHIR (TA)',
      icon: Icons.school_outlined,
      child: widget.advisees.isEmpty
          ? const DashboardEmpty(
              title: 'Belum ada mahasiswa bimbingan TA',
              icon: Icons.school_outlined,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _FilterChipButton(
                      label: 'Semua (${widget.advisees.length})',
                      selected: _filter == 'all',
                      onTap: () => setState(() => _filter = 'all'),
                    ),
                    _FilterChipButton(
                      label:
                          'Dalam Bimbingan (${widget.advisees.where((a) => a.stage != ThesisStage.readyDefense).length})',
                      selected: _filter == 'progress',
                      color: const Color(0xFF873DD1),
                      onTap: () => setState(() => _filter = 'progress'),
                    ),
                    _FilterChipButton(
                      label:
                          'Siap Sidang (${widget.advisees.where((a) => a.stage == ThesisStage.readyDefense).length})',
                      selected: _filter == 'ready',
                      color: const Color(0xFF198754),
                      onTap: () => setState(() => _filter = 'ready'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (filtered.isEmpty)
                  const DashboardEmpty(
                    title: 'Tidak ada mahasiswa pada filter ini',
                    message: 'Pilih filter lain untuk melihat bimbingan TA.',
                  )
                else
                  for (var i = 0; i < filtered.length; i++) ...[
                    if (i > 0) const SizedBox(height: 12),
                    _ThesisCard(
                      advisee: filtered[i],
                      onTap: () => widget.onOpen(filtered[i]),
                    ),
                  ],
              ],
            ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color = AppTheme.blue,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? color : Colors.white,
        border: Border.all(
          color: selected ? AppTheme.ink : color.withValues(alpha: .35),
          width: 2,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: selected ? Colors.white : color,
        ),
      ),
    ),
  );
}

class _ThesisCard extends StatelessWidget {
  const _ThesisCard({required this.advisee, required this.onTap});

  final ThesisAdvisee advisee;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (stageLabel, stageColor) = switch (advisee.stage) {
      ThesisStage.proposal => ('Proposal', const Color(0xFFED7D21)),
      ThesisStage.chapter1To3 => ('Bab 1-3', AppTheme.blue),
      ThesisStage.research => ('Penelitian', const Color(0xFF873DD1)),
      ThesisStage.finalDraft => ('Bab 4-5', const Color(0xFF174C8A)),
      ThesisStage.readyDefense => ('Siap Sidang', const Color(0xFF198754)),
    };

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFBF9FF),
          border: Border.all(color: const Color(0xFFD9CFEF), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${advisee.name} (${advisee.nim})',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InfoChip(stageLabel, color: stageColor),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              advisee.title,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                InfoChip(advisee.roleInThesis),
                InfoChip('Terakhir: ${advisee.lastGuidanceDate}'),
                InfoChip(advisee.pendingAction, color: const Color(0xFFED7D21)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: advisee.progress.clamp(0.0, 1.0),
                    minHeight: 7,
                    backgroundColor: const Color(0xFFE6E0F0),
                    color: stageColor,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${(advisee.progress * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Panel jadwal bimbingan, seminar proposal, dan sidang TA.
class ThesisSchedulePanel extends StatelessWidget {
  const ThesisSchedulePanel({
    super.key,
    required this.items,
    required this.onAll,
  });

  final List<ThesisScheduleItem> items;
  final VoidCallback onAll;

  @override
  Widget build(BuildContext context) => DashboardPanel(
    title: 'JADWAL BIMBINGAN & SIDANG TA',
    icon: Icons.event_available_outlined,
    action: DashboardAction('Semua', onAll),
    child: items.isEmpty
        ? const DashboardEmpty(
            title: 'Belum ada jadwal TA',
            icon: Icons.event_available_outlined,
          )
        : Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FBFF),
                    border: Border.all(
                      color: const Color(0xFFD5E0ED),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${items[i].studentName} (${items[i].nim})',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          InfoChip(
                            items[i].type,
                            color: items[i].type == 'Sidang Skripsi'
                                ? AppTheme.red
                                : const Color(0xFF873DD1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        items[i].topic,
                        style: const TextStyle(fontSize: 11),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${items[i].dateLabel} · ${items[i].timeLabel} · ${items[i].location}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
  );
}
