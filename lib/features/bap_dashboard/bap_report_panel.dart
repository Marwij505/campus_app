// Panel Rekapitulasi & Pelaporan Data (PDDikti) — BAP Dashboard.

import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../data/bap_models.dart';
import 'bap_widgets.dart';

class BapReportPanel extends StatelessWidget {
  const BapReportPanel({super.key, required this.stats});
  final BapDashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BapPanelHeader(
          icon: Icons.bar_chart_outlined,
          title: 'REKAPITULASI & PELAPORAN DATA (PDDikti)',
          subtitle: 'Unduh laporan akademik & sinkronisasi Neo Feeder Kemdikbud',
          color: const Color(0xFF065F46),
        ),
        const SizedBox(height: 14),

        // Statistik cepat semester
        LayoutBuilder(builder: (ctx, c) {
          final columns = c.maxWidth < 600 ? 2 : (c.maxWidth < 860 ? 2 : 4);
          return GridView.count(
            crossAxisCount: columns,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: columns == 4 ? 2.3 : 2.5,
            children: [
              _summaryCard('Total MK Aktif', '${stats.totalCourses}', const Color(0xFF065F46), Icons.menu_book_outlined),
              _summaryCard('Total Kelas', '${stats.totalClasses}', const Color(0xFF0369A1), Icons.class_outlined),
              _summaryCard('Mahasiswa Aktif', '${stats.totalActiveStudents}', const Color(0xFF16A34A), Icons.people_outlined),
              _summaryCard('Jadwal Ujian', '${stats.openExamSchedules}', const Color(0xFF7C3AED), Icons.quiz_outlined),
            ],
          );
        }),
        const SizedBox(height: 16),

        // Unduhan laporan
        BapSectionCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.download_outlined, size: 18, color: Color(0xFF065F46)),
                  const SizedBox(width: 8),
                  Text('UNDUHAN LAPORAN AKADEMIK RESMI', style: AppTheme.pixel(7.5, color: const Color(0xFF065F46))),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Pilih format laporan untuk evaluasi pimpinan fakultas atau audit mutu internal.',
                style: TextStyle(fontSize: 11, color: AppTheme.muted),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _downloadBtn(context, Icons.summarize_outlined, 'Rekap KHS Semester', 'PDF / Excel', const Color(0xFF065F46)),
                  _downloadBtn(context, Icons.school_outlined, 'Transkrip Sementara Massal', 'PDF', const Color(0xFF0369A1)),
                  _downloadBtn(context, Icons.insert_chart_outlined, 'Statistik Kelulusan', 'Excel', const Color(0xFF7C3AED)),
                  _downloadBtn(context, Icons.people_outlined, 'Daftar Mahasiswa Aktif', 'Excel', const Color(0xFF16A34A)),
                  _downloadBtn(context, Icons.bar_chart, 'Rekap Presensi Dosen & BAP', 'PDF / Excel', const Color(0xFFD97706)),
                  _downloadBtn(context, Icons.assessment_outlined, 'Rekap Nilai Akhir per Kelas', 'Excel', const Color(0xFF0F766E)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // PDDikti Sync
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.sync, size: 18, color: Color(0xFF16A34A)),
                  const SizedBox(width: 8),
                  Text('SINKRONISASI DATA PDDikti (NEO FEEDER)', style: AppTheme.pixel(7.5, color: const Color(0xFF15803D))),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Sinkronkan data akademik mahasiswa (KRS, nilai, status keaktifan, dan lulusan) ke sistem Neo Feeder PDDikti Kemdikbud. Pastikan data sudah divalidasi sebelum disinkronkan.',
                style: TextStyle(fontSize: 11, color: Color(0xFF166534), fontFamily: 'SpaceMono'),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _syncBtn(context, 'Sinkron Data Mahasiswa Aktif', Icons.person_outlined),
                  _syncBtn(context, 'Sinkron Nilai Semester Ini', Icons.grade_outlined),
                  _syncBtn(context, 'Sinkron Data Kelulusan', Icons.school_outlined),
                  _syncBtn(context, 'Ekspor Feeder XML', Icons.code_outlined),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: Color(0xFFBBF7D0)),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 6,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      const Text('Sinkronisasi terakhir: 15 November 2026 · 10:32 WIB',
                          style: TextStyle(fontSize: 10.5, color: Color(0xFF15803D), fontFamily: 'SpaceMono')),
                    ],
                  ),
                  const Text('Status: Sukses (1.847 record)',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Kalender deadline
        BapSectionCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.event_note_outlined, size: 18, color: Color(0xFF0F4C81)),
                  const SizedBox(width: 8),
                  Text('TENGGAT AKADEMIK MENDATANG', style: AppTheme.pixel(7.5, color: const Color(0xFF0F4C81))),
                ],
              ),
              const SizedBox(height: 12),
              _deadlineRow('30 Nov 2026', 'Batas upload nilai UTS ke SIAKAD', const Color(0xFFD97706)),
              _deadlineRow('10 Jan 2027', 'Pembukaan periode KRS Semester Genap', const Color(0xFF7C3AED)),
              _deadlineRow('20 Jan 2027', 'Batas sinkronisasi data ke PDDikti', const Color(0xFF16A34A)),
              _deadlineRow('25 Jan 2027', 'Penutupan masa batal-tambah KRS', const Color(0xFFDC2626)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontFamily: 'SpaceMono',
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppTheme.muted,
                    fontFamily: 'SpaceMono',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _downloadBtn(BuildContext context, IconData icon, String label, String format, Color color) {
    return InkWell(
      onTap: () => _showDownloadDialog(context, label, format, color),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 7),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
                Text(format, style: const TextStyle(fontSize: 9.5, color: AppTheme.muted)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _syncBtn(BuildContext context, String label, IconData icon) {
    return FilledButton.icon(
      onPressed: () => _showSyncDialog(context, label),
      icon: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 10.5)),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF16A34A),
        shape: const RoundedRectangleBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  void _showDownloadDialog(BuildContext context, String label, String format, Color color) {
    showDialog(
      context: context,
      builder: (context) => BapDialogShell(
        title: 'UNDUH LAPORAN: $label',
        subtitle: 'Siapkan ekspor data akademik dalam format $format',
        accentColor: color,
        maxWidth: 520,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.file_present_outlined, size: 28, color: color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
                        const Text(
                          'Semester: 2026/2027 Ganjil · Format: Resmi Terverifikasi',
                          style: TextStyle(fontSize: 10, color: AppTheme.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text('Pengaturan Filter Ekspor:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.ink)),
            const SizedBox(height: 6),
            const Text('• Mencakup seluruh Program Studi Fakultas Ilmu Komputer\n• Format disesuaikan dengan standar evaluasi BAN-PT & PDDikti\n• Termasuk watermark dan tanda tangan digital BAP',
                style: TextStyle(fontSize: 10.5, color: AppTheme.muted, height: 1.4)),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.ink,
              side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
              shape: const RoundedRectangleBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            ),
            child: const Text('Batal'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('File $label ($format) berhasil diunduh ke folder Downloads.'),
                  backgroundColor: color,
                ),
              );
            },
            icon: const Icon(Icons.download, size: 14),
            label: Text('Unduh File ($format)'),
            style: FilledButton.styleFrom(
              backgroundColor: color,
              shape: const RoundedRectangleBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            ),
          ),
        ],
      ),
    );
  }

  void _showSyncDialog(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (context) => BapDialogShell(
        title: 'SINKRONISASI PDDikti NEO FEEDER',
        subtitle: title,
        accentColor: const Color(0xFF16A34A),
        maxWidth: 520,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.cloud_sync_outlined, color: Color(0xFF16A34A), size: 20),
                      SizedBox(width: 8),
                      Text('Koneksi Server Neo Feeder Aktif', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text('Endpoint: https://feeder.esaunggul.ac.id:8100/ws/live2.php\nStatus Auth: Token Valid (Expired: 2 Jam)',
                      style: TextStyle(fontSize: 10, fontFamily: 'SpaceMono', color: Color(0xFF15803D))),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text('Tahapan Sinkronisasi Data:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.ink)),
            const SizedBox(height: 8),
            _syncStep(Icons.check_circle, '1. Validasi integritas data lokal SIAKAD', true),
            _syncStep(Icons.check_circle, '2. Enkripsi paket payload JSON Neo Feeder', true),
            _syncStep(Icons.check_circle, '3. Pengiriman & pencocokan data ke PDDikti', true),
            _syncStep(Icons.task_alt, '4. Penyimpanan log transaksi & token balikan', true),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.ink,
              side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
              shape: const RoundedRectangleBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            ),
            child: const Text('Tutup'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Sinkronisasi $title selesai: 1.847 record berhasil diperbarui di Neo Feeder.'),
                  backgroundColor: const Color(0xFF16A34A),
                ),
              );
            },
            icon: const Icon(Icons.sync, size: 14),
            label: const Text('Mulai Sinkronisasi'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              shape: const RoundedRectangleBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _syncStep(IconData icon, String text, bool active) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: active ? const Color(0xFF16A34A) : AppTheme.muted),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 10.5, color: active ? AppTheme.ink : AppTheme.muted))),
        ],
      ),
    );
  }

  Widget _deadlineRow(String date, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: color.withValues(alpha: 0.1),
            child: Text(date, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: color, fontFamily: 'SpaceMono')),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 11.5, color: AppTheme.ink))),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}
