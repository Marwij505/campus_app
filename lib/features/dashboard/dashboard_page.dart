import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_motion.dart';
import '../../core/app_theme.dart';
import '../../core/responsive_layout.dart';
import '../../data/dashboard_models.dart';
import '../../data/dashboard_repository.dart';
import '../../data/student_profile.dart';
import '../../shared/pixel_widgets.dart';
import 'dashboard_widgets.dart';
import 'information_panels.dart';
import 'profile_panel.dart';
import 'study_progress_panel.dart';

/// Kerangka beranda. Repository boleh diganti tanpa mengubah tampilan.
class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    required this.student,
    required this.onLogout,
    this.repository = const EmptyDashboardRepository(),
    this.clock,
  });
  final StudentProfile student;
  final VoidCallback onLogout;
  final DashboardRepository repository;
  // Clock dapat disuntikkan oleh test agar tanggal/status kelas dapat diuji.
  final DateTime Function()? clock;
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _profileKey = GlobalKey();
  final _scheduleKey = GlobalKey();
  final _academicKey = GlobalKey();
  final _counselingKey = GlobalKey();
  final _scroll = ScrollController();
  DashboardData _data = const DashboardData();
  bool _loading = true;
  String? _error;
  int _navIndex = 0;
  int _requestId = 0;
  Timer? _clockTimer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = (widget.clock ?? DateTime.now)().toLocal();
    _load();
    // Timer hanya mengubah status/tanggal setiap menit, bukan setiap frame.
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() => _now = (widget.clock ?? DateTime.now)().toLocal());
      }
    });
  }

  @override
  void didUpdateWidget(covariant DashboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository ||
        oldWidget.student.nim != widget.student.nim) {
      _load();
    }
  }

  /// Respons permintaan lama diabaikan bila permintaan baru sudah dimulai.
  /// Kesalahan ditampilkan terpisah, tidak diubah menjadi data kosong.
  Future<void> _load() async {
    final request = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.repository.load(widget.student.nim);
      if (!mounted || request != _requestId) {
        return;
      }
      setState(() {
        _data = result;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || request != _requestId) {
        return;
      }
      setState(() {
        _error = 'Data beranda gagal dimuat. Silakan coba lagi.';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  /// Navigasi pada beranda menggulir ke bagian yang bersangkutan.
  void _navigate(int index) {
    setState(() => _navIndex = index);
    if (index == 0) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          0,
          duration: AppMotion.duration(context, 420),
          curve: Curves.easeInOutCubic,
        );
      }
      return;
    }
    final key = [_profileKey, _scheduleKey, _academicKey, _profileKey][index];
    _showSection(key);
  }

  void _showSection(GlobalKey key) {
    final target = key.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: AppMotion.duration(context, 420),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _message(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  /// Halaman ringkas untuk membaca daftar lengkap/detail.
  /// Fitur transaksi seperti KRS/pembayaran belum dilaksanakan pada tahap beranda.
  void _details(String title, Widget child) {
    Navigator.of(context)
        .push(AppMotion.route(_DashboardDetail(title: title, child: child)));
  }

  void _unavailable(String title) => _details(
    title,
    DashboardEmpty(
      title: 'Belum ada data $title',
      message:
          'Halaman $title lengkap akan disambungkan pada tahap berikutnya.',
    ),
  );

  void _openNotice(CampusNotice item) => _details(
    item.title,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          campusDate(item.publishedAt.toLocal()),
          style: const TextStyle(color: AppTheme.muted),
        ),
        const SizedBox(height: 16),
        SelectableText(item.body),
      ],
    ),
  );

  void _allNotices(String title, List<CampusNotice> items) => _details(
    title,
    items.isEmpty
        ? DashboardEmpty(title: 'Belum ada ${title.toLowerCase()}')
        : Column(
            children: [
              for (final item in items)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.title),
                  subtitle: Text(campusDate(item.publishedAt.toLocal())),
                  onTap: () => _openNotice(item),
                ),
            ],
          ),
  );

  void _allSchedules() {
    final items = [..._data.classes]
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    _details(
      'Jadwal Kuliah',
      items.isEmpty
          ? const DashboardEmpty(
              title: 'Belum ada jadwal kuliah',
              icon: Icons.calendar_month_outlined,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final item in items) ...[
                  Text(campusDate(item.startsAt.toLocal())),
                  const SizedBox(height: 8),
                  ClassScheduleCard(
                    item: item,
                    now: _now,
                    onTap: () => _classDetails(item),
                  ),
                ],
              ],
            ),
    );
  }

  void _classDetails(ClassSchedule item) => _details(
    'Detail Kuliah',
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(campusDate(item.startsAt.toLocal())),
        const SizedBox(height: 12),
        ClassScheduleCard(item: item, now: _now, onTap: () {}),
      ],
    ),
  );

  void _quickAction(String label) {
    switch (label) {
      case 'Biodata':
        _navigate(3);
      case 'Jadwal Kuliah':
        _allSchedules();
      case 'Nilai & Presensi':
        _navigate(2);
      case 'Konseling':
        _showSection(_counselingKey);
      default:
        _unavailable(label);
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final desktop = bounds.maxWidth >= ResponsiveLayout.desktop;
      final tablet = bounds.maxWidth >= ResponsiveLayout.tablet && !desktop;
      final compact = !tablet && !desktop;
      final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppTheme.red,
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          elevation: 0,
          toolbarHeight: 72,
          automaticallyImplyLeading: false,
          titleSpacing: 12,
          title: Row(
            children: [
              if (!largeText) ...[
                const FacultyMark(compact: true),
                const SizedBox(width: 10),
              ],
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SIAKAD',
                    style: AppTheme.pixel(11, color: Colors.white),
                  ),
                  const Text(
                    'FASILKOM',
                    style: TextStyle(fontSize: 9, color: Color(0xFFFFD6BD)),
                  ),
                ],
              ),
              if (desktop) ...[
                const SizedBox(width: 22),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _topMenu(
                          'Beranda',
                          Icons.home_outlined,
                          () => _navigate(0),
                        ),
                        _topMenu(
                          'Biodata',
                          Icons.person_outline,
                          () => _navigate(3),
                        ),
                        _topMenu(
                          'Pembayaran',
                          Icons.account_balance_outlined,
                          () => _unavailable('Pembayaran'),
                        ),
                        PopupMenuButton<String>(
                          tooltip: 'Menu Akademik',
                          onSelected: (label) => _quickAction(label),
                          itemBuilder: (context) => [
                            for (final label in [
                              'KRS',
                              'Jadwal Kuliah',
                              'Nilai & Presensi',
                            ])
                              PopupMenuItem(value: label, child: Text(label)),
                          ],
                          child: const Padding(
                            padding: EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Text(
                                  'Akademik',
                                  style: TextStyle(fontSize: 11),
                                ),
                                Icon(Icons.arrow_drop_down, size: 18),
                              ],
                            ),
                          ),
                        ),
                        _topMenu(
                          'Tugas Akhir',
                          Icons.school_outlined,
                          () => _unavailable('Tugas Akhir'),
                        ),
                        _topMenu(
                          'Layanan',
                          Icons.support_agent,
                          () => _showSection(_counselingKey),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Muat ulang beranda',
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh, size: 21),
            ),
            if (!desktop)
              Builder(
                builder: (context) => IconButton(
                  tooltip: 'Buka menu',
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  icon: const Icon(Icons.menu),
                ),
              ),
            IconButton(
              tooltip: 'Keluar',
              onPressed: widget.onLogout,
              icon: const Icon(Icons.logout, size: 21),
            ),
            const SizedBox(width: 4),
          ],
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(4),
            child: ColoredBox(
              color: AppTheme.ink,
              child: SizedBox(height: 4, width: double.infinity),
            ),
          ),
        ),
        drawer: Drawer(
          child: SafeArea(
            child: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Text('MENU SIAKAD', style: AppTheme.pixel(11)),
                ),
                ListTile(
                  leading: const Icon(Icons.home_outlined),
                  title: const Text('Beranda'),
                  onTap: () {
                    Navigator.pop(context);
                    _navigate(0);
                  },
                ),
                for (final entry in _quickEntries)
                  ListTile(
                    leading: Icon(entry.icon),
                    title: Text(entry.label),
                    onTap: () {
                      Navigator.pop(context);
                      _quickAction(entry.label);
                    },
                  ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Keluar'),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onLogout();
                  },
                ),
              ],
            ),
          ),
        ),
        body: Row(
          children: [
            if (tablet)
              Container(
                key: const ValueKey('tablet-navigation'),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    right: BorderSide(color: AppTheme.ink, width: 2),
                  ),
                ),
                // Navigasi tetap bisa digulir ketika tinggi jendela kecil.
                width: 88,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (var i = 0; i < _destinations.length; i++)
                        _navButton(i, rail: true),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const RepaintBoundary(
                    child: CampusBackground(dashboard: true),
                  ),
                  SafeArea(
                    top: false,
                    child: RefreshIndicator(
                      onRefresh: _load,
                      child: Scrollbar(
                        controller: _scroll,
                        thumbVisibility: !compact,
                        child: SingleChildScrollView(
                          controller: _scroll,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.all(compact ? 16 : 24),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: ResponsiveLayout.maxContentWidth,
                              ),
                              child: _content(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: compact
            ? Material(
                color: Colors.white,
                child: SafeArea(
                  top: false,
                  child: Container(
                    key: const ValueKey('phone-navigation'),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppTheme.ink, width: 3),
                      ),
                    ),
                    child: Row(
                      children: [
                        for (var i = 0; i < _destinations.length; i++)
                          Expanded(child: _navButton(i)),
                      ],
                    ),
                  ),
                ),
              )
            : null,
      );
    },
  );

  Widget _topMenu(String label, IconData icon, VoidCallback onTap) =>
      TextButton.icon(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 48),
          shape: const RoundedRectangleBorder(),
        ),
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontSize: 11)),
      );

  Widget _navButton(int index, {bool rail = false}) {
    final entry = _destinations[index];
    final selected = _navIndex == index;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: () => _navigate(index),
        child: AnimatedContainer(
          duration: AppMotion.duration(context, 180),
          padding: EdgeInsets.symmetric(
            vertical: rail ? 20 : 12,
            horizontal: 4,
          ),
          color: selected ? const Color(0xFFEAF2FC) : Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                entry.icon,
                size: 23,
                color: selected ? AppTheme.blue : AppTheme.muted,
              ),
              const SizedBox(height: 6),
              Text(
                entry.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? AppTheme.blue : AppTheme.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content() {
    final profile = _data.student ?? widget.student;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('SELAMAT DATANG', style: AppTheme.pixel(9, color: AppTheme.blue)),
        const SizedBox(height: 8),
        const Text(
          'Ruang akademikmu, dalam satu beranda.',
          style: TextStyle(fontSize: 11, color: AppTheme.muted),
        ),
        const SizedBox(height: 20),
        if (_loading) ...[
          const LinearProgressIndicator(minHeight: 3),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Memuat beranda…'),
          ),
        ],
        if (_error != null) ...[
          PixelPanel(
            color: const Color(0xFFFFF0F0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_error!),
                const SizedBox(height: 10),
                DashboardAction('Coba lagi', _load),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        // Peringatan tagihan hanya tampil jika backend benar-benar memberi jumlahnya.
        if (!_loading &&
            _error == null &&
            (_data.outstandingBillCount ?? 0) > 0) ...[
          PixelPanel(
            color: const Color(0xFFFFF0F0),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Icon(Icons.receipt_long, color: AppTheme.red),
                Text(
                  'Ada ${_data.outstandingBillCount} tagihan belum dibayar.',
                ),
                DashboardAction('Lihat tagihan', () => _unavailable('Tagihan')),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (!_loading && _error == null) ...[
          _agendaBanner(),
          const SizedBox(height: 20),
        ],
        Entrance(
          child: ProfilePanel(key: _profileKey, student: profile),
        ),
        const SizedBox(height: 24),
        Text('AKSES CEPAT', style: AppTheme.pixel(9, color: AppTheme.blue)),
        const SizedBox(height: 14),
        Entrance(delay: 60, child: _quickGrid()),
        const SizedBox(height: 24),
        // Sembunyikan panel data saat gagal memuat, agar tidak menyesatkan pengguna.
        if (!_loading && _error == null) _responsivePanels(),
        const SizedBox(height: 28),
        const Text(
          'CAMPUS APP · SIAKAD FASILKOM',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10, color: AppTheme.muted),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _agendaBanner() {
    final next = activeOrNextClass(_data.classes, _now);
    final ongoing = next != null && !next.startsAt.isAfter(_now);
    return PixelPanel(
      color: const Color(0xFFF2F8FF),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            next == null ? Icons.event_note_outlined : Icons.school_outlined,
            color: AppTheme.blue,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  next == null
                      ? 'Belum ada informasi kuliah terdekat'
                      : ongoing
                      ? 'Kuliah sedang berlangsung'
                      : 'Kuliah berikutnya',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  next == null
                      ? 'Informasi akan muncul setelah jadwal tersedia.'
                      : '${next.code} · ${next.title}\n${campusDate(next.startsAt.toLocal())} · ${campusTime(next.startsAt)} – ${campusTime(next.endsAt)}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.muted),
                ),
                if (next != null) ...[
                  const SizedBox(height: 12),
                  DashboardAction('Lihat detail', () => _classDetails(next)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickGrid() => LayoutBuilder(
    builder: (context, bounds) {
      final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
      final columns = scale >= 1.8 && bounds.maxWidth < 430
          ? 1
          : ResponsiveLayout.quickColumns(bounds.maxWidth / scale);
      final width = (bounds.maxWidth - (columns - 1) * 12) / columns;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final entry in _quickEntries)
            SizedBox(
              width: width,
              child: PixelTapSurface(
                label: entry.label,
                onTap: () => _quickAction(entry.label),
                borderColor: AppTheme.ink,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 16,
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      color: entry.color.withValues(alpha: .1),
                      child: Icon(entry.icon, color: entry.color, size: 26),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      entry.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    },
  );

  Widget _responsivePanels() => LayoutBuilder(
    builder: (context, bounds) {
      final schedule = SchedulePanel(
        key: _scheduleKey,
        items: todayClasses(_data.classes, _now),
        now: _now,
        next: activeOrNextClass(_data.classes, _now),
        onAll: _allSchedules,
        onOpen: _classDetails,
      );
      final study = StudyProgressPanel(key: _academicKey, data: _data);
      final counseling = CounselingPanel(
        key: _counselingKey,
        items: _data.counseling,
        onApply: () => _message(
          _data.counseling.isEmpty ? 'Jadwal konseling belum tersedia.' : 'Pengajuan konseling akan disambungkan ke backend pada tahap berikutnya.',
        ),
      );
      final announcements = NoticePanel(
        title: 'PENGUMUMAN',
        emptyTitle: 'Belum ada pengumuman',
        items: _data.announcements,
        icon: Icons.campaign_outlined,
        onOpen: _openNotice,
        onAll: () => _allNotices('Pengumuman', _data.announcements),
      );
      final news = NoticePanel(
        title: 'BERITA',
        emptyTitle: 'Belum ada berita',
        items: _data.news,
        icon: Icons.newspaper_outlined,
        onOpen: _openNotice,
        onAll: () => _allNotices('Berita', _data.news),
      );
      final guides = GuidesPanel(
        items: _data.guides,
        onOpen: (guide) => _details(guide.title, SelectableText(guide.content)),
      );
      final scale = MediaQuery.textScalerOf(context).scale(1);
      // Dua kolom utama mengikuti referensi desktop. Panel kanan tetap cukup lebar.
      if (bounds.maxWidth >= 1000 && scale <= 1.3) {
        return Row(
          key: const ValueKey('desktop-panels'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 7, child: _stack([study, counseling])),
            const SizedBox(width: 24),
            Expanded(
              flex: 3,
              child: _stack([schedule, announcements, news, guides]),
            ),
          ],
        );
      }
      // Tablet memakai grid informasi; grafik memakai lebar utama agar terbaca.
      if (bounds.maxWidth >= 680 && scale <= 1.3) {
        return Column(
          key: const ValueKey('tablet-panels'),
          children: [
            ResponsiveCards(
              minWidth: 300,
              maximum: 2,
              children: [schedule, announcements, news, guides],
            ),
            const SizedBox(height: 24),
            study,
            const SizedBox(height: 24),
            counseling,
          ],
        );
      }
      return _stack([
        schedule,
        announcements,
        news,
        guides,
        study,
        counseling,
      ], key: const ValueKey('phone-panels'));
    },
  );

  Widget _stack(List<Widget> items, {Key? key}) => Column(
    key: key,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < items.length; i++) ...[
        if (i > 0) const SizedBox(height: 24),
        items[i],
      ],
    ],
  );
}

/// Halaman detail memakai kerangka yang sama, batas lebar, dan tombol Back standar.
class _DashboardDetail extends StatelessWidget {
  const _DashboardDetail({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(title, style: const TextStyle(fontSize: 14)),
      backgroundColor: AppTheme.red,
      foregroundColor: Colors.white,
    ),
    body: Stack(
      fit: StackFit.expand,
      children: [
        const CampusBackground(dashboard: true),
        SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Entrance(child: PixelPanel(child: child)),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _MenuEntry {
  const _MenuEntry(this.label, this.icon, [this.color = AppTheme.blue]);
  final String label;
  final IconData icon;
  final Color color;
}

const _quickEntries = [
  _MenuEntry('Biodata', Icons.person_outline, Color(0xFF873DD1)),
  _MenuEntry('KRS', Icons.edit_note, Color(0xFFED7D21)),
  _MenuEntry('Jadwal Kuliah', Icons.calendar_month_outlined),
  _MenuEntry('Nilai & Presensi', Icons.bar_chart_outlined),
  _MenuEntry('Tagihan', Icons.receipt_long_outlined, Color(0xFFBB851E)),
  _MenuEntry('Pembayaran', Icons.account_balance_outlined, Color(0xFFBB851E)),
  _MenuEntry('Konseling', Icons.handshake_outlined, Color(0xFF198754)),
];
const _destinations = [
  _MenuEntry('Beranda', Icons.home_outlined),
  _MenuEntry('Jadwal', Icons.calendar_month_outlined),
  _MenuEntry('Akademik', Icons.school_outlined),
  _MenuEntry('Profil', Icons.person_outline),
];
