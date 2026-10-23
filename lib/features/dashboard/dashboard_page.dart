// Pengatur utama beranda: mengambil data, menata panel, dan menangani navigasi.
// Data berasal dari repository; tampilan panelnya dipisah ke berkas-berkas lain.
// Alur baca: initState -> _load -> _content -> panel, lalu fungsi aksi untuk ketukan.
// Widget adalah konfigurasi layar; State menyimpan kondisi yang berubah saat dipakai.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_motion.dart';
import '../../core/app_theme.dart';
import '../../core/responsive_layout.dart';
import '../../data/dashboard_models.dart';
import '../../data/dashboard_repository.dart';
import '../../data/student_profile.dart';
import '../../shared/pixel_widgets.dart';
import '../chatbot/chat_controller.dart';
import '../chatbot/chat_launcher.dart';
import '../leave/leave_page.dart';
import '../leave/leave_repository.dart';
import 'dashboard_detail_page.dart';
import 'dashboard_widgets.dart';
import 'executive_menu.dart';
import 'information_panels.dart';
import 'profile_panel.dart';
import 'study_progress_panel.dart';

/// Kerangka beranda. Repository boleh diganti tanpa mengubah tampilan.
// Halaman utama yang menerima profil, sumber data, dan aksi logout dari induknya.
class DashboardPage extends StatefulWidget {
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
  const DashboardPage({
    super.key,
    required this.student,
    required this.onLogout,
    this.repository = const EmptyDashboardRepository(),
    this.clock,
    this.leaveRepository,
  });
  // Profil awal dari login; bisa dilengkapi oleh profil dari hasil repository.
  final StudentProfile student;
  // Fungsi tanpa hasil yang diberikan induk untuk mengakhiri sesi dan kembali ke login.
  final VoidCallback onLogout;
  // Penyedia data beranda; dapat diganti oleh API atau sumber khusus pengujian.
  final DashboardRepository repository;
  // Clock dapat disuntikkan oleh test agar tanggal/status kelas dapat diuji.
  // Jam opsional; jika tidak diberikan, halaman membaca waktu perangkat.
  final DateTime Function()? clock;
  final LeaveRepository? leaveRepository;
  @override
  // Hubungkan konfigurasi widget dengan objek State yang menyimpan perubahan selama tampil.
  State<DashboardPage> createState() => _DashboardPageState();
}

// Pusat penyimpanan kondisi pemuatan, data, waktu, dan menu yang sedang aktif.
class _DashboardPageState extends State<DashboardPage> {
  // Chat dan draf bertahan saat kembali ke beranda, lalu dibersihkan ketika logout.
  final _chat = ChatController();
  late final LeaveRepository _leaves;
  // Kunci-kunci berikut menjadi penanda lokasi panel untuk tujuan gulir otomatis.
  final _profileKey = GlobalKey();
  final _scheduleKey = GlobalKey();
  final _academicKey = GlobalKey();
  // Pengendali posisi gulir untuk scrollbar dan perintah kembali ke bagian atas.
  final _scroll = ScrollController();
  // Paket data yang sedang ditampilkan; awalnya kosong sambil menunggu pemuatan.
  DashboardData _data = const DashboardData();
  // true menampilkan indikator pemuatan dan menonaktifkan tombol muat ulang.
  bool _loading = true;
  // Pesan pemuatan gagal; null berarti belum ada kesalahan yang perlu ditampilkan.
  String? _error;
  // Nomor menu yang aktif: 0 beranda, 1 jadwal, 2 akademik, 3 profil.
  int _navIndex = 0;
  // Nomor urut permintaan untuk mencegah respons lama menimpa hasil permintaan terbaru.
  int _requestId = 0;
  // Pembaruan berkala agar tanggal dan status kelas mengikuti waktu berjalan.
  Timer? _clockTimer;
  // Waktu acuan tampilan; diisi saat halaman pertama kali dibuat.
  late DateTime _now;

  @override
  // Saat halaman muncul pertama kali, baca jam, muat data, dan mulai pembaruan per menit.
  void initState() {
    super.initState();
    _leaves =
        widget.leaveRepository ??
        LeaveRepository(session: () => widget.student);
    _chat.openLeave = _openLeave;
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
  // Jika induk mengganti sumber data atau NIM, ambil ulang data untuk konfigurasi baru.
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
    // Tambah nomor permintaan lalu simpan salinannya untuk memeriksa respons nanti.
    final request = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Tunggu paket data sesuai NIM; layar tetap dapat menampilkan indikator loading.
      final result = await widget.repository.load(widget.student.nim);
      // Abaikan hasil jika halaman sudah ditutup atau sudah ada permintaan yang lebih baru.
      if (!mounted || request != _requestId) {
        return;
      }
      setState(() {
        // Simpan hasil dan hentikan loading dalam setState agar panel diperbarui.
        _data = result;
        _loading = false;
      });
    } catch (_) {
      // Jika sumber data gagal, tampilkan kesalahan yang bisa dicoba ulang.
      // Abaikan hasil jika halaman sudah ditutup atau sudah ada permintaan yang lebih baru.
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
  // Hentikan jam berkala dan lepaskan pengendali gulir saat beranda ditutup.
  void dispose() {
    _chat.dispose();
    if (widget.leaveRepository == null) _leaves.dispose();
    _clockTimer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  /// Navigasi pada beranda menggulir ke bagian yang bersangkutan.
  void _navigate(int index) {
    setState(() => _navIndex = index);
    // Menu Beranda menggulir ke paling atas; menu lain mencari panel tujuannya.
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

  // Bawa panel dengan kunci tertentu ke area layar yang terlihat.
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

  // Tampilkan satu pesan singkat; hapus pesan lama agar pemberitahuan tidak menumpuk.
  void _message(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  /// Halaman ringkas untuk membaca daftar lengkap/detail.
  /// Fitur transaksi seperti KRS/pembayaran belum dilaksanakan pada tahap beranda.
  void _details(String title, Widget child) {
    Navigator.of(context).push(
      AppMotion.route(
        DashboardDetailPage(title: title, chat: _chat, child: child),
      ),
    );
  }

  // Buka penjelasan bahwa modul ini belum terhubung, tanpa menjalankan transaksi.
  void _unavailable(String title) =>
      Navigator.of(context)
          .push(AppMotion.route(DashboardDetailPage.empty(title, chat: _chat)));

  // Buka tanggal dan isi lengkap satu berita/pengumuman; teks isi bisa disalin.
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

  // Buka seluruh daftar informasi atau pesan kosong jika daftar belum tersedia.
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

  // Tampilkan seluruh jadwal berurutan, termasuk yang bukan hari ini.
  void _allSchedules() {
    // Buat salinan daftar agar pengurutan halaman detail tidak mengubah data asal.
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

  // Buka rincian satu kuliah dengan tanggal dan kartu informasi kelas.
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

  // Akses Cepat dan Executive Menu memakai tujuan yang sama.
  // Modul yang belum siap, termasuk Biodata, Nilai & Presensi, dan Konseling,
  // membuka halaman kosong tersendiri, bukan menggulir ke panel beranda.
  void _quickAction(String label) {
    switch (label) {
      case 'Izin Online':
        _openLeave();
      case 'Smart Chatbot':
        openSmartChat(context, _chat);
      case 'Jadwal Kuliah':
        _allSchedules();
      default:
        _unavailable(label);
    }
  }

  void _openLeave() =>
      Navigator.of(context)
          .push(AppMotion.route(LeavePage(repository: _leaves, chat: _chat)));

  @override
  // build menyusun tampilan ketika Flutter memintanya.
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      // Tablet memakai menu header dan seluruh lebar halaman untuk konten.
      final desktop = bounds.maxWidth >= ResponsiveLayout.desktop;
      final compact = bounds.maxWidth < ResponsiveLayout.tablet;
      final pagePadding = (bounds.maxWidth * .025).clamp(16.0, 24.0);
      // Deteksi teks yang diperbesar agar header dapat memberi ruang lebih banyak.
      final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
      return Scaffold(
        floatingActionButton: ChatLauncher(controller: _chat),
        // Bagian paling atas berisi identitas aplikasi dan tombol navigasi.
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
              // Sembunyikan logo kecil ketika tulisan diperbesar agar judul tetap muat.
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
              // Di layar lebar, letakkan menu utama langsung di bagian atas.
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
                          () => _quickAction('Biodata'),
                        ),
                        _topMenu(
                          'Pembayaran',
                          Icons.account_balance_outlined,
                          () => _unavailable('Pembayaran'),
                        ),
                        // Tiga kelompok menu berbagi daftar dengan versi HP.
                        ExecutiveDesktopMenu(onSelected: _quickAction),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            IconButton(
              // Tombol refresh mengambil ulang data dan dikunci selama proses masih berjalan.
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
        // Menu geser untuk akses yang ringkas pada layar sempit.
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
                // Akses utama tetap langsung; pilihan akademik dikelompokkan di bawah.
                for (final entry in _quickEntries.where(
                  (entry) => [
                    'Biodata',
                    'Pembayaran',
                    'Tagihan',
                  ].contains(entry.label),
                ))
                  ListTile(
                    leading: Icon(entry.icon),
                    title: Text(entry.label),
                    onTap: () {
                      Navigator.pop(context);
                      _quickAction(entry.label);
                    },
                  ),
                // Tutup menu geser sebelum menjalankan navigasi halaman induk.
                ExecutiveMobileMenu(
                  onSelected: (destination) {
                    Navigator.pop(context);
                    _quickAction(destination);
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
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Latar memenuhi halaman tanpa menyisakan jalur kosong di kiri.
            const RepaintBoundary(child: CampusBackground(dashboard: true)),
            SafeArea(
              top: false,
              // Gerakan tarik ke bawah tetap memuat ulang data beranda.
              child: RefreshIndicator(
                onRefresh: _load,
                child: Scrollbar(
                  controller: _scroll,
                  thumbVisibility: !compact,
                  child: SingleChildScrollView(
                    controller: _scroll,
                    physics: const AlwaysScrollableScrollPhysics(),
                    // Jarak tepi bertambah perlahan mengikuti lebar, bukan meloncat.
                    padding: EdgeInsets.all(pagePadding),
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
        // Pada layar kecil, empat menu utama dipasang di bawah agar mudah disentuh.
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

  // Buat satu tombol menu atas dengan ikon dan tulisan.
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

  // Navigasi bawah hanya dipakai HP; tablet mengakses menu melalui header.
  Widget _navButton(int index) {
    final entry = _destinations[index];
    final selected = _navIndex == index;
    // Berikan informasi tombol dan pilihan aktif kepada pembaca layar.
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: () => _navigate(index),
        child: AnimatedContainer(
          duration: AppMotion.duration(context, 180),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
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

  // Susun isi utama berdasarkan keadaan memuat, gagal, atau berhasil mendapatkan data.
  Widget _content() {
    // Pilih profil repository bila tersedia; jika tidak, tetap tampilkan NIM dari login.
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
        // Tampilkan penanda tunggu supaya pengguna tahu pemuatan belum selesai.
        if (_loading) ...[
          const LinearProgressIndicator(minHeight: 3),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Memuat beranda…'),
          ),
        ],
        // Kesalahan punya kotak dan tombol coba lagi tersendiri, berbeda dari data kosong.
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
        // Ruang ekstra di akhir beranda agar tombol chat tidak menutupi footer.
        const SizedBox(height: 88),
      ],
    );
  }

  // Ringkas kelas yang sedang berlangsung atau yang akan dimulai berikutnya.
  Widget _agendaBanner() {
    final next = activeOrNextClass(_data.classes, _now);
    // Kelas pilihan belum berakhir; jika waktu mulai sudah lewat, kelas sedang berlangsung.
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

  // Susun tombol akses cepat dalam jumlah kolom yang mengikuti lebar dan ukuran tulisan.
  Widget _quickGrid() => LayoutBuilder(
    builder: (context, bounds) {
      final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
      final columns = scale >= 1.8 && bounds.maxWidth < 430
          ? 1
          : ResponsiveLayout.quickColumns(bounds.maxWidth / scale);
      // Kurangi ruang antar kolom, lalu bagi sisa lebar secara merata.
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

  // Siapkan isi panel satu kali, lalu pilih susunan desktop, tablet, atau satu kolom.
  Widget _responsivePanels() => LayoutBuilder(
    builder: (context, bounds) {
      // Panel jadwal menerima kelas hari ini serta kelas terdekat untuk informasi tambahan.
      final schedule = SchedulePanel(
        key: _scheduleKey,
        items: todayClasses(_data.classes, _now),
        now: _now,
        next: activeOrNextClass(_data.classes, _now),
        onAll: _allSchedules,
        onOpen: _classDetails,
      );
      final study = StudyProgressPanel(key: _academicKey, data: _data);
      // Aksi pengajuan masih memberi pesan; belum mengirim permintaan konseling ke server.
      final counseling = CounselingPanel(
        items: _data.counseling,
        onApply: () => _message(
          _data.counseling.isEmpty ? 'Jadwal konseling belum tersedia.' : 'Pengajuan konseling akan disambungkan ke backend pada tahap berikutnya.',
        ),
      );
      // Pengumuman dan berita memakai komponen yang sama dengan data/judul berbeda.
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
      // Ketukan panduan membuka teks isinya dalam halaman detail.
      final guides = GuidesPanel(
        items: _data.guides,
        onOpen: (guide) => _details(guide.title, SelectableText(guide.content)),
      );
      final scale = MediaQuery.textScalerOf(context).scale(1);
      // Susunan 7:3 memerlukan ruang cukup agar panel kanan tidak terlalu sempit.
      // Tablet lebar tetap memakai dua kolom seimbang pada bagian informasi.
      if (bounds.maxWidth >= 1100 && scale <= 1.3) {
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

  // Susun daftar panel ke bawah dengan jarak 24 hanya di antara panel.
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

// Satu paket kecil berisi tulisan menu, ikon, dan warna tampilannya.
class _MenuEntry {
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
  const _MenuEntry(this.label, this.icon, [this.color = AppTheme.blue]);
  final String label;
  final IconData icon;
  final Color color;
}

// Daftar nama, ikon, dan warna akses cepat juga dipakai untuk membentuk menu geser.
const _quickEntries = [
  _MenuEntry('Smart Chatbot', Icons.smart_toy_outlined, Color(0xFF873DD1)),
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
  _MenuEntry('Biodata', Icons.person_outline, Color(0xFF873DD1)),
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
  _MenuEntry('KRS', Icons.edit_note, Color(0xFFED7D21)),
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
  _MenuEntry('Jadwal Kuliah', Icons.calendar_month_outlined),
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
  _MenuEntry('Nilai & Presensi', Icons.bar_chart_outlined),
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
  _MenuEntry('Tagihan', Icons.receipt_long_outlined, Color(0xFFBB851E)),
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
  _MenuEntry('Pembayaran', Icons.account_balance_outlined, Color(0xFFBB851E)),
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
  _MenuEntry('Konseling', Icons.handshake_outlined, Color(0xFF198754)),
  _MenuEntry('Izin Online', Icons.description_outlined, Color(0xFF198754)),
];
// Urutan ini harus sejalan dengan nomor menu yang ditangani _navigate.
const _destinations = [
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
  _MenuEntry('Beranda', Icons.home_outlined),
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
  _MenuEntry('Jadwal', Icons.calendar_month_outlined),
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
  _MenuEntry('Akademik', Icons.school_outlined),
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
  _MenuEntry('Profil', Icons.person_outline),
];
