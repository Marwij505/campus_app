// Menu bertingkat beranda mengikuti susunan referensi, dengan tema campus_app.
// Satu daftar dipakai desktop dan HP agar nama serta tujuan menu selalu sama.
// Komponen ini mengatur menu; halaman induk menentukan tindakan saat dipilih.

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';

/// Satu pilihan menu. Jika memiliki children, pilihan ini membuka submenu.
class ExecutiveMenuEntry {
  const ExecutiveMenuEntry({
    required this.id,
    required this.label,
    this.icon,
    this.destination,
    this.children = const [],
  });

  // ID tetap dipakai untuk mengenali tombol, meskipun tulisannya panjang.
  final String id;
  final String label;
  final IconData? icon;

  // Alias menyambungkan label referensi dengan nama aksi yang sudah ada.
  final String? destination;
  final List<ExecutiveMenuEntry> children;
}

// Isi menu hanya berupa pilihan navigasi, bukan data akademik mahasiswa.
const executiveMenuGroups = [
  ExecutiveMenuEntry(
    id: 'akademik',
    label: 'Akademik',
    icon: Icons.menu_book_outlined,
    children: [
      ExecutiveMenuEntry(
        id: 'krs',
        label: 'Kartu Rencana Studi (KRS)',
        destination: 'KRS',
      ),
      ExecutiveMenuEntry(
        id: 'jadwal',
        label: 'Jadwal Perkuliahan',
        destination: 'Jadwal Kuliah',
      ),
      ExecutiveMenuEntry(id: 'nilai', label: 'Nilai & Presensi'),
      ExecutiveMenuEntry(id: 'ekivalensi', label: 'Ekivalensi'),
      ExecutiveMenuEntry(
        id: 'program-akademik',
        label: 'Program Akademik',
        children: [
          ExecutiveMenuEntry(id: 'kkn', label: 'Kuliah Kerja Nyata (KKN)'),
          ExecutiveMenuEntry(id: 'kkp', label: 'Kuliah Kerja Praktek (KKP)'),
          ExecutiveMenuEntry(id: 'praktek-lahan', label: 'Praktek Lahan'),
          ExecutiveMenuEntry(id: 'project-based', label: 'Project Based'),
          ExecutiveMenuEntry(id: 'kampus-berdampak', label: 'Kampus Berdampak'),
          ExecutiveMenuEntry(
            id: 'praktik-apoteker',
            label: 'Pengajuan Praktik Apoteker',
          ),
        ],
      ),
    ],
  ),
  ExecutiveMenuEntry(
    id: 'tugas-akhir',
    label: 'Tugas Akhir',
    icon: Icons.school_outlined,
    children: [
      ExecutiveMenuEntry(id: 'skripsi-tesis', label: 'Skripsi/Tesis'),
      ExecutiveMenuEntry(id: 'business-plan', label: 'Business Plan'),
      ExecutiveMenuEntry(id: 'disertasi', label: 'Disertasi'),
    ],
  ),
  ExecutiveMenuEntry(
    id: 'layanan',
    label: 'Layanan',
    icon: Icons.support_agent,
    children: [
      ExecutiveMenuEntry(id: 'smart-chatbot', label: 'Smart Chatbot'),
      ExecutiveMenuEntry(id: 'konseling', label: 'Konseling'),
      ExecutiveMenuEntry(id: 'kuesioner', label: 'Kuesioner'),
      ExecutiveMenuEntry(
        id: 'dokumen',
        label: 'Dokumen',
        children: [
          ExecutiveMenuEntry(
            id: 'surat-lulus',
            label: 'Surat Keterangan Lulus',
          ),
        ],
      ),
      ExecutiveMenuEntry(
        id: 'referensi',
        label: 'Referensi',
        children: [ExecutiveMenuEntry(id: 'kurikulum', label: 'Kurikulum')],
      ),
    ],
  ),
];

/// Menu atas untuk desktop: submenu dapat terbuka ke samping seperti referensi.
/// Menu bawaan Flutter juga menangani fokus keyboard, Escape, dan klik di luar.
class ExecutiveDesktopMenu extends StatelessWidget {
  const ExecutiveDesktopMenu({super.key, required this.onSelected});

  final ValueChanged<String> onSelected;

  // Bingkai kotak, warna kertas, dan teks mengikuti tema pixel aplikasi.
  static const _popupStyle = MenuStyle(
    backgroundColor: WidgetStatePropertyAll(AppTheme.paper),
    surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
    shape: WidgetStatePropertyAll(RoundedRectangleBorder()),
    side: WidgetStatePropertyAll(BorderSide(color: AppTheme.ink, width: 2)),
    padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 6)),
  );

  // Fungsi memanggil dirinya sendiri untuk membentuk submenu sedalam datanya.
  Widget _item(ExecutiveMenuEntry entry) {
    final style = TextButton.styleFrom(
      foregroundColor: AppTheme.ink,
      iconColor: AppTheme.ink,
      textStyle: const TextStyle(fontFamily: 'SpaceMono', fontSize: 12),
      minimumSize: const Size(48, 48),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      shape: const RoundedRectangleBorder(),
    );
    final label = SizedBox(width: 230, child: Text(entry.label));
    final key = ValueKey('executive-desktop-${entry.id}');
    if (entry.children.isNotEmpty) {
      return SubmenuButton(
        key: key,
        style: style,
        menuStyle: _popupStyle,
        menuChildren: entry.children.map(_item).toList(),
        child: label,
      );
    }
    return MenuItemButton(
      key: key,
      style: style,
      // Menu menutup sebelum halaman induk menjalankan tujuan yang dipilih.
      onPressed: () => onSelected(entry.destination ?? entry.label),
      child: label,
    );
  }

  @override
  Widget build(BuildContext context) => MenuBar(
    // Bilah transparan menyatu dengan header merah yang sudah digunakan.
    style: const MenuStyle(
      backgroundColor: WidgetStatePropertyAll(Colors.transparent),
      surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
      elevation: WidgetStatePropertyAll(0),
      padding: WidgetStatePropertyAll(EdgeInsets.zero),
      shape: WidgetStatePropertyAll(RoundedRectangleBorder()),
    ),
    children: [
      for (final group in executiveMenuGroups)
        SubmenuButton(
          key: ValueKey('executive-desktop-${group.id}'),
          menuStyle: _popupStyle,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            iconColor: Colors.white,
            textStyle: const TextStyle(fontFamily: 'SpaceMono', fontSize: 11),
            minimumSize: const Size(48, 48),
            shape: const RoundedRectangleBorder(),
          ),
          leadingIcon: Icon(group.icon, size: 18),
          trailingIcon: const Icon(Icons.arrow_drop_down, size: 18),
          menuChildren: group.children.map(_item).toList(),
          child: Text(group.label),
        ),
    ],
  );
}

/// HP/tablet memakai bagian buka-tutup di menu geser yang sudah ada.
/// Submenu tumbuh ke bawah agar tidak keluar dari lebar layar kecil.
class ExecutiveMobileMenu extends StatelessWidget {
  const ExecutiveMobileMenu({super.key, required this.onSelected});

  final ValueChanged<String> onSelected;

  Widget _item(ExecutiveMenuEntry entry, {bool root = false}) {
    final key = PageStorageKey('executive-mobile-${entry.id}');
    if (entry.children.isEmpty) {
      return ListTile(
        key: key,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        title: Text(entry.label, style: const TextStyle(fontSize: 12)),
        onTap: () => onSelected(entry.destination ?? entry.label),
      );
    }
    return ExpansionTile(
      key: key,
      leading: root ? Icon(entry.icon, size: 22) : null,
      title: Text(
        entry.label,
        // Judul utama mengikuti ukuran 16 pada menu lain; tebal menandai submenu.
        style: TextStyle(fontSize: root ? 16 : 12, fontWeight: FontWeight.bold),
      ),
      textColor: AppTheme.blue,
      iconColor: AppTheme.blue,
      collapsedTextColor: AppTheme.ink,
      collapsedIconColor: AppTheme.ink,
      backgroundColor: AppTheme.paper,
      shape: const Border(),
      collapsedShape: const Border(),
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      childrenPadding: const EdgeInsets.only(left: 16, right: 8, bottom: 8),
      children: [
        // Garis samping membantu membedakan anak menu dari kelompok induknya.
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(left: BorderSide(color: AppTheme.blue, width: 3)),
          ),
          // Material diletakkan di atas dekorasi supaya efek sentuh tetap terlihat.
          child: Material(
            color: Colors.transparent,
            child: Column(
              children: entry.children.map((item) => _item(item)).toList(),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    children: executiveMenuGroups
        .map((group) => _item(group, root: true))
        .toList(),
  );
}
