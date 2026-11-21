// Panel Monitoring Presensi & BAP — BAP Dashboard.

import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../data/bap_models.dart';
import 'bap_widgets.dart';

class BapAttendancePanel extends StatefulWidget {
  const BapAttendancePanel({
    super.key,
    required this.summaries,
    required this.makeupRequests,
    required this.onMakeupUpdated,
  });

  final List<AttendanceSummary> summaries;
  final List<MakeupClassRequest> makeupRequests;
  final ValueChanged<List<MakeupClassRequest>> onMakeupUpdated;

  @override
  State<BapAttendancePanel> createState() => _BapAttendancePanelState();
}

class _BapAttendancePanelState extends State<BapAttendancePanel> {
  int _subTab = 0;

  @override
  Widget build(BuildContext context) {
    final pendingMakeup = widget.makeupRequests.where((m) => !m.isApproved).length;
    final pendingBap = widget.summaries.fold<int>(0, (s, a) => s + a.pendingBapCount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BapPanelHeader(
          icon: Icons.fact_check_outlined,
          title: 'MONITORING PRESENSI & BERITA ACARA KULIAH',
          subtitle: '$pendingBap BAP belum terisi · $pendingMakeup kuliah pengganti menunggu',
          color: const Color(0xFF0369A1),
          actionLabel: _subTab == 1 ? '+ Jadwalkan Pengganti' : null,
          onAction: _subTab == 1 ? _showAddMakeupDialog : null,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _subTabBtn(0, 'Rekap Kehadiran & BAP', pendingBap > 0 ? '$pendingBap' : null),
            const SizedBox(width: 8),
            _subTabBtn(1, 'Kuliah Pengganti', pendingMakeup > 0 ? '$pendingMakeup' : null),
          ],
        ),
        const SizedBox(height: 12),
        if (_subTab == 0) _buildAttendanceSection(),
        if (_subTab == 1) _buildMakeupSection(),
      ],
    );
  }

  Widget _subTabBtn(int idx, String label, String? badge) {
    final sel = _subTab == idx;
    return InkWell(
      onTap: () => setState(() => _subTab = idx),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFF0369A1) : Colors.white,
          border: Border.all(color: sel ? const Color(0xFF0369A1) : AppTheme.ink, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: sel ? Colors.white : AppTheme.ink, fontFamily: 'SpaceMono')),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFDC2626), borderRadius: BorderRadius.circular(10)),
                child: Text(badge, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceSection() {
    return Column(
      children: widget.summaries.map((a) {
        final pct = a.conductedMeetings / (a.totalMeetings == 0 ? 1 : a.totalMeetings);
        final alertBap = a.pendingBapCount > 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: alertBap ? const Color(0xFFFFFBEB) : Colors.white,
            border: Border.all(
              color: alertBap ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1),
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        color: const Color(0xFF0369A1),
                        child: Text(
                          '${a.courseCode} · ${a.classSection}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'SpaceMono',
                          ),
                        ),
                      ),
                      if (alertBap) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          color: const Color(0xFFD97706),
                          child: Text(
                            '${a.pendingBapCount} BAP BELUM TERISI',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'SpaceMono',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    '${a.averageStudentAttendance.toStringAsFixed(1)}% kehadiran mhs',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: a.averageStudentAttendance < 75
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF16A34A),
                      fontFamily: 'SpaceMono',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(a.courseName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.ink)),
              const SizedBox(height: 2),
              Text('Dosen: ${a.lecturerName}', style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Pertemuan Terlaksana: ${a.conductedMeetings} / ${a.totalMeetings}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.muted, fontFamily: 'SpaceMono')),
                  Text('${(pct * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.ink)),
                ],
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: pct,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(pct < 0.5 ? const Color(0xFFDC2626) : const Color(0xFF0369A1)),
                minHeight: 6,
              ),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 6,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _showExportRekapDialog(a),
                    icon: const Icon(Icons.description_outlined, size: 13),
                    label: const Text('Detail & Ekspor Rekap', style: TextStyle(fontSize: 10.5)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0369A1),
                      side: const BorderSide(color: Color(0xFF0369A1), width: 1.5),
                      shape: const RoundedRectangleBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                  ),
                  if (alertBap)
                    FilledButton.icon(
                      onPressed: () => _showReminderDialog(a),
                      icon: const Icon(Icons.send_outlined, size: 13),
                      label: const Text('Kirim Reminder', style: TextStyle(fontSize: 10.5)),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFD97706),
                        shape: const RoundedRectangleBorder(),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMakeupSection() {
    return Column(
      children: widget.makeupRequests.map((m) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: m.isApproved ? const Color(0xFFF0FDF4) : Colors.white,
            border: Border.all(
              color: m.isApproved ? const Color(0xFF86EFAC) : const Color(0xFFCBD5E1),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${m.courseName} · Kelas ${m.classSection}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.ink)),
                        const SizedBox(height: 2),
                        Text('Dosen: ${m.lecturerName}', style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
                      ],
                    ),
                  ),
                  BapStatusBadge(
                    label: m.isApproved ? 'Disetujui' : 'Menunggu',
                    color: m.isApproved ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              BapInfoRow(label: 'Kuliah Ditiadakan', value: m.originalDate, valueColor: const Color(0xFFDC2626)),
              BapInfoRow(label: 'Jadwal Pengganti', value: m.proposedDate, valueColor: const Color(0xFF16A34A)),
              BapInfoRow(label: 'Ruang Diusulkan', value: m.room),
              if (!m.isApproved) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        final updated = widget.makeupRequests.where((x) => x.id != m.id).toList();
                        widget.onMakeupUpdated(updated);
                        _showSnack('Jadwal kuliah pengganti ditolak.', const Color(0xFFDC2626));
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        side: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
                        shape: const RoundedRectangleBorder(),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      child: const Text('Tolak', style: TextStyle(fontSize: 10.5)),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () {
                        final updated = widget.makeupRequests.map((x) => x.id == m.id ? x.copyWith(isApproved: true) : x).toList();
                        widget.onMakeupUpdated(updated);
                        _showSnack('Kuliah pengganti disetujui & ruang dialokasikan.', const Color(0xFF16A34A));
                      },
                      icon: const Icon(Icons.check, size: 13),
                      label: const Text('Setujui Jadwal', style: TextStyle(fontSize: 10.5)),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        shape: const RoundedRectangleBorder(),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showExportRekapDialog(AttendanceSummary a) {
    showDialog(
      context: context,
      builder: (context) => BapDialogShell(
        title: 'REKAPITULASI BAP & PRESENSI KULIAH',
        subtitle: '${a.courseName} (${a.courseCode}) · Kelas ${a.classSection}',
        accentColor: const Color(0xFF0369A1),
        maxWidth: 620,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Dosen Pengampu: ${a.lecturerName}',
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.ink)),
                        const SizedBox(height: 2),
                        Text('Realisasi Tatap Muka: ${a.conductedMeetings} dari ${a.totalMeetings} pertemuan',
                            style: const TextStyle(fontSize: 10.5, color: AppTheme.muted)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${a.averageStudentAttendance.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: a.averageStudentAttendance < 75 ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                            fontFamily: 'SpaceMono',
                          )),
                      const Text('Rata-rata Presensi', style: TextStyle(fontSize: 9.5, color: AppTheme.muted)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text('DETAIL LOG PERTEMUAN BERKALA', style: AppTheme.pixel(6.5, color: AppTheme.ink)),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
              ),
              child: Column(
                children: [
                  Container(
                    color: const Color(0xFFF1F5F9),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    child: const Row(
                      children: [
                        SizedBox(width: 40, child: Text('Ptm', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'SpaceMono'))),
                        Expanded(child: Text('Topik Materi BAP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                        SizedBox(width: 70, child: Text('Kehadiran', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'SpaceMono'), textAlign: TextAlign.center)),
                        SizedBox(width: 80, child: Text('Status BAP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                      ],
                    ),
                  ),
                  for (var i = 1; i <= a.totalMeetings; i++) ...[
                    Builder(builder: (context) {
                      final done = i <= a.conductedMeetings;
                      final isPending = i > a.conductedMeetings && i <= a.conductedMeetings + a.pendingBapCount;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: i.isEven ? Colors.white : const Color(0xFFF8FAFC),
                          border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                        child: Row(
                          children: [
                            SizedBox(width: 40, child: Text('#$i', style: const TextStyle(fontSize: 10, fontFamily: 'SpaceMono'))),
                            Expanded(
                              child: Text(
                                done ? 'Pembahasan Modul & Praktikum $i' : (isPending ? 'Materi Terjadwal (Belum isi BAP)' : 'Rencana Perkuliahan'),
                                style: TextStyle(fontSize: 10.5, color: done ? AppTheme.ink : AppTheme.muted),
                              ),
                            ),
                            SizedBox(
                              width: 70,
                              child: Text(
                                done ? '${(85 + (i % 10)).clamp(0, 100)}%' : '-',
                                style: const TextStyle(fontSize: 10, fontFamily: 'SpaceMono'),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(
                              width: 80,
                              child: Align(
                                alignment: Alignment.center,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  color: done ? const Color(0xFFDCFCE7) : (isPending ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9)),
                                  child: Text(
                                    done ? 'Terverifikasi' : (isPending ? 'Pending' : 'Mendatang'),
                                    style: TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.bold,
                                      color: done ? const Color(0xFF16A34A) : (isPending ? const Color(0xFFD97706) : AppTheme.muted),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.ink,
              side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
              shape: const RoundedRectangleBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            ),
            child: const Text('Tutup'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showSnack('Rekap BAP & Presensi ${a.courseCode} berhasil diunduh (PDF / Excel).', const Color(0xFF0369A1));
            },
            icon: const Icon(Icons.download_outlined, size: 14),
            label: const Text('Unduh Rekap Lengkap'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0369A1),
              shape: const RoundedRectangleBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            ),
          ),
        ],
      ),
    );
  }

  void _showReminderDialog(AttendanceSummary a) {
    showDialog(
      context: context,
      builder: (context) => BapDialogShell(
        title: 'KIRIM NOTIFIKASI PENGINGAT BAP',
        subtitle: 'Kirim pengingat otomatis kepada dosen pengampu via WhatsApp & Email',
        accentColor: const Color(0xFFD97706),
        maxWidth: 520,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                border: Border.all(color: const Color(0xFFFCD34D), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Penerima: ${a.lecturerName}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.ink)),
                  const SizedBox(height: 2),
                  Text('Mata Kuliah: ${a.courseName} (${a.courseCode}) · Kelas ${a.classSection}', style: const TextStyle(fontSize: 10.5, color: AppTheme.muted)),
                  const SizedBox(height: 4),
                  Text('Terdapat ${a.pendingBapCount} pertemuan perkuliahan yang belum diisi berita acaranya.',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text('Pratinjau Pesan Notifikasi:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.ink)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              color: const Color(0xFFF8FAFC),
              child: Text(
                'Yth. Bapak/Ibu ${a.lecturerName},\n'
                'Mohon kesediaannya untuk melengkapi Berita Acara Perkuliahan (BAP) dan Presensi Mahasiswa untuk mata kuliah ${a.courseName} (${a.classSection}) pada portal SIAKAD sebelum batas akhir penutupan BAP.\n\n'
                'Terima kasih,\nBiro Administrasi Perkuliahan (BAP) FASILKOM',
                style: const TextStyle(fontSize: 10.5, fontFamily: 'SpaceMono', height: 1.4),
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.ink,
              side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
              shape: const RoundedRectangleBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            ),
            child: const Text('Batal'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showSnack('Pengingat BAP berhasil dikirimkan ke ${a.lecturerName} via WA & Email.', const Color(0xFF16A34A));
            },
            icon: const Icon(Icons.send_outlined, size: 14),
            label: const Text('Kirim Pengingat Sekarang'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              shape: const RoundedRectangleBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMakeupDialog() {
    final course = TextEditingController(text: 'Pemrograman Web');
    final section = TextEditingController(text: 'A');
    final lecturer = TextEditingController(text: 'Dr. Ir. Hendra Gunawan, S.Kom.');
    final originalDate = TextEditingController(text: '2026-11-25');
    final proposedDate = TextEditingController(text: '2026-11-28 13:00 - 15:30');
    final room = TextEditingController(text: 'Lab Komputasi 2');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => BapDialogShell(
          title: 'PENGAJUAN KULIAH PENGGANTI',
          subtitle: 'Jadwalkan sesi kuliah pengganti karena dosen berhalangan atau libur nasional',
          accentColor: const Color(0xFF0369A1),
          maxWidth: 560,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: BapTextField(
                      controller: course,
                      label: 'MATA KULIAH',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 4,
                    child: BapTextField(
                      controller: section,
                      label: 'KELAS',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              BapTextField(
                controller: lecturer,
                label: 'DOSEN PENGAMPU',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: BapTextField(
                      controller: originalDate,
                      label: 'TANGGAL KULIAH KOSONG',
                      hintText: 'YYYY-MM-DD',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: BapTextField(
                      controller: proposedDate,
                      label: 'JADWAL PENGGANTI',
                      hintText: 'YYYY-MM-DD HH:MM',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              BapTextField(
                controller: room,
                label: 'RUANG / LAB DIUSULKAN',
              ),
            ],
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.ink,
                side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                shape: const RoundedRectangleBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text('Batal'),
            ),
            FilledButton.icon(
              onPressed: () {
                final newReq = MakeupClassRequest(
                  id: 'MK-${DateTime.now().millisecondsSinceEpoch}',
                  courseName: course.text.trim(),
                  classSection: section.text.trim(),
                  lecturerName: lecturer.text.trim(),
                  originalDate: originalDate.text.trim(),
                  proposedDate: proposedDate.text.trim(),
                  room: room.text.trim(),
                  isApproved: true,
                );
                widget.onMakeupUpdated([...widget.makeupRequests, newReq]);
                Navigator.pop(context);
                _showSnack('Kuliah pengganti untuk ${newReq.courseName} langsung disetujui.', const Color(0xFF16A34A));
              },
              icon: const Icon(Icons.check, size: 14),
              label: const Text('Simpan & Jadwalkan'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0369A1),
                shape: const RoundedRectangleBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }
}
