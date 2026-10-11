import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/app_motion.dart';
import '../../core/app_theme.dart';
import '../../data/demo_data.dart';
import '../../shared/pixel_widgets.dart';
import 'academic_charts.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    required this.student,
    required this.onLogout,
  });

  final StudentProfile student;
  final VoidCallback onLogout;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Key menjadi penanda posisi bagian dalam halaman.
  final _profileKey = GlobalKey();
  final _scheduleKey = GlobalKey();
  final _academicKey = GlobalKey();

  int _navIndex = 0;

  /// Memberikan respons untuk fitur lanjutan yang belum dibuat.
  void _planned(String title) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text('$title akan dibuat pada tahap berikutnya.')),
    );

  /// Navigasi sementara mengarahkan pengguna ke bagian beranda.
  void _navigate(int index) {
    setState(() {
      _navIndex = index;
    });

    final target = [
      _profileKey,
      _scheduleKey,
      _academicKey,
      _profileKey,
    ][index].currentContext;

    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: AppMotion.duration(context, 450),
        curve: Curves.easeInOutCubic,
        alignment: 0,
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: AppTheme.red,
      foregroundColor: Colors.white,
      automaticallyImplyLeading: false,
      toolbarHeight: 67,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      titleSpacing: 17,
      elevation: 0,

      title: Row(
        children: [
          const FacultyMark(compact: true),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SIAKAD', style: AppTheme.pixel(13, color: Colors.white)),
              const Text(
                'FASILKOM',
                style: TextStyle(fontSize: 9, color: Color(0xFFFFD6BD)),
              ),
            ],
          ),
        ],
      ),

      actions: [
        // Builder menyediakan context yang berada di bawah Scaffold.
        Builder(
          builder: (context) => _headerButton(
            'Buka menu',
            Icons.menu,
            () => Scaffold.of(context).openDrawer(),
          ),
        ),
        const SizedBox(width: 8),
        _headerButton('Keluar', Icons.logout, widget.onLogout),
        const SizedBox(width: 17),
      ],

      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(5),
        child: ColoredBox(
          color: AppTheme.ink,
          child: SizedBox(height: 5, width: double.infinity),
        ),
      ),
    ),

    drawer: Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text('SIAKAD FASILKOM', style: AppTheme.pixel(13)),
            ),
            for (final label in [
              'Beranda',
              'Biodata',
              'KRS',
              'Jadwal',
              'Nilai',
              'Tagihan',
            ])
              ListTile(
                title: Text(label),
                onTap: () {
                  Navigator.of(context).pop();

                  if (label == 'Beranda') {
                    _navigate(0);
                  } else if (label == 'Jadwal') {
                    _navigate(1);
                  } else {
                    _planned(label);
                  }
                },
              ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Keluar'),
              onTap: () {
                Navigator.of(context).pop();
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
        const RepaintBoundary(child: CampusBackground(dashboard: true)),

        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(15, 22, 19, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SELAMAT DATANG KEMBALI',
                    style: AppTheme.pixel(7, color: AppTheme.red),
                  ),
                  const SizedBox(height: 12),

                  Entrance(child: _profile()),
                  Entrance(delay: 70, child: _quickActions()),

                  _section('KEMAJUAN BELAJAR', _stats(), badge: 'SMT 5'),

                  _section(
                    'JADWAL HARI INI',
                    Column(
                      children: [
                        _classCard(
                          '07:00',
                          '09:30',
                          'CIE512 · Kriptografi',
                          'Ruang KBA701',
                          true,
                        ),
                        const SizedBox(height: 10),
                        _classCard(
                          '09:30',
                          '12:00',
                          'CIE510 · Kecerdasan Artifisial',
                          'Ruang CR 305',
                          false,
                        ),
                      ],
                    ),
                    key: _scheduleKey,
                    badge: '09 OKT 2026',
                  ),

                  _section(
                    'RINGKASAN AKADEMIK',
                    const Column(
                      children: [
                        Text(
                          'Pantau perjalanan dan performa perkuliahanmu.',
                          style: TextStyle(fontSize: 10, color: AppTheme.muted),
                        ),
                        SizedBox(height: 14),
                        AcademicCharts(),
                      ],
                    ),
                    key: _academicKey,
                    badge: '4 SEMESTER',
                  ),

                  _section(
                    'PENGUMUMAN',
                    _notices(DemoData.announcements, false),
                    action: 'SEMUA',
                  ),

                  _section('JADWAL KONSELING', _counseling(), action: 'AJUKAN'),

                  _section(
                    'BERITA KAMPUS',
                    _notices(DemoData.news, true),
                    action: 'SEMUA',
                  ),

                  _section(
                    'PEDOMAN & PANDUAN',
                    Column(
                      children: [
                        for (final title in [
                          'Pedoman Akademik Mahasiswa',
                          'Buku Panduan Konseling',
                          'Panduan Aktivasi / Cuti',
                        ])
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.menu_book_outlined,
                              size: 19,
                              color: AppTheme.blue,
                            ),
                            title: Text(
                              title,
                              style: const TextStyle(fontSize: 11),
                            ),
                            trailing: const Icon(Icons.chevron_right, size: 18),
                            onTap: () => _planned(title),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  const Center(
                    child: Text(
                      'SIAKAD FASILKOM · RELEASE 2026.08.19',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 9, color: AppTheme.muted),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),

    bottomNavigationBar: Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF9FBF6),
        border: Border(top: BorderSide(color: AppTheme.ink, width: 4)),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: SafeArea(
          top: false,
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Row(
                children: List.generate(
                  4,
                  (i) => Expanded(
                    child: Semantics(
                      selected: i == _navIndex,
                      button: true,
                      child: InkWell(
                        onTap: () => _navigate(i),
                        child: AnimatedContainer(
                          duration: AppMotion.duration(context, 180),
                          color: i == _navIndex
                              ? const Color(0xFFE5F0F7)
                              : Colors.transparent,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedContainer(
                                duration: AppMotion.duration(context, 180),
                                height: 4,
                                width: 46,
                                color: i == _navIndex
                                    ? AppTheme.red
                                    : Colors.transparent,
                              ),
                              const SizedBox(height: 10),
                              Icon(
                                [
                                  Icons.home_outlined,
                                  Icons.calendar_month_outlined,
                                  Icons.menu_book_outlined,
                                  Icons.person_outline,
                                ][i],
                                size: 20,
                                color: i == _navIndex
                                    ? AppTheme.blue
                                    : AppTheme.muted,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                ['Beranda', 'Jadwal', 'Akademik', 'Profil'][i],
                                style: AppTheme.pixel(
                                  5,
                                  color: i == _navIndex
                                      ? AppTheme.blue
                                      : AppTheme.muted,
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _headerButton(String label, IconData icon, VoidCallback onTap) =>
      Tooltip(
        message: label,
        child: PixelTapSurface(
          label: label,
          onTap: onTap,
          color: const Color(0xFF9F1729),
          borderColor: const Color(0xFFF05462),
          shadowColor: const Color(0xFF64101C),
          child: SizedBox(
            width: 35,
            height: 35,
            child: Icon(icon, size: 20, color: Colors.white),
          ),
        ),
      );

  /// Kartu profil: gradient, kilau di kanan, badge, dan panel IPK.
  Widget _profile() => Container(
    key: _profileKey,
    decoration: BoxDecoration(
      border: Border.all(color: AppTheme.ink, width: 4),
      boxShadow: const [
        BoxShadow(color: Color(0xFFB9C3C4), offset: Offset(5, 5)),
      ],
    ),
    child: ClipRect(
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF123C80), Color(0xFF166AB1)],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(.9, -1),
                  radius: .8,
                  colors: [
                    const Color(0xFFF04B4C).withValues(alpha: .45),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: -16,
            top: -15,
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .13),
                    width: 3,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 17, 14, 13),
            child: Column(
              children: [
                Row(
                  children: [
                    const StudentAvatar(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.student.name,
                            style: AppTheme.pixel(11, color: Colors.white),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${widget.student.nim} · ${widget.student.major}',
                            style: const TextStyle(
                              fontSize: 9,
                              color: Color(0xFFD3EAFB),
                            ),
                          ),
                          const SizedBox(height: 9),
                          Wrap(
                            spacing: 5,
                            runSpacing: 5,
                            children: [
                              _profileTag('Aktif', active: true),
                              _profileTag(
                                'Semester ${widget.student.semester}',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: 'Lihat profil',
                      onPressed: () => _planned('Biodata'),
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 40,
                      ),
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  constraints: const BoxConstraints(minHeight: 55),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF081B3A).withValues(alpha: .65),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .3),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'IPK KUMULATIF',
                          style: AppTheme.pixel(7, color: Colors.white),
                        ),
                      ),
                      Text(
                        widget.student.gpa.toStringAsFixed(2),
                        style: AppTheme.pixel(
                          20,
                          color: const Color(0xFFFFDC72),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _profileTag(String text, {bool active = false}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .15),
      border: Border.all(color: Colors.white.withValues(alpha: .25)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (active) ...[
          const SizedBox(
            width: 6,
            height: 6,
            child: ColoredBox(color: Color(0xFF35E276)),
          ),
          const SizedBox(width: 4),
        ],
        Text(
          text,
          style: const TextStyle(
            fontSize: 8,
            color: Color(0xFFEAF5FF),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );

  /// Menu enam akses cepat mengikuti susunan Figma.
  Widget _quickActions() {
    const labels = ['Biodata', 'KRS', 'Jadwal', 'Nilai', 'Tagihan', 'Akademik'];

    const icons = [
      Icons.person_outline,
      Icons.description_outlined,
      Icons.calendar_month_outlined,
      Icons.bar_chart,
      Icons.credit_card,
      Icons.menu_book_outlined,
    ];

    const colors = [
      Color(0xFF7244A1),
      AppTheme.red,
      Color(0xFF276FB5),
      Color(0xFF168F54),
      Color(0xFFA5720E),
      Color(0xFF177D93),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 26),
      child: Column(
        children: [
          _heading('AKSES CEPAT', action: 'LIHAT SEMUA'),

          LayoutBuilder(
            builder: (context, bounds) => Wrap(
              spacing: 9,
              runSpacing: 9,
              children: List.generate(
                6,
                (i) => SizedBox(
                  width: (bounds.maxWidth - 18) / 3,
                  child: PixelTapSurface(
                    label: labels[i],
                    onTap: () {
                      if (i == 2) {
                        _navigate(1);
                      } else if (i == 5) {
                        _navigate(2);
                      } else {
                        _planned(labels[i]);
                      }
                    },
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 94),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 10,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: colors[i].withValues(alpha: .1),
                                border: Border.all(color: colors[i], width: 2),
                              ),
                              child: Icon(icons[i], color: colors[i], size: 21),
                            ),
                            const SizedBox(height: 9),
                            Text(
                              labels[i],
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Judul dan badge menggunakan ukuran yang konsisten di setiap panel.
  Widget _heading(String title, {String? badge, String? action}) {
    final icon = switch (title) {
      'PENGUMUMAN' => Icons.description_outlined,
      'JADWAL KONSELING' => Icons.person_outline,
      'BERITA KAMPUS' => Icons.menu_book_outlined,
      'PEDOMAN & PANDUAN' => Icons.menu_book_outlined,
      _ => null,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFE5F1FC),
                border: Border.all(color: const Color(0xFFBCD3E6)),
              ),
              child: Icon(icon, size: 16, color: AppTheme.blue),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(title, style: AppTheme.pixel(8, color: AppTheme.blue)),
          ),
          if (badge != null) ...[
            const SizedBox(width: 8),
            if (title == 'JADWAL HARI INI')
              Text(
                badge,
                style: const TextStyle(fontSize: 8, color: AppTheme.red),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                color: AppTheme.blue,
                child: Text(
                  badge,
                  style: AppTheme.pixel(5, color: Colors.white),
                ),
              ),
          ],
          if (action != null)
            TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size(44, 36),
                padding: const EdgeInsets.only(left: 8),
              ),
              onPressed: () => _planned(title),
              child: Text(
                action,
                style: const TextStyle(fontSize: 8, color: AppTheme.red),
              ),
            ),
        ],
      ),
    );
  }

  /// Pembungkus setiap bagian dashboard.
  Widget _section(
    String title,
    Widget child, {
    Key? key,
    String? badge,
    String? action,
  }) => Padding(
    key: key,
    padding: const EdgeInsets.only(top: 25),
    child: PixelPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heading(title, badge: badge, action: action),
          child,
        ],
      ),
    ),
  );

  /// Progress kemajuan belajar dianimasikan dari kosong ke nilai target.
  Widget _stats() => LayoutBuilder(
    builder: (context, bounds) => Wrap(
      spacing: 8,
      runSpacing: 8,
      children: DemoData.stats
          .map(
            (stat) => Container(
              width: (bounds.maxWidth - 8) / 2,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAFB),
                border: Border.all(color: const Color(0xFFD7E1E3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stat.label,
                    style: AppTheme.pixel(6, color: AppTheme.muted),
                  ),
                  const SizedBox(height: 12),

                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4,
                    children: [
                      Text(
                        stat.value,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(stat.suffix, style: const TextStyle(fontSize: 10)),
                    ],
                  ),

                  const SizedBox(height: 10),

                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: stat.progress),
                    duration: AppMotion.duration(context, 700),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) => LinearProgressIndicator(
                      value: value,
                      minHeight: 7,
                      color: stat.color,
                      backgroundColor: const Color(0xFFDFE7EC),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    ),
  );

  /// Tanggal, status, dan jadwal ini contoh desain, bukan jadwal live.
  Widget _classCard(
    String start,
    String end,
    String name,
    String room,
    bool live,
  ) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: live ? const Color(0xFFEFF9F3) : const Color(0xFFFFF9EC),
      border: Border.all(
        color: live ? const Color(0xFF64BD83) : const Color(0xFFD69B37),
        width: 2,
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Text(
              start,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            Text(
              end,
              style: const TextStyle(fontSize: 9, color: AppTheme.muted),
            ),
          ],
        ),

        const SizedBox(width: 9),
        SizedBox(
          width: 8,
          height: 68,
          child: Stack(
            children: [
              Positioned(
                left: 3,
                top: 3,
                bottom: 0,
                child: Container(width: 2, color: const Color(0xFFACD8B9)),
              ),
              Positioned(
                left: 0,
                top: 2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: live
                        ? const Color(0xFF22BC61)
                        : const Color(0xFFE49327),
                    border: Border.all(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 9),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                live ? 'SEDANG BERLANGSUNG' : 'SELANJUTNYA',
                style: AppTheme.pixel(
                  5,
                  color: live
                      ? const Color(0xFF0C8643)
                      : const Color(0xFFB46413),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text('$room · Pertemuan 4', style: const TextStyle(fontSize: 8)),
              if (live)
                const Padding(
                  padding: EdgeInsets.only(top: 7),
                  child: Text(
                    'Adi Widiantono, S.Kom., M.Kom.',
                    style: TextStyle(fontSize: 7),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );

  /// Material berasal dari PixelPanel, sehingga ripple daftar tidak tertutup.
  Widget _notices(List<NoticeData> items, bool news) => Column(
    children: List.generate(
      items.length,
      (i) => Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: const Color(0xFFD6E0E5),
              width: i == 0 ? .5 : 1,
            ),
          ),
        ),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          minLeadingWidth: 7,
          horizontalTitleGap: 10,
          minTileHeight: 66,
          leading: Icon(
            Icons.square,
            size: 7,
            color: news ? AppTheme.blue : const Color(0xFFEF781D),
          ),
          title: Text(
            items[i].title,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              items[i].date,
              style: const TextStyle(fontSize: 8, color: AppTheme.muted),
            ),
          ),
          trailing: const Icon(Icons.chevron_right, size: 17),
          onTap: () => _planned(items[i].title),
        ),
      ),
    ),
  );

  Widget _counseling() => Column(
    children: DemoData.counseling
        .map(
          (item) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F8FA),
              border: Border.all(color: const Color(0xFFD6E0E5)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.blue,
                    border: Border.all(color: const Color(0xFF09224B)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        color: AppTheme.red,
                        child: Text(
                          item.day,
                          textAlign: TextAlign.center,
                          style: AppTheme.pixel(5, color: Colors.white),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Text(
                          item.date,
                          style: AppTheme.pixel(13, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        '13:00 – 14:00',
                        style: TextStyle(fontSize: 9),
                      ),
                      Text(
                        item.mode,
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppTheme.blue,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4F7EB),
                    border: Border.all(color: const Color(0xFF9CD4AE)),
                  ),
                  child: const Text(
                    'BUKA',
                    style: TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF168F54),
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .toList(),
  );
}
