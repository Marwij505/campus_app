// Navigasi HP: dua tujuan di kiri, chatbot di tengah, dua tujuan di kanan.
// Halaman induk menentukan rute; komponen ini hanya menata tombol dan label.
import 'package:flutter/material.dart';

import '../../core/app_theme.dart';

class DashboardNavigation extends StatelessWidget {
  const DashboardNavigation({
    super.key,
    required this.onSelected,
    required this.chatButton,
    this.selectedIndex = 0,
  });
  // Indeks terakhir yang dipilih menentukan warna dan status aksesibilitas.
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Widget chatButton;

  @override
  Widget build(BuildContext context) => Stack(
    key: const ValueKey('phone-navigation'),
    children: [
      // Ruang atas membuat tombol chat menonjol tanpa keluar area sentuh.
      Positioned.fill(
        top: 20,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppTheme.ink, width: 3)),
          ),
        ),
      ),
      SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _destination(0, 'Beranda', Icons.home_outlined),
            _destination(1, 'Jadwal', Icons.calendar_month_outlined),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Ukuran tetap menjaga target sentuh cukup besar di HP kecil.
                    SizedBox(width: 56, height: 56, child: chatButton),
                    const SizedBox(height: 6),
                    const Text(
                      'Chatbot',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _destination(2, 'Akademik', Icons.school_outlined),
            _destination(3, 'Profil', Icons.person_outline),
          ],
        ),
      ),
    ],
  );

  // Beranda tetap aktif ketika pengguna kembali dari halaman tujuan.
  // Tinggi mengikuti teks, termasuk saat aksesibilitas memperbesar tulisan.
  Widget _destination(int index, String label, IconData icon) {
    final selected = index == selectedIndex;
    final color = selected ? AppTheme.blue : AppTheme.muted;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(top: 23),
        child: Material(
          color: selected ? const Color(0xFFEAF2FC) : Colors.white,
          child: Semantics(
            selected: selected,
            button: true,
            child: InkWell(
              key: ValueKey('bottom-nav-$index'),
              onTap: () => onSelected(index),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 2,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 23, color: color),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
