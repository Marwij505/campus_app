// Panel Jadwal Kuliah & Plotting Ruang — BAP Dashboard.

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../data/bap_models.dart';
import 'bap_widgets.dart';

class BapSchedulePanel extends StatefulWidget {
  const BapSchedulePanel({
    super.key,
    required this.schedules,
    required this.onScheduleUpdated,
  });
  final List<ClassSchedule> schedules;
  final ValueChanged<List<ClassSchedule>> onScheduleUpdated;

  @override
  State<BapSchedulePanel> createState() => _BapSchedulePanelState();
}

class _BapSchedulePanelState extends State<BapSchedulePanel> {
  String _filterDay = 'Semua';

  static const _days = ['Semua', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat'];

  @override
  Widget build(BuildContext context) {
    final filtered = widget.schedules
        .where((s) => _filterDay == 'Semua' || s.day == _filterDay)
        .toList();
    final conflictCount = widget.schedules.where((s) => s.isConflict).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BapPanelHeader(
          icon: Icons.calendar_month_outlined,
          title: 'PENJADWALAN KULIAH & PLOTTING RUANG',
          subtitle:
              '${widget.schedules.length} kelas terdaftar · $conflictCount konflik terdeteksi',
          actionLabel: '+ Tambah Jadwal',
          onAction: _showAddScheduleDialog,
          color: const Color(0xFF0F766E),
        ),
        if (conflictCount > 0) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              border: Border.all(color: const Color(0xFFFCA5A5), width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFDC2626),
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$conflictCount jadwal terdeteksi BENTROK ruang. Segera lakukan plot ulang atau pindahkan ruang.',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF991B1B),
                      fontFamily: 'SpaceMono',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _days.map((d) {
              final sel = _filterDay == d;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: InkWell(
                  onTap: () => setState(() => _filterDay = d),
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
                      d,
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
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filtered.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) => _buildScheduleCard(filtered[i]),
        ),
      ],
    );
  }

  Widget _buildScheduleCard(ClassSchedule s) {
    return Container(
      decoration: BoxDecoration(
        color: s.isConflict ? const Color(0xFFFFF1F1) : Colors.white,
        border: Border.all(
          color: s.isConflict
              ? const Color(0xFFF87171)
              : const Color(0xFFCBD5E1),
          width: s.isConflict ? 2 : 1.5,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hari & Waktu
          Container(
            width: 90,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            color: s.isConflict
                ? const Color(0xFFDC2626)
                : const Color(0xFF0F766E),
            child: Column(
              children: [
                Text(
                  s.day,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'SpaceMono',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  s.time,
                  style: const TextStyle(
                    fontSize: 9,
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
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
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
                    Text(
                      '${s.credits} SKS',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.muted,
                        fontFamily: 'SpaceMono',
                      ),
                    ),
                    if (s.isConflict)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        color: const Color(0xFFDC2626),
                        child: const Text(
                          'BENTROK RUANG',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'SpaceMono',
                          ),
                        ),
                      ),
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
                const SizedBox(height: 2),
                Text(
                  'Dosen: ${s.lecturerName}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.muted),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 14,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.room, size: 13, color: AppTheme.muted),
                        const SizedBox(width: 4),
                        Text(
                          s.room,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.muted,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.people_outline,
                          size: 13,
                          color: AppTheme.muted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${s.enrolledCount}/${s.capacity} Mahasiswa',
                          style: TextStyle(
                            fontSize: 11,
                            color: s.enrolledCount >= s.capacity
                                ? const Color(0xFFDC2626)
                                : AppTheme.muted,
                            fontWeight: s.enrolledCount >= s.capacity
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              OutlinedButton.icon(
                onPressed: () => _showEditScheduleDialog(s),
                icon: const Icon(Icons.tune, size: 12),
                label: const Text('Plot / Edit', style: TextStyle(fontSize: 10, fontFamily: 'SpaceMono')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F766E),
                  side: const BorderSide(color: Color(0xFF0F766E), width: 1.5),
                  shape: const RoundedRectangleBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
              if (s.isConflict) ...[
                const SizedBox(height: 6),
                FilledButton.icon(
                  onPressed: () => _resolveConflict(s),
                  icon: const Icon(Icons.auto_fix_high, size: 12),
                  label: const Text('Selesaikan', style: TextStyle(fontSize: 10, fontFamily: 'SpaceMono')),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    shape: const RoundedRectangleBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                ),
              ],
              const SizedBox(height: 4),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 16),
                color: const Color(0xFF94A3B8),
                tooltip: 'Hapus Jadwal',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                onPressed: () => _showDeleteScheduleDialog(s),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _showAddScheduleDialog() async {
    final code = TextEditingController();
    final name = TextEditingController();
    final section = TextEditingController(text: 'A');
    final lecturer = TextEditingController();
    final time = TextEditingController(text: '08:00 – 09:40');
    final room = TextEditingController(text: 'Ruang 301');
    final credits = TextEditingController(text: '3');
    final capacity = TextEditingController(text: '40');
    var day = 'Senin';

    const availableRooms = [
      'Ruang 201',
      'Ruang 202',
      'Ruang 301',
      'Ruang 302',
      'Ruang 303',
      'Ruang 401',
      'Lab Komputer 1',
      'Lab Komputer 2',
      'Lab Komputer 3',
    ];

    final created = await showDialog<ClassSchedule>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => BapDialogShell(
          title: 'TAMBAH JADWAL KULIAH',
          subtitle: 'Plotting jadwal perkuliahan, kelas paralel, dan alokasi ruang',
          icon: Icons.calendar_today_outlined,
          headerColor: const Color(0xFF0F766E),
          maxWidth: 540,
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
                if (code.text.trim().isEmpty || name.text.trim().isEmpty || lecturer.text.trim().isEmpty) {
                  _showSnack('Kode MK, nama mata kuliah, dan dosen wajib diisi.', const Color(0xFFDC2626));
                  return;
                }
                Navigator.pop(
                  context,
                  ClassSchedule(
                    id: 'SCH-${DateTime.now().millisecondsSinceEpoch}',
                    courseCode: code.text.trim().toUpperCase(),
                    courseName: name.text.trim(),
                    classSection: section.text.trim().toUpperCase(),
                    lecturerName: lecturer.text.trim(),
                    day: day,
                    time: time.text.trim(),
                    room: room.text.trim(),
                    credits: int.tryParse(credits.text.trim()) ?? 3,
                    enrolledCount: 0,
                    capacity: int.tryParse(capacity.text.trim()) ?? 40,
                    isConflict: false,
                  ),
                );
              },
              icon: const Icon(Icons.add, size: 14),
              label: const Text('Simpan Jadwal', style: TextStyle(fontFamily: 'SpaceMono', fontSize: 11)),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
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
                      hint: 'Misal: TI101',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: BapTextField(
                      label: 'Kelas',
                      controller: section,
                      hint: 'A',
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
              BapTextField(
                label: 'Dosen Pengampu',
                controller: lecturer,
                hint: 'Nama dosen pengampu lengkap dengan gelar',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: BapDropdownField<String>(
                      label: 'Hari Perkuliahan',
                      value: day,
                      items: const [
                        DropdownMenuItem(value: 'Senin', child: Text('Senin')),
                        DropdownMenuItem(value: 'Selasa', child: Text('Selasa')),
                        DropdownMenuItem(value: 'Rabu', child: Text('Rabu')),
                        DropdownMenuItem(value: 'Kamis', child: Text('Kamis')),
                        DropdownMenuItem(value: 'Jumat', child: Text('Jumat')),
                      ],
                      onChanged: (v) => setDialogState(() => day = v ?? day),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: BapTextField(
                      label: 'Jam Kuliah',
                      controller: time,
                      hint: '08:00 – 09:40',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: BapDropdownField<String>(
                      label: 'Alokasi Ruang',
                      value: availableRooms.contains(room.text) ? room.text : availableRooms.first,
                      items: availableRooms
                          .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                          .toList(),
                      onChanged: (v) => setDialogState(() => room.text = v ?? room.text),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: BapTextField(
                      label: 'SKS',
                      controller: credits,
                      numeric: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: BapTextField(
                      label: 'Kapasitas',
                      controller: capacity,
                      numeric: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    code.dispose();
    name.dispose();
    section.dispose();
    lecturer.dispose();
    time.dispose();
    room.dispose();
    credits.dispose();
    capacity.dispose();

    if (created != null) {
      widget.onScheduleUpdated([...widget.schedules, created]);
      _showSnack('Jadwal ${created.courseCode} (${created.classSection}) berhasil disimpan.', const Color(0xFF16A34A));
    }
  }

  Future<void> _showEditScheduleDialog(ClassSchedule schedule) async {
    final code = TextEditingController(text: schedule.courseCode);
    final name = TextEditingController(text: schedule.courseName);
    final section = TextEditingController(text: schedule.classSection);
    final lecturer = TextEditingController(text: schedule.lecturerName);
    final time = TextEditingController(text: schedule.time);
    final room = TextEditingController(text: schedule.room);
    final capacity = TextEditingController(text: '${schedule.capacity}');
    var day = schedule.day;

    const availableRooms = [
      'Ruang 201',
      'Ruang 202',
      'Ruang 301',
      'Ruang 302',
      'Ruang 303',
      'Ruang 401',
      'Lab Komputer 1',
      'Lab Komputer 2',
      'Lab Komputer 3',
    ];

    final updated = await showDialog<ClassSchedule>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => BapDialogShell(
          title: 'PLOT ULANG / EDIT JADWAL',
          subtitle: '${schedule.courseCode} · Kelas ${schedule.classSection}',
          icon: Icons.tune,
          headerColor: const Color(0xFF0F766E),
          maxWidth: 540,
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
                Navigator.pop(
                  context,
                  schedule.copyWith(
                    courseCode: code.text.trim().toUpperCase(),
                    courseName: name.text.trim(),
                    classSection: section.text.trim().toUpperCase(),
                    lecturerName: lecturer.text.trim(),
                    day: day,
                    time: time.text.trim(),
                    room: room.text.trim(),
                    capacity: int.tryParse(capacity.text.trim()) ?? schedule.capacity,
                    isConflict: false,
                  ),
                );
              },
              icon: const Icon(Icons.check, size: 14),
              label: const Text('Simpan Perubahan', style: TextStyle(fontFamily: 'SpaceMono', fontSize: 11)),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                shape: const RoundedRectangleBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (schedule.isConflict) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    border: Border.all(color: const Color(0xFFF87171), width: 1.5),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Pindahkan ruang atau ubah jam perkuliahan untuk menyelesaikan bentrok jadwal.',
                          style: TextStyle(fontSize: 10.5, color: Color(0xFF991B1B), fontFamily: 'SpaceMono'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: BapTextField(
                      label: 'Kode MK',
                      controller: code,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: BapTextField(
                      label: 'Kelas',
                      controller: section,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              BapTextField(
                label: 'Nama Mata Kuliah',
                controller: name,
              ),
              const SizedBox(height: 12),
              BapTextField(
                label: 'Dosen Pengampu',
                controller: lecturer,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: BapDropdownField<String>(
                      label: 'Hari',
                      value: day,
                      items: const [
                        DropdownMenuItem(value: 'Senin', child: Text('Senin')),
                        DropdownMenuItem(value: 'Selasa', child: Text('Selasa')),
                        DropdownMenuItem(value: 'Rabu', child: Text('Rabu')),
                        DropdownMenuItem(value: 'Kamis', child: Text('Kamis')),
                        DropdownMenuItem(value: 'Jumat', child: Text('Jumat')),
                      ],
                      onChanged: (v) => setDialogState(() => day = v ?? day),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: BapTextField(
                      label: 'Jam Kuliah',
                      controller: time,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: BapDropdownField<String>(
                      label: 'Pilih Ruang / Laboratorium',
                      value: availableRooms.contains(room.text) ? room.text : availableRooms.first,
                      items: availableRooms
                          .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                          .toList(),
                      onChanged: (v) => setDialogState(() => room.text = v ?? room.text),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: BapTextField(
                      label: 'Kapasitas',
                      controller: capacity,
                      numeric: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    code.dispose();
    name.dispose();
    section.dispose();
    lecturer.dispose();
    time.dispose();
    room.dispose();
    capacity.dispose();

    if (updated != null) {
      widget.onScheduleUpdated(
        widget.schedules.map((item) => item.id == schedule.id ? updated : item).toList(),
      );
      _showSnack('Jadwal ${updated.courseCode} berhasil diperbarui.', const Color(0xFF16A34A));
    }
  }

  void _resolveConflict(ClassSchedule schedule) {
    const fallbackRooms = ['Ruang 202', 'Ruang 303', 'Lab Komputer 3'];
    final newRoom = fallbackRooms.first;

    final updated = widget.schedules.map((item) {
      if (item.id == schedule.id) {
        return item.copyWith(room: newRoom, isConflict: false);
      }
      return item;
    }).toList();

    widget.onScheduleUpdated(updated);
    _showSnack(
      'Konflik ${schedule.courseCode} diselesaikan: dialihkan ke $newRoom.',
      const Color(0xFF16A34A),
    );
  }

  Future<void> _showDeleteScheduleDialog(ClassSchedule schedule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => BapDialogShell(
        title: 'HAPUS JADWAL KULIAH',
        subtitle: '${schedule.courseCode} · Kelas ${schedule.classSection}',
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
            label: const Text('Hapus Jadwal', style: TextStyle(fontFamily: 'SpaceMono', fontSize: 11)),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: const RoundedRectangleBorder(),
            ),
          ),
        ],
        child: Text(
          'Hapus jadwal mata kuliah ${schedule.courseName} (Kelas ${schedule.classSection}) pada ${schedule.day}, ${schedule.time} di ${schedule.room}?',
          style: const TextStyle(fontSize: 12, height: 1.5),
        ),
      ),
    );

    if (confirmed == true) {
      widget.onScheduleUpdated(
        widget.schedules.where((item) => item.id != schedule.id).toList(),
      );
      _showSnack('Jadwal ${schedule.courseCode} telah dihapus.', const Color(0xFFDC2626));
    }
  }
}
