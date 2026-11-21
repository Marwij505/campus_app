// Panel Administrasi KRS — BAP Dashboard.
// Mengatur periode KRS dan menangani permintaan override/manual.

import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../data/bap_models.dart';
import 'bap_widgets.dart';

class BapKrsPanel extends StatefulWidget {
  const BapKrsPanel({
    super.key,
    required this.periods,
    required this.overrideRequests,
    required this.onOverrideResolved,
    this.onPeriodsUpdated,
  });

  final List<KrsPeriod> periods;
  final List<KrsOverrideRequest> overrideRequests;
  final ValueChanged<List<KrsOverrideRequest>> onOverrideResolved;
  final ValueChanged<List<KrsPeriod>>? onPeriodsUpdated;

  @override
  State<BapKrsPanel> createState() => _BapKrsPanelState();
}

class _BapKrsPanelState extends State<BapKrsPanel> {
  int _subTab = 0; // 0: Periode KRS, 1: Override

  @override
  Widget build(BuildContext context) {
    final pendingCount = widget.overrideRequests.where((r) => !r.isResolved).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BapPanelHeader(
          icon: Icons.assignment_outlined,
          title: 'ADMINISTRASI KRS (KARTU RENCANA STUDI)',
          subtitle: 'Periode aktif, kalender registrasi & override manual mahasiswa',
          actionLabel: _subTab == 1 ? '+ Ajukan Override' : null,
          onAction: _subTab == 1 ? _showAddOverrideDialog : null,
          color: const Color(0xFF6D28D9),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _subTabBtn(0, 'Periode & Kalender KRS', null),
            const SizedBox(width: 8),
            _subTabBtn(1, 'Override KRS Manual', pendingCount > 0 ? '$pendingCount' : null),
          ],
        ),
        const SizedBox(height: 12),
        if (_subTab == 0) _buildPeriodSection(),
        if (_subTab == 1) _buildOverrideSection(),
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
          color: sel ? const Color(0xFF6D28D9) : Colors.white,
          border: Border.all(color: sel ? const Color(0xFF6D28D9) : AppTheme.ink, width: 2),
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

  Widget _buildPeriodSection() {
    return Column(
      children: widget.periods.map((p) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: p.isActive ? const Color(0xFF7C3AED) : const Color(0xFFCBD5E1),
              width: p.isActive ? 2 : 1.5,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        if (p.isActive)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            color: const Color(0xFF7C3AED),
                            child: const Text('AKTIF', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'SpaceMono')),
                          ),
                        Text(p.semester, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.ink, fontFamily: 'SpaceMono')),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _showEditPeriodDialog(p),
                    icon: const Icon(Icons.edit_calendar_outlined, size: 13),
                    label: const Text('Ubah Jadwal', style: TextStyle(fontSize: 10.5, fontFamily: 'SpaceMono')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6D28D9),
                      side: const BorderSide(color: Color(0xFF6D28D9), width: 1.5),
                      shape: const RoundedRectangleBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BapInfoRow(label: 'Periode Pengisian KRS', value: '${p.openDate} – ${p.closeDate}', valueColor: const Color(0xFF16A34A)),
                  BapInfoRow(label: 'Masa Revisi (Batal/Tambah)', value: '${p.revisionOpen} – ${p.revisionClose}', valueColor: const Color(0xFFD97706)),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOverrideSection() {
    final pending = widget.overrideRequests.where((r) => !r.isResolved).toList();
    final resolved = widget.overrideRequests.where((r) => r.isResolved).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F3FF),
            border: Border.all(color: const Color(0xFFDDD6FE), width: 1.5),
          ),
          child: const Text(
            'Override manual digunakan untuk mahasiswa yang mengalami kendala sistem, pindahan prodi, atau pengisian terlambat dengan dispensasi sah DPA / Wakil Dekan.',
            style: TextStyle(fontSize: 11, color: Color(0xFF5B21B6), fontFamily: 'SpaceMono'),
          ),
        ),
        const SizedBox(height: 12),
        if (pending.isNotEmpty) ...[
          Row(
            children: [
              const Icon(Icons.pending_actions, size: 16, color: Color(0xFF6D28D9)),
              const SizedBox(width: 6),
              Text('MENUNGGU TINDAKAN (${pending.length})', style: AppTheme.pixel(7.5, color: const Color(0xFF6D28D9))),
            ],
          ),
          const SizedBox(height: 8),
          ...pending.map((r) => _buildOverrideCard(r, resolved: false)),
          const SizedBox(height: 14),
        ],
        if (resolved.isNotEmpty) ...[
          Row(
            children: [
              const Icon(Icons.check_circle_outline, size: 16, color: AppTheme.muted),
              const SizedBox(width: 6),
              Text('SUDAH DISELESAIKAN (${resolved.length})', style: AppTheme.pixel(7.5, color: AppTheme.muted)),
            ],
          ),
          const SizedBox(height: 8),
          ...resolved.map((r) => _buildOverrideCard(r, resolved: true)),
        ],
      ],
    );
  }

  Widget _buildOverrideCard(KrsOverrideRequest r, {required bool resolved}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: resolved ? const Color(0xFFF8FAFC) : Colors.white,
        border: Border.all(
          color: resolved ? const Color(0xFFCBD5E1) : const Color(0xFF7C3AED).withValues(alpha: 0.6),
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
                    Text(r.studentName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.ink)),
                    Text('NIM: ${r.studentNim} · ${r.major} · Semester ${r.semester}',
                        style: const TextStyle(fontSize: 10.5, color: AppTheme.muted)),
                  ],
                ),
              ),
              BapStatusBadge(
                label: resolved ? 'Selesai' : 'Menunggu',
                color: resolved ? const Color(0xFF16A34A) : const Color(0xFF6D28D9),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                color: const Color(0xFFF5F3FF),
                child: Text(r.reasonLabel, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF5B21B6), fontFamily: 'SpaceMono')),
              ),
              const SizedBox(width: 10),
              Text('Diajukan: ${r.submittedAt}', style: const TextStyle(fontSize: 10.5, color: AppTheme.muted)),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 6,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showOverrideDetailDialog(r),
                icon: const Icon(Icons.visibility_outlined, size: 13),
                label: const Text('Detail Pengajuan', style: TextStyle(fontSize: 10.5, fontFamily: 'SpaceMono')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6D28D9),
                  side: const BorderSide(color: Color(0xFF6D28D9), width: 1.5),
                  shape: const RoundedRectangleBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
              if (!resolved)
                FilledButton.icon(
                  onPressed: () {
                    final updated = widget.overrideRequests.map((x) => x.id == r.id ? x.copyWith(isResolved: true) : x).toList();
                    widget.onOverrideResolved(updated);
                    _showSnack('Override KRS untuk ${r.studentName} berhasil diproses.', const Color(0xFF16A34A));
                  },
                  icon: const Icon(Icons.check, size: 13),
                  label: const Text('Proses Override', style: TextStyle(fontSize: 10.5, fontFamily: 'SpaceMono')),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
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

  Future<void> _showEditPeriodDialog(KrsPeriod period) async {
    final openCtrl = TextEditingController(text: period.openDate);
    final closeCtrl = TextEditingController(text: period.closeDate);
    final revOpenCtrl = TextEditingController(text: period.revisionOpen);
    final revCloseCtrl = TextEditingController(text: period.revisionClose);
    var active = period.isActive;

    final updated = await showDialog<KrsPeriod>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => BapDialogShell(
          title: 'UBAH KALENDER KRS',
          subtitle: period.semester,
          icon: Icons.edit_calendar_outlined,
          headerColor: const Color(0xFF6D28D9),
          maxWidth: 480,
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.ink,
                side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                shape: const RoundedRectangleBorder(),
              ),
              child: const Text('Batal', style: TextStyle(fontFamily: 'SpaceMono')),
            ),
            const SizedBox(width: 10),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(
                  context,
                  period.copyWith(
                    openDate: openCtrl.text.trim(),
                    closeDate: closeCtrl.text.trim(),
                    revisionOpen: revOpenCtrl.text.trim(),
                    revisionClose: revCloseCtrl.text.trim(),
                    isActive: active,
                  ),
                );
              },
              icon: const Icon(Icons.check, size: 14),
              label: const Text('Simpan Jadwal', style: TextStyle(fontFamily: 'SpaceMono', fontSize: 11)),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6D28D9),
                shape: const RoundedRectangleBorder(),
              ),
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BapTextField(label: 'Mulai Pengisian KRS', controller: openCtrl),
              const SizedBox(height: 10),
              BapTextField(label: 'Batas Akhir Pengisian KRS', controller: closeCtrl),
              const SizedBox(height: 10),
              BapTextField(label: 'Mulai Masa Batal / Tambah', controller: revOpenCtrl),
              const SizedBox(height: 10),
              BapTextField(label: 'Batas Masa Batal / Tambah', controller: revCloseCtrl),
              const SizedBox(height: 12),
              SwitchListTile(
                value: active,
                contentPadding: EdgeInsets.zero,
                title: const Text('Jadikan Semester Aktif', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, fontFamily: 'SpaceMono')),
                subtitle: const Text('Siswa hanya dapat mengisi KRS pada semester aktif', style: TextStyle(fontSize: 10, color: AppTheme.muted)),
                activeThumbColor: const Color(0xFF6D28D9),
                onChanged: (v) => setDialogState(() => active = v),
              ),
            ],
          ),
        ),
      ),
    );

    openCtrl.dispose();
    closeCtrl.dispose();
    revOpenCtrl.dispose();
    revCloseCtrl.dispose();

    if (updated != null) {
      final updatedList = widget.periods.map((p) => p.semester == period.semester ? updated : p).toList();
      widget.onPeriodsUpdated?.call(updatedList);
      _showSnack('Periode KRS ${period.semester} berhasil diperbarui.', const Color(0xFF16A34A));
    }
  }

  Future<void> _showOverrideDetailDialog(KrsOverrideRequest r) async {
    await showDialog(
      context: context,
      builder: (context) => BapDialogShell(
        title: 'DETAIL PENGAJUAN OVERRIDE',
        subtitle: '${r.studentName} (${r.studentNim})',
        icon: Icons.person_pin_outlined,
        headerColor: const Color(0xFF6D28D9),
        maxWidth: 480,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.ink,
              side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
              shape: const RoundedRectangleBorder(),
            ),
            child: const Text('Tutup', style: TextStyle(fontFamily: 'SpaceMono')),
          ),
          if (!r.isResolved) ...[
            const SizedBox(width: 10),
            FilledButton.icon(
              onPressed: () {
                final updated = widget.overrideRequests.map((x) => x.id == r.id ? x.copyWith(isResolved: true) : x).toList();
                widget.onOverrideResolved(updated);
                Navigator.pop(context);
                _showSnack('Override KRS untuk ${r.studentName} telah disetujui.', const Color(0xFF16A34A));
              },
              icon: const Icon(Icons.check, size: 14),
              label: const Text('Setujui Override', style: TextStyle(fontFamily: 'SpaceMono', fontSize: 11)),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                shape: const RoundedRectangleBorder(),
              ),
            ),
          ],
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BapInfoRow(label: 'Nama Mahasiswa', value: r.studentName),
            BapInfoRow(label: 'NIM Mahasiswa', value: r.studentNim),
            BapInfoRow(label: 'Program Studi', value: r.major),
            BapInfoRow(label: 'Semester', value: '${r.semester}'),
            BapInfoRow(label: 'Alasan Khusus', value: r.reasonLabel, valueColor: const Color(0xFF6D28D9)),
            BapInfoRow(label: 'Tanggal Diajukan', value: r.submittedAt),
            BapInfoRow(label: 'Status Saat Ini', value: r.isResolved ? 'Selesai Diproses' : 'Menunggu Verifikasi BAP', valueColor: r.isResolved ? const Color(0xFF16A34A) : const Color(0xFFD97706)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              color: const Color(0xFFF5F3FF),
              child: const Text(
                'Catatan: Verifikasi dokumen pendukung (Surat Pindah / Bukti Kendala IT) telah terekam di sistem pangkalan data SIAKAD.',
                style: TextStyle(fontSize: 10.5, fontStyle: FontStyle.italic, color: Color(0xFF5B21B6)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddOverrideDialog() async {
    final nimCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final semCtrl = TextEditingController(text: '3');
    var major = 'Teknik Informatika';
    var reason = KrsOverrideReason.systemError;

    final created = await showDialog<KrsOverrideRequest>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => BapDialogShell(
          title: 'AJUKAN OVERRIDE MANUAL',
          subtitle: 'Daftarkan pembukaan akses KRS khusus untuk mahasiswa',
          icon: Icons.add_moderator_outlined,
          headerColor: const Color(0xFF6D28D9),
          maxWidth: 480,
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.ink,
                side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                shape: const RoundedRectangleBorder(),
              ),
              child: const Text('Batal', style: TextStyle(fontFamily: 'SpaceMono')),
            ),
            const SizedBox(width: 10),
            FilledButton.icon(
              onPressed: () {
                if (nimCtrl.text.trim().isEmpty || nameCtrl.text.trim().isEmpty) {
                  _showSnack('NIM dan Nama Mahasiswa wajib diisi.', const Color(0xFFDC2626));
                  return;
                }
                Navigator.pop(
                  context,
                  KrsOverrideRequest(
                    id: 'OV-${DateTime.now().millisecondsSinceEpoch}',
                    studentNim: nimCtrl.text.trim(),
                    studentName: nameCtrl.text.trim(),
                    major: major,
                    semester: int.tryParse(semCtrl.text.trim()) ?? 1,
                    reason: reason,
                    submittedAt: 'Hari Ini',
                    isResolved: false,
                  ),
                );
              },
              icon: const Icon(Icons.add, size: 14),
              label: const Text('Simpan Pengajuan', style: TextStyle(fontFamily: 'SpaceMono', fontSize: 11)),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6D28D9),
                shape: const RoundedRectangleBorder(),
              ),
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BapTextField(label: 'NIM Mahasiswa', controller: nimCtrl, hint: 'Misal: 20240801099'),
              const SizedBox(height: 10),
              BapTextField(label: 'Nama Lengkap Mahasiswa', controller: nameCtrl, hint: 'Nama mahasiswa'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: BapDropdownField<String>(
                      label: 'Program Studi',
                      value: major,
                      items: const [
                        DropdownMenuItem(value: 'Teknik Informatika', child: Text('Teknik Informatika')),
                        DropdownMenuItem(value: 'Sistem Informasi', child: Text('Sistem Informasi')),
                      ],
                      onChanged: (v) => setDialogState(() => major = v ?? major),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: BapTextField(label: 'Semester', controller: semCtrl, numeric: true),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              BapDropdownField<KrsOverrideReason>(
                label: 'Alasan Khusus Override',
                value: reason,
                items: const [
                  DropdownMenuItem(value: KrsOverrideReason.systemError, child: Text('Kendala Sistem')),
                  DropdownMenuItem(value: KrsOverrideReason.transfer, child: Text('Mahasiswa Pindahan')),
                  DropdownMenuItem(value: KrsOverrideReason.late, child: Text('Pengisian Terlambat')),
                  DropdownMenuItem(value: KrsOverrideReason.correction, child: Text('Koreksi Data')),
                ],
                onChanged: (v) => setDialogState(() => reason = v ?? reason),
              ),
            ],
          ),
        ),
      ),
    );

    nimCtrl.dispose();
    nameCtrl.dispose();
    semCtrl.dispose();

    if (created != null) {
      widget.onOverrideResolved([created, ...widget.overrideRequests]);
      _showSnack('Pengajuan override untuk ${created.studentName} berhasil ditambahkan.', const Color(0xFF16A34A));
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, duration: const Duration(seconds: 2)),
    );
  }
}
