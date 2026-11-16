// Panel bimbingan akademik (perwalian) & skripsi untuk Dosen Pembimbing.
// Menyediakan validasi KRS, pemantauan kemajuan studi anak wali,
// serta pembimbingan skripsi / tugas akhir (khusus Dosen Pembimbing).

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../data/lecturer_models.dart';
import '../../shared/pixel_widgets.dart';
import 'lecturer_widgets.dart';

class AdvisorPanel extends StatefulWidget {
  const AdvisorPanel({
    super.key,
    required this.krsRequests,
    required this.advisees,
    required this.thesisAdvisees,
    required this.stats,
    required this.onKrsUpdated,
    required this.onThesisUpdated,
  });

  final List<KrsApprovalRequest> krsRequests;
  final List<AdvisedStudent> advisees;
  final List<ThesisAdvisee> thesisAdvisees;
  final LecturerDashboardStats stats;
  final ValueChanged<List<KrsApprovalRequest>> onKrsUpdated;
  final ValueChanged<List<ThesisAdvisee>> onThesisUpdated;

  @override
  State<AdvisorPanel> createState() => _AdvisorPanelState();
}

class _AdvisorPanelState extends State<AdvisorPanel> {
  int _activeSubTab = 0; // 0: Validasi KRS, 1: Mahasiswa Wali, 2: Bimbingan Skripsi
  String _searchQuery = '';
  String _krsFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    // Jika tidak memiliki bimbingan skripsi, pastikan tidak membuka subtab skripsi
    if (widget.thesisAdvisees.isEmpty && _activeSubTab == 2) {
      _activeSubTab = 0;
    }
  }

  void _openKrsDetail(KrsApprovalRequest req) {
    showDialog<void>(
      context: context,
      builder: (ctx) => KrsDetailDialog(
        request: req,
        onApprove: () => _approveKrs(req.id),
        onRevise: (notes) => _reviseKrs(req.id, notes),
      ),
    );
  }

  void _approveKrs(String id) {
    final updated = widget.krsRequests.map((r) {
      if (r.id == id) {
        return r.copyWith(status: KrsStatus.approved);
      }
      return r;
    }).toList();
    widget.onKrsUpdated(updated);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('KRS mahasiswa berhasil DISETUJUI (ACC). Mahasiswa dapat mencetak KSM.'),
        backgroundColor: Color(0xFF16A34A),
      ),
    );
  }

  void _reviseKrs(String id, String notes) {
    final updated = widget.krsRequests.map((r) {
      if (r.id == id) {
        return r.copyWith(
          status: KrsStatus.revision,
          advisorNotes: notes.isNotEmpty ? notes : 'Perbaiki pilihan mata kuliah sesuai ketentuan beban SKS.',
        );
      }
      return r;
    }).toList();
    widget.onKrsUpdated(updated);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Catatan revisi KRS telah dikirimkan ke portal mahasiswa.'),
        backgroundColor: Color(0xFFDC2626),
      ),
    );
  }

  void _openStudentDetail(AdvisedStudent student) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540, maxHeight: 650),
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
                      const Icon(Icons.person_pin_outlined, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'PROFIL MAHASISWA BIMBINGAN',
                          style: AppTheme.pixel(8, color: Colors.white),
                          overflow: TextOverflow.ellipsis,
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
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              color: const Color(0xFFE2E8F0),
                              child: const Icon(Icons.person, size: 30, color: AppTheme.blue),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  Text('NIM: ${student.nim} · Angkatan ${student.entryYear}', style: const TextStyle(color: AppTheme.muted, fontSize: 11)),
                                  Text('${student.major} · Semester ${student.currentSemester}', style: const TextStyle(color: AppTheme.muted, fontSize: 11)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(10),
                          color: Colors.white,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  Text(student.gpa.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.blue)),
                                  const Text('IPK Kumulatif', style: TextStyle(fontSize: 10, color: AppTheme.muted)),
                                ],
                              ),
                              Column(
                                children: [
                                  Text(student.ipsLatest.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF16A34A))),
                                  const Text('IPS Terakhir', style: TextStyle(fontSize: 10, color: AppTheme.muted)),
                                ],
                              ),
                              Column(
                                children: [
                                  Text('${student.passedCredits} / ${student.targetCredits}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFD97706))),
                                  const Text('SKS Lulus', style: TextStyle(fontSize: 10, color: AppTheme.muted)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text('STATUS AKADEMIK & PERWALIAN:', style: AppTheme.pixel(7.5)),
                        const SizedBox(height: 6),
                        Text('• Status: ${student.academicStatus}', style: const TextStyle(fontSize: 11.5)),
                        Text('• Status KRS: ${student.krsStatusText}', style: const TextStyle(fontSize: 11.5)),
                        Text('• Konsultasi Terakhir: ${student.lastConsultation}', style: const TextStyle(fontSize: 11.5)),
                        Text('• Kontak: ${student.phone} · ${student.email}', style: const TextStyle(fontSize: 11.5)),
                        const SizedBox(height: 12),
                        Text('CATATAN DOSEN PEMBIMBING AKADEMIK:', style: AppTheme.pixel(7.5, color: AppTheme.blue)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(10),
                          color: const Color(0xFFF1F5F9),
                          child: Text(
                            student.notes,
                            style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, fontFamily: 'SpaceMono'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.white,
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: FilledButton.styleFrom(backgroundColor: AppTheme.blue),
                    child: const Text('Tutup'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openThesisConsultationDialog(ThesisAdvisee advisee) {
    final noteController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 600),
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
                  color: const Color(0xFF4338CA),
                  child: Row(
                    children: [
                      const Icon(Icons.menu_book, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'LOGBOOK SKRIPSI · ${advisee.studentName}',
                          style: AppTheme.pixel(8, color: Colors.white),
                          overflow: TextOverflow.ellipsis,
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
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          advisee.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        Text('Tahap: ${advisee.stage}', style: const TextStyle(color: Color(0xFF4338CA), fontWeight: FontWeight.w600, fontSize: 11)),
                        const SizedBox(height: 4),
                        Text('Target: ${advisee.nextTarget}', style: const TextStyle(color: AppTheme.muted, fontSize: 11)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Progres Penelitian: ${(advisee.progress * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                            Text('Bimbingan ke-${advisee.totalConsultations}', style: const TextStyle(color: AppTheme.muted, fontSize: 11.5)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: advisee.progress,
                          backgroundColor: const Color(0xFFCBD5E1),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4338CA)),
                          minHeight: 8,
                        ),
                        const SizedBox(height: 16),
                        Text('CATATAN / REVISI BIMBINGAN:', style: AppTheme.pixel(7.5)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: noteController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'Tuliskan instruksi revisi atau persetujuan bab...',
                            border: OutlineInputBorder(),
                          ),
                          style: const TextStyle(fontSize: 12, fontFamily: 'SpaceMono'),
                        ),
                      ],
                    ),
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
                          final updated = widget.thesisAdvisees.map((t) {
                            if (t.id == advisee.id) {
                              return ThesisAdvisee(
                                id: t.id,
                                studentNim: t.studentNim,
                                studentName: t.studentName,
                                title: t.title,
                                stage: t.stage,
                                progress: (t.progress + 0.05).clamp(0.0, 1.0),
                                lastLogbookDate: 'Hari Ini',
                                totalConsultations: t.totalConsultations + 1,
                                status: t.progress >= 0.9 ? 'Siap Daftar Sidang' : 'Aktif Bimbingan',
                                nextTarget: t.nextTarget,
                              );
                            }
                            return t;
                          }).toList();
                          widget.onThesisUpdated(updated);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Catatan bimbingan dan logbook skripsi berhasil divalidasi.'),
                              backgroundColor: Color(0xFF4338CA),
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF4338CA)),
                        child: const Text('Validasi Bimbingan (+1)'),
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

  @override
  Widget build(BuildContext context) {
    final hasThesis = widget.thesisAdvisees.isNotEmpty;
    final pendingKrs = widget.krsRequests.where((r) => r.status == KrsStatus.pending).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Ringkasan Statistik Perwalian & DPA
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 600;
            final columnCount = hasThesis ? (isNarrow ? 2 : 4) : (isNarrow ? 2 : 3);

            return GridView.count(
              crossAxisCount: columnCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: isNarrow ? 1.35 : 1.55,
              children: [
                LecturerStatCard(
                  label: 'MAHASISWA WALI',
                  value: '${widget.stats.totalAdvisees}',
                  suffix: 'Mhs',
                  icon: Icons.school_outlined,
                  color: AppTheme.blue,
                  subtitle: 'Bimbingan akademik aktif',
                ),
                LecturerStatCard(
                  label: 'MENUNGGU ACC KRS',
                  value: '$pendingKrs',
                  suffix: 'Mhs',
                  icon: Icons.pending_actions_outlined,
                  color: pendingKrs > 0 ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                  subtitle: 'Perlu validasi rencana studi',
                ),
                if (hasThesis)
                  LecturerStatCard(
                    label: 'BIMBINGAN SKRIPSI',
                    value: '${widget.thesisAdvisees.length}',
                    suffix: 'Mhs',
                    icon: Icons.auto_stories_outlined,
                    color: const Color(0xFF4338CA),
                    subtitle: 'Tugas Akhir aktif',
                  ),
                LecturerStatCard(
                  label: 'PERLU PERHATIAN',
                  value: '${widget.stats.studentsWarningCount}',
                  suffix: 'Mhs',
                  icon: Icons.warning_amber_outlined,
                  color: const Color(0xFFD97706),
                  subtitle: 'Evaluasi IPK & masa studi',
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 20),

        // Sub Tab Selector dengan SingleChildScrollView agar tidak pernah overflow di layar HP
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _subTabButton(0, 'Persetujuan KRS', pendingKrs > 0 ? '$pendingKrs' : null),
              const SizedBox(width: 8),
              _subTabButton(1, 'Daftar Anak Wali', '${widget.advisees.length}'),
              if (hasThesis) ...[
                const SizedBox(width: 8),
                _subTabButton(2, 'Bimbingan Skripsi', '${widget.thesisAdvisees.length}'),
              ],
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Isi Sub Tab 0: Persetujuan KRS
        if (_activeSubTab == 0) ...[
          PixelPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('VALIDASI & APPROVAL KRS:', style: AppTheme.pixel(8, color: AppTheme.blue)),
                    ),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (final f in ['Semua', 'Menunggu', 'Disetujui', 'Revisi']) ...[
                          ChoiceChip(
                            label: Text(f, style: const TextStyle(fontSize: 10, fontFamily: 'SpaceMono')),
                            selected: _krsFilter == f,
                            onSelected: (_) => setState(() => _krsFilter = f),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildKrsList(),
              ],
            ),
          ),
        ],

        // Isi Sub Tab 1: Daftar Mahasiswa Perwalian
        if (_activeSubTab == 1) ...[
          PixelPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.people_alt_outlined, color: AppTheme.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('DAFTAR MAHASISWA PERWALIAN (${widget.advisees.length} MHS)', style: AppTheme.pixel(8, color: AppTheme.blue)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                  decoration: const InputDecoration(
                    hintText: 'Cari nama atau NIM mahasiswa wali...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(fontSize: 12, fontFamily: 'SpaceMono'),
                ),
                const SizedBox(height: 14),
                _buildAdviseesList(),
              ],
            ),
          ),
        ],

        // Isi Sub Tab 2: Bimbingan Skripsi / Tugas Akhir (Khusus Dosen Pembimbing)
        if (_activeSubTab == 2 && hasThesis) ...[
          PixelPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_stories_outlined, color: Color(0xFF4338CA), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'MAHASISWA BIMBINGAN TUGAS AKHIR / SKRIPSI',
                        style: AppTheme.pixel(8, color: const Color(0xFF4338CA)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Pantau progres penulisan, catatan konsultasi mingguan, dan validasi logbook mahasiswa bimbingan tugas akhir.',
                  style: TextStyle(fontSize: 11, color: AppTheme.muted),
                ),
                const SizedBox(height: 14),
                _buildThesisList(),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _subTabButton(int index, String title, String? badge) {
    final isSelected = _activeSubTab == index;
    return InkWell(
      onTap: () => setState(() => _activeSubTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.blue : Colors.white,
          border: Border.all(color: AppTheme.ink, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppTheme.ink,
                fontFamily: 'SpaceMono',
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : const Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppTheme.blue : Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildKrsList() {
    final filtered = widget.krsRequests.where((r) {
      if (_krsFilter == 'Menunggu') return r.status == KrsStatus.pending;
      if (_krsFilter == 'Disetujui') return r.status == KrsStatus.approved;
      if (_krsFilter == 'Revisi') return r.status == KrsStatus.revision;
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: const Text('Tidak ada pengajuan KRS pada kategori ini.', style: TextStyle(color: AppTheme.muted)),
      );
    }

    return Column(
      children: [
        for (final req in filtered) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: KrsApprovalCard(
              request: req,
              onApprove: () => _approveKrs(req.id),
              onRevise: () => _openKrsDetail(req),
              onViewDetails: () => _openKrsDetail(req),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAdviseesList() {
    final filtered = widget.advisees.where((s) {
      if (_searchQuery.isEmpty) return true;
      return s.name.toLowerCase().contains(_searchQuery) || s.nim.contains(_searchQuery);
    }).toList();

    if (filtered.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: const Text('Mahasiswa tidak ditemukan.', style: TextStyle(color: AppTheme.muted)),
      );
    }

    return Column(
      children: [
        for (final s in filtered) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: s.hasWarning ? const Color(0xFFFCA5A5) : const Color(0xFFCBD5E1),
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        s.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (s.hasWarning) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        color: const Color(0xFFFEE2E2),
                        child: const Row(
                          children: [
                            Icon(Icons.warning, size: 12, color: Color(0xFFDC2626)),
                            SizedBox(width: 4),
                            Text('Perlu Perhatian', style: TextStyle(fontSize: 10, color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text('NIM: ${s.nim} · Semester ${s.currentSemester} · Angkatan ${s.entryYear}', style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('IPK: ${s.gpa.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: AppTheme.blue)),
                    const SizedBox(width: 12),
                    Text('SKS Lulus: ${s.passedCredits}/${s.targetCredits}', style: const TextStyle(fontSize: 11, color: AppTheme.ink)),
                    const Spacer(),
                    Text('KRS: ${s.krsStatusText}', style: const TextStyle(fontSize: 10.5, color: Color(0xFF16A34A), fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: s.creditProgress,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor: AlwaysStoppedAnimation<Color>(s.hasWarning ? const Color(0xFFDC2626) : AppTheme.blue),
                  minHeight: 5,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _openStudentDetail(s),
                    icon: const Icon(Icons.info_outline, size: 14),
                    label: const Text('Buka Profil & Catatan', style: TextStyle(fontSize: 11)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.blue,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildThesisList() {
    return Column(
      children: [
        for (final t in widget.thesisAdvisees) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
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
                        '${t.studentName} (${t.studentNim})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      color: const Color(0xFFEEF2FF),
                      child: Text(
                        t.status,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF4338CA)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '"${t.title}"',
                  style: const TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: AppTheme.ink),
                ),
                const SizedBox(height: 8),
                Text('Tahapan: ${t.stage}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF4338CA))),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Target: ${t.nextTarget}',
                        style: const TextStyle(fontSize: 10.5, color: AppTheme.muted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(t.progress * 100).toInt()}%',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4338CA)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: t.progress,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4338CA)),
                  minHeight: 6,
                ),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 420;
                    if (isCompact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Logbook: ${t.totalConsultations}x · Terakhir: ${t.lastLogbookDate}',
                            style: const TextStyle(fontSize: 10.5, color: AppTheme.muted),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _openThesisConsultationDialog(t),
                              icon: const Icon(Icons.rate_review_outlined, size: 14),
                              label: const Text('Bimbingan / Logbook', style: TextStyle(fontSize: 11)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF4338CA),
                                side: const BorderSide(color: Color(0xFF4338CA), width: 1.5),
                                shape: const RoundedRectangleBorder(),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Logbook: ${t.totalConsultations}x · Terakhir: ${t.lastLogbookDate}',
                            style: const TextStyle(fontSize: 10.5, color: AppTheme.muted),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () => _openThesisConsultationDialog(t),
                          icon: const Icon(Icons.rate_review_outlined, size: 14),
                          label: const Text('Bimbingan / Logbook', style: TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF4338CA),
                            side: const BorderSide(color: Color(0xFF4338CA), width: 1.5),
                            shape: const RoundedRectangleBorder(),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
