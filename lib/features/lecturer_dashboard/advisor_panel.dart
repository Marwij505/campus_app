// Panel Perwalian & Bimbingan Mahasiswa Versi Baru.
// Dirancang mandiri dan intuitif untuk validasi KRS, evaluasi studi anak wali,
// serta pembimbingan skripsi (khusus Dosen Pembimbing).

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../data/lecturer_models.dart';
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
    this.initialSubTab = 0,
  });

  final List<KrsApprovalRequest> krsRequests;
  final List<AdvisedStudent> advisees;
  final List<ThesisAdvisee> thesisAdvisees;
  final LecturerDashboardStats stats;
  final ValueChanged<List<KrsApprovalRequest>> onKrsUpdated;
  final ValueChanged<List<ThesisAdvisee>> onThesisUpdated;
  final int initialSubTab;

  @override
  State<AdvisorPanel> createState() => _AdvisorPanelState();
}

class _AdvisorPanelState extends State<AdvisorPanel> {
  int _activeSubTab =
      0; // 0: Validasi KRS, 1: Mahasiswa Wali, 2: Bimbingan Skripsi
  String _searchQuery = '';
  String _krsFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    _activeSubTab = widget.initialSubTab;
    if (widget.thesisAdvisees.isEmpty && _activeSubTab == 2) {
      _activeSubTab = 0;
    }
  }

  @override
  void didUpdateWidget(covariant AdvisorPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSubTab != widget.initialSubTab) {
      _activeSubTab = widget.initialSubTab;
      if (widget.thesisAdvisees.isEmpty && _activeSubTab == 2) {
        _activeSubTab = 0;
      }
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
        content: Text(
          'KRS mahasiswa berhasil DISETUJUI (ACC). Mahasiswa dapat mencetak KSM.',
        ),
        backgroundColor: Color(0xFF16A34A),
      ),
    );
  }

  void _reviseKrs(String id, String notes) {
    final updated = widget.krsRequests.map((r) {
      if (r.id == id) {
        return r.copyWith(
          status: KrsStatus.revision,
          advisorNotes: notes.isNotEmpty
              ? notes
              : 'Perbaiki pilihan mata kuliah sesuai ketentuan beban SKS.',
        );
      }
      return r;
    }).toList();
    widget.onKrsUpdated(updated);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Catatan revisi KRS telah dikirimkan ke portal mahasiswa.',
        ),
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
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 620),
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
                        Icons.person_pin_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'PROFIL MAHASISWA WALI',
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
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              color: const Color(0xFFE2E8F0),
                              child: const Icon(
                                Icons.person,
                                size: 28,
                                color: AppTheme.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    student.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                  Text(
                                    'NIM: ${student.nim} · Semester ${student.currentSemester} · Angkatan ${student.entryYear}',
                                    style: const TextStyle(
                                      color: AppTheme.muted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(10),
                          color: Colors.white,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    student.gpa.toStringAsFixed(2),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: AppTheme.blue,
                                    ),
                                  ),
                                  const Text(
                                    'IPK Kumulatif',
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
                                    student.ipsLatest.toStringAsFixed(2),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xFF16A34A),
                                    ),
                                  ),
                                  const Text(
                                    'IPS Terakhir',
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
                                    '${student.passedCredits} / ${student.targetCredits}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xFFD97706),
                                    ),
                                  ),
                                  const Text(
                                    'SKS Lulus',
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
                        const SizedBox(height: 12),
                        Text(
                          'STATUS PERWALIAN & AKADEMIK:',
                          style: AppTheme.pixel(7),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '• Status: ${student.academicStatus}',
                          style: const TextStyle(fontSize: 11.5),
                        ),
                        Text(
                          '• Status KRS: ${student.krsStatusText}',
                          style: const TextStyle(fontSize: 11.5),
                        ),
                        Text(
                          '• Konsultasi Terakhir: ${student.lastConsultation}',
                          style: const TextStyle(fontSize: 11.5),
                        ),
                        Text(
                          '• Kontak: ${student.phone}',
                          style: const TextStyle(fontSize: 11.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'CATATAN KONSELING DPA:',
                          style: AppTheme.pixel(7, color: AppTheme.blue),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(10),
                          color: const Color(0xFFF1F5F9),
                          child: Text(
                            student.notes,
                            style: const TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              fontFamily: 'SpaceMono',
                            ),
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
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.blue,
                    ),
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
                  color: const Color(0xFF4338CA),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.menu_book,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'LOGBOOK SKRIPSI · ${advisee.studentName}',
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
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          advisee.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tahap: ${advisee.stage}',
                          style: const TextStyle(
                            color: Color(0xFF4338CA),
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Target: ${advisee.nextTarget}',
                          style: const TextStyle(
                            color: AppTheme.muted,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progres: ${(advisee.progress * 100).toInt()}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11.5,
                              ),
                            ),
                            Text(
                              'Bimbingan ke-${advisee.totalConsultations}',
                              style: const TextStyle(
                                color: AppTheme.muted,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: advisee.progress,
                          backgroundColor: const Color(0xFFCBD5E1),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF4338CA),
                          ),
                          minHeight: 6,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'CATATAN / ARAHAN REVISI:',
                          style: AppTheme.pixel(7),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: noteController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'Tuliskan catatan revisi bab...',
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
                                status: t.progress >= 0.9
                                    ? 'Siap Daftar Sidang'
                                    : 'Aktif Bimbingan',
                                nextTarget: t.nextTarget,
                              );
                            }
                            return t;
                          }).toList();
                          widget.onThesisUpdated(updated);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Catatan bimbingan dan logbook skripsi tersimpan.',
                              ),
                              backgroundColor: Color(0xFF4338CA),
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF4338CA),
                        ),
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
    final pendingKrs = widget.krsRequests
        .where((r) => r.status == KrsStatus.pending)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Ringkasan Statistik Perwalian & Skripsi (Skripsi HANYA jika dosen pembimbing)
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 620;
            final columnCount = hasThesis
                ? (isNarrow ? 2 : 4)
                : (isNarrow ? 2 : 3);

            return GridView.count(
              crossAxisCount: columnCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: isNarrow ? 1.45 : 1.7,
              children: [
                ModernStatPill(
                  label: 'MAHASISWA WALI',
                  value: '${widget.stats.totalAdvisees}',
                  suffix: 'Mhs',
                  color: AppTheme.blue,
                  icon: Icons.school_outlined,
                  progress: 1.0,
                ),
                ModernStatPill(
                  label: 'MENUNGGU ACC KRS',
                  value: '$pendingKrs',
                  suffix: 'Mhs',
                  color: pendingKrs > 0
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF16A34A),
                  icon: Icons.pending_actions_outlined,
                  progress: pendingKrs > 0 ? 0.3 : 1.0,
                ),
                if (hasThesis)
                  ModernStatPill(
                    label: 'BIMBINGAN SKRIPSI',
                    value: '${widget.thesisAdvisees.length}',
                    suffix: 'Mhs',
                    color: const Color(0xFF4338CA),
                    icon: Icons.auto_stories_outlined,
                    progress: 0.7,
                  ),
                ModernStatPill(
                  label: 'PERLU EVALUASI',
                  value: '${widget.stats.studentsWarningCount}',
                  suffix: 'Mhs',
                  color: const Color(0xFFD97706),
                  icon: Icons.warning_amber_outlined,
                  progress: 0.2,
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 16),

        // Sub Tab 0: Validasi KRS
        if (_activeSubTab == 0) ...[
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ANTREAN VALIDASI RENCANA STUDI (KRS)',
                      style: AppTheme.pixel(8, color: AppTheme.blue),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (final f in [
                          'Semua',
                          'Menunggu',
                          'Disetujui',
                          'Revisi',
                        ]) ...[
                          ChoiceChip(
                            label: Text(
                              f,
                              style: const TextStyle(
                                fontSize: 10,
                                fontFamily: 'SpaceMono',
                              ),
                            ),
                            selected: _krsFilter == f,
                            onSelected: (_) => setState(() => _krsFilter = f),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildKrsList(),
              ],
            ),
          ),
        ],

        // Sub Tab 1: Daftar Mahasiswa Wali
        if (_activeSubTab == 1) ...[
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
                Row(
                  children: [
                    const Icon(
                      Icons.people_alt_outlined,
                      color: AppTheme.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'DAFTAR MAHASISWA PERWALIAN (${widget.advisees.length} MHS)',
                        style: AppTheme.pixel(8, color: AppTheme.blue),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (val) =>
                      setState(() => _searchQuery = val.toLowerCase()),
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

        // Sub Tab 2: Bimbingan Skripsi (Khusus Dosen Pembimbing)
        if (_activeSubTab == 2 && hasThesis) ...[
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
                Row(
                  children: [
                    const Icon(
                      Icons.auto_stories_outlined,
                      color: Color(0xFF4338CA),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'PORTAL PEMBIMBINGAN SKRIPSI & TUGAS AKHIR',
                        style: AppTheme.pixel(
                          8,
                          color: const Color(0xFF4338CA),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Monitoring progres penelitian, logbook konsultasi, dan kesiapan sidang mahasiswa.',
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
        child: const Text(
          'Tidak ada pengajuan KRS pada filter ini.',
          style: TextStyle(color: AppTheme.muted),
        ),
      );
    }

    return Column(
      children: [
        for (final req in filtered) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
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
                          Text(
                            req.studentName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'NIM: ${req.studentNim} · Smt ${req.semester} · ${req.major}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: req.status == KrsStatus.approved
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFFEF3C7),
                        border: Border.all(
                          color: req.status == KrsStatus.approved
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFD97706),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        req.status == KrsStatus.approved
                            ? 'Disetujui'
                            : (req.status == KrsStatus.pending
                                  ? 'Menunggu ACC'
                                  : 'Perlu Revisi'),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: req.status == KrsStatus.approved
                              ? const Color(0xFF15803D)
                              : const Color(0xFFB45309),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    Text(
                      'IPK: ${req.gpa.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11.5,
                        color: AppTheme.blue,
                      ),
                    ),
                    Text(
                      'SKS Diajukan: ${req.proposedCredits} SKS',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11.5,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                    Text(
                      'Maksimal: ${req.maxCredits} SKS',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.muted,
                      ),
                    ),
                  ],
                ),
                if (req.advisorNotes != null &&
                    req.advisorNotes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Catatan DPA: "${req.advisorNotes}"',
                    style: const TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: AppTheme.blue,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: () => _openKrsDetail(req),
                      icon: const Icon(Icons.list_alt, size: 15),
                      label: const Text(
                        'Rincian MK',
                        style: TextStyle(fontSize: 11),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                      ),
                    ),
                    if (req.status == KrsStatus.pending) ...[
                      OutlinedButton(
                        onPressed: () => _openKrsDetail(req),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFDC2626),
                          side: const BorderSide(
                            color: Color(0xFFDC2626),
                            width: 1.5,
                          ),
                          shape: const RoundedRectangleBorder(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                        ),
                        child: const Text(
                          'Minta Revisi',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                      FilledButton(
                        onPressed: () => _approveKrs(req.id),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          shape: const RoundedRectangleBorder(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                        ),
                        child: const Text(
                          'Setujui (ACC)',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAdviseesList() {
    final filtered = widget.advisees.where((s) {
      if (_searchQuery.isEmpty) return true;
      return s.name.toLowerCase().contains(_searchQuery) ||
          s.nim.contains(_searchQuery);
    }).toList();

    if (filtered.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: const Text(
          'Mahasiswa tidak ditemukan.',
          style: TextStyle(color: AppTheme.muted),
        ),
      );
    }

    return Column(
      children: [
        for (final s in filtered) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border.all(
                color: s.hasWarning
                    ? const Color(0xFFFCA5A5)
                    : const Color(0xFFCBD5E1),
                width: 1.5,
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
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (s.hasWarning) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        color: const Color(0xFFFEE2E2),
                        child: const Text(
                          'Perlu Evaluasi',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFFDC2626),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'NIM: ${s.nim} · Semester ${s.currentSemester} · Angkatan ${s.entryYear}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.muted),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'IPK: ${s.gpa.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11.5,
                        color: AppTheme.blue,
                      ),
                    ),
                    Text(
                      'SKS Lulus: ${s.passedCredits}/${s.targetCredits}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.ink),
                    ),
                    Text(
                      'KRS: ${s.krsStatusText}',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF16A34A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: s.creditProgress,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    s.hasWarning ? const Color(0xFFDC2626) : AppTheme.blue,
                  ),
                  minHeight: 5,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _openStudentDetail(s),
                    icon: const Icon(Icons.info_outline, size: 14),
                    label: const Text(
                      'Buka Profil & Catatan',
                      style: TextStyle(fontSize: 11),
                    ),
                    style: TextButton.styleFrom(
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
              color: const Color(0xFFF8FAFC),
              border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
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
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      color: const Color(0xFFEEF2FF),
                      child: Text(
                        t.status,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4338CA),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '"${t.title}"',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontStyle: FontStyle.italic,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tahapan: ${t.stage}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4338CA),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Target: ${t.nextTarget}',
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppTheme.muted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(t.progress * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4338CA),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: t.progress,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF4338CA),
                  ),
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
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: AppTheme.muted,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _openThesisConsultationDialog(t),
                              icon: const Icon(
                                Icons.rate_review_outlined,
                                size: 14,
                              ),
                              label: const Text(
                                'Bimbingan / Logbook',
                                style: TextStyle(fontSize: 11),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF4338CA),
                                side: const BorderSide(
                                  color: Color(0xFF4338CA),
                                  width: 1.5,
                                ),
                                shape: const RoundedRectangleBorder(),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
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
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: AppTheme.muted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () => _openThesisConsultationDialog(t),
                          icon: const Icon(
                            Icons.rate_review_outlined,
                            size: 14,
                          ),
                          label: const Text(
                            'Bimbingan / Logbook',
                            style: TextStyle(fontSize: 11),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF4338CA),
                            side: const BorderSide(
                              color: Color(0xFF4338CA),
                              width: 1.5,
                            ),
                            shape: const RoundedRectangleBorder(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
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
