// Layar tempat pengguna memasukkan identitas dan password.
// Urutan proses: periksa isian, panggil layanan login, lalu kirim profil ke AuthGate.
// Halaman mengurus interaksi pengguna; pemeriksaan akun berada di AuthService.
// Nama berawalan _ hanya bisa digunakan di dalam pustaka Dart berkas ini.

import 'package:flutter/material.dart';

import '../../core/app_motion.dart';
import '../../core/app_theme.dart';
import '../../data/auth_service.dart';
import '../../data/student_profile.dart';
import '../../shared/pixel_widgets.dart';
import 'forgot_password_page.dart';

// Form masuk yang menerima layanan login dan fungsi pemberitahuan keberhasilan.
class LoginPage extends StatefulWidget {
  // Constructor menerima data/pengaturan awal ketika objek ini dibuat.
  const LoginPage({super.key, required this.service, required this.onLogin});

  // Layanan yang diberikan induk halaman untuk memeriksa akun.
  final AuthService service;
  // Fungsi balasan yang memberi tahu induk bahwa login berhasil beserta profilnya.
  final ValueChanged<StudentProfile> onLogin;

  @override
  // Hubungkan konfigurasi widget dengan objek State yang menyimpan perubahan selama tampil.
  State<LoginPage> createState() => _LoginPageState();
}

// Menyimpan isian, pilihan sesi, status tunggu, dan kesalahan selama halaman dibuka.
class _LoginPageState extends State<LoginPage> {
  // Kunci untuk menemukan Form dan menjalankan seluruh pemeriksaan isian sekaligus.
  final _form = GlobalKey<FormState>();
  // Controller menyimpan dan membaca teks yang sedang diketik pada kolom identitas.
  final _identity = TextEditingController();
  // Controller terpisah untuk membaca password persis seperti yang diketik.
  final _password = TextEditingController();

  // true menyamarkan tulisan password; false menampilkannya.
  bool _hidden = true;
  // Menyimpan pilihan lama sesi demo, bukan menyimpan password ke perangkat.
  bool _remember = false;
  // Penanda proses login sedang berlangsung; tombol dan input sementara dikunci.
  bool _loading = false;
  // Pesan gagal yang ditampilkan; null berarti tidak ada pesan kesalahan.
  String? _error;

  // Jalankan alur login setelah tombol MASUK atau tombol selesai di keyboard ditekan.
  Future<void> _login() async {
    // Cegah submit ganda dari tombol maupun keyboard.
    if (_loading) return;

    // Tutup fokus input agar keyboard tidak menghalangi hasil proses.
    FocusScope.of(context).unfocus();

    // Jika validator menemukan kolom kosong, tampilkan pesannya dan hentikan proses.
    if (!_form.currentState!.validate()) return;

    setState(() {
      // setState meminta layar menampilkan indikator tunggu dan menghapus pesan lama.
      _loading = true;
      _error = null;
    });

    try {
      // Tunggu hasil layanan tanpa membekukan layar. trim membuang spasi tepi pada identitas.
      final student = await widget.service.login(
        identity: _identity.text.trim(),
        password: _password.text,
        rememberSession: _remember,
      );

      // Halaman mungkin sudah ditutup ketika proses async selesai.
      if (!mounted) return;

      widget.onLogin(student);
    } on AuthException catch (error) {
      // Kesalahan akun yang dikenali boleh ditampilkan dengan pesan dari layanan.
      if (mounted) {
        setState(() {
          _error = error.message;
        });
      }
    } catch (_) {
      // Kesalahan lain mendapat pesan umum agar pengguna tetap mendapat penjelasan.
      if (mounted) {
        setState(() {
          _error = 'Tidak dapat masuk. Coba lagi.';
        });
      }
    } finally {
      // Bagian ini tetap dijalankan setelah berhasil atau gagal untuk mengakhiri loading.
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // Lepaskan controller agar tidak terus menggunakan memori.
    _identity.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  // build menyusun tampilan ketika Flutter memintanya.
  Widget build(BuildContext context) => AuthLayout(
    child: Entrance(
      child: AuthWindow(
        fileName: 'SIAKAD.EXE',
        subtitle: 'SISTEM AKADEMIK',
        title: 'SIAKAD FASILKOM',

        // Kelompokkan identitas dan password agar pengisian otomatis mengenalinya sebagai satu akun.
        child: AutofillGroup(
          child: Form(
            key: _form,

            // Hapus pesan server lama ketika pengguna memperbaiki isian.
            onChanged: () {
              if (_error != null) {
                setState(() {
                  _error = null;
                });
              }
            },

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PixelField(
                  // Kolom identitas: wajib terisi sebelum layanan login dipanggil.
                  label: 'NIM / NIP',
                  hint: 'Masukkan NIM / NIP',
                  controller: _identity,
                  icon: Icons.person_outline,
                  enabled: !_loading,
                  autofillHints: const [AutofillHints.username],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'NIM / NIP wajib diisi.';
                    }
                    // Pada validator, null berarti isian lolos pemeriksaan.
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                PixelField(
                  // Kolom password: tampilannya mengikuti _hidden, isinya tetap sama.
                  label: 'PASSWORD',
                  hint: 'Masukkan password',
                  controller: _password,
                  obscure: _hidden,
                  enabled: !_loading,
                  autofillHints: const [AutofillHints.password],
                  action: TextInputAction.done,
                  onSubmitted: (_) => _login(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password wajib diisi.';
                    }
                    // Pada validator, null berarti isian lolos pemeriksaan.
                    return null;
                  },

                  // Ikon mata hanya mengubah terlihat/tidaknya password, bukan nilainya.
                  suffix: IconButton(
                    tooltip: _hidden
                        ? 'Tampilkan password'
                        : 'Sembunyikan password',
                    onPressed: _loading
                        ? null
                        : () {
                            setState(() {
                              _hidden = !_hidden;
                            });
                          },
                    icon: AnimatedSwitcher(
                      duration: AppMotion.duration(context, 160),
                      child: Icon(
                        _hidden
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        key: ValueKey(_hidden),
                        color: AppTheme.blue,
                        size: 20,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                // Area sentuh tetap cukup besar, meski checkbox tampil kecil.
                InkWell(
                  onTap: _loading
                      ? null
                      : () => setState(() => _remember = !_remember),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 32,
                        height: 44,
                        child: Checkbox(
                          value: _remember,
                          activeColor: const Color(0xFF19BD5C),
                          shape: const RoundedRectangleBorder(),
                          onChanged: _loading
                              ? null
                              : (value) =>
                                    setState(() => _remember = value ?? false),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'Simpan sesi masuk',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Tinggi area pesan berubah secara halus.
                AnimatedSize(
                  duration: AppMotion.duration(context, 220),
                  // Pesan kesalahan hanya memakan ruang bila memang ada isi pesan.
                  child: _error == null
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: StatusMessage(message: _error!),
                        ),
                ),

                const SizedBox(height: 8),

                PixelButton(
                  label: 'MASUK',
                  loading: _loading,
                  onPressed: _login,
                ),

                const SizedBox(height: 14),

                Center(
                  child: TextButton(
                    onPressed: _loading
                        ? null
                        : () {
                            // Tambahkan halaman pemulihan ke tumpukan navigasi agar pengguna bisa kembali.
                            Navigator.of(context).push(
                              AppMotion.route(
                                ForgotPasswordPage(service: widget.service),
                              ),
                            );
                          },
                    child: const Text(
                      'Lupa password?',
                      style: TextStyle(
                        color: AppTheme.ink,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
