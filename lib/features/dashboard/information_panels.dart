import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../data/dashboard_models.dart';
import 'dashboard_widgets.dart';

/// HP memakai kartu, layar lebar memakai tabel untuk konseling.
/// Tidak ada tabel yang harus digeser ke kanan pada layar HP.
class CounselingPanel extends StatelessWidget {
  const CounselingPanel({
    super.key,
    required this.items,
    required this.onApply,
  });
  final List<CounselingSession> items;
  final VoidCallback onApply;
  @override
  Widget build(BuildContext context) => DashboardPanel(
    title: 'JADWAL KONSELING',
    icon: Icons.handshake_outlined,
    action: DashboardAction('Ajukan konseling', onApply, icon: Icons.edit_note),
    child: items.isEmpty
        ? const DashboardEmpty(
            title: 'Belum ada jadwal konseling',
            message: 'Jadwal dosen atau psikolog akan tampil di sini.',
            icon: Icons.handshake_outlined,
          )
        : LayoutBuilder(
            builder: (context, bounds) {
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

class NoticePanel extends StatelessWidget {
  const NoticePanel({
    super.key,
    required this.title,
    required this.items,
    required this.icon,
    required this.onOpen,
    required this.onAll,
    required this.emptyTitle,
  });
  final String title, emptyTitle;
  final List<CampusNotice> items;
  final IconData icon;
  final void Function(CampusNotice) onOpen;
  final VoidCallback onAll;
  @override
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

class GuidesPanel extends StatelessWidget {
  const GuidesPanel({super.key, required this.items, required this.onOpen});
  final List<CampusGuide> items;
  final void Function(CampusGuide) onOpen;
  @override
  Widget build(BuildContext context) => DashboardPanel(
    title: 'PEDOMAN & PANDUAN',
    icon: Icons.menu_book_outlined,
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

class SchedulePanel extends StatelessWidget {
  const SchedulePanel({
    super.key,
    required this.items,
    required this.now,
    required this.onAll,
    required this.onOpen,
    this.next,
  });
  final List<ClassSchedule> items;
  final ClassSchedule? next;
  final DateTime now;
  final VoidCallback onAll;
  final void Function(ClassSchedule) onOpen;
  @override
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
class ClassScheduleCard extends StatelessWidget {
  const ClassScheduleCard({
    super.key,
    required this.item,
    required this.now,
    required this.onTap,
  });
  final ClassSchedule item;
  final DateTime now;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final ongoing = !item.startsAt.isAfter(now) && item.endsAt.isAfter(now);
    final finished = !item.endsAt.isAfter(now);
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
