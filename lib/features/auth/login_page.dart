// Halaman untuk memasukkan NIM/NIP dan password.
//
// Halaman ini mengurus form serta interaksi pengguna.
// Pemeriksaan akun dan durasi sesi berada di AuthService.

import 'package:flutter/material.dart';

import '../../core/app_motion.dart';
import '../../core/app_theme.dart';
import '../../data/auth_service.dart';
import '../../data/student_profile.dart';
import '../../shared/pixel_widgets.dart';
import 'forgot_password_page.dart';

/// Form login yang menerima layanan dan callback dari halaman induk.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.service, required this.onLogin});

  // Layanan yang memeriksa akun.
  final AuthService service;

  // Fungsi untuk memberi tahu AuthGate bahwa login berhasil.
  final ValueChanged<StudentProfile> onLogin;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

/// Menyimpan isian, status loading, dan pesan kesalahan.
class _LoginPageState extends State<LoginPage> {
  // Kunci untuk menjalankan validator pada seluruh form.
  final _form = GlobalKey<FormState>();

  // Menyimpan teks yang diketik pada kolom identitas.
  final _identity = TextEditingController();

  // Menyimpan teks yang diketik pada kolom password.
  final _password = TextEditingController();

  // true berarti password ditampilkan dalam bentuk tersamarkan.
  bool _hidden = true;

  // true berarti proses login sedang berlangsung.
  bool _loading = false;

  // null berarti tidak ada pesan kesalahan.
  String? _error;

  /// Dipanggil oleh tombol MASUK atau tombol selesai pada keyboard.
  Future<void> _login() async {
    // Cegah dua permintaan login berjalan bersamaan.
    if (_loading) return;

    // Lepaskan fokus input untuk menutup keyboard.
    FocusScope.of(context).unfocus();

    // Hentikan proses jika ada kolom yang belum valid.
    if (!_form.currentState!.validate()) return;

    // Perbarui tampilan agar loading muncul dan pesan lama hilang.
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Kirim isian ke layanan login.
      // trim hanya membuang spasi tepi pada NIM/NIP.
      // Password dipertahankan persis seperti yang diketik.
      final student = await widget.service.login(
        identity: _identity.text.trim(),
        password: _password.text,
      );

      // Jangan mengubah halaman yang sudah ditutup.
      if (!mounted) return;

      // Kirim profil ke AuthGate untuk membuka beranda.
      widget.onLogin(student);
    } on AuthException catch (error) {
      // Tampilkan pesan kesalahan akun dari layanan.
      if (mounted) {
        setState(() {
          _error = error.message;
        });
      }
    } catch (_) {
      // Kesalahan lain mendapat pesan umum.
      if (mounted) {
        setState(() {
          _error = 'Tidak dapat masuk. Coba lagi.';
        });
      }
    } finally {
      // Matikan loading setelah proses berhasil maupun gagal.
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // Lepaskan controller saat halaman dibuang agar memori dibersihkan.
    _identity.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AuthLayout(
    // Animasi kemunculan konten mengikuti pengaturan AppMotion.
    child: Entrance(
      child: AuthWindow(
        fileName: 'SIAKAD.EXE',
        subtitle: 'SISTEM AKADEMIK',
        title: 'SIAKAD FASILKOM',

        // Kelompokkan input untuk autofill perangkat.
        // Autofill mengisi kolom; tidak memperpanjang sesi aplikasi.
        child: AutofillGroup(
          child: Form(
            key: _form,

            // Hapus pesan gagal ketika pengguna memperbaiki isian.
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
                  label: 'NIM / NIP',
                  hint: 'Masukkan NIM / NIP',
                  controller: _identity,
                  icon: Icons.person_outline,

                  // Input dikunci sementara ketika login berlangsung.
                  enabled: !_loading,
                  autofillHints: const [AutofillHints.username],

                  // Validator memeriksa kelengkapan isian.
                  // Pemeriksaan kebenaran akun tetap di AuthService.
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'NIM / NIP wajib diisi.';
                    }

                    // null berarti isian lolos pemeriksaan.
                    return null;
                  },
                ),

                // Jarak antara kolom identitas dan password.
                const SizedBox(height: 20),

                PixelField(
                  label: 'PASSWORD',
                  hint: 'Masukkan password',
                  controller: _password,
                  obscure: _hidden,
                  enabled: !_loading,
                  autofillHints: const [AutofillHints.password],

                  // Tombol selesai pada keyboard menjalankan login.
                  action: TextInputAction.done,
                  onSubmitted: (_) => _login(),

                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password wajib diisi.';
                    }

                    return null;
                  },

                  // Ikon mata hanya mengubah tampilan password.
                  suffix: IconButton(
                    tooltip: _hidden
                        ? 'Tampilkan password'
                        : 'Sembunyikan password',

                    // null membuat tombol tidak aktif saat loading.
                    onPressed: _loading
                        ? null
                        : () {
                            setState(() {
                              _hidden = !_hidden;
                            });
                          },

                    // Pergantian ikon dibuat halus.
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

                // Area checkbox sudah dihapus.
                // Sisakan jarak yang rapi menuju pesan dan tombol.
                const SizedBox(height: 16),

                // Perubahan tinggi pesan kesalahan dianimasikan.
                AnimatedSize(
                  duration: AppMotion.duration(context, 220),
                  child: _error == null
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: StatusMessage(message: _error!),
                        ),
                ),

                const SizedBox(height: 8),

                // Tombol utama untuk menjalankan login.
                PixelButton(
                  label: 'MASUK',
                  loading: _loading,
                  onPressed: _login,
                ),

                const SizedBox(height: 14),

                Center(
                  child: AuthNavigationLink(
                    label: 'Lupa password?',

                    // Panah kanan berada setelah tulisan.
                    arrowRight: true,

                    // Tidak bisa membuka halaman lain selama login diproses.
                    onPressed: _loading
                        ? null
                        : () {
                            // Tutup keyboard sebelum berpindah halaman.
                            FocusScope.of(context).unfocus();

                            // Gunakan transisi fade dan geser yang sudah tersedia.
                            Navigator.of(context).push(
                              AppMotion.route(
                                ForgotPasswordPage(service: widget.service),
                              ),
                            );
                          },
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
