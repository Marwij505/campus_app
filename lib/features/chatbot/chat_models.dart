// Data lokal chatbot: pesan, kategori bantuan, dan draf selama sesi login.
// Tidak ada nilai, identitas kampus, kontak dosen, atau status kirim buatan.
import 'dart:typed_data';

enum ChatMode { guided, localAi }

class ChatMessage {
  const ChatMessage(this.text, {this.isUser = false, this.isAi = false});
  final String text;
  final bool isUser;
  final bool isAi;
}

enum HelpTopic {
  academic(
    'Tanya Akademik',
    'Panduan resmi kampus belum tersedia. Saya belum dapat memastikan syarat atau aturan kampus. Anda dapat menyiapkan pertanyaan untuk petugas.',
  ),
  contact(
    'Hubungi Dosen',
    'Data kontak dosen belum tersedia. Chat langsung dan pengiriman WhatsApp belum terhubung. Belum ada pesan yang dikirim.',
  ),
  letter(
    'Buat Surat Izin',
    'Isi data manual, tanggal izin, alasan, dan lampiran bukti untuk membuat draf lokal. Draf belum dikirim ke kampus.',
  ),
  issue(
    'Laporkan Kendala',
    'Tuliskan kendala untuk membuat draf pengajuan. Nomor pengajuan dan pelacakan resmi belum tersedia.',
  ),
  files(
    'Periksa Berkas',
    'Pemeriksaan lokal hanya mencakup format, ukuran, dan keberadaan lampiran. Isi, keaslian, serta OCR belum diperiksa. Tambahkan berkas lewat formulir draf.',
  ),
  records(
    'KRS, Nilai & Tagihan',
    'Data KRS, nilai, presensi, dan tagihan belum terhubung. Tampilan kosong tidak berarti nilai nol atau tagihan lunas.',
  ),
  study(
    'Pendamping Belajar',
    'Aktifkan AI lokal untuk bertanya tentang konsep umum. Materi dosen dan panduan skripsi atau magang resmi belum tersedia.',
  );

  const HelpTopic(this.label, this.reply);
  final String label;
  final String reply;
}

// Jawaban terpandu selalu jujur mengenai sumber yang belum tersedia.
// Permintaan layanan kampus ditangani secara pasti sebelum mencapai model AI.
bool needsCampusData(String text) => RegExp(
  r'\b(krs|ipk|ips|presensi|tagihan|dosen|nim|biodata|profil|kampus|siakad|izin|surat|lampiran|whatsapp)\b|nilai saya|jadwal saya|esa unggul|kirim pengajuan',
  caseSensitive: false,
).hasMatch(text);

String guidedReply(String text) {
  final value = text.toLowerCase();
  if (RegExp(r'izin|sakit|surat').hasMatch(value)) {
    return HelpTopic.letter.reply;
  }
  if (RegExp(r'dosen|kontak|whatsapp|pembimbing').hasMatch(value)) {
    return HelpTopic.contact.reply;
  }
  if (RegExp(
    r'krs|nilai|ipk|ips|presensi|tagihan|bayar|jadwal|nim|biodata|profil',
  ).hasMatch(value)) {
    return HelpTopic.records.reply;
  }
  if (RegExp(r'berkas|lampiran|gambar|screenshot|pdf').hasMatch(value)) {
    return HelpTopic.files.reply;
  }
  if (RegExp(r'kendala|lapor|error').hasMatch(value)) {
    return HelpTopic.issue.reply;
  }
  if (RegExp(r'syarat|aturan|cuti|skripsi|magang').hasMatch(value)) {
    return HelpTopic.academic.reply;
  }
  return 'Saya dalam mode bantuan terpandu. Pilih bantuan di atas untuk membuat draf atau melihat ketersediaan layanan. Untuk pertanyaan bebas, aktifkan AI lokal. Data kampus belum terhubung.';
}

// Berkas ditampung di RAM, tidak diunggah ke Ollama maupun server kampus.
class DraftAttachment {
  const DraftAttachment(this.name, this.bytes);
  final String name;
  final Uint8List bytes;
  bool get isImage => !name.toLowerCase().endsWith('.pdf');

  // Periksa penanda awal berkas juga, bukan hanya nama ekstensi.
  static String? validate(String name, Uint8List bytes) {
    if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
      return 'Berkas harus berisi data dan berukuran maksimal 5 MB.';
    }
    final lower = name.toLowerCase();
    final pdf =
        lower.endsWith('.pdf') &&
        bytes.length >= 5 &&
        String.fromCharCodes(bytes.take(5)) == '%PDF-';
    final png =
        lower.endsWith('.png') &&
        bytes.length >= 8 &&
        [
          137,
          80,
          78,
          71,
          13,
          10,
          26,
          10,
        ].asMap().entries.every((e) => bytes[e.key] == e.value);
    final jpg =
        (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) &&
        bytes.length >= 3 &&
        bytes[0] == 255 &&
        bytes[1] == 216 &&
        bytes[2] == 255;
    return pdf || png || jpg
        ? null
        : 'Gunakan berkas PDF, JPG, atau PNG dengan format yang sesuai.';
  }
}

enum DraftKind { letter, issue }

class StudentDraft {
  StudentDraft(this.kind);
  final DraftKind kind;
  // Semua identitas diisi manual dan belum diverifikasi kampus.
  final fields = <String, String>{};
  final attachments = <DraftAttachment>[];
  String? preview;
  String get title =>
      kind == DraftKind.letter ? 'Draf Surat Izin' : 'Draf Kendala';
  String value(String key) => fields[key]?.trim() ?? '';

  // Tanggal memakai format tegas supaya 31 Februari tidak dinormalisasi diam-diam.
  static DateTime? parseDate(String input) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(input)) return null;
    final date = DateTime.tryParse(input);
    return date != null && date.toIso8601String().startsWith(input)
        ? date
        : null;
  }

  String? validate() {
    final required = kind == DraftKind.letter
        ? [
            'Nama',
            'NIM',
            'Penerima',
            'Tanggal mulai',
            'Tanggal akhir',
            'Alasan',
          ]
        : ['Nama', 'NIM', 'Kategori', 'Ringkasan', 'Kronologi'];
    if (required.any((key) => value(key).isEmpty)) {
      return 'Lengkapi seluruh kolom wajib.';
    }
    if (kind == DraftKind.letter) {
      final start = parseDate(value('Tanggal mulai'));
      final end = parseDate(value('Tanggal akhir'));
      if (start == null || end == null) {
        return 'Gunakan tanggal yang valid dengan format YYYY-MM-DD.';
      }
      if (end.isBefore(start)) {
        return 'Tanggal akhir tidak boleh mendahului tanggal mulai.';
      }
      if (attachments.isEmpty) {
        return 'Tambahkan bukti terlebih dahulu sebelum membuat pratinjau surat.';
      }
    }
    return null;
  }

  // Template merangkai fakta yang diisi pengguna; tidak menambahkan diagnosis atau keputusan.
  String compose() {
    final error = validate();
    if (error != null) throw StateError(error);
    final files = attachments.isEmpty
        ? 'Belum ada'
        : attachments.map((a) => a.name).join(', ');
    if (kind == DraftKind.issue) {
      return 'DRAF KENDALA — BELUM DIKIRIM\n\nNama: ${value('Nama')}\nNIM: ${value('NIM')}\nKategori: ${value('Kategori')}\nRingkasan: ${value('Ringkasan')}\n\nKronologi:\n${value('Kronologi')}\n\nLampiran: $files\n\nIdentitas manual, belum diverifikasi kampus.';
    }
    return 'DRAF SURAT IZIN — BELUM DIKIRIM\n\nYth. ${value('Penerima')}\n\nDengan hormat,\nSaya, ${value('Nama')} (NIM ${value('NIM')}), mengajukan izin pada ${value('Tanggal mulai')} sampai ${value('Tanggal akhir')}.\n\nAlasan izin:\n${value('Alasan')}\n\nSebagai bahan pertimbangan, saya melampirkan: $files.\nDemikian permohonan ini saya sampaikan. Terima kasih atas perhatian Bapak/Ibu.\n\nHormat saya,\n${value('Nama')}\n\nIdentitas manual, belum diverifikasi kampus. Keputusan izin mengikuti pemeriksaan pihak yang berwenang.';
  }
}
