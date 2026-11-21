// Panel Kurikulum & Mata Kuliah — BAP Dashboard.
// Menampilkan dan mengelola data master mata kuliah, SKS, prasyarat.

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../data/bap_models.dart';
import 'bap_widgets.dart';

class BapCurriculumPanel extends StatefulWidget {
  const BapCurriculumPanel({
    super.key,
    required this.courses,
    this.onCoursesUpdated,
  });
  final List<Coursemaster> courses;
  final ValueChanged<List<Coursemaster>>? onCoursesUpdated;

  @override
  State<BapCurriculumPanel> createState() => _BapCurriculumPanelState();
}

class _BapCurriculumPanelState extends State<BapCurriculumPanel> {
  String _filterProdi = 'Semua';
  String _search = '';
  late List<Coursemaster> _courses;

  @override
  void initState() {
    super.initState();
    _courses = List.from(widget.courses);
  }

  @override
  void didUpdateWidget(covariant BapCurriculumPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.courses != widget.courses) {
      _courses = List.from(widget.courses);
    }
  }

  void _notifyUpdated() {
    widget.onCoursesUpdated?.call(_courses);
  }

  @override
  Widget build(BuildContext context) {
    final prodiList = [
      'Semua',
      ..._courses.map((c) => c.programStudy).toSet().toList()..sort(),
    ];
    final filtered = _courses.where((c) {
      final matchProdi =
          _filterProdi == 'Semua' || c.programStudy == _filterProdi;
      final q = _search.toLowerCase();
      final matchSearch =
          q.isEmpty ||
          c.name.toLowerCase().contains(q) ||
          c.code.toLowerCase().contains(q);
      return matchProdi && matchSearch;
    }).toList()..sort((a, b) => a.semester.compareTo(b.semester));

    final totalSks = filtered.fold<int>(0, (s, c) => s + c.credits);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BapPanelHeader(
          icon: Icons.menu_book_outlined,
          title: 'MANAJEMEN KURIKULUM & MATA KULIAH',
          subtitle: '${filtered.length} mata kuliah · Total $totalSks SKS',
          actionLabel: '+ Tambah MK',
          onAction: () => _showAddCourseDialog(),
          color: const Color(0xFF0F4C81),
        ),
        const SizedBox(height: 12),
        // Filter & search row
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
                  hintText: 'Cari kode atau nama MK...',
                  prefixIcon: Icon(Icons.search, size: 16),
                ),
                style: const TextStyle(fontSize: 11, fontFamily: 'SpaceMono'),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: prodiList.map((p) {
                  final sel = _filterProdi == p;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      onTap: () => setState(() => _filterProdi = p),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: sel ? const Color(0xFF0F4C81) : Colors.white,
                          border: Border.all(
                            color: sel
                                ? const Color(0xFF0F4C81)
                                : const Color(0xFFCBD5E1),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          p == 'Semua' ? 'Semua Prodi' : p,
                          style: TextStyle(
                            fontSize: 10,
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
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final tableWidth =
                constraints.maxWidth < 620 ? 620.0 : constraints.maxWidth;
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth,
                  child: Column(
                    children: [
                      // Table header
                      Container(
                        color: const Color(0xFF0F4C81),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        child: const Row(
                          children: [
                            SizedBox(
                              width: 76,
                              child: Text(
                                'KODE',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'SpaceMono',
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'NAMA MATA KULIAH',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'SpaceMono',
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 46,
                              child: Text(
                                'SKS',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'SpaceMono',
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(
                              width: 54,
                              child: Text(
                                'SMT',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'SpaceMono',
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(
                              width: 76,
                              child: Text(
                                'JENIS',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'SpaceMono',
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(
                              width: 76,
                              child: Text(
                                'AKSI',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'SpaceMono',
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filtered.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        itemBuilder: (ctx, i) => _buildCourseRow(filtered[i]),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCourseRow(Coursemaster c) {
    return Container(
      color: c.type == 'Pilihan' ? const Color(0xFFFFFBEB) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            child: Text(
              c.code,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F4C81),
                fontFamily: 'SpaceMono',
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.ink,
                  ),
                ),
                if (c.prerequisite != null)
                  Text(
                    'Prasyarat: ${c.prerequisite}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.muted,
                      fontFamily: 'SpaceMono',
                    ),
                  ),
                Text(
                  c.programStudy,
                  style: const TextStyle(fontSize: 10, color: AppTheme.muted),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 46,
            child: Text(
              '${c.credits}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.ink,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 54,
            child: Text(
              'Smt ${c.semester}',
              style: const TextStyle(fontSize: 11, color: AppTheme.muted),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 76,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                color: c.type == 'Pilihan'
                    ? const Color(0xFFFEF3C7)
                    : const Color(0xFFEFF6FF),
                child: Text(
                  c.type,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: c.type == 'Pilihan'
                        ? const Color(0xFFB45309)
                        : const Color(0xFF1D4ED8),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 76,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  color: const Color(0xFF0F4C81),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                  tooltip: 'Edit Mata Kuliah',
                  onPressed: () => _showEditCourseDialog(c),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 16),
                  color: const Color(0xFFDC2626),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                  tooltip: 'Hapus Mata Kuliah',
                  onPressed: () => _showDeleteCourseDialog(c),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditCourseDialog(Coursemaster course) async {
    final code = TextEditingController(text: course.code);
    final name = TextEditingController(text: course.name);
    final credits = TextEditingController(text: '${course.credits}');
    final semester = TextEditingController(text: '${course.semester}');
    final prereq = TextEditingController(text: course.prerequisite ?? '');
    var prodi = course.programStudy;
    var type = course.type;

    final updated = await showDialog<Coursemaster>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => BapDialogShell(
          title: 'EDIT MATA KULIAH',
          subtitle: '${course.code} - ${course.name}',
          icon: Icons.edit_note,
          headerColor: const Color(0xFF0F4C81),
          maxWidth: 500,
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.ink,
                side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                shape: const RoundedRectangleBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              child: const Text('Batal', style: TextStyle(fontFamily: 'SpaceMono')),
            ),
            const SizedBox(width: 10),
            FilledButton.icon(
              onPressed: () {
                if (code.text.trim().isEmpty || name.text.trim().isEmpty) {
                  _showSnackBar('Kode dan nama mata kuliah wajib diisi.', const Color(0xFFDC2626));
                  return;
                }
                Navigator.pop(
                  context,
                  Coursemaster(
                    code: code.text.trim().toUpperCase(),
                    name: name.text.trim(),
                    credits: int.tryParse(credits.text.trim()) ?? 3,
                    semester: int.tryParse(semester.text.trim()) ?? 1,
                    programStudy: prodi,
                    prerequisite: prereq.text.trim().isEmpty ? null : prereq.text.trim().toUpperCase(),
                    type: type,
                  ),
                );
              },
              icon: const Icon(Icons.check, size: 14),
              label: const Text('Simpan Perubahan', style: TextStyle(fontFamily: 'SpaceMono', fontSize: 11)),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0F4C81),
                shape: const RoundedRectangleBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: BapTextField(
                      label: 'Kode MK',
                      controller: code,
                      hint: 'Misal: TI201',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: BapDropdownField<String>(
                      label: 'Program Studi',
                      value: prodi,
                      items: const [
                        DropdownMenuItem(value: 'Teknik Informatika', child: Text('Teknik Informatika')),
                        DropdownMenuItem(value: 'Sistem Informasi', child: Text('Sistem Informasi')),
                      ],
                      onChanged: (v) => setDialogState(() => prodi = v ?? prodi),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              BapTextField(
                label: 'Nama Mata Kuliah',
                controller: name,
                hint: 'Nama lengkap mata kuliah',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: BapTextField(
                      label: 'Beban SKS',
                      controller: credits,
                      numeric: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: BapTextField(
                      label: 'Semester Penempatan',
                      controller: semester,
                      numeric: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: BapDropdownField<String>(
                      label: 'Sifat MK',
                      value: type,
                      items: const [
                        DropdownMenuItem(value: 'Wajib', child: Text('Wajib')),
                        DropdownMenuItem(value: 'Pilihan', child: Text('Pilihan')),
                      ],
                      onChanged: (v) => setDialogState(() => type = v ?? type),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              BapTextField(
                label: 'Mata Kuliah Prasyarat (Opsional)',
                controller: prereq,
                hint: 'Kode MK prasyarat, contoh: TI101',
              ),
            ],
          ),
        ),
      ),
    );

    code.dispose();
    name.dispose();
    credits.dispose();
    semester.dispose();
    prereq.dispose();

    if (updated != null) {
      setState(() {
        final index = _courses.indexWhere((item) => item.code == course.code);
        if (index != -1) {
          _courses[index] = updated;
        }
      });
      _notifyUpdated();
      _showSnackBar('Mata kuliah ${updated.code} berhasil diperbarui.', const Color(0xFF16A34A));
    }
  }

  Future<void> _showAddCourseDialog() async {
    final code = TextEditingController();
    final name = TextEditingController();
    final credits = TextEditingController(text: '3');
    final semester = TextEditingController(text: '1');
    final prereq = TextEditingController();
    var prodi = 'Teknik Informatika';
    var type = 'Wajib';

    final created = await showDialog<Coursemaster>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => BapDialogShell(
          title: 'TAMBAH MATA KULIAH BARU',
          subtitle: 'Masukkan data kurikulum mata kuliah pangkalan data SIAKAD',
          icon: Icons.add_circle_outline,
          headerColor: const Color(0xFF0F4C81),
          maxWidth: 500,
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.ink,
                side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                shape: const RoundedRectangleBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              child: const Text('Batal', style: TextStyle(fontFamily: 'SpaceMono')),
            ),
            const SizedBox(width: 10),
            FilledButton.icon(
              onPressed: () {
                if (code.text.trim().isEmpty || name.text.trim().isEmpty) {
                  _showSnackBar('Kode dan nama mata kuliah wajib diisi.', const Color(0xFFDC2626));
                  return;
                }
                Navigator.pop(
                  context,
                  Coursemaster(
                    code: code.text.trim().toUpperCase(),
                    name: name.text.trim(),
                    credits: int.tryParse(credits.text.trim()) ?? 3,
                    semester: int.tryParse(semester.text.trim()) ?? 1,
                    programStudy: prodi,
                    prerequisite: prereq.text.trim().isEmpty ? null : prereq.text.trim().toUpperCase(),
                    type: type,
                  ),
                );
              },
              icon: const Icon(Icons.add, size: 14),
              label: const Text('Tambah MK', style: TextStyle(fontFamily: 'SpaceMono', fontSize: 11)),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0F4C81),
                shape: const RoundedRectangleBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: BapTextField(
                      label: 'Kode MK',
                      controller: code,
                      hint: 'Contoh: TI205',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: BapDropdownField<String>(
                      label: 'Program Studi',
                      value: prodi,
                      items: const [
                        DropdownMenuItem(value: 'Teknik Informatika', child: Text('Teknik Informatika')),
                        DropdownMenuItem(value: 'Sistem Informasi', child: Text('Sistem Informasi')),
                      ],
                      onChanged: (v) => setDialogState(() => prodi = v ?? prodi),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              BapTextField(
                label: 'Nama Mata Kuliah',
                controller: name,
                hint: 'Nama lengkap mata kuliah kurikulum',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: BapTextField(
                      label: 'Beban SKS',
                      controller: credits,
                      numeric: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: BapTextField(
                      label: 'Semester',
                      controller: semester,
                      numeric: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: BapDropdownField<String>(
                      label: 'Sifat MK',
                      value: type,
                      items: const [
                        DropdownMenuItem(value: 'Wajib', child: Text('Wajib')),
                        DropdownMenuItem(value: 'Pilihan', child: Text('Pilihan')),
                      ],
                      onChanged: (v) => setDialogState(() => type = v ?? type),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              BapTextField(
                label: 'Prasyarat (Opsional)',
                controller: prereq,
                hint: 'Kode MK prasyarat, contoh: TI101',
              ),
            ],
          ),
        ),
      ),
    );

    code.dispose();
    name.dispose();
    credits.dispose();
    semester.dispose();
    prereq.dispose();

    if (created != null) {
      setState(() {
        _courses.add(created);
      });
      _notifyUpdated();
      _showSnackBar('Mata kuliah ${created.code} berhasil ditambahkan ke kurikulum.', const Color(0xFF16A34A));
    }
  }

  Future<void> _showDeleteCourseDialog(Coursemaster course) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => BapDialogShell(
        title: 'HAPUS MATA KULIAH',
        subtitle: 'Konfirmasi penghapusan data kurikulum',
        icon: Icons.warning_amber_rounded,
        headerColor: const Color(0xFFDC2626),
        maxWidth: 440,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.ink,
              side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
              shape: const RoundedRectangleBorder(),
            ),
            child: const Text('Batal', style: TextStyle(fontFamily: 'SpaceMono')),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete, size: 14),
            label: const Text('Hapus Sekarang', style: TextStyle(fontFamily: 'SpaceMono', fontSize: 11)),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: const RoundedRectangleBorder(),
            ),
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apakah Anda yakin ingin menghapus mata kuliah ${course.code} - ${course.name} (${course.credits} SKS)?',
              style: const TextStyle(fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 8),
            const Text(
              'Perhatian: Tindakan ini akan menghapus master mata kuliah dari rencana perkuliahan.',
              style: TextStyle(fontSize: 10.5, color: Color(0xFFDC2626), fontFamily: 'SpaceMono'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      setState(() {
        _courses.removeWhere((item) => item.code == course.code);
      });
      _notifyUpdated();
      _showSnackBar('Mata kuliah ${course.code} telah dihapus.', const Color(0xFFDC2626));
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
