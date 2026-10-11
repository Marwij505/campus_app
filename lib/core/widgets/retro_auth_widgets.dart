// Kumpulan komponen autentikasi alternatif dengan latar laboratorium hasil gambar kode.
// Halaman login utama sekarang memakai komponen di shared/pixel_widgets.dart.
// Berkas ini tetap dijelaskan agar perannya tidak tertukar dengan komponen aktif.
// Row menyusun ke samping, Column ke bawah, Stack menumpuk lapisan, dan child adalah isi.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../graphics/pixel_lab_painter.dart';
import '../theme/retro_theme.dart';

/// Latar, header fakultas, footer, dan posisi kartu yang sama pada dua halaman.
// Kerangka autentikasi alternatif dengan header, ilustrasi lab, dan footer.
class RetroAuthScaffold extends StatelessWidget {
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
  const RetroAuthScaffold({super.key, required this.child});
  // Tampilan isi diberikan dari luar sehingga kerangka dapat digunakan berulang.
  final Widget child;

  @override
  // build menyusun tampilan ketika Flutter memintanya.
  Widget build(BuildContext context) => Scaffold(
    // Tinggi body otomatis menyesuaikan keyboard; konten dapat digulir.
    resizeToAvoidBottomInset: true,
    body: Stack(
      fit: StackFit.expand,
      children: [
        // Pisahkan kanvas latar yang statis dari pembaruan komponen form di atasnya.
        const RepaintBoundary(child: CustomPaint(painter: PixelLabPainter())),
        // Lapisan tipis menjaga keterbacaan kartu, sementara lab tetap terlihat.
        ColoredBox(color: RetroTheme.ink.withValues(alpha: 0.10)),
        // Hindarkan isi dari bagian layar yang dipakai kamera atau kontrol sistem.
        SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                decoration: const BoxDecoration(
                  color: RetroTheme.red,
                  border: Border(
                    top: BorderSide(color: Color(0xFFEA7885), width: 3),
                    bottom: BorderSide(color: RetroTheme.ink, width: 4),
                  ),
                ),
                child: Row(
                  children: [
                    const PixelLogo(size: 38, showLabel: false),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'FAKULTAS ILMU KOMPUTER',
                        style: RetroTheme.pixel(14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      // Izinkan gerakan gulir menutup keyboard ketika pengguna ingin melihat bagian lain.
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(18, 30, 22, 34),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          // Isi minimal setinggi ruang yang tersisa, tetapi tidak pernah memiliki tinggi negatif.
                          minHeight: math.max(0.0, constraints.maxHeight - 64),
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            // Cegah form melebar berlebihan pada monitor besar.
                            constraints: const BoxConstraints(maxWidth: 390),
                            child: child,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                width: double.infinity,
                color: RetroTheme.ink.withValues(alpha: 0.94),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Text(
                  'FASILKOM DIGITAL CAMPUS',
                  textAlign: TextAlign.center,
                  style: RetroTheme.pixel(9, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Logo geometris pengganti sementara, bukan logo resmi institusi.
// Logo geometris alternatif yang ukurannya dapat diatur.
class PixelLogo extends StatelessWidget {
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
  const PixelLogo({super.key, this.size = 64, this.showLabel = true});
  // Ukuran dasar logo; potongan di dalamnya memakai proporsi ukuran ini.
  final double size;
  // Tentukan apakah tulisan FASILKOM ikut ditampilkan di bawah menara.
  final bool showLabel;

  @override
  // build menyusun tampilan ketika Flutter memintanya.
  Widget build(BuildContext context) => Semantics(
    label: 'Ikon Fasilkom',
    image: true,
    // Pembaca layar cukup membaca nama logo dari pembungkus, tanpa mengulang bagian dekoratif.
    child: ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4D8),
          border: Border.all(color: RetroTheme.ink, width: 2),
          boxShadow: const [
            BoxShadow(color: Color(0xFFA6B9C7), offset: Offset(2, 2)),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(size * 0.10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  // Gambar tiga menara dengan pola yang sama; menara tengah dibuat lebih tinggi.
                  children: List.generate(
                    3,
                    (i) => Container(
                      width: size * 0.13,
                      height: size * (i == 1 ? 0.49 : 0.36),
                      margin: EdgeInsets.symmetric(horizontal: size * 0.025),
                      decoration: BoxDecoration(
                        color: RetroTheme.red,
                        border: Border.all(color: RetroTheme.ink, width: 2),
                      ),
                    ),
                  ),
                ),
              ),
              if (showLabel) ...[
                const SizedBox(height: 5),
                Text('FASILKOM', style: RetroTheme.pixel(size * 0.105)),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

/// Kartu seperti jendela komputer retro: title bar, brand biru, dan isi form.
// Bingkai jendela retro untuk menampung form dari pemanggil.
class RetroWindow extends StatelessWidget {
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
  const RetroWindow({
    super.key,
    required this.fileName,
    required this.title,
    required this.subtitle,
    required this.child,
    this.onBack,
  });
  // Nama dekoratif bilah jendela, bukan berkas yang dibuka atau dieksekusi.
  final String fileName;
  // Judul utama yang menjelaskan fungsi kartu.
  final String title;
  // Keterangan singkat di atas judul.
  final String subtitle;
  // Tampilan isi diberikan dari luar sehingga kerangka dapat digunakan berulang.
  final Widget child;
  // Fungsi kembali opsional untuk mengaktifkan tombol tutup.
  final VoidCallback? onBack;

  @override
  // build menyusun tampilan ketika Flutter memintanya.
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: RetroTheme.paper,
      border: Border.all(color: RetroTheme.ink, width: 4),
      boxShadow: const [
        BoxShadow(color: Color(0xFF071121), offset: Offset(6, 6)),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.only(left: 10, right: 4),
          decoration: const BoxDecoration(
            color: RetroTheme.titleBar,
            border: Border(bottom: BorderSide(color: RetroTheme.ink, width: 3)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  fileName,
                  style: RetroTheme.pixel(11, color: Colors.white),
                ),
              ),
              // Tampilkan tombol kembali hanya jika aksi tersebut memang diberikan.
              if (onBack != null)
                IconButton(
                  tooltip: 'Kembali ke login',
                  onPressed: onBack,
                  icon: const Icon(
                    Icons.close,
                    color: RetroTheme.ink,
                    size: 21,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: RetroTheme.paper,
                    shape: const RoundedRectangleBorder(
                      side: BorderSide(color: RetroTheme.ink, width: 2),
                    ),
                    minimumSize: const Size(44, 44),
                  ),
                )
              else
                // Halaman pertama tidak memiliki tujuan "tutup"; gunakan dekorasi
                // kotak, tanpa menampilkan tombol X yang tidak dapat bekerja.
                const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(Icons.crop_square, color: Colors.white, size: 20),
                ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF183D83), RetroTheme.blue],
            ),
            border: Border(bottom: BorderSide(color: RetroTheme.ink, width: 4)),
          ),
          child: Row(
            children: [
              const PixelLogo(),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subtitle,
                      style: RetroTheme.pixel(
                        9,
                        color: const Color(0xFFA4D5EF),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      title,
                      style: RetroTheme.pixel(23, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: child,
        ),
      ],
    ),
  );
}

/// Kemunculan kartu: transparan + geser 16px. child tidak dibangun ulang
/// pada setiap frame sehingga animasi lebih ringan.
// Efek muncul sekali dari transparan menjadi terlihat sambil bergeser sedikit.
class RetroEntrance extends StatelessWidget {
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
  const RetroEntrance({super.key, required this.child});
  // Tampilan isi diberikan dari luar sehingga kerangka dapat digunakan berulang.
  final Widget child;

  @override
  // build menyusun tampilan ketika Flutter memintanya.
  Widget build(BuildContext context) {
    // Lewati efek gerak bila pengaturan aksesibilitas meminta animasi dikurangi.
    if (MediaQuery.disableAnimationsOf(context)) return child;
    // Naikkan nilai dari 0 ke 1 untuk membuat isi muncul dan bergeser ke posisi normal.
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Label di atas input + border persegi. TextFormField tetap mendukung
/// validasi, autofill, keyboard Android, dan pembaca layar.
// Kolom isian alternatif dengan label, validasi, ikon, dan bingkai kotak.
class RetroField extends StatelessWidget {
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
  const RetroField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    required this.validator,
    required this.icon,
    this.obscureText = false,
    this.suffix,
    this.enabled = true,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.autofillHints,
    this.enableSuggestions = true,
  });
  // Tulisan yang membantu pengguna mengenali kolom atau tombol.
  final String label;
  // Contoh isian yang terlihat samar ketika kolom masih kosong.
  final String hint;
  // Pengelola isi teks dibuat oleh pemakai komponen, lalu diteruskan ke TextFormField.
  final TextEditingController controller;
  // Pemeriksa kolom mengembalikan pesan jika salah dan null jika benar.
  final String? Function(String?) validator;
  // Simbol yang ditampilkan bersama kolom atau tombol.
  final IconData icon;
  // Samarkan karakter saat kolom dipakai untuk password.
  final bool obscureText;
  // Isi tambahan di ujung kolom, seperti tombol untuk membuka tampilan password.
  final Widget? suffix;
  // Atur apakah kolom sedang boleh diubah pengguna.
  final bool enabled;
  // Pilih jenis papan ketik yang sesuai dengan jenis isian.
  final TextInputType keyboardType;
  // Atur tombol lanjut/selesai pada papan ketik.
  final TextInputAction textInputAction;
  // Fungsi opsional yang menerima isi ketika pengguna mengirim lewat keyboard.
  final ValueChanged<String>? onSubmitted;
  // Petunjuk untuk fasilitas pengisian otomatis perangkat.
  final Iterable<String>? autofillHints;
  // Tentukan apakah saran kata dari keyboard boleh muncul.
  final bool enableSuggestions;

  @override
  // build menyusun tampilan ketika Flutter memintanya.
  Widget build(BuildContext context) {
    // Buat bingkai yang sama dengan warna dan ketebalan berbeda sesuai keadaan input.
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: color, width: width),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: RetroTheme.pixel(12)),
        const SizedBox(height: 9),
        Semantics(
          label: label,
          child: TextFormField(
            controller: controller,
            enabled: enabled,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            onFieldSubmitted: onSubmitted,
            validator: validator,
            autofillHints: autofillHints,
            autocorrect: false,
            enableSuggestions: enableSuggestions,
            style: const TextStyle(fontSize: 14, color: RetroTheme.ink),
            decoration: InputDecoration(
              // Label semantik tetap tersedia meskipun label visual di luar input.
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 13, color: RetroTheme.muted),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 18,
              ),
              prefixIcon: Icon(icon, color: RetroTheme.blue, size: 21),
              suffixIcon: suffix,
              border: border(RetroTheme.ink, 3),
              enabledBorder: border(RetroTheme.ink, 3),
              disabledBorder: border(RetroTheme.muted, 2),
              // Bingkai berubah saat kolom dipilih; bingkai error berubah ketika validasi gagal.
              focusedBorder: border(RetroTheme.titleBar, 3),
              errorBorder: border(RetroTheme.red, 2),
              focusedErrorBorder: border(RetroTheme.red, 3),
              errorMaxLines: 3,
            ),
          ),
        ),
      ],
    );
  }
}

/// Tombol pixel dengan efek ditekan 3px, bayangan tegas, dan loading.
// Tombol alternatif dengan efek tekanan, ikon, dan status loading.
class RetroButton extends StatefulWidget {
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
  const RetroButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon = Icons.chevron_right,
  });
  // Tulisan yang membantu pengguna mengenali kolom atau tombol.
  final String label;
  // Aksi tombol dari pemakai; null berarti tombol tidak aktif.
  final VoidCallback? onPressed;
  // Penanda untuk mengganti tulisan tombol dengan indikator proses.
  final bool loading;
  // Simbol yang ditampilkan bersama kolom atau tombol.
  final IconData icon;

  @override
  // Hubungkan konfigurasi widget dengan objek State yang menyimpan perubahan selama tampil.
  State<RetroButton> createState() => _RetroButtonState();
}

// Pengatur efek tekanan dan keadaan aktif tombol.
class _RetroButtonState extends State<RetroButton> {
  // Keadaan sesaat ketika jari menekan, untuk menggerakkan tombol dan bayangannya.
  bool _pressed = false;

  @override
  // build menyusun tampilan ketika Flutter memintanya.
  Widget build(BuildContext context) {
    // Nonaktifkan tombol selama loading atau ketika tidak ada tindakan yang diberikan.
    final disabled = widget.loading || widget.onPressed == null;
    // Pilih durasi nol bagi pengguna yang mengurangi animasi.
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 120);
    // Semantics membuat tombol custom dikenali TalkBack sebagai tombol.
    return Semantics(
      button: true,
      enabled: !disabled,
      label: widget.loading ? 'Sedang memproses' : widget.label,
      child: AnimatedContainer(
        duration: duration,
        // Geser tombol sedikit ke bawah saat ditekan untuk memberi kesan fisik.
        transform: Matrix4.translationValues(0, _pressed ? 3 : 0, 0),
        decoration: BoxDecoration(
          color: disabled ? const Color(0xFF9BE4BB) : RetroTheme.green,
          border: Border.all(color: RetroTheme.ink, width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF75B895),
              offset: Offset(_pressed ? 1 : 4, _pressed ? 1 : 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            // Aksi hanya diteruskan saat tombol aktif.
            onTap: disabled ? null : widget.onPressed,
            // Perbarui efek tekan ketika sentuhan mulai atau dilepas.
            onHighlightChanged: (value) => setState(() => _pressed = value),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                child: Center(
                  // Tukar label dan indikator loading dengan perpindahan singkat.
                  child: AnimatedSwitcher(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 180),
                    child: widget.loading
                        ? const SizedBox(
                            key: ValueKey('loading'),
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: RetroTheme.ink,
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
                                  style: RetroTheme.pixel(18),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Icon(widget.icon, size: 23),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pesan hasil yang ikut dianimasikan tanpa menutupi form.
// Kotak pesan hasil dengan warna sesuai keberhasilan proses.
class RetroNotice extends StatelessWidget {
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
  const RetroNotice({super.key, required this.message, this.success = false});
  // Pesan yang ingin dijelaskan kepada pengguna setelah proses.
  final String message;
  // Warna hijau untuk hasil berhasil, merah untuk pesan kesalahan.
  final bool success;

  @override
  // build menyusun tampilan ketika Flutter memintanya.
  Widget build(BuildContext context) => Semantics(
    // Pembaca layar diberi tahu ketika isi pesan berubah.
    liveRegion: true,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: success ? const Color(0xFFDFF8E9) : const Color(0xFFFFE9EC),
        border: Border.all(
          color: success ? const Color(0xFF257447) : RetroTheme.red,
          width: 2,
        ),
      ),
      child: Text(message, style: const TextStyle(fontSize: 13, height: 1.5)),
    ),
  );
}
