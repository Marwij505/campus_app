import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:qr/qr.dart';

import '../../core/app_theme.dart';
import '../../shared/pixel_widgets.dart';
import 'academic_calendar.dart';
import 'academic_repository.dart';
import 'academic_staff_page.dart';

const academicDestinations = [
  'Registrasi',
  'Pembayaran',
  'KRS',
  'Jadwal Kuliah',
  'Kurikulum',
  'Ekivalensi',
  'Notifikasi',
];

String academicStatus(dynamic status) =>
    const {
      'inactive': 'Belum aktif',
      'active': 'Aktif',
      'leave_pending': 'Cuti menunggu keputusan',
      'leave_approved': 'Cuti disetujui',
      'auto_leave': 'Cuti Otomatis',
      'draft': 'Draf',
      'submitted': 'Diajukan',
      'revision': 'Perlu revisi',
      'approved': 'Disetujui',
      'pending': 'Menunggu pembayaran',
      'review': 'Menunggu verifikasi',
      'expired': 'Kedaluwarsa',
      'failed': 'Gagal',
      'cancelled': 'Dibatalkan',
      'paid': 'Terverifikasi',
      'reconcile': 'Perlu rekonsiliasi',
      'rejected': 'Ditolak',
      'regular': 'Reguler',
      'employee': 'Karyawan',
    }[status] ??
    (status?.toString() ?? 'Belum tersedia');

class AcademicPage extends StatefulWidget {
  const AcademicPage({
    super.key,
    required this.repository,
    this.initialTab = 'Registrasi',
    this.initialPeriod,
    this.onLogout,
  });
  final AcademicRepository repository;
  final String initialTab;
  final String? initialPeriod;
  final VoidCallback? onLogout;
  @override
  State<AcademicPage> createState() => _AcademicPageState();
}

class _AcademicPageState extends State<AcademicPage>
    with WidgetsBindingObserver {
  AcademicSnapshot? _snapshot;
  String? _period, _error;
  late String _tab;
  String _scheduleTab = 'Harian';
  bool _busy = false, _loading = true;
  int _request = 0;
  final _selected = <String>{};
  final _requestKeys = <String, String>{};
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
    _period = widget.initialPeriod;
    WidgetsBinding.instance.addObserver(this);
    _load();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!_busy && !_loading) _load(silent: true);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_busy) _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    final request = ++_request;
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final s = await widget.repository.snapshot(_period);
      if (!mounted || request != _request) return;
      setState(() {
        _snapshot = s;
        _error = null;
        if (!silent) {
          _selected.clear();
          _selected.addAll((s.data['krs_items'] as List? ?? []).cast<String>());
        }
      });
    } catch (e) {
      if (mounted && request == _request) {
        setState(
          () => _error = e is AcademicException
              ? e.message
              : 'Gagal memuat data. Coba lagi.',
        );
      }
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  Future<void> _act(String action, Json data, {String? period}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.repository.command(
        action,
        period ?? _snapshot!.periodId!,
        data,
      );
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is AcademicException
                  ? e.message
                  : 'Hasil belum pasti. Cek status sebelum mengulang.',
            ),
          ),
        );
        await _load(silent: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _text(String title) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLength: 1000,
          minLines: 2,
          maxLines: 5,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().length >= 3) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
    // Dialog route may still be animating; defer disposal until its fields unmount.
    Future<void>.delayed(const Duration(seconds: 1), controller.dispose);
    return result;
  }

  Widget _card(String title, List<Widget> content) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: PixelPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          ...content,
        ],
      ),
    ),
  );
  Widget _button(String label, VoidCallback onTap, {bool enabled = true}) =>
      Padding(
        padding: const EdgeInsets.only(right: 8, bottom: 8),
        child: OutlinedButton(
          onPressed: !_busy && enabled ? onTap : null,
          child: Text(label),
        ),
      );
  Widget _deadline(String id, String title, dynamic due) {
    if (due == null) return const SizedBox.shrink();
    final time = DateTime.parse(due.toString());
    final remaining = time.difference(_snapshot!.now);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(
        '${academicTime(due)}\n${remaining.isNegative || remaining == Duration.zero ? 'Tenggat terlewat' : 'Sisa ${remaining.inDays} hari ${remaining.inHours % 24} jam'}',
      ),
      trailing: remaining > Duration.zero
          ? IconButton(
              tooltip: 'Tambah ke Kalender',
              icon: const Icon(Icons.event_available),
              onPressed: () => _export(
                AcademicCalendarEvent(
                  id: id,
                  title: title,
                  start: time,
                  end: time.add(const Duration(minutes: 15)),
                ),
              ),
            )
          : null,
    );
  }

  Future<void> _export(AcademicCalendarEvent event) async {
    Future<void> validate() async {
      // Revalidate ownership/session and latest relevance before any external export.
      final fresh = await widget.repository.snapshot(_snapshot!.periodId);
      final match = fresh.events.where((e) => e['id'] == event.id).firstOrNull;
      final deadline = [
        'bill-',
        'registration-',
        'first-',
        'krs-',
      ].any(event.id.startsWith);
      if (!deadline && match == null) {
        throw const AcademicException(
          'Acara tidak lagi tersedia untuk akun ini.',
        );
      }
      if (match != null &&
          (match['cancelled'] == true || match['revision'] != event.revision)) {
        throw const AcademicException(
          'Jadwal berubah. Muat ulang sebelum mengekspor.',
        );
      }
      final installment = [
        for (final v in fresh.invoices.where((v) => v['cancelled'] != true))
          ...rows(v['installments']),
      ].where((i) => 'bill-${i['id']}' == event.id).firstOrNull;
      if (event.id.startsWith('bill-') &&
          (installment == null || installment['paid'] == true)) {
        throw const AcademicException(
          'Tagihan selesai atau dibatalkan. Hapus pengingat lama.',
        );
      }
      if ((event.id.startsWith('first-') &&
              fresh.registration['initial_paid_at'] != null) ||
          (event.id.startsWith('krs-') && fresh.krs['status'] == 'approved') ||
          (event.id.startsWith('registration-') &&
              fresh.registration['status'] == 'active') ||
          (deadline &&
              [
                'leave_approved',
                'auto_leave',
                'leave_pending',
              ].contains(fresh.registration['status']))) {
        throw const AcademicException(
          'Tenggat tidak lagi memerlukan tindakan. Hapus salinan kalender lama.',
        );
      }
      if (!event.start.isAfter(fresh.now)) {
        throw const AcademicException('Acara sudah lewat.');
      }
    }

    try {
      await validate();
      if (!mounted) return;
      await addAcademicCalendar(context, event, validate: validate);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is AcademicException
                  ? e.message
                  : 'Kalender tidak dapat dibuka. Coba lagi.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Akademik & Keuangan'),
      actions: [
        if (widget.onLogout != null)
          IconButton(
            tooltip: 'Keluar',
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout),
          ),
        IconButton(
          tooltip: 'Cek status / muat ulang',
          onPressed: _busy ? null : _load,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (_busy || _loading) const LinearProgressIndicator(),
              if (_error != null)
                _card('Data gagal dimuat', [
                  Text(_error!),
                  _button('Coba lagi', _load),
                ]),
              if (!_loading && _error == null && _snapshot != null)
                ..._content(_snapshot!),
            ],
          ),
        ),
      ),
    ),
  );

  List<Widget> _content(AcademicSnapshot s) => [
    if (s.demo)
      _card('SIMULASI — Kurikulum 2026', [
        Text(
          'Tanggal skenario: ${academicTime(s.data['server_now'])}. Pembayaran dan realisasi demo bukan data resmi.',
        ),
      ]),
    if (rows(s.data['periods']).isNotEmpty)
      DropdownButtonFormField<String>(
        isExpanded: true,
        key: ValueKey('period-${s.periodId}'),
        initialValue: s.periodId,
        decoration: const InputDecoration(
          labelText: 'Periode akademik / riwayat',
        ),
        items: [
          for (final p in rows(s.data['periods']))
            DropdownMenuItem(value: p['id'] as String, child: Text(p['label'])),
        ],
        onChanged: _busy
            ? null
            : (p) {
                _period = p;
                _load();
              },
      ),
    const SizedBox(height: 16),
    Text(
      s.stage,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    ),
    if (s.registration.isNotEmpty)
      Text(
        'Semester ${s.registration['semester']} · Angkatan ${s.registration['entry_year']} · ${s.registration['campus']}',
      ),
    const SizedBox(height: 16),
    if (s.registration.isNotEmpty)
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final tab in academicDestinations)
            ChoiceChip(
              label: Text(tab == 'Notifikasi' ? '$tab (${s.unread})' : tab),
              selected: _tab == tab,
              onSelected: (_) => setState(() => _tab = tab),
            ),
        ],
      ),
    const SizedBox(height: 20),
    for (final alert in s.alerts)
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(alert, style: const TextStyle(color: AppTheme.red)),
      ),
    if (s.periodId != null && (s.data['permissions'] as List? ?? []).isNotEmpty)
      _button(
        'Panel petugas berwenang',
        () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => AcademicStaffPage(
              repository: widget.repository,
              period: s.periodId!,
            ),
          ),
        ),
      ),
    if (s.periodId != null && s.registration.isNotEmpty)
      ...switch (_tab) {
        'Registrasi' => _registration(s),
        'Pembayaran' => _payments(s),
        'KRS' => _krs(s),
        'Jadwal Kuliah' => _schedule(s),
        'Kurikulum' => _curriculum(s),
        'Ekivalensi' => [
          _card('Ekivalensi', [
            Text(
              rows(s.data['equivalences']).isEmpty
                  ? 'Belum ada ekivalensi'
                  : rows(s.data['equivalences'])
                        .map(
                          (e) =>
                              '${e['source_course']} → ${e['target_course']}: ${e['decision']}',
                        )
                        .join('\n'),
            ),
          ]),
        ],
        _ => _notifications(s),
      },
  ];

  List<Widget> _registration(AcademicSnapshot s) => [
    _card('Registrasi semester', [
      Text(
        'Jalur: ${academicStatus(s.registration['track'])}\nStatus: ${academicStatus(s.registration['status'])}',
      ),
      if (s.registration['reason'] != null) Text(s.registration['reason']),
      Text('Pembukaan: ${academicTime(s.period['registration_opens'])}'),
      _deadline(
        'registration-${s.periodId}',
        'Tenggat registrasi',
        s.period['registration_closes'],
      ),
      if (s.registration['initial_paid_at'] == null)
        _deadline(
          'first-${s.periodId}',
          'Tenggat pembayaran pertama',
          s.registration['first_due'],
        ),
      const Text(
        'Reguler/Karyawan menentukan tagihan dan penawaran kelas. Cuti memerlukan keputusan petugas; tidak menerbitkan tagihan kuliah baru.',
      ),
      Wrap(
        children: [
          _button(
            'Pilih Reguler',
            () => _act('register', {'track': 'regular'}),
            enabled: s.canRegister && s.registration['initial_paid_at'] == null,
          ),
          _button(
            'Pilih Karyawan',
            () => _act('register', {'track': 'employee'}),
            enabled: s.canRegister && s.registration['initial_paid_at'] == null,
          ),
          _button(
            'Ajukan Cuti',
            () async {
              final reason = await _text('Alasan cuti semester');
              if (reason != null) _act('request_leave', {'reason': reason});
            },
            enabled:
                s.canRegister &&
                s.registration['leave_eligible'] == true &&
                s.registration['initial_paid_at'] == null,
          ),
          _button(
            'Lihat pembayaran',
            () => setState(() => _tab = 'Pembayaran'),
          ),
        ],
      ),
      for (final leave in rows(s.data['leave_requests']))
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(academicStatus(leave['status'])),
          subtitle: Text(
            '${leave['reason']}\n${leave['decision_reason'] ?? 'Menunggu petugas akademik'}',
          ),
        ),
    ]),
  ];

  List<Widget> _payments(AcademicSnapshot s) => [
    _card('Pembayaran simulasi', [
      if (s.data['tuition'] != null)
        Text(
          'Semester ${s.registration['semester']}: Rp${s.data['tuition']['semester_fee']}. '
          'Semester 1–8: Rp17.500.000/semester (total Rp140.000.000). '
          'Semester 9+: Rp10.000.000/semester. Pembagian rata sesuai konfigurasi pengguna; rincian resmi kampus belum tersedia.',
        ),
      const Text(
        'Tidak ada transfer nyata. Biaya kanal Rp0. Bukti BCA menunggu verifikasi petugas. QR demo tidak memindahkan uang.',
      ),
      if (s.registration['initial_paid_at'] == null)
        Wrap(
          children: [
            for (final n in [1, 3, 6])
              _button(
                n == 1 ? 'Bayar penuh 1×' : 'Cicilan $n×',
                () => _previewPlan(n),
                enabled: s.canRegister && s.registration['track'] != null,
              ),
          ],
        ),
      const Text(
        'Pilih skema untuk meninjau nominal dan tenggat sebelum membuat transaksi.',
      ),
    ]),
    if (s.invoices.isEmpty)
      _card('Belum ada tagihan', [
        const Text(
          'Pilih jalur registrasi dan skema bayar saat jendela dibuka.',
        ),
      ]),
    for (final invoice in s.invoices)
      _card(
        '${invoice['cancelled'] == true
            ? 'Dibatalkan'
            : invoice['paid'] == invoice['principal']
            ? 'Lunas'
            : invoice['paid'] > 0
            ? 'Dicicil — masih ada sisa'
            : 'Belum dibayar'} · ${invoice['plan']}×',
        [
          Text(
            'Pokok Rp${invoice['principal']} · Terbayar Rp${invoice['paid']} · Sisa Rp${invoice['principal'] - invoice['paid']}',
          ),
          for (final installment in rows(invoice['installments'])) ...[
            Text(
              'Pembayaran ${installment['ordinal']}: Rp${installment['amount']} · ${installment['paid'] == true
                  ? 'Terverifikasi'
                  : DateTime.parse(installment['due_at']).isAfter(s.now)
                  ? 'Belum dibayar'
                  : 'Tertunggak'}',
            ),
            if (installment['paid'] != true &&
                invoice['cancelled'] != true) ...[
              _deadline(
                'bill-${installment['id']}',
                'Tenggat pembayaran',
                installment['due_at'],
              ),
              Wrap(
                children: [
                  for (final channel in ['qris', 'bca'])
                    _button(
                      'Pilih ${channel.toUpperCase()}',
                      () => _createPayment(s, installment, channel),
                      enabled:
                          ![
                            'auto_leave',
                            'leave_pending',
                            'leave_approved',
                          ].contains(s.registration['status']) &&
                          (channel != 'qris' ||
                              installment['amount'] <= 10000000),
                    ),
                ],
              ),
            ],
            const Divider(),
          ],
        ],
      ),
    for (final p in rows(s.data['payments']))
      _card(
        '${(p['channel'] as String).toUpperCase()} · ${academicStatus(p['status'])}',
        [
          SelectableText(
            'Referensi: ${p['id']}\nNominal: Rp${p['amount']}\nKedaluwarsa: ${academicTime(p['expires_at'])}',
          ),
          if (p['verification_reason'] != null) Text(p['verification_reason']),
          if (p['channel'] == 'bca')
            SelectableText(
              '${s.data['payment_instructions']?['recipient']}\n${s.data['payment_instructions']?['account']}',
            ),
          if (p['qr_payload'] != null && p['status'] == 'pending')
            Center(
              child: Semantics(
                label: 'QR simulasi tidak dapat membayar',
                child: CustomPaint(
                  size: const Size(220, 220),
                  painter: _DemoQr(p['qr_payload']),
                ),
              ),
            ),
          Wrap(
            children: [
              _button('Cek status', _load),
              if (p['channel'] == 'bca' &&
                  ['pending', 'review'].contains(p['status']))
                _button('Kirim referensi bukti', () async {
                  final reference = await _text('Referensi transfer simulasi');
                  if (reference != null) {
                    _act('submit_evidence', {
                      'id': p['id'],
                      'reference': reference,
                    });
                  }
                }),
              if (p['status'] == 'pending')
                _button(
                  'Batalkan transaksi',
                  () => _act('cancel_payment', {'id': p['id']}),
                ),
              if (p['status'] == 'pending' && p['channel'] == 'qris' && s.demo)
                _button(
                  'Simulasikan gagal',
                  () => _act('fail_payment', {'id': p['id']}),
                ),
            ],
          ),
        ],
      ),
  ];

  Future<void> _previewPlan(int count) async {
    if (_busy) return;
    setState(() => _busy = true);
    Json? preview;
    try {
      preview = await widget.repository.command(
        'preview_plan',
        _snapshot!.periodId!,
        {'count': count},
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is AcademicException
                  ? e.message
                  : 'Pratinjau gagal. Coba lagi.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (preview == null || !mounted) return;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tinjau skema $count×'),
        content: SingleChildScrollView(
          child: Text(
            'Pokok Rp${preview!['principal']} · Biaya kanal Rp${preview['fee']}\n'
            '${rows(preview['installments']).map((i) => '${i['ordinal']}. Rp${i['amount']} — ${academicTime(i['due_at'])}').join('\n')}\n'
            'Pembayaran pertama termasuk dalam jumlah cicilan. Tagihan diterbitkan setelah konfirmasi.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Konfirmasi skema'),
          ),
        ],
      ),
    );
    if (accepted == true && mounted) await _act('plan', {'count': count});
  }

  Future<void> _createPayment(
    AcademicSnapshot s,
    Json installment,
    String channel,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi transaksi simulasi'),
        content: Text(
          '${s.period['label']}\nPembayaran ${installment['ordinal']} · ${channel.toUpperCase()}\nPokok Rp${installment['amount']} · Biaya kanal Rp0\nTenggat ${academicTime(installment['due_at'])}\nTidak memindahkan uang.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Buat transaksi'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final key = '${installment['id']}:$channel';
    // Keep idempotency key after network uncertainty; reset only after authoritative final status.
    final current = rows(_snapshot!.data['payments'])
        .where((p) => p['request_key'] == _requestKeys[key])
        .firstOrNull;
    if (current != null && !['pending', 'review'].contains(current['status'])) {
      _requestKeys.remove(key);
    }
    final request = _requestKeys.putIfAbsent(key, () {
      final random = Random.secure();
      final bytes = List.generate(16, (_) => random.nextInt(256));
      bytes[6] = (bytes[6] & 15) | 64;
      bytes[8] = (bytes[8] & 63) | 128;
      final h = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
    });
    await _act('create_payment', {
      'installment_id': installment['id'],
      'channel': channel,
      'request_key': request,
    });
  }

  List<Widget> _krs(AcademicSnapshot s) {
    final courses = {for (final c in rows(s.data['courses'])) c['code']: c};
    final offerings = rows(s.data['offerings']);
    final credits = offerings
        .where((o) => _selected.contains(o['id']))
        .fold<int>(
          0,
          (n, o) => n + (courses[o['course_code']]!['credits'] as int),
        );
    return [
      _card('Kartu Rencana Studi', [
        Text(
          '${academicStatus(s.krs['status'])} · $credits SKS · ${_selected.length} mata kuliah\nBatas demo ${s.period['max_credits']} SKS',
        ),
        if (s.krs['reason'] != null) Text(s.krs['reason']),
        _deadline('krs-${s.periodId}', 'Tenggat KRS', s.period['krs_closes']),
        if (!s.canEditKrs)
          const Text(
            'Perubahan hanya saat semester aktif, pembayaran pertama terverifikasi, dan jendela KRS terbuka. KRS sah tetap dapat dibaca.',
          ),
        if (offerings.isEmpty)
          const Text('Penawaran tersedia setelah pilihan jalur registrasi.'),
        for (final o in offerings)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _selected.contains(o['id']),
            onChanged: s.canEditKrs && !_busy
                ? (value) => setState(() {
                    if (value == true) {
                      _selected.add(o['id']);
                    } else {
                      _selected.remove(o['id']);
                    }
                  })
                : null,
            title: Text(
              '${o['course_code']} · ${courses[o['course_code']]?['name']} · ${courses[o['course_code']]?['credits']} SKS',
            ),
            subtitle: Text(
              '${o['class_code']} · ${o['lecturer']} · ${o['room']}\n${rows(o['slots']).map((slot) => '${_day(slot['weekday'])} ${slot['starts']}–${slot['ends']} (${slot['kind']})').join('\n')}',
            ),
          ),
        Wrap(
          children: [
            _button(
              'Simpan draf',
              () => _act('save_krs', {
                'version': s.krs['version'] ?? 0,
                'offering_ids': _selected.toList(),
              }),
              enabled: s.canEditKrs,
            ),
            _button(
              'Ajukan KRS',
              () => _act('submit_krs', {'version': s.krs['version']}),
              enabled: s.canEditKrs && s.krs.isNotEmpty,
            ),
          ],
        ),
        const Text(
          'Satu mata kuliah agama per kelompok. Jadwal pribadi terbentuk setelah pengesahan validator.',
        ),
      ]),
    ];
  }

  String _day(int day) =>
      ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'][day - 1];
  List<Widget> _schedule(AcademicSnapshot s) {
    final events = s.events;
    final nextClass = events
        .where(
          (e) =>
              e['kind'] == 'class' &&
              e['cancelled'] != true &&
              DateTime.parse(e['ends_at']).isAfter(s.now),
        )
        .firstOrNull;
    final anchor = wib(
      nextClass == null ? s.now : DateTime.parse(nextClass['starts_at']),
    );
    final weekStart = DateTime.utc(
      anchor.year,
      anchor.month,
      anchor.day,
    ).subtract(Duration(days: anchor.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    final weekly = events.where((e) {
      final date = wib(DateTime.parse(e['starts_at']));
      return e['kind'] == 'class' &&
          !date.isBefore(weekStart) &&
          date.isBefore(weekEnd);
    }).toList();
    final visible = events
        .where(
          (e) => _scheduleTab == 'UTS/UAS'
              ? e['kind'] != 'class'
              : _scheduleTab == 'Harian'
              ? e['kind'] == 'class'
              : true,
        )
        .toList();
    return [
      Wrap(
        spacing: 8,
        children: [
          for (final t in ['Mingguan', 'Harian', 'UTS/UAS', 'Kalender'])
            ChoiceChip(
              label: Text(t),
              selected: _scheduleTab == t,
              onSelected: (_) => setState(() => _scheduleTab = t),
            ),
        ],
      ),
      const SizedBox(height: 16),
      if (!s.liveSchedule)
        Text(
          '${s.stage}. Jadwal periode terpilih ditampilkan sebagai rencana/riwayat.',
        ),
      if (events.isEmpty)
        _card(
          _scheduleTab == 'UTS/UAS'
              ? 'Jadwal ujian belum tersedia'
              : 'Belum ada jadwal pribadi',
          [const Text('Jadwal berasal dari KRS yang sudah disahkan.')],
        ),
      if (_scheduleTab == 'Mingguan') ...[
        Text(
          'Pekan ${weekStart.day}/${weekStart.month}/${weekStart.year} · jadwal terbit terbaru',
        ),
        for (var day = 1; day <= 7; day++)
          _card(_day(day), [
            for (final e in weekly.where(
              (e) => wib(DateTime.parse(e['starts_at'])).weekday == day,
            ))
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '${e['course_code']} · ${e['title']} · Pertemuan ${e['meeting']}',
                ),
                subtitle: Text(
                  '${academicTime(e['starts_at'])}–${academicTime(e['ends_at'])}\n${e['class_code']} · ${e['lecturer']}\n${e['room']} · ${e['mode']} ${e['cancelled'] == true ? '· Dibatalkan' : ''}',
                ),
              ),
            if (!weekly.any(
              (e) => wib(DateTime.parse(e['starts_at'])).weekday == day,
            ))
              const Text('Tidak ada kelas pada hari ini.'),
          ]),
      ] else ...[
        if (visible.isEmpty && events.isNotEmpty)
          const Text('Jadwal ujian belum tersedia'),
        for (final e in visible)
          _card(
            '${e['kind'] == 'class' ? 'Pertemuan ${e['meeting']}' : (e['kind'] as String).toUpperCase()} · ${e['title']}',
            [
              Text(
                '${academicTime(e['starts_at'])}–${academicTime(e['ends_at'])}\n${e['class_code']} · ${e['lecturer']}\n${e['room']} · ${e['mode']}',
              ),
              Text(
                e['cancelled'] == true
                    ? 'Dibatalkan'
                    : e['realization'] != null
                    ? 'Realisasi tercatat'
                    : DateTime.parse(e['ends_at']).isBefore(s.now)
                    ? 'Lewat — realisasi belum tercatat'
                    : 'Terjadwal',
              ),
              Text(
                'Rencana: ${e['plan']}\nRealisasi: ${e['realization'] ?? 'Belum tercatat'}',
              ),
              if (e['change_reason'] != null)
                Text('Perubahan: ${e['change_reason']}'),
              if (e['cancelled'] != true &&
                  DateTime.parse(e['starts_at']).isAfter(s.now))
                _button(
                  'Tambah ke Kalender',
                  () => _export(AcademicCalendarEvent.meeting(e)),
                ),
            ],
          ),
      ],
      const Text(
        'Realisasi pertemuan berbeda dari presensi pribadi. Salinan kalender eksternal tidak diperbarui otomatis.',
      ),
    ];
  }

  List<Widget> _curriculum(AcademicSnapshot s) => [
    _card('Kurikulum ${s.registration['curriculum']}', [
      const Text(
        'Acuan struktur: Ekivalensi 2026.pdf. Agama dipilih satu. Paket wajib semester 1: 19 SKS; MKU112 pilihan tidak ditambahkan otomatis.',
      ),
      for (final c in rows(s.data['courses']))
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('${c['code']} · ${c['name']}'),
          subtitle: Text(
            'Semester ${c['semester']} · ${c['credits']} SKS · ${c['required'] == true ? 'Wajib' : 'Pilihan'}${c['alternative_group'] == 'agama' ? ' · alternatif agama' : ''}',
          ),
        ),
    ]),
  ];

  List<Widget> _notifications(AcademicSnapshot s) => [
    if (s.notifications.isEmpty) const Text('Belum ada notifikasi'),
    for (final n in s.notifications)
      _card('${n['read_at'] == null ? 'Belum dibaca · ' : ''}${n['title']}', [
        Text('${academicTime(n['created_at'])}\n${n['body']}'),
        Wrap(
          children: [
            _button('Buka ${n['target']}', () async {
              await _act('read_notification', {
                'id': n['id'],
              }, period: n['period_id']);
              if (!mounted) return;
              setState(() {
                _tab = academicDestinations.contains(n['target'])
                    ? n['target']
                    : 'Registrasi';
                _period = n['period_id'];
              });
              await _load();
            }),
            if (n['read_at'] == null)
              _button(
                'Tandai dibaca',
                () => _act('read_notification', {
                  'id': n['id'],
                }, period: n['period_id']),
              ),
          ],
        ),
      ]),
  ];
}

class _DemoQr extends CustomPainter {
  _DemoQr(String payload)
    : code = QrImage(
        QrCode.fromData(
          data: payload,
          errorCorrectLevel: QrErrorCorrectLevel.M,
        ),
      );
  final QrImage code;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    final unit = size.shortestSide / (code.moduleCount + 8);
    final paint = Paint()..color = Colors.black;
    for (var y = 0; y < code.moduleCount; y++) {
      for (var x = 0; x < code.moduleCount; x++) {
        if (code.isDark(y, x)) {
          canvas.drawRect(
            Rect.fromLTWH((x + 4) * unit, (y + 4) * unit, unit, unit),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DemoQr oldDelegate) => oldDelegate.code != code;
}
