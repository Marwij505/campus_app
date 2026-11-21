// Panel Status Akademik Mahasiswa — BAP Dashboard.

import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../data/bap_models.dart';
import 'bap_widgets.dart';

class BapStudentStatusPanel extends StatefulWidget {
  const BapStudentStatusPanel({
    super.key,
    required this.students,
    this.onStudentsUpdated,
  });

  final List<StudentAcademicStatus> students;
  final ValueChanged<List<StudentAcademicStatus>>? onStudentsUpdated;

  @override
  State<BapStudentStatusPanel> createState() => _BapStudentStatusPanelState();
}

class _BapStudentStatusPanelState extends State<BapStudentStatusPanel> {
  String _filter = 'Semua';
  String _search = '';

  static const _statusFilters = [
    'Semua', 'Aktif', 'Cuti Akademik', 'Non-Aktif', 'Pindah Prodi', 'Lulus / Yudisium',
  ];

  Color _colorOf(AcademicStatusType s) => switch (s) {
    AcademicStatusType.active => const Color(0xFF16A34A),
    AcademicStatusType.leave => const Color(0xFFD97706),
    AcademicStatusType.inactive => const Color(0xFFDC2626),
    AcademicStatusType.transfer => const Color(0xFF7C3AED),
    AcademicStatusType.resigned => const Color(0xFF6B7280),
    AcademicStatusType.graduated => const Color(0xFF0369A1),
  };

  @override
  Widget build(BuildContext context) {
    final filtered = widget.students.where((s) {
      final matchFilter = _filter == 'Semua' || s.statusLabel == _filter;
      final q = _search.toLowerCase();
      final matchSearch = q.isEmpty || s.name.toLowerCase().contains(q) || s.nim.contains(q);
      return matchFilter && matchSearch;
    }).toList();

    // Hitung distribusi status
    final counts = <AcademicStatusType, int>{};
    for (final s in widget.students) {
      counts[s.status] = (counts[s.status] ?? 0) + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BapPanelHeader(
          icon: Icons.manage_accounts_outlined,
          title: 'PENGELOLAAN STATUS AKADEMIK MAHASISWA',
          subtitle: '${widget.students.length} mahasiswa terdata · semester ganjil 2026/2027',
          color: const Color(0xFF1E40AF),
          actionLabel: '+ Registrasi Status',
          onAction: _showAddStudentStatusDialog,
        ),
        const SizedBox(height: 12),

        // Distribusi status ringkas
        BapSectionCard(
          child: Wrap(
            spacing: 20,
            runSpacing: 10,
            children: [
              BapMiniStat(
                value: '${counts[AcademicStatusType.active] ?? 0}',
                label: 'Aktif',
                color: const Color(0xFF16A34A),
              ),
              BapMiniStat(
                value: '${counts[AcademicStatusType.leave] ?? 0}',
                label: 'Cuti',
                color: const Color(0xFFD97706),
              ),
              BapMiniStat(
                value: '${counts[AcademicStatusType.inactive] ?? 0}',
                label: 'Non-Aktif',
                color: const Color(0xFFDC2626),
              ),
              BapMiniStat(
                value: '${counts[AcademicStatusType.transfer] ?? 0}',
                label: 'Pindah',
                color: const Color(0xFF7C3AED),
              ),
              BapMiniStat(
                value: '${counts[AcademicStatusType.graduated] ?? 0}',
                label: 'Lulus',
                color: const Color(0xFF0369A1),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Search & filter
        Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 240,
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: const InputDecoration(
                  hintText: 'Cari nama atau NIM...',
                  prefixIcon: Icon(Icons.search, size: 16),
                ),
                style: const TextStyle(fontSize: 11, fontFamily: 'SpaceMono'),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _statusFilters.map((f) {
                  final sel = _filter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      onTap: () => setState(() => _filter = f),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: sel ? const Color(0xFF1E40AF) : Colors.white,
                          border: Border.all(color: sel ? const Color(0xFF1E40AF) : const Color(0xFFCBD5E1), width: 1.5),
                        ),
                        child: Text(f, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: sel ? Colors.white : AppTheme.ink, fontFamily: 'SpaceMono')),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (filtered.isEmpty)
          const BapSectionCard(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Tidak ada mahasiswa yang cocok dengan filter.', style: TextStyle(color: AppTheme.muted)),
              ),
            ),
          )
        else
          ...filtered.map((s) => _buildStudentCard(s)),
      ],
    );
  }

  Widget _buildStudentCard(StudentAcademicStatus s) {
    final color = _colorOf(s.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: const [BoxShadow(color: Color(0x0E000000), offset: Offset(0, 2), blurRadius: 0)],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.ink)),
                    const SizedBox(height: 2),
                    Text('NIM: ${s.nim} · ${s.major} · Angkatan ${s.entryYear} · Semester ${s.currentSemester}',
                        style: const TextStyle(fontSize: 10.5, color: AppTheme.muted)),
                  ],
                ),
              ),
              BapStatusBadge(label: s.statusLabel, color: color),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _infoChip('IPK: ${s.gpa.toStringAsFixed(2)}', const Color(0xFF1E40AF)),
              const SizedBox(width: 12),
              _infoChip('${s.passedCredits} SKS Lulus', const Color(0xFF0F766E)),
            ],
          ),
          if (s.note != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              color: const Color(0xFFF8FAFC),
              child: Text(s.note!, style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppTheme.muted, fontFamily: 'SpaceMono')),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 6,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showChangeStatusDialog(s),
                icon: const Icon(Icons.edit_outlined, size: 13),
                label: const Text('Ubah Status', style: TextStyle(fontSize: 10.5)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1E40AF),
                  side: const BorderSide(color: Color(0xFF1E40AF), width: 1.5),
                  shape: const RoundedRectangleBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _showTranscriptDialog(s),
                icon: const Icon(Icons.description_outlined, size: 13),
                label: const Text('Transkrip & KHS', style: TextStyle(fontSize: 10.5)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0369A1),
                  side: const BorderSide(color: Color(0xFF0369A1), width: 1.5),
                  shape: const RoundedRectangleBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    color: color.withValues(alpha: 0.1),
    child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color, fontFamily: 'SpaceMono')),
  );

  void _showChangeStatusDialog(StudentAcademicStatus s) {
    var selectedStatus = s.status;
    final skController = TextEditingController(text: 'SK-DEK/AKAD/2026/${s.nim}');
    final noteController = TextEditingController(text: s.note ?? '');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => BapDialogShell(
          title: 'UBAH STATUS AKADEMIK MAHASISWA',
          subtitle: 'Perbarui status keaktifan semester mahasiswa: ${s.name} (${s.nim})',
          accentColor: const Color(0xFF1E40AF),
          maxWidth: 540,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 18, color: Color(0xFF1E40AF)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Mahasiswa: ${s.name} · NIM: ${s.nim} · Semester ${s.currentSemester}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              BapDropdownField<AcademicStatusType>(
                label: 'STATUS KEAKTIFAN BARU',
                value: selectedStatus,
                items: const [
                  DropdownMenuItem(value: AcademicStatusType.active, child: Text('Aktif (Mengikuti Kuliah)')),
                  DropdownMenuItem(value: AcademicStatusType.leave, child: Text('Cuti Akademik (Izin Resmi)')),
                  DropdownMenuItem(value: AcademicStatusType.inactive, child: Text('Non-Aktif (Alpa / Belum Registrasi)')),
                  DropdownMenuItem(value: AcademicStatusType.transfer, child: Text('Pindah Program Studi / Kampus')),
                  DropdownMenuItem(value: AcademicStatusType.resigned, child: Text('Mengundurkan Diri')),
                  DropdownMenuItem(value: AcademicStatusType.graduated, child: Text('Lulus / Yudisium')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedStatus = val);
                },
              ),
              const SizedBox(height: 12),
              BapTextField(
                controller: skController,
                label: 'NOMOR SURAT KEPUTUSAN (SK)',
                hintText: 'Misal: SK-DEK/AKAD/2026/044',
              ),
              const SizedBox(height: 12),
              BapTextField(
                controller: noteController,
                label: 'CATATAN / KETERANGAN RESMI',
                hintText: 'Misal: Cuti disetujui karena alasan kesehatan / pertukaran mahasiswa',
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
                final updatedStudent = s.copyWith(
                  status: selectedStatus,
                  note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
                );
                final updatedList = widget.students.map((x) => x.nim == s.nim ? updatedStudent : x).toList();
                widget.onStudentsUpdated?.call(updatedList);
                Navigator.pop(context);
                _showSnack('Status akademik ${s.name} berhasil diperbarui.', const Color(0xFF16A34A));
              },
              icon: const Icon(Icons.check, size: 14),
              label: const Text('Simpan Status'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1E40AF),
                shape: const RoundedRectangleBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTranscriptDialog(StudentAcademicStatus s) {
    final sampleCourses = [
      {'code': 'TI101', 'name': 'Pengantar Ilmu Komputer', 'sks': 3, 'grade': 'A', 'score': 4.0},
      {'code': 'TI102', 'name': 'Algoritma & Pemrograman', 'sks': 4, 'grade': 'A', 'score': 4.0},
      {'code': 'TI103', 'name': 'Matematika Diskrit', 'sks': 3, 'grade': 'B+', 'score': 3.5},
      {'code': 'TI201', 'name': 'Struktur Data & Analisis', 'sks': 3, 'grade': 'A', 'score': 4.0},
      {'code': 'TI202', 'name': 'Basis Data Relasional', 'sks': 3, 'grade': 'B', 'score': 3.0},
      {'code': 'TI301', 'name': 'Pemrograman Berorientasi Objek', 'sks': 3, 'grade': 'A', 'score': 4.0},
    ];

    showDialog(
      context: context,
      builder: (context) => BapDialogShell(
        title: 'TRANSKRIP AKADEMIK SEMENTARA',
        subtitle: 'Rekapitulasi Indeks Prestasi Kumulatif dan beban SKS mahasiswa',
        accentColor: const Color(0xFF0369A1),
        maxWidth: 640,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.ink)),
                        Text('NIM: ${s.nim} · ${s.major}', style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
                        Text('Angkatan: ${s.entryYear} · Semester: ${s.currentSemester}', style: const TextStyle(fontSize: 10.5, color: AppTheme.muted)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('IPK: ${s.gpa.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF16A34A), fontFamily: 'SpaceMono')),
                      Text('${s.passedCredits} SKS Telah Ditempuh',
                          style: const TextStyle(fontSize: 10, color: AppTheme.muted, fontFamily: 'SpaceMono')),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text('DAFTAR MATA KULIAH LULUS & NILAI', style: AppTheme.pixel(6.5, color: AppTheme.ink)),
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
                        SizedBox(width: 70, child: Text('Kode', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'SpaceMono'))),
                        Expanded(child: Text('Mata Kuliah', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                        SizedBox(width: 40, child: Text('SKS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'SpaceMono'), textAlign: TextAlign.center)),
                        SizedBox(width: 45, child: Text('Nilai', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'SpaceMono'), textAlign: TextAlign.center)),
                        SizedBox(width: 45, child: Text('Bobot', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'SpaceMono'), textAlign: TextAlign.center)),
                      ],
                    ),
                  ),
                  ...sampleCourses.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final c = entry.value;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: idx.isEven ? Colors.white : const Color(0xFFF8FAFC),
                        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                      child: Row(
                        children: [
                          SizedBox(width: 70, child: Text(c['code'] as String, style: const TextStyle(fontSize: 10, fontFamily: 'SpaceMono', color: Color(0xFF1E40AF)))),
                          Expanded(child: Text(c['name'] as String, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600))),
                          SizedBox(width: 40, child: Text('${c['sks']}', style: const TextStyle(fontSize: 10, fontFamily: 'SpaceMono'), textAlign: TextAlign.center)),
                          SizedBox(width: 45, child: Text(c['grade'] as String, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)), textAlign: TextAlign.center)),
                          SizedBox(width: 45, child: Text('${c['score']}', style: const TextStyle(fontSize: 10, fontFamily: 'SpaceMono'), textAlign: TextAlign.center)),
                        ],
                      ),
                    );
                  }),
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
              _showSnack('Transkrip resmi ${s.name} berhasil diunduh sebagai PDF.', const Color(0xFF0369A1));
            },
            icon: const Icon(Icons.download_outlined, size: 14),
            label: const Text('Unduh Transkrip PDF'),
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

  void _showAddStudentStatusDialog() {
    final nim = TextEditingController();
    final name = TextEditingController();
    final major = TextEditingController(text: 'Teknik Informatika');
    final entryYear = TextEditingController(text: '2026');
    final semester = TextEditingController(text: '1');
    var status = AcademicStatusType.active;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => BapDialogShell(
          title: 'REGISTRASI STATUS MAHASISWA BARU',
          subtitle: 'Tambahkan data mahasiswa atau mahasiswa pindahan ke basis data akademik',
          accentColor: const Color(0xFF1E40AF),
          maxWidth: 560,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: BapTextField(
                      controller: nim,
                      label: 'NIM MAHASISWA',
                      hintText: '20260801...',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 6,
                    child: BapTextField(
                      controller: name,
                      label: 'NAMA LENGKAP',
                      hintText: 'Nama mahasiswa...',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              BapTextField(
                controller: major,
                label: 'PROGRAM STUDI',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: BapTextField(
                      controller: entryYear,
                      label: 'TAHUN MASUK',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: BapTextField(
                      controller: semester,
                      label: 'SEMESTER AKTIF',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              BapDropdownField<AcademicStatusType>(
                label: 'STATUS AWAL',
                value: status,
                items: const [
                  DropdownMenuItem(value: AcademicStatusType.active, child: Text('Aktif')),
                  DropdownMenuItem(value: AcademicStatusType.transfer, child: Text('Mahasiswa Pindahan')),
                  DropdownMenuItem(value: AcademicStatusType.leave, child: Text('Cuti Akademik')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => status = val);
                },
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
                if (nim.text.trim().isEmpty || name.text.trim().isEmpty) {
                  _showSnack('NIM dan nama mahasiswa wajib diisi.', const Color(0xFFDC2626));
                  return;
                }
                final newStudent = StudentAcademicStatus(
                  nim: nim.text.trim(),
                  name: name.text.trim(),
                  major: major.text.trim(),
                  entryYear: int.tryParse(entryYear.text) ?? 2026,
                  currentSemester: int.tryParse(semester.text) ?? 1,
                  status: status,
                  passedCredits: 0,
                  gpa: 0.0,
                );
                widget.onStudentsUpdated?.call([...widget.students, newStudent]);
                Navigator.pop(context);
                _showSnack('Mahasiswa ${newStudent.name} berhasil ditambahkan.', const Color(0xFF16A34A));
              },
              icon: const Icon(Icons.check, size: 14),
              label: const Text('Daftarkan Mahasiswa'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1E40AF),
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
