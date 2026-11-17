// Panel Tridharma Pengajaran & Perkuliahan Versi Baru.
// Menghadirkan timeline kelas modern, presensi interaktif, validasi BAP,
// dan pemantauan mahasiswa izin.

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../data/lecturer_models.dart';
import '../leave/leave_page.dart';
import '../leave/leave_repository.dart';
import 'lecturer_widgets.dart';

class TeachingPanel extends StatefulWidget {
  const TeachingPanel({
    super.key,
    required this.schedules,
    required this.classes,
    required this.stats,
    required this.onScheduleUpdated,
    this.leaveRepository,
  });

  final List<TeachingScheduleItem> schedules;
  final List<TeachingClassSummary> classes;
  final LecturerDashboardStats stats;
  final ValueChanged<List<TeachingScheduleItem>> onScheduleUpdated;
  final LeaveRepository? leaveRepository;

  @override
  State<TeachingPanel> createState() => _TeachingPanelState();
}

class _TeachingPanelState extends State<TeachingPanel> {
  String _selectedFilter = 'Semua';

  void _openAttendanceDialog(TeachingScheduleItem schedule) {
    int attended = schedule.attendedStudents;
    final total = schedule.enrolledStudents;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
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
                          Icons.fact_check_outlined,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'PRESENSI · ${schedule.courseCode} (${schedule.classSection})',
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
                          schedule.courseName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Pertemuan ke-${schedule.currentMeeting} dari ${schedule.totalMeetings} · ${schedule.room}',
                          style: const TextStyle(
                            color: AppTheme.muted,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          color: Colors.white,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    '$attended / $total',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.blue,
                                    ),
                                  ),
                                  const Text(
                                    'Mahasiswa Hadir',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.muted,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  Text(
                                    '${((attended / total) * 100).toStringAsFixed(1)}%',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF16A34A),
                                    ),
                                  ),
                                  const Text(
                                    'Tingkat Kehadiran',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'SIMULASI JUMLAH KEHADIRAN MAHASISWA:',
                          style: AppTheme.pixel(7),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: attended > 0
                                  ? () => setDialogState(() => attended--)
                                  : null,
                              icon: const Icon(Icons.remove_circle_outline),
                              color: const Color(0xFFDC2626),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: AppTheme.ink,
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                '$attended Mahasiswa',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: attended < total
                                  ? () => setDialogState(() => attended++)
                                  : null,
                              icon: const Icon(Icons.add_circle_outline),
                              color: const Color(0xFF16A34A),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.white,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Batal'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            _updateScheduleAttendance(schedule.id, attended);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.blue,
                          ),
                          child: const Text('Simpan Presensi'),
                        ),
                      ],
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

  void _openBapDialog(TeachingScheduleItem schedule) {
    final topicController = TextEditingController(text: schedule.bapTopic);
    final notesController = TextEditingController(
      text: schedule.bapSubmitted
          ? 'Perkuliahan berjalan lancar. Materi tersampaikan dan mahasiswa aktif bertanya.'
          : '',
    );

    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
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
                  color: const Color(0xFF0F766E),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.edit_document,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'PENGISIAN BAP · ${schedule.courseCode}',
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
                        '${schedule.courseName} (${schedule.classSection})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Pertemuan ke-${schedule.currentMeeting} · ${schedule.room}',
                        style: const TextStyle(
                          color: AppTheme.muted,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'TOPIK / MATERI PERKULIAHAN:',
                        style: AppTheme.pixel(7),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: topicController,
                        decoration: const InputDecoration(
                          hintText: 'Materi yang disampaikan hari ini...',
                          border: OutlineInputBorder(),
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'SpaceMono',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'CATATAN / TUGAS PERKULIAHAN:',
                        style: AppTheme.pixel(7),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'Catatan tambahan evaluasi kelas...',
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
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Batal'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () {
                          final topic = topicController.text.trim();
                          if (topic.isNotEmpty) {
                            Navigator.of(ctx).pop();
                            _updateScheduleBap(schedule.id, topic);
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                        ),
                        child: const Text('Validasi & Simpan BAP'),
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

  void _updateScheduleAttendance(String id, int attended) {
    final updated = widget.schedules.map((s) {
      if (s.id == id) {
        return s.copyWith(attendedStudents: attended);
      }
      return s;
    }).toList();
    widget.onScheduleUpdated(updated);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Presensi kelas tersimpan di pangkalan data SIAKAD.'),
        backgroundColor: Color(0xFF16A34A),
      ),
    );
  }

  void _updateScheduleBap(String id, String topic) {
    final updated = widget.schedules.map((s) {
      if (s.id == id) {
        return s.copyWith(bapSubmitted: true, bapTopic: topic);
      }
      return s;
    }).toList();
    widget.onScheduleUpdated(updated);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Berita Acara Perkuliahan (BAP) telah diverifikasi & tersimpan.',
        ),
        backgroundColor: Color(0xFF0F766E),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final liveOrNextSchedule = widget.schedules.firstWhere(
      (s) => s.status == 'Berlangsung',
      orElse: () => widget.schedules.first,
    );

    final filtered = widget.schedules.where((s) {
      if (_selectedFilter == 'Berlangsung') return s.status == 'Berlangsung';
      if (_selectedFilter == 'Akan Datang') return s.status == 'Akan Datang';
      if (_selectedFilter == 'Selesai') return s.status == 'Selesai';
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 4 Stat Pills Ringkas
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 620;
            return GridView.count(
              crossAxisCount: isNarrow ? 2 : 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: isNarrow ? 1.25 : 1.6,
              children: [
                ModernStatPill(
                  label: 'KELAS DIAMPU',
                  value: '${widget.stats.totalClasses}',
                  suffix: 'Kelas',
                  color: AppTheme.blue,
                  icon: Icons.class_outlined,
                  progress: 1.0,
                ),
                ModernStatPill(
                  label: 'TOTAL MAHASISWA',
                  value: '${widget.stats.totalStudentsTaught}',
                  suffix: 'Mhs',
                  color: const Color(0xFF16A34A),
                  icon: Icons.groups_outlined,
                  progress: 0.9,
                ),
                ModernStatPill(
                  label: 'RATA PRESENSI',
                  value: '${widget.stats.averageAttendance.toStringAsFixed(1)}',
                  suffix: '%',
                  color: const Color(0xFFD97706),
                  icon: Icons.fact_check_outlined,
                  progress: widget.stats.averageAttendance / 100,
                ),
                ModernStatPill(
                  label: 'PENGISIAN BAP',
                  value: '${widget.stats.bapCompletionRate.toStringAsFixed(0)}',
                  suffix: '%',
                  color: const Color(0xFF8B5CF6),
                  icon: Icons.task_alt_outlined,
                  progress: widget.stats.bapCompletionRate / 100,
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 16),

        // Spotlight Kelas Terdekat / Aktif
        SpotlightLectureCard(
          schedule: liveOrNextSchedule,
          onAttendanceTap: () => _openAttendanceDialog(liveOrNextSchedule),
          onBapTap: () => _openBapDialog(liveOrNextSchedule),
        ),

        const SizedBox(height: 20),

        // Section Jadwal Mengajar & Timeline Kelas
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFCBD5E1), width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x15000000),
                offset: Offset(2, 3),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 620;
                  final chips = SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final filter in [
                          'Semua',
                          'Berlangsung',
                          'Akan Datang',
                          'Selesai',
                        ]) ...[
                          ChoiceChip(
                            label: Text(
                              filter,
                              style: const TextStyle(
                                fontSize: 10,
                                fontFamily: 'SpaceMono',
                              ),
                            ),
                            selected: _selectedFilter == filter,
                            onSelected: (_) =>
                                setState(() => _selectedFilter = filter),
                            selectedColor: AppTheme.blue.withValues(
                              alpha: 0.15,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                      ],
                    ),
                  );

                  if (isCompact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.view_timeline_outlined,
                              color: AppTheme.blue,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'TIMELINE PERKULIAHAN SEMESTER AKTIF',
                                style: AppTheme.pixel(8, color: AppTheme.blue),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        chips,
                      ],
                    );
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.view_timeline_outlined,
                            color: AppTheme.blue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'TIMELINE PERKULIAHAN SEMESTER AKTIF',
                            style: AppTheme.pixel(8, color: AppTheme.blue),
                          ),
                        ],
                      ),
                      chips,
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),
              for (final item in filtered) ...[
                _buildTimelineClassItem(item),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Tombol Akses Izin Mahasiswa
        if (widget.leaveRepository != null)
          InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (ctx) =>
                    LeavePage(repository: widget.leaveRepository!),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                border: Border.all(color: const Color(0xFFF87171), width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.mail_outline,
                    color: Color(0xFFDC2626),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Pusat Surat Izin & Dispensasi Kuliah Mahasiswa',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Color(0xFF991B1B),
                          ),
                        ),
                        Text(
                          'Tinjau surat izin sakit & tugas resmi mahasiswa kelas Anda',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFFB91C1C),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Color(0xFFDC2626),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTimelineClassItem(TeachingScheduleItem item) {
    final isLive = item.status == 'Berlangsung';
    final statusColor = isLive
        ? const Color(0xFF16A34A)
        : (item.status == 'Selesai' ? AppTheme.muted : const Color(0xFF2563EB));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(
          color: isLive ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                color: AppTheme.blue,
                child: Text(
                  '${item.courseCode} · ${item.classSection}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${item.credits} SKS',
                style: const TextStyle(
                  fontSize: 10.5,
                  color: AppTheme.muted,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                color: statusColor.withValues(alpha: 0.12),
                child: Text(
                  item.status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            item.courseName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            children: [
              Text(
                '${item.day}, ${item.time}',
                style: const TextStyle(fontSize: 11, color: AppTheme.muted),
              ),
              Text(
                'Ruang: ${item.room}',
                style: const TextStyle(fontSize: 11, color: AppTheme.muted),
              ),
              Text(
                'Pertemuan ${item.currentMeeting}/${item.totalMeetings}',
                style: const TextStyle(fontSize: 11, color: AppTheme.muted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 420;
              final bapText = Text(
                item.bapSubmitted
                    ? '✓ BAP: "${item.bapTopic}"'
                    : '⚠ BAP belum terisi untuk pertemuan ini',
                style: TextStyle(
                  fontSize: 10.5,
                  fontStyle: FontStyle.italic,
                  color: item.bapSubmitted
                      ? const Color(0xFF15803D)
                      : const Color(0xFFB45309),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              );

              final actionButtons = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton(
                    onPressed: () => _openAttendanceDialog(item),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      shape: const RoundedRectangleBorder(),
                    ),
                    child: const Text(
                      'Presensi',
                      style: TextStyle(fontSize: 10.5),
                    ),
                  ),
                  const SizedBox(width: 6),
                  FilledButton(
                    onPressed: () => _openBapDialog(item),
                    style: FilledButton.styleFrom(
                      backgroundColor: item.bapSubmitted
                          ? const Color(0xFF0F766E)
                          : AppTheme.blue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      shape: const RoundedRectangleBorder(),
                    ),
                    child: Text(
                      item.bapSubmitted ? 'BAP' : 'Isi BAP',
                      style: const TextStyle(fontSize: 10.5),
                    ),
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [bapText, const SizedBox(height: 8), actionButtons],
                );
              }

              return Row(
                children: [
                  Expanded(child: bapText),
                  const SizedBox(width: 8),
                  actionButtons,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
