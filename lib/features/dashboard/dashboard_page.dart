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
      toolbarHeight: 72,
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
          builder: (context) => IconButton(
            tooltip: 'Buka menu',
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        IconButton(
          tooltip: 'Keluar',
          onPressed: widget.onLogout,
          icon: const Icon(Icons.logout),
        ),
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
              child: Entrance(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SELAMAT DATANG KEMBALI',
                      style: AppTheme.pixel(7, color: AppTheme.red),
                    ),
                    const SizedBox(height: 12),

                    _profile(),
                    _quickActions(),

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
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.muted,
                            ),
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
                    ),

                    _section(
                      'JADWAL KONSELING',
                      _counseling(),
                      action: 'AJUKAN',
                    ),

                    _section('BERITA KAMPUS', _notices(DemoData.news, true)),

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
                              trailing: const Icon(
                                Icons.chevron_right,
                                size: 18,
                              ),
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
        ),
      ],
    ),

    bottomNavigationBar: Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF9FBF6),
        border: Border(top: BorderSide(color: AppTheme.ink, width: 4)),
      ),
      child: SafeArea(
        top: false,
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
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    color: i == _navIndex
                        ? const Color(0xFFE5F0F7)
                        : Colors.transparent,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          [
                            Icons.home_outlined,
                            Icons.calendar_month_outlined,
                            Icons.menu_book_outlined,
                            Icons.person_outline,
                          ][i],
                          color: i == _navIndex
                              ? AppTheme.blue
                              : AppTheme.muted,
                          size: 23,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ['Beranda', 'Jadwal', 'Akademik', 'Profil'][i],
                          style: const TextStyle(fontSize: 10),
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
    ),
  );

  /// Kartu identitas dan IPK mengikuti profil contoh Figma.
  Widget _profile() => Container(
    key: _profileKey,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF123C80), Color(0xFF166AB1)],
      ),
      border: Border.all(color: AppTheme.ink, width: 4),
      boxShadow: const [
        BoxShadow(color: Color(0xFFB9C3C4), offset: Offset(5, 5)),
      ],
    ),
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
                  const SizedBox(height: 7),
                  Text(
                    '${widget.student.nim} · ${widget.student.major}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFFD3EAFB),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '● Aktif   ·   Semester ${widget.student.semester}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFFB5F6D0),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 17),

        Container(
          padding: const EdgeInsets.all(12),
          color: AppTheme.ink.withValues(alpha: .65),
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
                style: AppTheme.pixel(20, color: const Color(0xFFFFDC72)),
              ),
            ],
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
                  child: Material(
                    color: Colors.white,
                    child: InkWell(
                      onTap: () {
                        if (i == 2) {
                          _navigate(1);
                        } else if (i == 5) {
                          _navigate(2);
                        } else {
                          _planned(labels[i]);
                        }
                      },
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 94),
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFFDBE4E6),
                            width: 2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0xFFC8D0D1),
                              offset: Offset(3, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
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
                                fontSize: 11,
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

  /// Judul bagian, badge, dan tombol aksi ditata secara konsisten.
  Widget _heading(String title, {String? badge, String? action}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Text(title, style: AppTheme.pixel(8, color: AppTheme.blue)),
        ),
        if (badge != null)
          Text(
            badge,
            style: const TextStyle(fontSize: 9, color: AppTheme.blue),
          ),
        if (action != null)
          TextButton(
            onPressed: () => _planned(title),
            child: Text(action, style: const TextStyle(fontSize: 9)),
          ),
      ],
    ),
  );

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

        const SizedBox(width: 12),

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
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text('$room · Pertemuan 4', style: const TextStyle(fontSize: 9)),
              if (live)
                const Padding(
                  padding: EdgeInsets.only(top: 7),
                  child: Text(
                    'Adi Widiantono, S.Kom., M.Kom.',
                    style: TextStyle(fontSize: 9),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );

  /// Daftar pengumuman atau berita menggunakan komponen yang sama.
  Widget _notices(List<NoticeData> items, bool news) => Column(
    children: items
        .map(
          (item) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.square,
              size: 9,
              color: news ? AppTheme.blue : const Color(0xFFEF781D),
            ),
            minLeadingWidth: 10,
            title: Text(
              item.title,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              item.date,
              style: const TextStyle(fontSize: 9, color: AppTheme.muted),
            ),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () => _planned(item.title),
          ),
        )
        .toList(),
  );

  Widget _counseling() => Column(
    children: DemoData.counseling
        .map(
          (item) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(9),
            color: const Color(0xFFF5F8FA),
            child: Row(
              children: [
                Container(
                  width: 42,
                  padding: const EdgeInsets.all(5),
                  color: AppTheme.blue,
                  child: Column(
                    children: [
                      Text(
                        item.day,
                        style: const TextStyle(
                          fontSize: 8,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        item.date,
                        style: AppTheme.pixel(15, color: Colors.white),
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

                const Text(
                  'BUKA',
                  style: TextStyle(fontSize: 9, color: Color(0xFF168F54)),
                ),
              ],
            ),
          ),
        )
        .toList(),
  );
}
