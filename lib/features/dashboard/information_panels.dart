// Panel informasi beranda: konseling, pengumuman, panduan, dan jadwal kuliah.
// Masing-masing menerima daftar data serta fungsi untuk menangani ketukan pengguna.
// Komponen hanya menampilkan isi; pengambilan data dan tujuan navigasi diatur induknya.

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../data/dashboard_models.dart';
import 'dashboard_widgets.dart';

/// HP memakai kartu, layar lebar memakai tabel untuk konseling.
/// Tidak ada tabel yang harus digeser ke kanan pada layar HP.
// Menampilkan jadwal konseling dalam kartu atau tabel sesuai ruang.
class CounselingPanel extends StatelessWidget {
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
  const CounselingPanel({
    super.key,
    required this.items,
    required this.onApply,
  });
  // Daftar jadwal konseling yang sudah disediakan halaman induk.
  final List<CounselingSession> items;
  // Panggil fungsi dari induk saat tombol pengajuan ditekan.
  final VoidCallback onApply;
  @override
  // build menyusun tampilan ketika Flutter memintanya.
  Widget build(BuildContext context) => DashboardPanel(
    title: 'JADWAL KONSELING',
    icon: Icons.handshake_outlined,
    action: DashboardAction('Ajukan konseling', onApply, icon: Icons.edit_note),
    // Jika tidak ada data, tampilkan penjelasan kosong alih-alih membuat isi contoh.
    child: items.isEmpty
        ? const DashboardEmpty(
            title: 'Belum ada jadwal konseling',
            message: 'Jadwal dosen atau psikolog akan tampil di sini.',
            icon: Icons.handshake_outlined,
          )
        : LayoutBuilder(
            builder: (context, bounds) {
              // Pilih kartu bertumpuk pada layar sempit atau teks besar agar tidak perlu gulir ke samping.
              if (bounds.maxWidth < 820 ||
                  MediaQuery.textScalerOf(context).scale(1) > 1.2) {
                return Column(
                  children: [
                    for (final item in items)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FBFF),
                          border: Border.all(
                            color: const Color(0xFFD5E0ED),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              item.counselor,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text('${item.day} · ${item.time}'),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                InfoChip(item.kind),
                                InfoChip(item.method),
                                InfoChip(
                                  // Label buka/tutup berasal dari data, bukan dihitung dari jam oleh panel ini.
                                  item.isOpen ? 'Buka' : 'Tutup',
                                  color: item.isOpen
                                      ? const Color(0xFF198754)
                                      : AppTheme.muted,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              }
              // Table memakai lebar fleksibel; nama panjang boleh membungkus.
              // Pembantu lokal untuk menyamakan jarak, warna, dan tulisan setiap sel tabel.
              Widget cell(String text, {bool header = false}) => Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: header ? FontWeight.bold : FontWeight.normal,
                    color: header ? Colors.white : AppTheme.ink,
                  ),
                ),
              );
              return Table(
                // Kolom nomor dibuat tetap; kolom lain berbagi sisa ruang menurut bobotnya.
                columnWidths: const {
                  0: FixedColumnWidth(45),
                  1: FlexColumnWidth(1),
                  2: FlexColumnWidth(2.5),
                  3: FlexColumnWidth(1.5),
                  4: FlexColumnWidth(1.5),
                  5: FlexColumnWidth(1),
                  6: FlexColumnWidth(1),
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                border: const TableBorder(
                  horizontalInside: BorderSide(color: Color(0xFFDFE6EF)),
                ),
                children: [
                  TableRow(
                    decoration: const BoxDecoration(color: AppTheme.blue),
                    children: [
                      for (final label in [
                        'No',
                        'Hari',
                        'Dosen/Psikolog',
                        'Jenis',
                        'Waktu',
                        'Metode',
                        'Status',
                      ])
                        cell(label, header: true),
                    ],
                  ),
                  for (var i = 0; i < items.length; i++)
                    TableRow(
                      decoration: BoxDecoration(
                        // Selang-seling warna baris memudahkan mata mengikuti satu baris tabel.
                        color: i.isEven
                            ? const Color(0xFFF8FBFF)
                            : Colors.white,
                      ),
                      children: [
                        cell('${i + 1}'),
                        cell(items[i].day),
                        cell(items[i].counselor),
                        cell(items[i].kind),
                        cell(items[i].time),
                        cell(items[i].method),
                        cell(items[i].isOpen ? 'Buka' : 'Tutup'),
                      ],
                    ),
                ],
              );
            },
          ),
  );
}

// Ringkasan berita/pengumuman dengan akses ke isi dan daftar lengkap.
class NoticePanel extends StatelessWidget {
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
  const NoticePanel({
    super.key,
    required this.title,
    required this.items,
    required this.icon,
    required this.onOpen,
    required this.onAll,
    required this.emptyTitle,
  });
  // Judul panel dan pesan kosong dapat berbeda antara berita dan pengumuman.
  final String title, emptyTitle;
  // Daftar informasi; panel hanya menampilkan sebagian sebagai ringkasan.
  final List<CampusNotice> items;
  final IconData icon;
  // Kirim item yang dipilih ke induk untuk membuka isi lengkapnya.
  final void Function(CampusNotice) onOpen;
  // Aksi untuk membuka daftar lengkap di halaman lain.
  final VoidCallback onAll;
  @override
  // build menyusun tampilan ketika Flutter memintanya.
  Widget build(BuildContext context) => DashboardPanel(
    title: title,
    icon: icon,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (items.isEmpty)
          DashboardEmpty(
            title: emptyTitle,
            message: 'Informasi terbaru akan tampil di sini.',
            icon: icon,
          )
        else ...[
          // Batasi ringkasan menjadi lima item pertama; sisanya melalui tombol Lihat semua.
          for (final item in items.take(5)) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.circle,
                size: 9,
                color: Color(0xFFED7D21),
              ),
              title: Text(
                item.title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                campusDate(item.publishedAt.toLocal()),
                style: const TextStyle(fontSize: 10),
              ),
              onTap: () => onOpen(item),
            ),
            const Divider(color: Color(0xFFDFE6EF)),
          ],
        ],
        DashboardAction('Lihat semua', onAll, icon: Icons.arrow_forward),
      ],
    ),
  );
}

// Daftar panduan yang dapat dipilih untuk dibaca.
class GuidesPanel extends StatelessWidget {
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
  const GuidesPanel({super.key, required this.items, required this.onOpen});
  // Judul dan isi panduan yang siap dibaca.
  final List<CampusGuide> items;
  // Teruskan panduan yang diklik ke fungsi pembuka detail.
  final void Function(CampusGuide) onOpen;
  @override
  // build menyusun tampilan ketika Flutter memintanya.
  Widget build(BuildContext context) => DashboardPanel(
    title: 'PEDOMAN & PANDUAN',
    icon: Icons.menu_book_outlined,
    // Jika tidak ada data, tampilkan penjelasan kosong alih-alih membuat isi contoh.
    child: items.isEmpty
        ? const DashboardEmpty(
            title: 'Belum ada pedoman atau panduan',
            message: 'Dokumen akademik dan panduan akan tampil di sini.',
            icon: Icons.menu_book_outlined,
          )
        : Column(
            children: [
              for (final guide in items)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.menu_book_outlined,
                    color: AppTheme.blue,
                  ),
                  title: Text(
                    guide.title,
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => onOpen(guide),
                ),
            ],
          ),
  );
}

// Daftar kelas hari ini ditambah kegiatan berikutnya jika berada di hari lain.
class SchedulePanel extends StatelessWidget {
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
  const SchedulePanel({
    super.key,
    required this.items,
    required this.now,
    required this.onAll,
    required this.onOpen,
    this.next,
  });
  // Jadwal hari ini; sudah disaring oleh halaman beranda sebelum dikirim ke panel.
  final List<ClassSchedule> items;
  // Kelas terdekat bisa berada pada hari berikutnya atau tidak tersedia sama sekali.
  final ClassSchedule? next;
  // Waktu acuan diberikan induk agar tanggal dan status kartu konsisten.
  final DateTime now;
  // Aksi untuk membuka daftar lengkap di halaman lain.
  final VoidCallback onAll;
  // Buka rincian jadwal yang dipilih pengguna.
  final void Function(ClassSchedule) onOpen;
  @override
  // build menyusun tampilan ketika Flutter memintanya.
  Widget build(BuildContext context) => DashboardPanel(
    title: 'JADWAL KULIAH HARI INI',
    icon: Icons.calendar_month_outlined,
    action: DashboardAction('Semua', onAll),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              campusDate(now),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppTheme.blue,
              ),
            ),
            if (items.isNotEmpty) InfoChip('${items.length} kelas'),
          ],
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          const DashboardEmpty(
            title: 'Belum ada jadwal kuliah hari ini',
            message: 'Jadwal akan tampil setelah data tersedia.',
            icon: Icons.event_available_outlined,
          )
        else
          for (final item in items)
            ClassScheduleCard(item: item, now: now, onTap: () => onOpen(item)),
        // Tambahkan kelas terdekat dari hari lain tanpa menggandakannya dalam daftar hari ini.
        if (next != null && !sameDay(next!.startsAt.toLocal(), now)) ...[
          const Divider(),
          Text(
            'KEGIATAN BERIKUTNYA',
            style: AppTheme.pixel(7, color: AppTheme.blue),
          ),
          const SizedBox(height: 10),
          Text(campusDate(next!.startsAt.toLocal())),
          ClassScheduleCard(item: next!, now: now, onTap: () => onOpen(next!)),
        ],
      ],
    ),
  );
}

/// Status bergantung pada waktu saat ini, bukan teks tetap dari screenshot.
// Kartu satu kelas dengan status yang dihitung dari waktu acuan.
class ClassScheduleCard extends StatelessWidget {
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
  const ClassScheduleCard({
    super.key,
    required this.item,
    required this.now,
    required this.onTap,
  });
  // Satu jadwal yang memuat waktu, ruang, dosen, dan informasi pertemuan.
  final ClassSchedule item;
  // Waktu acuan diberikan induk agar tanggal dan status kartu konsisten.
  final DateTime now;
  // Tindakan dari induk ketika kartu kelas disentuh.
  final VoidCallback onTap;
  @override
  // build menyusun tampilan ketika Flutter memintanya.
  Widget build(BuildContext context) {
    // Kelas aktif jika waktu mulai sudah tiba dan waktu selesai belum tiba.
    final ongoing = !item.startsAt.isAfter(now) && item.endsAt.isAfter(now);
    // Kelas dianggap selesai tepat saat waktu akhirnya tiba atau sudah lewat.
    final finished = !item.endsAt.isAfter(now);
    // Hijau menandai kelas aktif, abu-abu kelas selesai, dan biru kelas yang akan datang.
    final color = ongoing
        ? const Color(0xFF198754)
        : finished
        ? AppTheme.muted
        : AppTheme.blue;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .04),
        border: Border.all(color: color.withValues(alpha: .25), width: 2),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${campusTime(item.startsAt)} – ${campusTime(item.endsAt)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${item.code} · ${item.title}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('Ruang: ${item.room}'),
              Text('Dosen: ${item.lecturer}'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Tampilkan nomor pertemuan dan metode hanya bila informasinya tersedia.
                  if (item.meeting != null)
                    InfoChip('Pertemuan ${item.meeting}'),
                  if (item.method != null) InfoChip(item.method!),
                  InfoChip(
                    ongoing
                        ? 'Sedang berlangsung'
                        : finished
                        ? 'Selesai'
                        : 'Terjadwal',
                    color: color,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
