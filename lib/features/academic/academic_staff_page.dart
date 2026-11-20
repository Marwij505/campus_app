import 'package:flutter/material.dart';

import 'academic_repository.dart';

/// Server permissions, not the visibility of these controls, authorize decisions.
class AcademicStaffPage extends StatefulWidget {
  const AcademicStaffPage({
    super.key,
    required this.repository,
    required this.period,
  });
  final AcademicRepository repository;
  final String period;
  @override
  State<AcademicStaffPage> createState() => _AcademicStaffPageState();
}

class _AcademicStaffPageState extends State<AcademicStaffPage> {
  final _student = TextEditingController(), _reason = TextEditingController();
  final _bank = TextEditingController(), _paidAt = TextEditingController();
  Json? _data;
  String? _reviewedStudent;
  String? _error;
  bool _busy = false;
  @override
  void dispose() {
    _student.dispose();
    _reason.dispose();
    _bank.dispose();
    _paidAt.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      _error = e is AcademicException
          ? e.message
          : 'Data/izin tidak valid; muat ulang.';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _load() async {
    final id = _student.text.trim();
    final data = await widget.repository.review(id, widget.period);
    if (_student.text.trim() == id) {
      _data = data;
      _reviewedStudent = id;
    }
  }

  Future<void> _decide(String action, Json values) => _run(() async {
    if (_data == null || _reviewedStudent != _student.text.trim()) {
      throw const AcademicException(
        'Muat data mahasiswa sebelum mengambil keputusan.',
      );
    }
    await widget.repository.command(action, widget.period, {
      'student_id': _data!['student']['user_id'],
      'reason': _reason.text.trim(),
      ...values,
    });
    await _load();
  });
  Widget _button(String label, VoidCallback action) => Padding(
    padding: const EdgeInsets.all(4),
    child: OutlinedButton(onPressed: _busy ? null : action, child: Text(label)),
  );

  Future<void> _editEvent(Json event) async {
    final start = TextEditingController(text: event['starts_at']);
    final end = TextEditingController(text: event['ends_at']);
    final room = TextEditingController(text: event['room']);
    final mode = TextEditingController(text: event['mode']);
    var cancelled = event['cancelled'] == true;
    final result = await showDialog<Json>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Terbitkan perubahan jadwal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Waktu ISO dengan zona +07:00. Gunakan alasan keputusan pada panel petugas.',
                ),
                TextField(
                  controller: start,
                  decoration: const InputDecoration(labelText: 'Mulai'),
                ),
                TextField(
                  controller: end,
                  decoration: const InputDecoration(labelText: 'Selesai'),
                ),
                TextField(
                  controller: room,
                  decoration: const InputDecoration(labelText: 'Ruang'),
                ),
                TextField(
                  controller: mode,
                  decoration: const InputDecoration(
                    labelText: 'Mode pembelajaran',
                  ),
                ),
                CheckboxListTile(
                  title: const Text('Batalkan pertemuan'),
                  value: cancelled,
                  onChanged: (value) =>
                      setDialogState(() => cancelled = value ?? false),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, <String, dynamic>{
                'id': event['id'],
                'revision': event['revision'],
                'starts_at': start.text.trim(),
                'ends_at': end.text.trim(),
                'room': room.text.trim(),
                'mode': mode.text.trim(),
                'cancelled': cancelled,
              }),
              child: const Text('Terbitkan'),
            ),
          ],
        ),
      ),
    );
    Future<void>.delayed(const Duration(seconds: 1), () {
      start.dispose();
      end.dispose();
      room.dispose();
      mode.dispose();
    });
    if (result != null && mounted) await _decide('publish_event', result);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Petugas akademik / keuangan')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Periode ${widget.period} · Semua keputusan diaudit oleh server.'),
        TextField(
          controller: _student,
          enabled: !_busy,
          onChanged: (_) => setState(() {
            _data = null;
            _reviewedStudent = null;
          }),
          decoration: const InputDecoration(labelText: 'NIM mahasiswa'),
        ),
        _button('Muat permohonan', () => _run(_load)),
        if (_busy) const LinearProgressIndicator(),
        if (_error != null) Text(_error!),
        TextField(
          controller: _reason,
          decoration: const InputDecoration(
            labelText: 'Alasan keputusan (wajib)',
          ),
        ),
        if (_data != null) ...[
          Text(
            '${_data!['student']?['name'] ?? ''} · ${_data!['student']?['nim'] ?? ''}',
          ),
          if (rows(_data!['events']).isNotEmpty)
            ExpansionTile(
              title: const Text('Perubahan jadwal'),
              children: [
                for (final event in rows(_data!['events']))
                  ListTile(
                    title: Text(
                      '${event['offering_id']} · ${event['kind']} ${event['meeting'] ?? ''}',
                    ),
                    subtitle: Text(
                      '${academicTime(event['starts_at'])} · ${event['room']} · ${event['cancelled'] == true ? 'Dibatalkan' : 'Terjadwal'}',
                    ),
                    trailing: IconButton(
                      tooltip: 'Ubah jadwal',
                      onPressed: _busy ? null : () => _editEvent(event),
                      icon: const Icon(Icons.edit_calendar),
                    ),
                  ),
              ],
            ),
          Text('Status registrasi: ${_data!['registration']?['status']}'),
          if (_data!['krs']?['status'] == 'submitted')
            Wrap(
              children: [
                for (final decision in ['approved', 'revision'])
                  _button(
                    decision == 'approved' ? 'Sahkan KRS' : 'Kembalikan revisi',
                    () => _decide('decide_krs', {
                      'version': _data!['krs']['version'],
                      'decision': decision,
                    }),
                  ),
              ],
            ),
          for (final leave in rows(_data!['leave_requests']))
            ListTile(
              title: Text('${leave['reason']} · ${leave['status']}'),
              subtitle: leave['status'] == 'submitted'
                  ? Wrap(
                      children: [
                        for (final decision in ['approved', 'rejected'])
                          _button(
                            decision == 'approved'
                                ? 'Setujui cuti'
                                : 'Tolak cuti',
                            () => _decide('decide_leave', {
                              'id': leave['id'],
                              'decision': decision,
                            }),
                          ),
                      ],
                    )
                  : null,
            ),
          if (rows(_data!['payments']).isNotEmpty) ...[
            const Divider(),
            const Text(
              'Mutasi/konfirmasi simulasi. Jangan masukkan data bank nyata.',
            ),
            TextField(
              controller: _bank,
              decoration: const InputDecoration(
                labelText: 'ID mutasi simulasi unik',
              ),
            ),
            TextField(
              controller: _paidAt,
              decoration: const InputDecoration(
                labelText: 'Waktu pembayaran tepercaya (contoh 2027-01-19T09:05:00+07:00)',
              ),
            ),
          ],
          for (final pay in rows(_data!['payments']))
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      '${pay['id']}\n${pay['channel']} · Rp${pay['amount']} · ${pay['status']}\nBukti: ${pay['evidence'] ?? '-'}\nMutasi: ${pay['bank_reference'] ?? '-'}',
                    ),
                    if ([
                      'pending',
                      'review',
                      'expired',
                      'reconcile',
                    ].contains(pay['status']))
                      Wrap(
                        children: [
                          _button(
                            pay['status'] == 'reconcile'
                                ? 'Rekonsiliasi'
                                : 'Verifikasi cocok',
                            () => _decide(
                              pay['status'] == 'reconcile'
                                  ? 'reconcile'
                                  : 'verify_payment',
                              {
                                'id': pay['id'],
                                'reference': pay['id'],
                                'currency': 'IDR',
                                'amount': pay['amount'],
                                'decision': 'approved',
                                'bank_reference': pay['status'] == 'reconcile'
                                    ? pay['bank_reference']
                                    : _bank.text.trim(),
                                'paid_at': pay['status'] == 'reconcile'
                                    ? pay['paid_at']
                                    : _paidAt.text.trim(),
                              },
                            ),
                          ),
                          if (['pending', 'review'].contains(pay['status']))
                            _button(
                              'Tolak pembayaran',
                              () => _decide('verify_payment', {
                                'id': pay['id'],
                                'decision': 'rejected',
                              }),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
        ],
      ],
    ),
  );
}
