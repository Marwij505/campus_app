// Komponen visual modern & retro-executive untuk Dashboard Dosen Versi Baru.
// Dirancang mandiri tanpa mengikuti desain Figma, mengutamakan efisiensi kerja tridharma,
// kejelasan visual, keterbacaan tipografi, dan responsivitas penuh di semua ukuran layar.

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../data/lecturer_models.dart';

/// Banner sambutan eksekutif dosen dengan status tridharma dan informasi waktu.
class LecturerHeroBanner extends StatelessWidget {
  const LecturerHeroBanner({
    super.key,
    required this.profile,
    required this.onSwitchAccount,
    required this.onLogout,
  });

  final LecturerProfileData profile;
  final VoidCallback onSwitchAccount;
  final VoidCallback onLogout;

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  @override
  Widget build(BuildContext context) {
    final isThesisAdvisor = profile.roleType == LecturerRoleType.both;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.ink,
        border: Border.all(color: const Color(0xFF1E293B), width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            offset: Offset(4, 5),
            blurRadius: 0,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Aksen dekoratif garis retro di sudut
          Positioned(
            right: -20,
            top: -20,
            child: Opacity(
              opacity: 0.08,
              child: Icon(Icons.school, size: 140, color: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar Dosen Retro dengan Bingkai
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        border: Border.all(color: AppTheme.blue, width: 2.5),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                _greeting(),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontFamily: 'SpaceMono',
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF16A34A)
                                      .withValues(alpha: 0.2),
                                  border: Border.all(
                                    color: const Color(0xFF16A34A),
                                    width: 1.2,
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
                                      'ONLINE · SIAKAD',
                                      style: TextStyle(
                                        fontSize: 9,
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
                          const SizedBox(height: 3),
                          Text(
                            profile.nameWithTitle,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              fontFamily: 'SpaceMono',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'NIP: ${profile.nip} · ${profile.functionalRole} · ${profile.department}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.8),
                              fontFamily: 'SpaceMono',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFF334155)),
                const SizedBox(height: 12),
                // Informasi Peran & Tombol Cepat Ganti Akun Demo
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isThesisAdvisor
                                ? const Color(0xFF4338CA)
                                      .withValues(alpha: 0.25)
                                : const Color(0xFF0284C7)
                                      .withValues(alpha: 0.25),
                            border: Border.all(
                              color: isThesisAdvisor
                                  ? const Color(0xFF818CF8)
                                  : const Color(0xFF38BDF8),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            isThesisAdvisor
                                ? '★ Dosen Pembimbing Akademik & Skripsi'
                                : '★ Dosen Akademik Pengampu',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: isThesisAdvisor
                                  ? const Color(0xFFC7D2FE)
                                  : const Color(0xFFBAE6FD),
                              fontFamily: 'SpaceMono',
                            ),
                          ),
                        ),
                        Text(
                          'Smt ${profile.activeSemester}',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: Colors.white.withValues(alpha: 0.6),
                            fontFamily: 'SpaceMono',
                          ),
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: onSwitchAccount,
                          icon: const Icon(Icons.swap_horiz, size: 14),
                          label: Text(
                            profile.nip == 'DOS001'
                                ? 'Demo Akun DOS002 (DPA)'
                                : 'Demo Akun DOS001 (Pengajar)',
                            style: const TextStyle(fontSize: 10.5),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFDE047),
                            side: const BorderSide(
                              color: Color(0xFFFDE047),
                              width: 1.2,
                            ),
                            shape: const RoundedRectangleBorder(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: onLogout,
                          tooltip: 'Keluar dari Portal Dosen',
                          icon: const Icon(
                            Icons.power_settings_new,
                            size: 18,
                            color: Color(0xFFEF4444),
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu sorotan "Agenda Perkuliahan Terdekat" dengan tombol aksi cepat presensi & BAP.
class SpotlightLectureCard extends StatelessWidget {
  const SpotlightLectureCard({
    super.key,
    required this.schedule,
    required this.onAttendanceTap,
    required this.onBapTap,
  });

  final TeachingScheduleItem schedule;
  final VoidCallback onAttendanceTap;
  final VoidCallback onBapTap;

  @override
  Widget build(BuildContext context) {
    final isLive = schedule.status == 'Berlangsung';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border.all(
          color: isLive ? const Color(0xFF22C55E) : AppTheme.blue,
          width: 2.5,
        ),
        boxShadow: const [
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
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 420;
              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isLive
                                ? const Color(0xFF16A34A)
                                : AppTheme.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.flash_on,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isLive
                                ? 'KELAS SEDANG BERLANGSUNG'
                                : 'AGENDA MENGAJAR TERDEKAT',
                            style: AppTheme.pixel(
                              7.5,
                              color: isLive
                                  ? const Color(0xFF86EFAC)
                                  : const Color(0xFF93C5FD),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${schedule.courseCode} · ${schedule.classSection}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'SpaceMono',
                        ),
                      ),
                    ),
                  ],
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isLive
                              ? const Color(0xFF16A34A)
                              : AppTheme.blue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.flash_on,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isLive
                            ? 'KELAS SEDANG BERLANGSUNG'
                            : 'AGENDA MENGAJAR TERDEKAT',
                        style: AppTheme.pixel(
                          7.5,
                          color: isLive
                              ? const Color(0xFF86EFAC)
                              : const Color(0xFF93C5FD),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${schedule.courseCode} · ${schedule.classSection}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'SpaceMono',
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Text(
            schedule.courseName,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontFamily: 'SpaceMono',
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _metricChip(Icons.access_time, schedule.time),
              _metricChip(Icons.room, schedule.room),
              _metricChip(
                Icons.people_outline,
                '${schedule.attendedStudents}/${schedule.enrolledStudents} Hadir',
              ),
              _metricChip(
                Icons.calendar_today,
                'Pertemuan ke-${schedule.currentMeeting}/${schedule.totalMeetings}',
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 360;
              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.icon(
                      onPressed: onAttendanceTap,
                      icon: const Icon(Icons.fact_check_outlined, size: 15),
                      label: const Text(
                        'Presensi Kelas',
                        style: TextStyle(fontSize: 11),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        shape: const RoundedRectangleBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: onBapTap,
                      icon: Icon(
                        schedule.bapSubmitted
                            ? Icons.check_circle_outline
                            : Icons.edit_note,
                        size: 15,
                      ),
                      label: Text(
                        schedule.bapSubmitted
                            ? 'BAP Terisi (Ubah)'
                            : 'Isi BAP Kuliah',
                        style: const TextStyle(fontSize: 11),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: schedule.bapSubmitted
                            ? const Color(0xFF0F766E)
                            : const Color(0xFFD97706),
                        shape: const RoundedRectangleBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onAttendanceTap,
                      icon: const Icon(Icons.fact_check_outlined, size: 15),
                      label: const Text(
                        'Presensi Kelas',
                        style: TextStyle(fontSize: 11),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        shape: const RoundedRectangleBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onBapTap,
                      icon: Icon(
                        schedule.bapSubmitted
                            ? Icons.check_circle_outline
                            : Icons.edit_note,
                        size: 15,
                      ),
                      label: Text(
                        schedule.bapSubmitted
                            ? 'BAP Terisi (Ubah)'
                            : 'Isi BAP Kuliah',
                        style: const TextStyle(fontSize: 11),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: schedule.bapSubmitted
                            ? const Color(0xFF0F766E)
                            : const Color(0xFFD97706),
                        shape: const RoundedRectangleBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _metricChip(IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: const Color(0xFF94A3B8)),
      const SizedBox(width: 4),
      Flexible(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFFE2E8F0),
            fontFamily: 'SpaceMono',
          ),
        ),
      ),
    ],
  );
}

/// Sidebar dashboard dosen dengan mode lebar dan ikon saja.
class ModernLecturerSideBar extends StatelessWidget {
  const ModernLecturerSideBar({
    super.key,
    required this.selectedIndex,
    required this.hasThesisTab,
    required this.pendingKrsCount,
    required this.expanded,
    required this.onToggle,
    required this.onTabSelected,
  });

  final int selectedIndex;
  final bool hasThesisTab;
  final int pendingKrsCount;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showLabels = expanded && constraints.maxWidth >= 226;
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            border: Border.all(color: AppTheme.ink, width: 2),
            boxShadow: const [
              BoxShadow(color: Color(0x22000000), offset: Offset(3, 3)),
            ],
          ),
          child: Column(
            children: [
              Container(
                color: AppTheme.ink,
                padding: EdgeInsets.symmetric(
                  horizontal: showLabels ? 10 : 4,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    if (showLabels)
                      Expanded(
                        child: Text(
                          'MENU DOSEN',
                          style: AppTheme.pixel(7, color: Colors.white),
                        ),
                      )
                    else
                      const Spacer(),
                    IconButton(
                      tooltip: expanded
                          ? 'Sembunyikan menu navigasi'
                          : 'Tampilkan menu navigasi',
                      onPressed: onToggle,
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        expanded ? Icons.chevron_left : Icons.menu,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 5,
                  ),
                  child: Column(
                    children: [
                      _buildItem(
                        index: 0,
                        icon: Icons.calendar_month_outlined,
                        label: 'Perkuliahan & Jadwal',
                        showLabel: showLabels,
                      ),
                      _buildItem(
                        index: 1,
                        icon: Icons.school_outlined,
                        label: 'Perwalian Mahasiswa',
                        badge: pendingKrsCount > 0 ? '$pendingKrsCount' : null,
                        showLabel: showLabels,
                      ),
                      if (hasThesisTab)
                        _buildItem(
                          index: 2,
                          icon: Icons.auto_stories_outlined,
                          label: 'Bimbingan Skripsi',
                          showLabel: showLabels,
                        ),
                      _buildItem(
                        index: hasThesisTab ? 3 : 2,
                        icon: Icons.assessment_outlined,
                        label: 'Rekap Nilai & Kelas',
                        showLabel: showLabels,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildItem({
    required int index,
    required IconData icon,
    required String label,
    required bool showLabel,
    String? badge,
  }) {
    final isSelected = selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Tooltip(
        message: showLabel ? '' : label,
        child: Material(
          color: isSelected ? AppTheme.blue : Colors.transparent,
          child: InkWell(
            key: ValueKey('lecturer-nav-$label'),
            onTap: () => onTabSelected(index),
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: EdgeInsets.symmetric(
                horizontal: showLabel ? 10 : 0,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? AppTheme.ink : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: showLabel
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 17,
                    color: isSelected ? Colors.white : AppTheme.ink,
                  ),
                  if (showLabel) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: isSelected ? Colors.white : AppTheme.ink,
                          fontFamily: 'SpaceMono',
                        ),
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        color: const Color(0xFFDC2626),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ] else if (badge != null)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDC2626),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Kartu metrik tridharma modern dengan progress bar dan warna tegas.
class ModernStatPill extends StatelessWidget {
  const ModernStatPill({
    super.key,
    required this.label,
    required this.value,
    this.suffix,
    required this.color,
    required this.icon,
    this.progress,
  });

  final String label;
  final String value;
  final String? suffix;
  final Color color;
  final IconData icon;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFCBD5E1), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x15000000),
            offset: Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.muted,
                    fontFamily: 'SpaceMono',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, size: 14, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontFamily: 'SpaceMono',
                ),
              ),
              if (suffix != null) ...[
                const SizedBox(width: 3),
                Text(
                  suffix!,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.muted,
                    fontFamily: 'SpaceMono',
                  ),
                ),
              ],
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 6),
            ClipRRect(
              child: LinearProgressIndicator(
                value: progress!.clamp(0.0, 1.0),
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Dialog konfirmasi ACC KRS dengan animasi dan konfirmasi aman.
class KrsDetailDialog extends StatelessWidget {
  const KrsDetailDialog({
    super.key,
    required this.request,
    required this.onApprove,
    required this.onRevise,
  });

  final KrsApprovalRequest request;
  final VoidCallback onApprove;
  final ValueChanged<String> onRevise;

  @override
  Widget build(BuildContext context) {
    final noteController = TextEditingController(
      text: request.advisorNotes ?? '',
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 680),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.paper,
            border: Border.all(color: AppTheme.ink, width: 3.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x35000000),
                offset: Offset(5, 6),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                color: AppTheme.blue,
                child: Row(
                  children: [
                    const Icon(Icons.school, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'VALIDASI KRS · ${request.studentName}',
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
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'NIM: ${request.studentNim}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                'Semester ${request.semester} · ${request.major}',
                                style: const TextStyle(
                                  color: AppTheme.muted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: request.status == KrsStatus.approved
                                  ? const Color(0xFFDCFCE7)
                                  : const Color(0xFFFEF3C7),
                              border: Border.all(
                                color: request.status == KrsStatus.approved
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFFD97706),
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              request.status == KrsStatus.approved
                                  ? 'Disetujui'
                                  : 'Menunggu ACC',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: request.status == KrsStatus.approved
                                    ? const Color(0xFF15803D)
                                    : const Color(0xFFB45309),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: Colors.white,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _stat(
                              'IPK Kumulatif',
                              request.gpa.toStringAsFixed(2),
                            ),
                            _stat(
                              'SKS Diajukan',
                              '${request.proposedCredits} SKS',
                            ),
                            _stat(
                              'Batas Maksimal',
                              '${request.maxCredits} SKS',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'DAFTAR MATA KULIAH DIAJUKAN:',
                        style: AppTheme.pixel(7.5, color: AppTheme.blue),
                      ),
                      const SizedBox(height: 8),
                      for (var i = 0; i < request.courses.length; i++) ...[
                        _courseRow(i + 1, request.courses[i]),
                        if (i < request.courses.length - 1)
                          const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      ],
                      const SizedBox(height: 16),
                      Text(
                        'CATATAN DOSEN PEMBIMBING AKADEMIK:',
                        style: AppTheme.pixel(7.5),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: noteController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'Tuliskan catatan akademik atau instruksi revisi...',
                          border: OutlineInputBorder(),
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'SpaceMono',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(14),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onRevise(noteController.text.trim());
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        side: const BorderSide(
                          color: Color(0xFFDC2626),
                          width: 1.5,
                        ),
                        shape: const RoundedRectangleBorder(),
                      ),
                      child: const Text('Minta Revisi'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onApprove();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        shape: const RoundedRectangleBorder(),
                      ),
                      child: const Text('Setujui (ACC) KRS'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, String value) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: AppTheme.blue,
        ),
      ),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.muted)),
    ],
  );

  Widget _courseRow(int index, KrsCourseItem course) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          color: const Color(0xFFE2E8F0),
          child: Text(
            '$index',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${course.code} - ${course.name}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Kelas ${course.classSection} · ${course.schedule} · ${course.room}',
                style: const TextStyle(fontSize: 10.5, color: AppTheme.muted),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          color: const Color(0xFFE0F2FE),
          child: Text(
            '${course.credits} SKS',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0369A1),
            ),
          ),
        ),
      ],
    ),
  );
}
