// Form permintaan pemulihan akun melalui alamat email.
// Alur saat ini adalah simulasi: email diperiksa bentuknya, lalu layanan ditunggu.
// Keberhasilan simulasi tidak berarti email terkirim atau password berubah.

import 'package:flutter/material.dart';

import '../../core/app_motion.dart';
import '../../core/app_theme.dart';
import '../../data/auth_service.dart';
import '../../shared/pixel_widgets.dart';

// Halaman pemulihan akun yang menerima layanan dari halaman login.
class ForgotPasswordPage extends StatefulWidget {
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
  const ForgotPasswordPage({super.key, required this.service});

  // Gunakan layanan yang sama dengan halaman login melalui parameter dari induk.
  final AuthService service;

  @override
  // Hubungkan konfigurasi widget dengan objek State yang menyimpan perubahan selama tampil.
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

// Menyimpan email dan perkembangan proses permintaan reset.
class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  // Kunci untuk menjalankan validator pada form email.
  final _form = GlobalKey<FormState>();
  // Pengelola teks untuk membaca alamat yang dimasukkan pengguna.
  final _email = TextEditingController();

  // Mencegah pengiriman ulang ketika permintaan sebelumnya masih diproses.
  bool _loading = false;
  // Memilih gaya pesan berhasil; bukan bukti email telah dikirim.
  bool _success = false;
  // Menyimpan hasil simulasi atau pesan gagal; null membuat area pesan kosong.
  String? _message;

  // Periksa email terlebih dahulu, lalu jalankan permintaan melalui layanan.
  Future<void> _submit() async {
    // Abaikan ketukan kedua saat proses yang sama belum selesai.
    if (_loading) return;

    // Lepaskan fokus kolom supaya keyboard menutup.
    FocusScope.of(context).unfocus();

    // Hentikan di sini jika kolom kosong atau bentuk alamat belum valid.
    if (!_form.currentState!.validate()) return;

    // Beritahu Flutter bahwa kondisi form berubah sehingga tampilan perlu diperbarui.
    setState(() {
      _loading = true;
      _success = false;
      _message = null;
    });

    try {
      // trim membersihkan spasi di tepi email; await menunggu simulasi selesai.
      await widget.service.requestReset(_email.text.trim());

      // Jangan menyentuh layar apabila pengguna sudah meninggalkan halaman ini.
      if (!mounted) return;

      // Beritahu Flutter bahwa kondisi form berubah sehingga tampilan perlu diperbarui.
      setState(() {
        _success = true;

        // Jangan mengklaim email sudah dikirim pada layanan demo.
        _message =
            'Simulasi berhasil. Email belum dikirim dan password belum diubah.';
      });
    } catch (_) {
      // Tampilkan pesan yang dapat dipahami jika layanan gagal menyelesaikan permintaan.
      if (mounted) {
        // Beritahu Flutter bahwa kondisi form berubah sehingga tampilan perlu diperbarui.
        setState(() {
          _message = 'Permintaan gagal. Silakan coba lagi.';
        });
      }
    } finally {
      // Matikan status tunggu setelah proses selesai, baik berhasil maupun gagal.
      if (mounted) {
        // Beritahu Flutter bahwa kondisi form berubah sehingga tampilan perlu diperbarui.
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  // Lepaskan pengelola teks ketika halaman ditutup agar tidak tertinggal di memori.
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  // build menyusun tampilan ketika Flutter memintanya.
  Widget build(BuildContext context) => AuthLayout(
    // Transisi halaman sudah ditangani AppMotion.route().
    child: AuthWindow(
      fileName: 'RESET_PASSWORD.EXE',
      subtitle: 'PEMULIHAN AKUN',
      title: 'LUPA PASSWORD?',
      // pop menutup halaman saat ini dan mengembalikan pengguna ke login.
      onBack: () => Navigator.of(context).pop(),

      child: Form(
        key: _form,

        // Pesan lama dihapus ketika email diperbaiki.
        onChanged: () {
          if (_message != null) {
            // Beritahu Flutter bahwa kondisi form berubah sehingga tampilan perlu diperbarui.
            setState(() {
              _message = null;
              _success = false;
            });
          }
        },

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan email yang terdaftar pada akun akademikmu.',
              style: TextStyle(fontSize: 12, color: AppTheme.muted),
            ),

            const SizedBox(height: 22),

            PixelField(
              label: 'EMAIL AKADEMIK',
              hint: 'nama@student.kampus.ac.id',
              controller: _email,
              icon: Icons.mail_outline,
              enabled: !_loading,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              action: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              // Validator memeriksa isi kolom; kembalikan teks jika salah atau null jika lolos.
              validator: (value) {
                final email = value?.trim() ?? '';

                if (email.isEmpty) {
                  return 'Email wajib diisi.';
                }

                // Pola sederhana memeriksa bagian sebelum @, nama domain, dan titik.
                // Ini hanya pemeriksaan bentuk alamat, bukan pemeriksaan apakah email benar-benar ada.
                final valid = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                    .hasMatch(email);

                if (!valid) {
                  return 'Alamat email belum valid.';
                }

                return null;
              },
            ),

            const SizedBox(height: 22),

            PixelButton(
              label: 'KIRIM LINK RESET',
              loading: _loading,
              onPressed: _submit,
            ),

            AnimatedSize(
              duration: AppMotion.duration(context, 220),
              // Sembunyikan kotak hasil bila belum ada pesan, atau tampilkan sesuai statusnya.
              child: _message == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(top: 18),
                      child: StatusMessage(
                        message: _message!,
                        success: _success,
                      ),
                    ),
            ),

            const SizedBox(height: 14),

            Center(
              child: AuthNavigationLink(
                label: 'Kembali ke login',

                // Panah kiri berada sebelum tulisan.
                arrowRight: false,

                onPressed: () {
                  // Tutup keyboard sebelum kembali.
                  FocusScope.of(context).unfocus();

                  // Tutup halaman ini.
                  // Route yang sama menjalankan transisi kembali secara otomatis.
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
