// PDF hasil keputusan dibuat setelah BAP meninjau, bukan oleh model AI.

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'leave_models.dart';

class LeavePdf {
  static Future<Uint8List> build(LeaveRequest request) async {
    final font = pw.Font.ttf(
      await rootBundle.load('assets/fonts/SpaceMono-Regular.ttf'),
    );
    final document = pw.Document();
    final draft = request.draft;
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        maxPages: 100,
        margin: const pw.EdgeInsets.all(36),
        theme: pw.ThemeData.withFont(base: font, bold: font),
        footer: (context) => pw.Text(
          'SIMULASI LOKAL - Bukan surat resmi kampus | ${context.pageNumber}/${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 8),
        ),
        build: (_) => [
          pw.Text(
            'SIAKAD - HASIL PEMERIKSAAN IZIN',
            style: const pw.TextStyle(fontSize: 17),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'SIMULASI LOKAL - TANPA TANDA TANGAN RESMI',
            style: pw.TextStyle(color: PdfColors.red, fontSize: 11),
          ),
          pw.Divider(),
          for (final entry in {
            'Nomor / versi': '${request.id} / ${request.version}',
            'Mahasiswa': draft.value('Nama'),
            'NIM akun': request.studentId,
            'Program studi': draft.value('Program studi'),
            'Jenis izin': draft.value('Jenis izin'),
            'Rentang izin':
                '${draft.value('Tanggal mulai')} s.d. ${draft.value('Tanggal akhir')}',
            'Keputusan BAP': request.status.label,
            'Pemeriksa': request.reviewer ?? '-',
            'Tanggal keputusan': request.reviewedAt == null
                ? '-'
                : leaveDate(request.reviewedAt!),
          }.entries)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Text(
                '${entry.key}: ${entry.value}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
          pw.SizedBox(height: 10),
          // Sisakan ruang untuk judul dan awal isi agar judul tidak tertinggal sendiri.
          pw.NewPage(freeSpace: 70),
          pw.Text('Alasan mahasiswa', style: const pw.TextStyle(fontSize: 12)),
          pw.Text(
            draft.value('Alasan'),
            overflow: pw.TextOverflow.span,
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 12),
          pw.NewPage(freeSpace: 70),
          pw.Text(
            'Catatan pemeriksaan BAP',
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.Text(
            request.note,
            overflow: pw.TextOverflow.span,
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 12),
          pw.NewPage(freeSpace: 85),
          pw.Text(
            'Perkuliahan dan penerima hasil',
            style: const pw.TextStyle(fontSize: 12),
          ),
          for (final item in draft.classes)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 6),
              child: pw.Text(
                '${item.course}\nKelas: ${item.classCode} | ${item.date}\nKode dosen: ${item.lecturerCode}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
          pw.Divider(),
          pw.Text(
            'Hasil tersedia bagi mahasiswa dan kotak masuk dosen sesuai kode akun dalam simulasi ini. '
            'Mahasiswa dapat meneruskan PDF secara manual. Keputusan ini tidak otomatis mengubah presensi. '
            'Lampiran bukti tidak disertakan dalam PDF.',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );
    return document.save();
  }
}
