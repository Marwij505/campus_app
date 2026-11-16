// Panel tridharma pengajaran & perkuliahan untuk Dosen Akademik.
// Menyediakan jadwal mengajar, pengisian BAP, presensi mahasiswa, rekap nilai kelas,
// serta akses terpadu ke surat izin mahasiswa yang relevan.

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../data/lecturer_models.dart';
import '../../shared/pixel_widgets.dart';
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
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: PixelPanel(
              color: AppTheme.paper,
              borderWidth: 4,
              shadowOffset: 6,
              padding: EdgeInsets.zero,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: AppTheme.blue,
                    child: Row(
                      children: [
                        const Icon(Icons.fact_check_outlined, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'PRESENSI · ${schedule.courseCode}',
                            style: AppTheme.pixel(8, color: Colors.white),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 18),
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
                        Text(schedule.courseName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                        const SizedBox(height: 4),
                        Text(
                          'Kelas ${schedule.classSection} · Pertemuan ${schedule.currentMeeting} · ${schedule.room}',
                          style: const TextStyle(color: AppTheme.muted, fontSize: 11),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    '$attended / $total',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.blue),
                                  ),
                                  const Text('Mahasiswa Hadir', style: TextStyle(fontSize: 10, color: AppTheme.muted)),
                                ],
                              ),
                              Column(
                                children: [
                                  Text(
                                    '${((attended / total) * 100).toStringAsFixed(1)}%',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                                  ),
                                  const Text('Tingkat Kehadiran', style: TextStyle(fontSize: 10, color: AppTheme.muted)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('SIMULASI JUMLAH KEHADIRAN:', style: AppTheme.pixel(7.5)),
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
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: AppTheme.ink, width: 2),
                              ),
                              child: Text(
                                '$attended Mahasiswa',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
                          style: FilledButton.styleFrom(backgroundColor: AppTheme.blue),
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
          ? 'Perkuliahan berjalan lancar. Materi tersampaikan 100% dan sesi tanya jawab aktif.'
          : '',
    );

    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: PixelPanel(
            color: AppTheme.paper,
            borderWidth: 4,
            shadowOffset: 6,
            padding: EdgeInsets.zero,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  color: const Color(0xFF0F766E),
                  child: Row(
                    children: [
                      const Icon(Icons.edit_document, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'BERITA ACARA PERKULIAHAN (BAP)',
                          style: AppTheme.pixel(8, color: Colors.white),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 18),
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
                      Text('${schedule.courseCode} · ${schedule.courseName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('Kelas ${schedule.classSection} · Pertemuan ke-${schedule.currentMeeting} dari ${schedule.totalMeetings}', style: const TextStyle(color: AppTheme.muted, fontSize: 11)),
                      const SizedBox(height: 14),
                      Text('TOPIK / MATERI PERKULIAHAN:', style: AppTheme.pixel(7.5)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: topicController,
                        decoration: const InputDecoration(
                          hintText: 'Contoh: Analisis Kebutuhan Sistem & Pemodelan UML',
                          border: OutlineInputBorder(),
                        ),
                        style: const TextStyle(fontSize: 12, fontFamily: 'SpaceMono'),
                      ),
                      const SizedBox(height: 12),
                      Text('CATATAN PELAKSANAAN KELAS & TUGAS:', style: AppTheme.pixel(7.5)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Catatan progres materi, keaktifan mahasiswa, kendala, atau tugas yang diberikan...',
                          border: OutlineInputBorder(),
                        ),
                        style: const TextStyle(fontSize: 12, fontFamily: 'SpaceMono'),
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
                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0F766E)),
                        child: const Text('Simpan & Validasi BAP'),
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
        content: Text('Presensi kelas berhasil diperbarui & tersimpan di SIAKAD.'),
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
        content: Text('BAP Perkuliahan berhasil disimpan & divalidasi ke sistem fakultas.'),
        backgroundColor: Color(0xFF0F766E),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredSchedules = widget.schedules.where((s) {
      if (_selectedFilter == 'Berlangsung') return s.status == 'Berlangsung';
      if (_selectedFilter == 'Akan Datang') return s.status == 'Akan Datang';
      if (_selectedFilter == 'Selesai') return s.status == 'Selesai';
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Kartu Ringkasan Pengajaran
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 600;
            return GridView.count(
              crossAxisCount: isNarrow ? 2 : 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: isNarrow ? 1.4 : 1.6,
              children: [
                LecturerStatCard(
                  label: 'KELAS DIAMPU',
                  value: '${widget.stats.totalClasses}',
                  suffix: 'Kelas',
                  icon: Icons.menu_book_outlined,
                  color: AppTheme.blue,
                  subtitle: '${widget.stats.totalCredits} SKS Semester Ini',
                ),
                LecturerStatCard(
                  label: 'TOTAL MAHASISWA',
                  value: '${widget.stats.totalStudentsTaught}',
                  suffix: 'Mhs',
                  icon: Icons.groups_outlined,
                  color: const Color(0xFF16A34A),
                  subtitle: 'Aktif terdaftar di kelas',
                ),
                LecturerStatCard(
                  label: 'RATA KEHADIRAN',
                  value: '${widget.stats.averageAttendance.toStringAsFixed(1)}',
                  suffix: '%',
                  icon: Icons.fact_check_outlined,
                  color: const Color(0xFFD97706),
                  progress: widget.stats.averageAttendance / 100,
                  subtitle: 'Presensi mahasiswa',
                ),
                LecturerStatCard(
                  label: 'PENGISIAN BAP',
                  value: '${widget.stats.bapCompletionRate.toStringAsFixed(0)}',
                  suffix: '%',
                  icon: Icons.task_alt_outlined,
                  color: const Color(0xFF8B5CF6),
                  progress: widget.stats.bapCompletionRate / 100,
                  subtitle: 'Berita acara perkuliahan',
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 20),

        // Section Jadwal Mengajar
        PixelPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_month_outlined, color: AppTheme.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'JADWAL MENGAJAR & KELAS KULIAH',
                      style: AppTheme.pixel(8.5, color: AppTheme.blue),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final filter in ['Semua', 'Berlangsung', 'Akan Datang', 'Selesai']) ...[
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(filter, style: const TextStyle(fontSize: 11, fontFamily: 'SpaceMono')),
                          selected: _selectedFilter == filter,
                          onSelected: (_) => setState(() => _selectedFilter = filter),
                          selectedColor: AppTheme.blue.withValues(alpha: 0.15),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (filteredSchedules.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  child: const Text('Tidak ada jadwal mengajar pada filter ini.', style: TextStyle(color: AppTheme.muted)),
                )
              else
                for (final item in filteredSchedules) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TeachingScheduleCard(
                      schedule: item,
                      onAttendanceTap: () => _openAttendanceDialog(item),
                      onBapTap: () => _openBapDialog(item),
                    ),
                  ),
                ],
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Section Rekap Kelas Kuliah & Input Nilai
        PixelPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.table_chart_outlined, color: AppTheme.ink, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'REKAP PERKULIAHAN & STATUS INPUT NILAI',
                      style: AppTheme.pixel(8, color: AppTheme.ink),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              for (final cls in widget.classes) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFCBD5E1), width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${cls.courseCode} - ${cls.courseName} (${cls.classSection})',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            color: const Color(0xFFE0F2FE),
                            child: Text(
                              '${cls.credits} SKS',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.people_outline, size: 14, color: AppTheme.muted),
                          const SizedBox(width: 4),
                          Text('${cls.totalStudents} Mahasiswa', style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
                          const SizedBox(width: 14),
                          const Icon(Icons.percent, size: 14, color: Color(0xFF16A34A)),
                          const SizedBox(width: 4),
                          Text('Rata Presensi ${cls.averageAttendance.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 11, color: Color(0xFF16A34A))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        color: const Color(0xFFFEF9C3),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, size: 13, color: Color(0xFFCA8A04)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Nilai: ${cls.gradeInputStatus}',
                                style: const TextStyle(fontSize: 10.5, color: Color(0xFF854D0E), fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Section Akses Terpadu Izin Kuliah Mahasiswa
        if (widget.leaveRepository != null)
          PixelPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.mark_email_read_outlined, color: AppTheme.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'SURAT IZIN & DISPENSASI MAHASISWA',
                        style: AppTheme.pixel(8, color: AppTheme.red),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Lihat permohonan izin sakit, dispensasi kegiatan, atau ketidakhadiran resmi yang diajukan mahasiswa untuk kelas Anda.',
                  style: TextStyle(fontSize: 11.5, color: AppTheme.muted),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => LeavePage(
                        repository: widget.leaveRepository!,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.folder_shared_outlined, size: 16),
                  label: const Text('Buka Kotak Surat Izin Kuliah'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.red,
                    side: const BorderSide(color: AppTheme.red, width: 2),
                    shape: const RoundedRectangleBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
