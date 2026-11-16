// Komponen visual dan kartu khusus untuk Dashboard Dosen Akademik & Pembimbing.
// Menggunakan gaya visual konsisten dengan AppTheme, PixelPanel, dan PressStart2P.

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../data/lecturer_models.dart';
import '../../shared/pixel_widgets.dart';

/// Kartu statistik retro dengan bingkai piksel dan indikator progres.
class LecturerStatCard extends StatelessWidget {
  const LecturerStatCard({
    super.key,
    required this.label,
    required this.value,
    this.suffix,
    required this.icon,
    required this.color,
    this.progress,
    this.subtitle,
    this.onTap,
  });

  final String label;
  final String value;
  final String? suffix;
  final IconData icon;
  final Color color;
  final double? progress;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cardContent = PixelPanel(
      color: Colors.white,
      padding: const EdgeInsets.all(14),
      borderWidth: 3,
      shadowOffset: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTheme.pixel(7.5, color: AppTheme.muted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  border: Border.all(color: color, width: 2),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontFamily: 'SpaceMono',
                ),
              ),
              if (suffix != null) ...[
                const SizedBox(width: 4),
                Text(
                  suffix!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.muted,
                    fontFamily: 'SpaceMono',
                  ),
                ),
              ],
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.zero,
              child: LinearProgressIndicator(
                value: progress!.clamp(0.0, 1.0),
                backgroundColor: const Color(0xFFE5ECEE),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
          ],
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 10.5,
                color: AppTheme.ink,
                fontFamily: 'SpaceMono',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        child: cardContent,
      );
    }
    return cardContent;
  }
}

/// Chip lencana status peran dosen atau kategori akademik.
class RoleBadgeChip extends StatelessWidget {
  const RoleBadgeChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      border: Border.all(color: color, width: 1.5),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: color,
            fontFamily: 'SpaceMono',
          ),
        ),
      ],
    ),
  );
}

/// Chip status persetujuan KRS.
class KrsStatusBadge extends StatelessWidget {
  const KrsStatusBadge({super.key, required this.status});

  final KrsStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      KrsStatus.pending => (
        'Menunggu ACC',
        const Color(0xFFD97706),
        Icons.hourglass_top_outlined,
      ),
      KrsStatus.approved => (
        'Disetujui',
        const Color(0xFF16A34A),
        Icons.check_circle_outline,
      ),
      KrsStatus.revision => (
        'Perlu Revisi',
        const Color(0xFFDC2626),
        Icons.warning_amber_outlined,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: color,
              fontFamily: 'SpaceMono',
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu jadwal mengajar dengan rincian kelas, pertemuan, dan tombol aksi BAP/Presensi.
class TeachingScheduleCard extends StatelessWidget {
  const TeachingScheduleCard({
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
    final statusColor = isLive
        ? const Color(0xFF16A34A)
        : (schedule.status == 'Selesai'
            ? AppTheme.muted
            : const Color(0xFF2563EB));

    return PixelPanel(
      color: Colors.white,
      padding: const EdgeInsets.all(14),
      borderWidth: 3,
      shadowOffset: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.blue,
                  border: Border.all(color: AppTheme.ink, width: 1.5),
                ),
                child: Text(
                  '${schedule.courseCode} · ${schedule.classSection}',
                  style: AppTheme.pixel(7, color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  border: Border.all(color: const Color(0xFFD97706), width: 1.5),
                ),
                child: Text(
                  '${schedule.credits} SKS',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFB45309),
                    fontFamily: 'SpaceMono',
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  border: Border.all(color: statusColor, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      schedule.status,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                        fontFamily: 'SpaceMono',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            schedule.courseName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
              fontFamily: 'SpaceMono',
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _infoChip(Icons.access_time_outlined, '${schedule.day}, ${schedule.time}'),
              _infoChip(Icons.room_outlined, schedule.room),
              _infoChip(Icons.people_outline, '${schedule.attendedStudents}/${schedule.enrolledStudents} Mhs Hadir (${schedule.attendancePercentage.toStringAsFixed(0)}%)'),
              _infoChip(Icons.calendar_today_outlined, 'Pertemuan ke-${schedule.currentMeeting} dari ${schedule.totalMeetings}'),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              border: Border.all(
                color: schedule.bapSubmitted
                    ? const Color(0xFF86EFAC)
                    : const Color(0xFFFDE047),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  schedule.bapSubmitted
                      ? Icons.task_alt_outlined
                      : Icons.pending_actions_outlined,
                  size: 16,
                  color: schedule.bapSubmitted
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFCA8A04),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    schedule.bapSubmitted
                        ? 'BAP Terisi: "${schedule.bapTopic}"'
                        : 'BAP Belum Terisi untuk sesi perkuliahan ini',
                    style: TextStyle(
                      fontSize: 11,
                      color: schedule.bapSubmitted
                          ? const Color(0xFF15803D)
                          : const Color(0xFFA16207),
                      fontFamily: 'SpaceMono',
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onAttendanceTap,
                  icon: const Icon(Icons.fact_check_outlined, size: 16),
                  label: const Text('Presensi Kelas', style: TextStyle(fontSize: 11.5)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.blue,
                    side: const BorderSide(color: AppTheme.blue, width: 2),
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
                    schedule.bapSubmitted ? Icons.edit_note : Icons.edit_document,
                    size: 16,
                  ),
                  label: Text(
                    schedule.bapSubmitted ? 'Ubah BAP' : 'Isi BAP',
                    style: const TextStyle(fontSize: 11.5),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.blue,
                    shape: const RoundedRectangleBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: AppTheme.muted),
      const SizedBox(width: 4),
      Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          color: AppTheme.muted,
          fontFamily: 'SpaceMono',
        ),
      ),
    ],
  );
}

/// Kartu pengajuan KRS mahasiswa bimbingan dengan tombol ACC dan detail mata kuliah.
class KrsApprovalCard extends StatelessWidget {
  const KrsApprovalCard({
    super.key,
    required this.request,
    required this.onApprove,
    required this.onRevise,
    required this.onViewDetails,
  });

  final KrsApprovalRequest request;
  final VoidCallback onApprove;
  final VoidCallback onRevise;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) => PixelPanel(
    color: Colors.white,
    padding: const EdgeInsets.all(14),
    borderWidth: 3,
    shadowOffset: 4,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        request.studentName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.ink,
                          fontFamily: 'SpaceMono',
                        ),
                      ),
                      const SizedBox(width: 8),
                      KrsStatusBadge(status: request.status),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'NIM: ${request.studentNim} · Smt ${request.semester} · ${request.major}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.muted,
                      fontFamily: 'SpaceMono',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          color: const Color(0xFFF8FAFC),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _metric('IPK Kumulatif', request.gpa.toStringAsFixed(2), AppTheme.blue),
              _metric('SKS Diajukan', '${request.proposedCredits} SKS', const Color(0xFF16A34A)),
              _metric('Maksimal Beban', '${request.maxCredits} SKS', AppTheme.ink),
              _metric('Jml Mata Kuliah', '${request.courses.length} MK', AppTheme.muted),
            ],
          ),
        ),
        if (request.advisorNotes != null && request.advisorNotes!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Catatan DPA: "${request.advisorNotes}"',
            style: const TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: AppTheme.blue,
              fontFamily: 'SpaceMono',
            ),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            TextButton.icon(
              onPressed: onViewDetails,
              icon: const Icon(Icons.list_alt_outlined, size: 15),
              label: const Text('Rincian MK', style: TextStyle(fontSize: 11)),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.blue,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            ),
            const Spacer(),
            if (request.status == KrsStatus.pending) ...[
              OutlinedButton.icon(
                onPressed: onRevise,
                icon: const Icon(Icons.edit_note, size: 15),
                label: const Text('Minta Revisi', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
                  shape: const RoundedRectangleBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: onApprove,
                icon: const Icon(Icons.check, size: 15),
                label: const Text('ACC KRS', style: TextStyle(fontSize: 11)),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  shape: const RoundedRectangleBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              ),
            ] else ...[
              Text(
                request.status == KrsStatus.approved
                    ? '✓ Telah Disetujui'
                    : '⚠ Menunggu Mahasiswa Memperbaiki',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: request.status == KrsStatus.approved
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFDC2626),
                  fontFamily: 'SpaceMono',
                ),
              ),
            ],
          ],
        ),
      ],
    ),
  );

  Widget _metric(String label, String value, Color color) => Column(
    children: [
      Text(
        value,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: color,
          fontFamily: 'SpaceMono',
        ),
      ),
      const SizedBox(height: 2),
      Text(
        label,
        style: const TextStyle(
          fontSize: 9.5,
          color: AppTheme.muted,
          fontFamily: 'SpaceMono',
        ),
      ),
    ],
  );
}

/// Dialog rincian mata kuliah yang diajukan dalam KRS dengan opsi persetujuan langsung.
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
    final noteController = TextEditingController(text: request.advisorNotes ?? '');

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 680),
        child: PixelPanel(
          color: AppTheme.paper,
          borderWidth: 4,
          shadowOffset: 6,
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                color: AppTheme.blue,
                child: Row(
                  children: [
                    const Icon(Icons.school_outlined, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'RINCIAN KRS · ${request.studentName}',
                        style: AppTheme.pixel(8, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 18),
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
                              Text('NIM: ${request.studentNim}', style: const TextStyle(fontWeight: FontWeight.w700)),
                              Text('Semester ${request.semester} · ${request.major}', style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
                            ],
                          ),
                          KrsStatusBadge(status: request.status),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _stat('IPK Kumulatif', request.gpa.toStringAsFixed(2)),
                            _stat('Total SKS Diajukan', '${request.proposedCredits} SKS'),
                            _stat('Maksimal Beban', '${request.maxCredits} SKS'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('DAFTAR MATA KULIAH DIAJUKAN (${request.courses.length} MK):', style: AppTheme.pixel(7.5, color: AppTheme.blue)),
                      const SizedBox(height: 8),
                      for (var i = 0; i < request.courses.length; i++) ...[
                        _courseRow(i + 1, request.courses[i]),
                        if (i < request.courses.length - 1)
                          const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      ],
                      const SizedBox(height: 16),
                      Text('CATATAN / ARAHAN DOSEN PEMBIMBING:', style: AppTheme.pixel(7.5, color: AppTheme.ink)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: noteController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'Tuliskan catatan akademik atau instruksi revisi...',
                          border: OutlineInputBorder(),
                        ),
                        style: const TextStyle(fontSize: 12, fontFamily: 'SpaceMono'),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFCBD5E1), width: 2)),
                ),
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
                        side: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
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
      Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.blue)),
      Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.muted)),
    ],
  );

  Widget _courseRow(int index, KrsCourseItem course) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          color: const Color(0xFFE2E8F0),
          child: Text('$index', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${course.code} - ${course.name}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                'Kelas: ${course.classSection} · ${course.schedule} · ${course.room}',
                style: const TextStyle(fontSize: 11, color: AppTheme.muted),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          color: const Color(0xFFE0F2FE),
          child: Text(
            '${course.credits} SKS',
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
          ),
        ),
      ],
    ),
  );
}
