// Kotak perkakas tampilan pixel yang dipakai login, pemulihan, dan beranda.
// Setiap kelas membuat bagian kecil yang bisa dipakai ulang dengan isi berbeda.
// Panduan susunan: Row berjajar ke samping, Column ke bawah, Stack bertumpuk,
// Padding memberi ruang dalam, SizedBox memberi jarak, dan Expanded membagi sisa ruang.
// Warna/bingkai mengatur penampilan; onTap/onPressed menentukan aksi ketika disentuh.

import 'package:flutter/material.dart';

import '../core/app_motion.dart';
import '../core/app_theme.dart';

/// Memuat background asli Figma.
///
/// Tidak menggambar ulang laboratorium menggunakan CustomPainter.
// Latar gambar kampus dengan lapisan warna untuk menjaga keterbacaan isi.
class CampusBackground extends StatelessWidget {
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
  const CampusBackground({super.key, this.dashboard = false});

  // Pilih tampilan latar: terang untuk beranda, lebih gelap untuk form login.
  final bool dashboard;

  @override
  // build menyusun tampilan ketika Flutter memintanya.
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      // Baca gambar yang dibundel bersama aplikasi; cover memenuhi area dengan menjaga perbandingan gambar.
      Image.asset(
        AppTheme.backgroundAsset,
        fit: BoxFit.cover,
        alignment: dashboard ? Alignment.topCenter : Alignment.center,

        // Mengikuti image-rendering: pixelated pada CSS Figma.
        filterQuality: FilterQuality.none,

        // Form tetap terlihat jika PNG belum dipasang.
        // Latar polos ini bukan pengganti background desain.
        errorBuilder: (context, error, stackTrace) =>
            const ColoredBox(color: Color(0xFF07101D)),
      ),

      // Dashboard memakai overlay terang.
      // Login memakai overlay gelap tipis seperti CSS referensi.
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: dashboard
                ? [
                    const Color(0xFFF8F5E8).withValues(alpha: .95),
                    const Color(0xFFF2F7F4).withValues(alpha: .98),
                  ]
                : [
                    AppTheme.ink.withValues(alpha: .08),
                    AppTheme.ink.withValues(alpha: .28),
                  ],
          ),
        ),
      ),
    ],
  );
}

/// Logo tiga menara mengikuti FacultyMark pada App.tsx.
// Logo dekoratif fakultas dari tiga menara berbentuk kotak.
class FacultyMark extends StatelessWidget {
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
  const FacultyMark({super.key, this.compact = false});

  // Versi ringkas dipakai pada header; versi besar dapat menyertakan tulisan fakultas.
  final bool compact;

  @override
  // build menyusun tampilan ketika Flutter memintanya.
  Widget build(BuildContext context) => Container(
    width: compact ? 38 : 72,
    height: compact ? 38 : 64,
    decoration: BoxDecoration(
      color: const Color(0xFFF6F0DC),
      border: Border.all(color: AppTheme.ink, width: compact ? 2 : 3),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          // Buat tiga menara logo dengan pola sama; menara tengah dibuat lebih tinggi.
          children: List.generate(
            3,
            (index) => Container(
              width: compact ? 5 : 8,
              height: index == 1 ? (compact ? 22 : 27) : 18,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                color: AppTheme.red,
                border: Border.all(color: AppTheme.ink, width: compact ? 1 : 2),
              ),
            ),
          ),
        ),
        if (!compact) ...[
          const SizedBox(height: 5),
          Text('FASILKOM', style: AppTheme.pixel(6)),
        ],
      ],
    ),
  );
}

/// Avatar geometris mengikuti kepala dan badan pada CSS Figma.
// Avatar dekoratif berbentuk geometris; profil utama saat ini memakai ikon orang.
class StudentAvatar extends StatelessWidget {
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
  const StudentAvatar({super.key});

  @override
  // build menyusun tampilan ketika Flutter memintanya.
  Widget build(BuildContext context) => Container(
    width: 56,
    height: 67,
    decoration: BoxDecoration(
      color: const Color(0xFFE6F2EF),
      border: Border.all(color: Colors.white, width: 3),
    ),
    child: Stack(
      // Potong bagian avatar yang melewati bingkai agar tetap berada dalam kotak.
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned(
          // Bagian atas avatar membentuk kepala dan rambut dengan kotak serta garis tepi.
          top: 11,
          left: 18,
          width: 20,
          height: 21,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFB76E4B),
              border: Border(
                top: BorderSide(color: AppTheme.ink, width: 7),
                left: BorderSide(color: AppTheme.ink, width: 3),
                right: BorderSide(color: AppTheme.ink, width: 3),
                bottom: BorderSide(color: AppTheme.ink, width: 3),
              ),
            ),
          ),
        ),
        Positioned(
          left: 9,
          // Bagian badan sedikit melewati batas bawah sehingga tampak memenuhi bingkai.
          bottom: -5,
          width: 38,
          height: 34,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF164A91),
              border: Border.all(color: AppTheme.ink, width: 3),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Kerangka login dan lupa password.
///
/// Header tetap terlihat.
/// Area form dapat digulir ketika keyboard terbuka.
// Kerangka halaman autentikasi: header, area form yang bisa digulir, dan footer.
class AuthLayout extends StatelessWidget {
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
  const AuthLayout({super.key, required this.child});

  // Isi diberikan pemanggil, sehingga pembungkus yang sama dapat memuat form atau panel lain.
  final Widget child;

  @override
  // build menyusun tampilan ketika Flutter memintanya.
  Widget build(BuildContext context) => Scaffold(
    // Biarkan tinggi halaman mengecil saat keyboard tampil supaya form tidak tertutup.
    resizeToAvoidBottomInset: true,
    backgroundColor: AppTheme.ink,
    body: Stack(
      fit: StackFit.expand,
      children: [
        // Pisahkan pengecatan gambar latar dari perubahan pada form di atasnya.
        const RepaintBoundary(child: CampusBackground()),
        // Jauhkan isi penting dari poni kamera dan area sistem perangkat.
        SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 72),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(
                  color: AppTheme.red,
                  border: Border(
                    bottom: BorderSide(color: AppTheme.ink, width: 5),
                  ),
                ),
                child: Row(
                  children: [
                    const FacultyMark(compact: true),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'FAKULTAS ILMU KOMPUTER',
                        style: AppTheme.pixel(
                          MediaQuery.sizeOf(context).width < 360 ? 9 : 11,
                          color: const Color(0xFFFFF5DC),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: LayoutBuilder(
                  builder: (context, bounds) => SingleChildScrollView(
                    // Menggulir form dengan jari juga dapat menutup keyboard.
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(22, 32, 22, 28),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        // Pusatkan form pada ruang yang tersisa; clamp mencegah tinggi minimum menjadi negatif.
                        minHeight: (bounds.maxHeight - 60)
                            .clamp(0.0, double.infinity)
                            .toDouble(),
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          // Batasi lebar form agar kolom input tetap nyaman dibaca pada layar besar.
                          constraints: const BoxConstraints(maxWidth: 390),
                          child: child,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 18),
                child: Container(
                  color: AppTheme.ink.withValues(alpha: .78),
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    'FASILKOM DIGITAL CAMPUS · V2.4',
                    textAlign: TextAlign.center,
                    style: AppTheme.pixel(6, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Kartu seperti jendela komputer pada desain login.
// Bingkai form seperti jendela komputer dengan bilah judul dan identitas fakultas.
class AuthWindow extends StatelessWidget {
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
  const AuthWindow({
    super.key,
    required this.fileName,
    required this.title,
    required this.subtitle,
    required this.child,
    this.onBack,
  });

  // Teks dekoratif pada bilah jendela, misalnya SIAKAD.EXE; bukan program yang dijalankan.
  final String fileName;
  // Judul utama kartu, misalnya nama sistem atau pemulihan akun.
  final String title;
  // Keterangan pendek di atas judul utama.
  final String subtitle;
  // Isi diberikan pemanggil, sehingga pembungkus yang sama dapat memuat form atau panel lain.
  final Widget child;
  // Aksi kembali opsional; tanpa fungsi ini, bagian tutup hanya menjadi dekorasi.
  final VoidCallback? onBack;

  @override
  // build menyusun tampilan ketika Flutter memintanya.
  Widget build(BuildContext context) => PixelPanel(
    color: AppTheme.paper,
    padding: EdgeInsets.zero,
    borderWidth: 5,
    shadowOffset: 7,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 34,
          padding: const EdgeInsets.only(left: 10, right: 4),
          decoration: const BoxDecoration(
            color: Color(0xFF1677AD),
            border: Border(bottom: BorderSide(color: AppTheme.ink, width: 4)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  fileName,
                  style: AppTheme.pixel(8, color: Colors.white),
                ),
              ),
              // Tombol tutup hanya aktif bila halaman memiliki tujuan kembali.
              if (onBack != null)
                Tooltip(
                  message: 'Kembali ke login',
                  child: InkWell(
                    onTap: onBack,
                    child: const SizedBox(
                      width: 32,
                      height: 30,
                      child: Icon(Icons.close, size: 18, color: Colors.white),
                    ),
                  ),
                )
              else
                // Pada login, X adalah dekorasi seperti referensi Figma.
                ExcludeSemantics(
                  child: Container(
                    margin: const EdgeInsets.only(right: 4),
                    width: 27,
                    height: 25,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCECEF),
                      border: Border.all(color: AppTheme.ink, width: 2),
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 18,
                      color: AppTheme.ink,
                    ),
                  ),
                ),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF143C83), Color(0xFF1959A2)],
            ),
            border: Border(bottom: BorderSide(color: AppTheme.ink, width: 4)),
          ),
          child: Row(
            children: [
              const FacultyMark(),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF99CAE8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: AppTheme.pixel(
                        MediaQuery.sizeOf(context).width < 360 ? 13 : 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(22, 25, 22, 27),
          child: child,
        ),
      ],
    ),
  );
}

/// Panel bersama. Material di DALAM dekorasi membuat efek sentuhan terlihat.
// Bingkai kotak bersama dengan garis tebal, bayangan, dan ruang untuk isi.
class PixelPanel extends StatelessWidget {
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
  const PixelPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.color = Colors.white,
    this.borderWidth = 3,
    this.shadowOffset = 4,
  });

  // Isi diberikan pemanggil, sehingga pembungkus yang sama dapat memuat form atau panel lain.
  final Widget child;
  // Jarak antara bingkai dan isi, bisa ditentukan berbeda untuk tiap penggunaan.
  final EdgeInsetsGeometry padding;
  // Warna latar komponen.
  final Color color;
  // Ketebalan garis tepi untuk mempertahankan gaya kotak pixel.
  final double borderWidth;
  // Jarak bayangan dari kotak agar terlihat memiliki ketebalan.
  final double shadowOffset;

  @override
  // build menyusun tampilan ketika Flutter memintanya.
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      border: Border.all(color: AppTheme.ink, width: borderWidth),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFFB9C3C4),
          offset: Offset(shadowOffset, shadowOffset),
        ),
      ],
    ),
    // Lapisan Material transparan menyediakan permukaan efek sentuh di atas dekorasi.
    child: Material(type: MaterialType.transparency, child: child),
  );
}

/// Permukaan interaktif reusable untuk kartu, menu, dan ikon header.
/// Animasi hanya mengubah posisi/bayangan kecil; isi tidak dibangun setiap frame.
// Kartu interaktif yang dapat diberi aksi dan efek tekanan.
class PixelTapSurface extends StatefulWidget {
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
  const PixelTapSurface({
    super.key,
    required this.child,
    required this.onTap,
    required this.label,
    this.color = Colors.white,
    this.borderColor = const Color(0xFFDBE4E6),
    this.shadowColor = const Color(0xFFC8D0D1),
    this.borderWidth = 2,
    this.padding = EdgeInsets.zero,
  });
  // Isi diberikan pemanggil, sehingga pembungkus yang sama dapat memuat form atau panel lain.
  final Widget child;
  // Fungsi tindakan ketika kartu/tombol disentuh, diberikan oleh halaman pemakai.
  final VoidCallback onTap;
  // Nama yang terlihat atau dibacakan untuk mengenali fungsi komponen.
  final String label;
  // Pisahkan warna latar, bingkai, dan bayangan agar kartu mudah disesuaikan.
  final Color color, borderColor, shadowColor;
  // Ketebalan garis tepi untuk mempertahankan gaya kotak pixel.
  final double borderWidth;
  // Jarak antara bingkai dan isi, bisa ditentukan berbeda untuk tiap penggunaan.
  final EdgeInsetsGeometry padding;

  @override
  // Hubungkan konfigurasi widget dengan objek State yang menyimpan perubahan selama tampil.
  State<PixelTapSurface> createState() => _PixelTapSurfaceState();
}

// Pengatur perubahan posisi dan bayangan kartu selama ditekan.
class _PixelTapSurfaceState extends State<PixelTapSurface> {
  // Simpan apakah jari sedang menekan agar posisi dan bayangan bisa berubah sesaat.
  bool _pressed = false;

  @override
  // build menyusun tampilan ketika Flutter memintanya.
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: widget.label,
    child: AnimatedContainer(
      duration: AppMotion.duration(context, 120),
      curve: Curves.easeOutCubic,
      // Geser kotak beberapa satuan ketika ditekan untuk memberi kesan tombol mekanis.
      transform: Matrix4.translationValues(
        _pressed ? 2 : 0,
        _pressed ? 2 : 0,
        0,
      ),
      decoration: BoxDecoration(
        color: widget.color,
        border: Border.all(
          color: widget.borderColor,
          width: widget.borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.shadowColor,
            offset: Offset(_pressed ? 1 : 3, _pressed ? 1 : 3),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: widget.onTap,
          // Saat tekanan dimulai/berakhir, perbarui _pressed agar efek visual mengikuti sentuhan.
          onHighlightChanged: (value) {
            if (_pressed != value) setState(() => _pressed = value);
          },
          child: Padding(padding: widget.padding, child: widget.child),
        ),
      ),
    ),
  );
}

/// Input bersama untuk login dan lupa password.
// Kolom input seragam yang meneruskan teks dan validasi ke halaman pemakai.
class PixelField extends StatelessWidget {
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
  const PixelField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    required this.validator,
    this.icon,
    this.suffix,
    this.obscure = false,
    this.enabled = true,
    this.keyboardType = TextInputType.text,
    this.action = TextInputAction.next,
    this.onSubmitted,
    this.autofillHints,
  });

  // Nama yang terlihat atau dibacakan untuk mengenali fungsi komponen.
  final String label;
  // Contoh tulisan samar saat kolom belum diisi.
  final String hint;
  // Pengelola teks berasal dari halaman; komponen input hanya memakainya.
  final TextEditingController controller;
  // Fungsi pemeriksa isian: teks hasil adalah pesan salah, null berarti valid.
  final String? Function(String?) validator;
  // Ikon di depan kolom jika diperlukan.
  final IconData? icon;
  // Bagian tambahan di ujung kolom, seperti tombol mata pada password.
  final Widget? suffix;
  // Jika true, samarkan tulisan yang diketik untuk kolom rahasia.
  final bool obscure;
  // Jika false, pengguna sementara tidak dapat mengubah kolom.
  final bool enabled;
  // Pilih bentuk keyboard yang cocok, misalnya papan ketik email.
  final TextInputType keyboardType;
  // Tulisan/tindakan tombol keyboard: lanjut ke kolom berikut atau selesai.
  final TextInputAction action;
  // Aksi opsional saat tombol selesai pada keyboard ditekan.
  final ValueChanged<String>? onSubmitted;
  // Petunjuk ke sistem untuk pengisian otomatis seperti username atau email.
  final Iterable<String>? autofillHints;

  @override
  // build menyusun tampilan ketika Flutter memintanya.
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: AppTheme.pixel(8)),
      const SizedBox(height: 8),

      // Label juga diberikan kepada pembaca layar.
      Semantics(
        label: label,
        child: TextFormField(
          controller: controller,
          validator: validator,
          enabled: enabled,
          obscureText: obscure,
          keyboardType: keyboardType,
          textInputAction: action,
          onFieldSubmitted: onSubmitted,
          autofillHints: autofillHints,
          autocorrect: false,
          // Matikan saran kata untuk password agar kolom rahasia tidak diperlakukan sebagai teks biasa.
          enableSuggestions: !obscure && label != 'PASSWORD',
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon == null
                ? null
                : Icon(icon, size: 20, color: AppTheme.blue),
            suffixIcon: suffix,
          ),
        ),
      ),
    ],
  );
}

/// Tombol hijau dengan efek ditekan dan pergantian loading.
// Tombol aksi dengan efek tekan dan keadaan sedang memproses.
class PixelButton extends StatefulWidget {
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
  const PixelButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  // Nama yang terlihat atau dibacakan untuk mengenali fungsi komponen.
  final String label;
  // Fungsi yang dijalankan saat tombol aktif; null berarti tidak ada tindakan.
  final VoidCallback? onPressed;
  // Pilih indikator tunggu dan cegah ketukan selama proses berjalan.
  final bool loading;

  @override
  // Hubungkan konfigurasi widget dengan objek State yang menyimpan perubahan selama tampil.
  State<PixelButton> createState() => _PixelButtonState();
}

// Menyimpan keadaan tekanan dan memilih tampilan label atau indikator tunggu.
class _PixelButtonState extends State<PixelButton> {
  // Simpan apakah jari sedang menekan agar posisi dan bayangan bisa berubah sesaat.
  bool _pressed = false;

  @override
  // build menyusun tampilan ketika Flutter memintanya.
  Widget build(BuildContext context) => AnimatedContainer(
    duration: AppMotion.duration(context, 100),

    // Tombol bergerak sedikit ketika ditekan.
    // Geser kotak beberapa satuan ketika ditekan untuk memberi kesan tombol mekanis.
    transform: Matrix4.translationValues(_pressed ? 2 : 0, _pressed ? 2 : 0, 0),

    decoration: BoxDecoration(
      color: widget.loading ? const Color(0xFF9BE8BA) : AppTheme.green,
      border: Border.all(color: AppTheme.ink, width: 3),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFFA8CBD1),
          offset: Offset(_pressed ? 1 : 4, _pressed ? 1 : 4),
        ),
      ],
    ),

    child: Material(
      type: MaterialType.transparency,
      child: InkWell(
        // Tombol tidak mengirim aksi baru selama loading agar permintaan tidak berulang.
        onTap: widget.loading ? null : widget.onPressed,
        // Saat tekanan dimulai/berakhir, perbarui _pressed agar efek visual mengikuti sentuhan.
        onHighlightChanged: (value) {
          setState(() {
            _pressed = value;
          });
        },
        child: ConstrainedBox(
          // Pertahankan tinggi sentuh yang nyaman walau tulisan tombol pendek.
          constraints: const BoxConstraints(minHeight: 56),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: _pressed
                      ? const Color(0xFF159743)
                      : const Color(0xFF76F59F),
                  width: 3,
                ),
                left: BorderSide(
                  color: _pressed
                      ? const Color(0xFF159743)
                      : const Color(0xFF76F59F),
                  width: 3,
                ),
                bottom: const BorderSide(color: Color(0xFF159743), width: 3),
                right: const BorderSide(color: Color(0xFF159743), width: 3),
              ),
            ),
            child: Center(
              // Ganti tulisan tombol dengan lingkaran tunggu menggunakan perpindahan yang halus.
              child: AnimatedSwitcher(
                duration: AppMotion.duration(context, 180),
                child: widget.loading
                    ? const SizedBox(
                        key: ValueKey('loading'),
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.ink,
                        ),
                      )
                    : Row(
                        key: const ValueKey('label'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              widget.label,
                              textAlign: TextAlign.center,
                              style: AppTheme.pixel(
                                widget.label.length > 12 ? 10 : 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.chevron_right, size: 18),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Pesan hasil dibacakan pembaca layar sebagai perubahan status.
// Kotak pesan berhasil/gagal yang juga dikenali pembaca layar.
class StatusMessage extends StatelessWidget {
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
  const StatusMessage({super.key, required this.message, this.success = false});

  // Pesan hasil proses yang perlu dibaca pengguna.
  final String message;
  // Pilih warna pesan berhasil atau kesalahan.
  final bool success;

  @override
  // build menyusun tampilan ketika Flutter memintanya.
  Widget build(BuildContext context) => Semantics(
    // Minta pembaca layar mengumumkan perubahan pesan tanpa pengguna harus mencarinya.
    liveRegion: true,
    child: Container(
      padding: const EdgeInsets.all(10),
      color: success ? const Color(0xFFDFF7E8) : const Color(0xFFFFE5E8),
      child: Text(message, style: const TextStyle(fontSize: 11)),
    ),
  );
}
