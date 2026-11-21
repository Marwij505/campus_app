// Panel Manajemen Ujian & Periode Nilai — BAP Dashboard.

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../data/bap_models.dart';
import 'bap_widgets.dart';

class BapExamPanel extends StatefulWidget {
  const BapExamPanel({
    super.key,
    required this.schedules,
    required this.onScheduleUpdated,
  });

  final List<ExamSchedule> schedules;
  final ValueChanged<List<ExamSchedule>> onScheduleUpdated;

  @override
  State<BapExamPanel> createState() => _BapExamPanelState();
}

class _BapExamPanelState extends State<BapExamPanel> {
  String _filter = 'Semua'; // Semua, UTS, UAS

  @override
  Widget build(BuildContext context) {
    final filtered = widget.schedules.where((s) {
      if (_filter == 'UTS') return s.examType == ExamType.uts;
      if (_filter == 'UAS') return s.examType == ExamType.uas;
      return true;
    }).toList();

    final openGradeCount = widget.schedules
        .where((s) => s.gradeInputOpen)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BapPanelHeader(
          icon: Icons.quiz_outlined,
          title: 'MANAJEMEN UJIAN & PERIODE NILAI',
          subtitle:
              '${widget.schedules.length} jadwal ujian · $openGradeCount input nilai terbuka',
          actionLabel: '+ Jadwal Ujian',
          onAction: _showAddExamDialog,
          color: const Color(0xFF0F766E),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: ['Semua', 'UTS', 'UAS'].map((f) {
                final sel = _filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () => setState(() => _filter = f),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: sel ? const Color(0xFF0F766E) : Colors.white,
                        border: Border.all(
                          color: sel
                              ? const Color(0xFF0F766E)
                              : const Color(0xFFCBD5E1),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        f,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: sel ? Colors.white : AppTheme.ink,
                          fontFamily: 'SpaceMono',
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            OutlinedButton.icon(
              onPressed: () {
                if (filtered.isNotEmpty) {
                  _showDpuPreviewDialog(filtered.first);
                } else if (widget.schedules.isNotEmpty) {
                  _showDpuPreviewDialog(widget.schedules.first);
                } else {
                  _showSnack('Belum ada jadwal ujian untuk dicetak.', const Color(0xFFDC2626));
                }
              },
              icon: const Icon(Icons.print_outlined, size: 13),
              label: const Text('Cetak DPU Massal', style: TextStyle(fontSize: 10.5)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F766E),
                side: const BorderSide(color: Color(0xFF0F766E), width: 1.5),
                shape: const RoundedRectangleBorder(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filtered.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) => _buildExamCard(filtered[i]),
        ),
      ],
    );
  }

  Widget _buildExamCard(ExamSchedule s) {
    final capacityPct = s.registeredCount / (s.capacity == 0 ? 1 : s.capacity);
    final isFull = s.registeredCount >= s.capacity && s.capacity > 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tipe ujian badge
          Container(
            width: 56,
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: s.examType == ExamType.uts
                ? const Color(0xFF0369A1)
                : const Color(0xFF0F766E),
            child: Column(
              children: [
                Text(
                  s.typeLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'SpaceMono',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  '${s.registeredCount}/${s.capacity}',
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: Colors.white70,
                    fontFamily: 'SpaceMono',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      color: const Color(0xFFEFF6FF),
                      child: Text(
                        '${s.courseCode} · Kelas ${s.classSection}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D4ED8),
                          fontFamily: 'SpaceMono',
                        ),
                      ),
                    ),
                    if (isFull) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        color: const Color(0xFFDC2626),
                        child: const Text(
                          'PENUH',
                          style: TextStyle(
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
                const SizedBox(height: 4),
                Text(
                  s.courseName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 14,
                  runSpacing: 4,
                  children: [
                    _chip(Icons.calendar_today, s.date),
                    _chip(Icons.access_time, s.time),
                    _chip(Icons.room, s.room),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: capacityPct.clamp(0.0, 1.0),
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isFull ? const Color(0xFFDC2626) : const Color(0xFF0F766E),
                  ),
                  minHeight: 5,
                ),
                const SizedBox(height: 2),
                Text(
                  '${s.registeredCount} dari ${s.capacity} kursi terisi',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.muted,
                    fontFamily: 'SpaceMono',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _showDpuPreviewDialog(s),
                    icon: const Icon(Icons.description_outlined, size: 12),
                    label: const Text('DPU', style: TextStyle(fontSize: 10)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0369A1),
                      side: const BorderSide(color: Color(0xFF0369A1), width: 1.5),
                      shape: const RoundedRectangleBorder(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _showBauPreviewDialog(s),
                    icon: const Icon(Icons.print_outlined, size: 12),
                    label: const Text('BAU', style: TextStyle(fontSize: 10)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F766E),
                      side: const BorderSide(color: Color(0xFF0F766E), width: 1.5),
                      shape: const RoundedRectangleBorder(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Edit Ujian',
                    onPressed: () => _showEditExamDialog(s),
                    icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF0F766E)),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                  s.gradeInputOpen
                      ? FilledButton.icon(
                          onPressed: () {
                            final updated = widget.schedules
                                .map(
                                  (x) => x.id == s.id
                                      ? x.copyWith(gradeInputOpen: false)
                                      : x,
                                )
                                .toList();
                            widget.onScheduleUpdated(updated);
                            _showSnack(
                              'Input nilai dikunci untuk ${s.courseName}.',
                              const Color(0xFFDC2626),
                            );
                          },
                          icon: const Icon(Icons.lock_outline, size: 12),
                          label: const Text(
                            'Kunci Nilai',
                            style: TextStyle(fontSize: 10),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFDC2626),
                            shape: const RoundedRectangleBorder(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                          ),
                        )
                      : FilledButton.icon(
                          onPressed: () {
                            final updated = widget.schedules
                                .map(
                                  (x) => x.id == s.id
                                      ? x.copyWith(gradeInputOpen: true)
                                      : x,
                                )
                                .toList();
                            widget.onScheduleUpdated(updated);
                            _showSnack(
                              'Input nilai dibuka untuk ${s.courseName}.',
                              const Color(0xFF16A34A),
                            );
                          },
                          icon: const Icon(Icons.lock_open_outlined, size: 12),
                          label: const Text(
                            'Buka Nilai',
                            style: TextStyle(fontSize: 10),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            shape: const RoundedRectangleBorder(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                          ),
                        ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 12, color: AppTheme.muted),
      const SizedBox(width: 4),
      Text(text, style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
    ],
  );

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  Future<void> _showAddExamDialog() async {
    final code = TextEditingController();
    final name = TextEditingController();
    final section = TextEditingController(text: 'A');
    final date = TextEditingController(text: '2026-11-30');
    final time = TextEditingController(text: '08:00 – 09:40');
    final room = TextEditingController(text: 'Aula 1');
    final capacity = TextEditingController(text: '40');
    var type = ExamType.uts;

    final result = await showDialog<ExamSchedule>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => BapDialogShell(
          title: 'TAMBAH JADWAL UJIAN BARU',
          subtitle: 'Alokasikan waktu, ruang, dan kuota kursi peserta ujian',
          accentColor: const Color(0xFF0F766E),
          maxWidth: 580,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: BapTextField(
                      controller: code,
                      label: 'KODE MATA KULIAH',
                      hintText: 'Misal: TI201',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 6,
                    child: BapTextField(
                      controller: name,
                      label: 'NAMA MATA KULIAH',
                      hintText: 'Misal: Struktur Data',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: BapDropdownField<ExamType>(
                      label: 'JENIS UJIAN',
                      value: type,
                      items: const [
                        DropdownMenuItem(value: ExamType.uts, child: Text('Ujian Tengah Semester (UTS)')),
                        DropdownMenuItem(value: ExamType.uas, child: Text('Ujian Akhir Semester (UAS)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => type = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 5,
                    child: BapTextField(
                      controller: section,
                      label: 'KELAS PARALEL',
                      hintText: 'A / B / C',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: BapTextField(
                      controller: date,
                      label: 'TANGGAL UJIAN',
                      hintText: 'YYYY-MM-DD',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: BapTextField(
                      controller: time,
                      label: 'WAKTU UJIAN',
                      hintText: '08:00 – 09:40',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: BapTextField(
                      controller: room,
                      label: 'RUANG UJIAN / LAB',
                      hintText: 'Misal: R.401 / Aula Utama',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 4,
                    child: BapTextField(
                      controller: capacity,
                      label: 'KAPASITAS KURSI',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
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
                if (code.text.trim().isEmpty || name.text.trim().isEmpty) {
                  _showSnack('Kode dan nama mata kuliah wajib diisi.', const Color(0xFFDC2626));
                  return;
                }
                Navigator.pop(
                  context,
                  ExamSchedule(
                    id: 'EX-${DateTime.now().millisecondsSinceEpoch}',
                    courseCode: code.text.trim(),
                    courseName: name.text.trim(),
                    classSection: section.text.trim(),
                    examType: type,
                    date: date.text.trim(),
                    time: time.text.trim(),
                    room: room.text.trim(),
                    capacity: int.tryParse(capacity.text) ?? 40,
                    registeredCount: 0,
                  ),
                );
              },
              icon: const Icon(Icons.check, size: 14),
              label: const Text('Simpan Jadwal Ujian'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                shape: const RoundedRectangleBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
            ),
          ],
        ),
      ),
    );
    code.dispose();
    name.dispose();
    section.dispose();
    date.dispose();
    time.dispose();
    room.dispose();
    capacity.dispose();
    if (result != null) {
      widget.onScheduleUpdated([...widget.schedules, result]);
      _showSnack(
        'Jadwal ujian ${result.courseCode} berhasil ditambahkan.',
        const Color(0xFF16A34A),
      );
    }
  }

  Future<void> _showEditExamDialog(ExamSchedule s) async {
    final code = TextEditingController(text: s.courseCode);
    final name = TextEditingController(text: s.courseName);
    final section = TextEditingController(text: s.classSection);
    final date = TextEditingController(text: s.date);
    final time = TextEditingController(text: s.time);
    final room = TextEditingController(text: s.room);
    final capacity = TextEditingController(text: '${s.capacity}');
    var type = s.examType;

    final result = await showDialog<ExamSchedule>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => BapDialogShell(
          title: 'EDIT JADWAL UJIAN: ${s.courseCode}',
          subtitle: 'Perbarui ruang, waktu ujian, atau kapasitas peserta',
          accentColor: const Color(0xFF0F766E),
          maxWidth: 580,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: BapTextField(
                      controller: code,
                      label: 'KODE MATA KULIAH',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 6,
                    child: BapTextField(
                      controller: name,
                      label: 'NAMA MATA KULIAH',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: BapDropdownField<ExamType>(
                      label: 'JENIS UJIAN',
                      value: type,
                      items: const [
                        DropdownMenuItem(value: ExamType.uts, child: Text('Ujian Tengah Semester (UTS)')),
                        DropdownMenuItem(value: ExamType.uas, child: Text('Ujian Akhir Semester (UAS)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => type = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 5,
                    child: BapTextField(
                      controller: section,
                      label: 'KELAS PARALEL',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: BapTextField(
                      controller: date,
                      label: 'TANGGAL UJIAN',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: BapTextField(
                      controller: time,
                      label: 'WAKTU UJIAN',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: BapTextField(
                      controller: room,
                      label: 'RUANG UJIAN / LAB',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 4,
                    child: BapTextField(
                      controller: capacity,
                      label: 'KAPASITAS KURSI',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
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
                Navigator.pop(
                  context,
                  s.copyWith(
                    courseCode: code.text.trim(),
                    courseName: name.text.trim(),
                    classSection: section.text.trim(),
                    examType: type,
                    date: date.text.trim(),
                    time: time.text.trim(),
                    room: room.text.trim(),
                    capacity: int.tryParse(capacity.text) ?? s.capacity,
                  ),
                );
              },
              icon: const Icon(Icons.check, size: 14),
              label: const Text('Simpan Perubahan'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                shape: const RoundedRectangleBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
            ),
          ],
        ),
      ),
    );
    code.dispose();
    name.dispose();
    section.dispose();
    date.dispose();
    time.dispose();
    room.dispose();
    capacity.dispose();
    if (result != null) {
      widget.onScheduleUpdated(
        widget.schedules.map((x) => x.id == result.id ? result : x).toList(),
      );
      _showSnack(
        'Jadwal ujian ${result.courseCode} berhasil diperbarui.',
        const Color(0xFF16A34A),
      );
    }
  }

  void _showDpuPreviewDialog(ExamSchedule s) {
    final dummyStudents = [
      {'nim': '20230801001', 'name': 'Aditya Pratama', 'seat': '01'},
      {'nim': '20230801004', 'name': 'Bella Clarissa', 'seat': '02'},
      {'nim': '20230801012', 'name': 'Dina Kartika', 'seat': '03'},
      {'nim': '20230801019', 'name': 'Farhan Ramadhan', 'seat': '04'},
      {'nim': '20230801025', 'name': 'Gita Nurulita', 'seat': '05'},
      {'nim': '20230801033', 'name': 'Hendra Wijaya', 'seat': '06'},
      {'nim': '20230801041', 'name': 'Indra Permana', 'seat': '07'},
      {'nim': '20230801050', 'name': 'Jessica Olivia', 'seat': '08'},
    ];

    showDialog(
      context: context,
      builder: (context) => BapDialogShell(
        title: 'DAFTAR PESERTA UJIAN (DPU)',
        subtitle: 'Format resmi cetak daftar presensi peserta ujian semester',
        accentColor: const Color(0xFF0369A1),
        maxWidth: 640,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kop Surat Mini
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        color: const Color(0xFF0F4C81),
                        child: const Icon(Icons.school, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'UNIVERSITAS ESA UNGGUL · FAKULTAS ILMU KOMPUTER',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'SpaceMono',
                                color: Color(0xFF0F4C81),
                              ),
                            ),
                            Text(
                              'BIRO ADMINISTRASI PERKULIAHAN (BAP) · T.A. 2026/2027 GANJIL',
                              style: TextStyle(
                                fontSize: 9.5,
                                color: AppTheme.muted,
                                fontFamily: 'SpaceMono',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        color: const Color(0xFF0369A1),
                        child: Text(
                          s.typeLabel,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'SpaceMono',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 18, color: Color(0xFFCBD5E1)),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Mata Kuliah: ${s.courseName} (${s.courseCode})',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.ink)),
                            Text('Kelas: ${s.classSection} · Ruang: ${s.room}',
                                style: const TextStyle(fontSize: 10.5, color: AppTheme.muted)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Tanggal: ${s.date}', style: const TextStyle(fontSize: 10.5, fontFamily: 'SpaceMono')),
                          Text('Waktu: ${s.time}', style: const TextStyle(fontSize: 10.5, fontFamily: 'SpaceMono')),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'DAFTAR PESERTA UJIAN TERDAFTAR (${s.registeredCount} Mahasiswa)',
              style: AppTheme.pixel(6.5, color: AppTheme.ink),
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 480),
                child: Container(
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
                            SizedBox(width: 32, child: Text('No', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'SpaceMono'))),
                            SizedBox(width: 100, child: Text('NIM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'SpaceMono'))),
                            Expanded(child: Text('Nama Mahasiswa', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                            SizedBox(width: 50, child: Text('Kursi', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'SpaceMono'), textAlign: TextAlign.center)),
                            SizedBox(width: 70, child: Text('Tanda Tangan', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                          ],
                        ),
                      ),
                      ...dummyStudents.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final m = entry.value;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: idx.isEven ? Colors.white : const Color(0xFFF8FAFC),
                            border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                          ),
                          child: Row(
                            children: [
                              SizedBox(width: 32, child: Text('${idx + 1}', style: const TextStyle(fontSize: 10, fontFamily: 'SpaceMono'))),
                              SizedBox(width: 100, child: Text(m['nim']!, style: const TextStyle(fontSize: 10, fontFamily: 'SpaceMono', color: Color(0xFF0369A1)))),
                              Expanded(child: Text(m['name']!, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600))),
                              SizedBox(width: 50, child: Text(m['seat']!, style: const TextStyle(fontSize: 10, fontFamily: 'SpaceMono', fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                              const SizedBox(width: 70, child: Text('.................', style: TextStyle(fontSize: 10, color: Color(0xFFCBD5E1)), textAlign: TextAlign.center)),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
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
              _showSnack('DPU ${s.courseCode} siap dicetak / diunduh sebagai PDF.', const Color(0xFF0369A1));
            },
            icon: const Icon(Icons.print_outlined, size: 14),
            label: const Text('Cetak / Unduh PDF'),
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

  void _showBauPreviewDialog(ExamSchedule s) {
    showDialog(
      context: context,
      builder: (context) => BapDialogShell(
        title: 'BERITA ACARA UJIAN (BAU)',
        subtitle: 'Dokumen berita acara pelaksanaan ujian dan laporan pengawas',
        accentColor: const Color(0xFF0F766E),
        maxWidth: 620,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDFA),
                border: Border.all(color: const Color(0xFF99F6E4), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('NO. DOKUMEN: BAU/${s.examType.name.toUpperCase()}/2026/${s.courseCode}',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'SpaceMono', color: Color(0xFF0F766E))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        color: const Color(0xFF0F766E),
                        child: Text(s.typeLabel, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'SpaceMono')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(s.courseName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.ink)),
                  Text('Kelas: ${s.classSection} · Tanggal: ${s.date} · Waktu: ${s.time} · Ruang: ${s.room}',
                      style: const TextStyle(fontSize: 10.5, color: AppTheme.muted)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            BapSectionCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('RINGKASAN KEHADIRAN UJIAN', style: AppTheme.pixel(6.5, color: AppTheme.ink)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _bauStat('Peserta Terdaftar', '${s.registeredCount} Mhs', const Color(0xFF0369A1)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _bauStat('Hadir Ujian', '${(s.registeredCount * 0.95).round()} Mhs', const Color(0xFF16A34A)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _bauStat('Tidak Hadir', '${(s.registeredCount * 0.05).round()} Mhs', const Color(0xFFDC2626)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                color: Colors.white,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Catatan Pelaksanaan Ujian:', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.ink)),
                  SizedBox(height: 4),
                  Text('1. Ujian dimulai tepat waktu dan tertib.', style: TextStyle(fontSize: 10.5, color: AppTheme.muted)),
                  Text('2. Berkas lembar soal dan jawaban tercetak lengkap sejumlah kursi.', style: TextStyle(fontSize: 10.5, color: AppTheme.muted)),
                  Text('3. Tidak ditemukan pelanggaran atau kecurangan selama ujian berlangsung.', style: TextStyle(fontSize: 10.5, color: AppTheme.muted)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.spaceAround,
              spacing: 16,
              runSpacing: 16,
              children: [
                _signatureBox('Pengawas 1 (Dosen Pengampu)', 'Dr. Ir. Hendra Gunawan, S.Kom.'),
                _signatureBox('Pengawas 2 (Staf BAP)', 'Staf Administrasi Perkuliahan'),
              ],
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
              _showSnack('Berita Acara Ujian ${s.courseCode} berhasil dicetak.', const Color(0xFF0F766E));
            },
            icon: const Icon(Icons.print_outlined, size: 14),
            label: const Text('Cetak Dokumen BAU'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0F766E),
              shape: const RoundedRectangleBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bauStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 9, color: AppTheme.muted)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color, fontFamily: 'SpaceMono')),
        ],
      ),
    );
  }

  Widget _signatureBox(String role, String name) {
    return Column(
      children: [
        Text(role, style: const TextStyle(fontSize: 10, color: AppTheme.muted)),
        const SizedBox(height: 36),
        Text(name, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, fontFamily: 'SpaceMono')),
        Container(width: 140, height: 1, color: AppTheme.ink),
      ],
    );
  }
}
