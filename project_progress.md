# Project Progress — Campus App / SIAKAD FASILKOM Esa Unggul

**Tanggal audit awal:** 1 November 2026, zona waktu Asia/Jakarta.  
**Pembaruan terakhir:** 4 November 2026 — penambahan prosedur manajemen token, verifikasi teknologi melalui source/configuration, dan pedoman kesinambungan sesi pada bagian P. Pembaruan ini hanya dokumentasi.
**Verifikasi fungsional terakhir:** 3 November 2026 — pengiriman OTP Resend nyata terverifikasi, pengujian ulang Flutter/Deno/SQL, dan pencatatan skill/plugin Resend. Navigasi bawah tetap menjadi pintasan gulir dengan Chatbot di tengah.
**Repository lokal:** `C:/Users/Marcell/Repositories/campus_app`.  
**Branch aktif:** `marcell-works`.  
**Git HEAD dasar pengerjaan OTP:** `d2e584f61975f793c56da3903d60b7562ca453ce`.
**Versi aplikasi dalam pubspec:** `1.0.0+1`; nama package `campus_app`.  
**Jenis dokumen:** audit kondisi aktual, keputusan pengembangan, dan serah terima.

## Ringkasan eksekutif

Campus App adalah aplikasi Flutter untuk Sistem Informasi Akademik Fakultas Ilmu Komputer Universitas Esa Unggul. Fondasi antarmuka responsif, dashboard, menu bertingkat, chatbot lokal, formulir profil, dan simulasi izin sudah tersedia. **Sistem belum merupakan SIAKAD produksi dengan seluruh data akademik terhubung.**

Integrasi nyata yang paling maju adalah **Supabase Auth, profil mahasiswa, lima bagian biodata, foto, dan penyimpanan berkas privat**. Dashboard menggunakan identitas dari Supabase, tetapi sumber jadwal, IPK, nilai, presensi, dan pengumuman masih `EmptyDashboardRepository`. Halaman riwayat keuangan sudah membaca tabel Supabase; tabel tersebut masih kosong dan belum memiliki alur penerbitan tagihan maupun pembayaran nyata.

Smart Chatbot menggabungkan aturan aplikasi, glosarium, pengenal pesan singkat, jawaban profil dari sesi, dan model Ollama lokal `qwen2.5:1.5b`. Jawaban akademik personal harus menyatakan bahwa data belum terhubung. Profil sendiri dapat dijawab tanpa mengirim profil secara otomatis ke model. RAG, akses data akademik lengkap, dan transaksi layanan melalui AI belum tersedia.

Izin Online mempunyai formulir, validasi, status peninjauan BAP, penerima berdasarkan kode dosen, dan PDF. Namun repositorinya masih **memori proses**, penerima dosen masih contoh, dan login nyata saat ini menyelesaikan NIM mahasiswa saja. Karena itu, alur mahasiswa–BAP–dosen lintas akun/perangkat belum menjadi layanan backend nyata.

Audit awal mencatat **208 tes Flutter lulus** pada 1 November. Perbaikan emulator/nama dan navigasi sebelumnya memiliki bukti historis terpisah di bagian J. Setelah revisi OTP pada 2 November, **seluruh 218 tes Flutter lulus**, `flutter analyze --no-pub` bersih, dan build web berhasil. **15 tes Deno** serta uji SQL OTP dengan rollback pada Supabase juga lulus. Angka subset historis tidak dijumlahkan dengan suite terbaru. **APK debug terbaru berhasil dibangun** memakai JBR 25.0.3 bawaan Android Studio dan cache Gradle terpisah setelah menemui lock/JDK 26; APK OTP ini belum diuji interaktif pada emulator.

Lupa password sekarang memakai kode enam karakter campuran huruf besar dan angka yang diketik di aplikasi. Server memeriksa kelayakan akun, membatasi percobaan, menyimpan HMAC, dan mencabut sesi setelah reset. Migrasi serta Edge Function `password-reset` sudah diterapkan. **Pada 3 November, satu permintaan OTP nyata menghasilkan email berstatus delivered di Resend; format kode sesuai.** Seluruh 218 tes Flutter dan 15 tes Deno kembali lulus, analisis bersih, serta tes SQL OTP lulus dengan rollback. Password pengguna tidak diubah. Reset password dan login ulang nyata melalui aplikasi masih perlu diuji; rincian ada di bagian J dan `docs/password_reset_otp.md`.

Pada dashboard dengan lebar di bawah 600 px, navigasi bawah berurutan **Beranda, Jadwal, Chatbot, Akademik, Profil**. Chatbot menjadi tombol bulat menonjol di tengah. Empat tombol lainnya merupakan pintasan informasi landing page: Beranda menggulir ke awal dashboard, Jadwal ke panel jadwal hari ini, Akademik ke Kemajuan Belajar, dan Profil ke kartu informasi mahasiswa. Tombol tersebut tidak membuka halaman baru. Indikator aktif mengikuti tombol terakhir yang diketuk. Halaman kumpulan menu Akademik dari navigasi bawah sudah dihapus; layanan akademik tetap tersedia melalui Executive Menu. Akses Cepat tetap membuka halaman masing-masing. Halaman lain serta dashboard layar lebar mempertahankan launcher Chatbot kanan bawah.

Nama teknis proyek diseragamkan menjadi `campus_app`, termasuk konfigurasi platform, judul jendela desktop, metadata executable, modul IDE, dan metadata preview lokal. Android/Linux menggunakan `com.example.campus_app`; bundle identifier iOS/macOS menggunakan `com.example.campusApp`. Login nyata sebelumnya dikonfirmasi pengguna pada web; login nyata di emulator, penyimpanan terbaru pada semua perangkat, pemulihan email, dan seluruh format foto masih memerlukan verifikasi.

**Peringatan serah terima:** working tree awal pengerjaan OTP bersih pada HEAD di atas. Perubahan OTP, tes, dan dokumentasi saat ini belum di-commit. Clone HEAD tersebut belum mendapatkan revisi OTP sampai perubahan dibagikan melalui Git. Database dan fungsi cloud sudah diterapkan terpisah; merge tidak mengisi secrets Resend.

### Dasar dan batas audit

- Fakta utama berasal dari source `lib/`, `test/`, `supabase/`, skrip `tool/`, konfigurasi platform, dokumentasi, status Git, dan riwayat commit.
- Audit awal 1 November memakai plugin Supabase secara baca saja. Pada pengerjaan OTP 2 November, plugin dipakai untuk pemeriksaan schema, penerapan migrasi `password_reset_otp`, deploy fungsi, tes SQL rollback, dan pemeriksaan advisor. Pengujian 2 November tidak mengirim email atau mereset password pengguna. Pada 3 November, satu email OTP nyata dikirim melalui endpoint aplikasi dan statusnya diperiksa melalui plugin Resend; password tetap tidak diubah.
- Audit awal membaca akhir tiga log pengujian di `build/`. Ketiga log tersebut tidak lagi tersedia saat pembaruan 2 November, sehingga hasilnya dicatat sebagai bukti historis. Bukti tambahan berasal dari hasil perintah pada sesi perbaikan, artefak APK/EXE, dan screenshot lokal `build/diagnostics/`. Cache dan artefak lokal dapat hilang saat `flutter clean`; objek Git dan isi model `.local-ai` tidak diaudit.
- Bukti dibedakan menjadi **source saat audit**, **metadata backend saat audit**, **log pengujian tersimpan**, **konfirmasi pengguna**, dan **rencana/rekomendasi**. Keberadaan source atau tes bukan bukti bahwa semua skenario sudah berhasil pada semua perangkat.
- Audit ini bukan pengujian penetrasi, sertifikasi keamanan, penilaian kepatuhan institusi, atau persetujuan penggunaan data produksi.
- Path bukti di bawah relatif terhadap root repository agar dokumen dapat dipindahkan ke komputer anggota tim lain. Data pribadi, kata sandi, dan nilai kunci akses sengaja tidak disalin.
- Batas tugas audit dokumentasi awal hanya `project_progress.md`. Permintaan berikutnya secara eksplisit mengizinkan implementasi OTP/Resend, perubahan backend yang terkait, pengujian, dan pembaruan dokumentasi ini.

## Daftar isi

- [A. Project Overview](#a-project-overview)
- [B. Project Vision & Final Objectives](#b-project-vision--final-objectives)
- [C. Complete Project Structure](#c-complete-project-structure)
- [D. Current Development Progress](#d-current-development-progress)
- [E. Application Architecture](#e-application-architecture)
- [F. Database & Backend Development](#f-database--backend-development)
- [G. AI Chatbot Development](#g-ai-chatbot-development)
- [H. UI/UX Development](#h-uiux-development)
- [I. Authentication & Security](#i-authentication--security)
- [J. Testing & Quality Assurance](#j-testing--quality-assurance)
- [K. Development History & Technical Decisions](#k-development-history--technical-decisions)
- [L. Known Issues & Technical Debt](#l-known-issues--technical-debt)
- [M. Development Roadmap](#m-development-roadmap)
- [N. Priority Tasks & Next Development Steps](#n-priority-tasks--next-development-steps)
- [O. Project Handover — New Codex Account](#o-project-handover--new-codex-account)
- [P. Prosedur Manajemen Token — GPT-6 Astra High](#p-prosedur-manajemen-token--gpt-6-astra-high)

## A. Project Overview

### Identitas, latar belakang, dan masalah

Aplikasi bernama teknis `campus_app`, dengan identitas antarmuka SIAKAD FASILKOM. Pengembangannya bertujuan menyatukan akses informasi akademik mahasiswa, identitas pribadi, layanan kampus, dan bantuan percakapan. Referensi pengguna adalah tampilan SIAKAD mahasiswa Esa Unggul dalam screenshot percakapan, bukan izin untuk menyalin data pribadi dan angka akademik dari screenshot ke database.

Masalah yang dituju meliputi navigasi layanan yang tersebar, pencarian informasi saat mahasiswa terburu-buru, pembaruan biodata, pengurusan izin, dan keterbatasan tampilan pada ukuran layar berbeda. Chatbot diarahkan memahami pesan pendek seperti `jadwal`, `ipk`, `krs`, dan `izin`, tanpa mengarang informasi ketika sumber resmi belum tersedia.

### Pengguna dan ruang lingkup

| Pengguna | Tujuan penggunaan | Kondisi saat audit |
|---|---|---|
| Mahasiswa | Login, melihat/mengubah data pribadi yang diizinkan, membaca informasi akademik, mengajukan izin, memakai chatbot | Login dan profil nyata; akademik sebagian besar kosong; izin lokal |
| BAP/pengelola pembelajaran | Memeriksa kelayakan izin, memberi keputusan dan catatan | Model peran dan antarmuka simulasi tersedia; akses backend staf belum tersedia |
| Dosen | Menerima keputusan izin untuk kelas yang relevan | Kode penerima dan pembatasan tampilan lokal tersedia; belum pengiriman lintas perangkat |
| Pengelola data kampus | Menetapkan identitas resmi, data akademik, tagihan, dan kebijakan | Dapat mengelola backend melalui alat administrasi; aplikasi admin khusus belum tersedia |
| Tim pengembang | Mengembangkan modul melalui branch, menguji antarmuka dan integrasi | Branch aktif `marcell-works`; perubahan terbaru belum seluruhnya di-commit |

Istilah BAP pada alur aplikasi mengacu pada **unit yang memeriksa pengajuan**. Berita Acara Perkuliahan merupakan dokumen/catatan kegiatan; penyebutan tersebut tidak otomatis menjadikan dokumen sebagai aktor pengguna. Nama unit, kewenangan, dan ketentuan persetujuan perlu ditetapkan bersama pihak kampus sebelum produksi.

### Platform dan teknologi

- Frontend: Flutter/Dart, Material 3 dengan komponen khusus bergaya pixel/retro.
- Platform scaffold: web, Android, iOS, Windows, macOS, Linux. Keberadaan folder platform tidak berarti semua target sudah dibangun dan diuji.
- Lingkungan yang digunakan: Windows, VS Code, PowerShell, Chrome, Flutter 3.47.5/Dart 3.13.4 pada host pengujian. Build web tercatat pada 1 November; build APK debug dan Windows debug berhasil pada 2 November. Startup Android diverifikasi pada AVD `Medium_Phone` x86_64; runtime Windows, perangkat Android fisik, iOS, macOS, dan Linux belum diverifikasi melalui pengujian terbaru ini.
- Backend nyata: Supabase berbasis PostgreSQL, Auth, Storage, Data API/RPC, dan dua Edge Function TypeScript/Deno: `login-with-nim` dan `password-reset`.
- AI: Ollama portable khusus proyek pada host Windows, diakses melalui HTTP lokal/LAN; model tidak dibundel ke Flutter.
- Pengelolaan state: `StatefulWidget`, `ChangeNotifier`, listener, dan objek repository/service yang diinjeksi. Tidak ditemukan penerapan Provider, Riverpod, atau Bloc sebagai fondasi saat ini.

Konsep pembeda yang sedang dibangun adalah bantuan mahasiswa melalui satu antarmuka responsif, akses cepat yang konsisten dengan menu, dan chatbot yang membedakan data nyata dari informasi umum. Keunggulan tersebut merupakan arah produk; belum ada studi pembanding atau pengukuran pengguna yang membuktikan keunggulan atas sistem kampus lain.

## B. Project Vision & Final Objectives

### Sasaran akhir

Sasaran akhir adalah sistem akademik yang menampilkan data milik pengguna yang benar, memiliki layanan kampus dengan status yang dapat ditelusuri, serta menyediakan bantuan AI yang tidak melampaui hak akses. Sistem harus dapat didemonstrasikan dan, jika kelak disetujui institusi, dioperasikan sesuai ruang lingkup dan kebijakan kampus.

| Area tujuan | Target akhir | Batas kondisi sekarang |
|---|---|---|
| Dashboard | Ringkasan jadwal, progres, nilai, presensi, informasi dan pengumuman terkini | Layout/model siap; sumber akademik belum diintegrasikan |
| Profil | Identitas resmi terkelola; biodata, pendidikan, keluarga, pekerjaan, disabilitas, dan berkas tersimpan aman | Implementasi Supabase tersedia; verifikasi pengguna terbaru belum lengkap |
| KRS dan nilai | Pengambilan mata kuliah, persetujuan, hasil studi dan riwayat yang konsisten | Menu/halaman kosong; belum transaksi atau aturan KRS |
| Jadwal dan kalender | Informasi hari ini, kelas berikutnya, kalender akademik resmi | Komponen pembacaan tersedia tanpa sumber data resmi |
| Keuangan | Riwayat, tagihan, dan proses pembayaran yang dapat diverifikasi | Tabel baca riwayat tersedia; penerbitan tagihan/virtual account belum ada |
| Izin Online | Mahasiswa mengirim bukti; BAP memutuskan; mahasiswa memperoleh PDF; dosen terkait menerima hasil | Alur lokal tersedia; backend, akun staf, dan pengiriman belum nyata |
| Komunikasi | Interaksi mahasiswa dengan dosen atau unit akademik | Belum chat antarmanusia/notifikasi layanan nyata |
| AI akademik | Pesan singkat dipahami; sumber resmi dan data pribadi diakses melalui API berotorisasi | Aturan, tutor lokal dan sebagian jawaban profil ada; tahap data akademik belum lengkap |
| Keamanan | Hak akses server, sesi terbatas, privasi berkas, pemulihan akun, pengujian lintas pengguna | Fondasi tersedia; audit dan kesiapan produksi masih berlanjut |
| UX | Nyaman di desktop, tablet, HP, keyboard dan teks besar | Responsivitas telah diuji pada widget; perlu uji perangkat dan aksesibilitas lanjutan |

### Standar dan keputusan yang perlu dipertahankan

1. Nilai yang belum tersedia tetap kosong/tidak diketahui. Jangan mengubahnya menjadi IPK nol, tagihan lunas, atau kesimpulan tidak ada kuliah tanpa sumber yang sah.
2. Pengguna meminta gaya kode **hybrid**: pembagian file menurut tanggung jawab, tanpa satu file menampung seluruh sistem atau pemecahan satu fungsi kecil menjadi banyak file. Tidak ada ukuran numerik 50% yang ditetapkan sebagai metrik source.
3. Komentar kode harus memakai bahasa Indonesia yang mudah dipahami, terutama untuk alur data, validasi, dan keputusan penting. Komentar yang ketinggalan harus diperbarui pada tugas implementasi terkait.
4. Identitas, peran, nilai, status akademik dan tagihan resmi tidak boleh menjadi input bebas mahasiswa.
5. Komunikasi kerja dengan pengguna mengikuti preferensi Caveman yang singkat; kualitas kode, keamanan, pengujian, dan dokumentasi rinci tidak dikurangi.
6. Gunakan plugin Supabase bila pekerjaan memerlukan backend dan tersedia. Perubahan data harus mempunyai kebutuhan jelas; jangan membuat data rekaan hanya agar UI tampak penuh.
7. Pertahankan desain aplikasi secara umum. Revisi profil mengikuti struktur referensi SIAKAD; kesamaan visual 100% belum dibuktikan dan tidak boleh diklaim.
8. Eksekusi AI lokal harus mudah untuk pengembang. Target otomatis tidak berarti browser/HP dapat menyalakan proses host tanpa mekanisme host yang sudah dipasang.

## C. Complete Project Structure

Pohon berikut mencakup source fitur dan konfigurasi penting. Berkas scaffold platform standar dikelompokkan; dependensi, hasil build, dan model besar tidak diperinci.

```text
campus_app/
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── app_theme.dart
│   │   ├── app_motion.dart
│   │   ├── responsive_layout.dart
│   │   ├── config/{app_startup.dart,supabase_config.dart}
│   │   ├── navigation/app_page_route.dart
│   │   ├── theme/retro_theme.dart
│   │   ├── graphics/pixel_lab_painter.dart
│   │   └── widgets/retro_auth_widgets.dart
│   ├── data/
│   │   ├── auth_service.dart
│   │   ├── supabase_auth_service.dart
│   │   ├── password_reset_validation.dart
│   │   ├── student_profile.dart
│   │   ├── profile_repository.dart
│   │   ├── supabase_profile_repository.dart
│   │   ├── profile_photo.dart
│   │   ├── profile_phone.dart
│   │   ├── biodata_fields.dart
│   │   ├── biodata_repository.dart
│   │   ├── dashboard_models.dart
│   │   └── dashboard_repository.dart
│   ├── features/
│   │   ├── auth/
│   │   │   ├── login_page.dart
│   │   │   ├── forgot_password_page.dart
│   │   │   └── reset_password_page.dart
│   │   ├── dashboard/
│   │   │   ├── dashboard_page.dart
│   │   │   ├── executive_menu.dart
│   │   │   ├── dashboard_detail_page.dart
│   │   │   ├── dashboard_widgets.dart
│   │   │   ├── academic_charts.dart
│   │   │   ├── information_panels.dart
│   │   │   ├── profile_panel.dart
│   │   │   └── study_progress_panel.dart
│   │   ├── profile/
│   │   │   ├── profile_page.dart
│   │   │   ├── edit_profile_page.dart
│   │   │   ├── biodata_form.dart
│   │   │   └── profile_records.dart
│   │   ├── chatbot/
│   │   │   ├── chat_models.dart
│   │   │   ├── chat_controller.dart
│   │   │   ├── chat_page.dart
│   │   │   ├── chat_widgets.dart
│   │   │   ├── chat_launcher.dart
│   │   │   ├── chat_connection.dart
│   │   │   ├── connection_settings.dart
│   │   │   ├── ollama_service.dart
│   │   │   ├── chat_policy.dart
│   │   │   ├── chat_protocol.dart
│   │   │   ├── student_topics.dart
│   │   │   ├── student_intents.dart
│   │   │   ├── profile_answers.dart
│   │   │   ├── draft_page.dart
│   │   │   ├── draft_editor.dart
│   │   │   └── draft_language.dart
│   │   └── leave/
│   │       ├── leave_models.dart
│   │       ├── leave_repository.dart
│   │       ├── leave_page.dart
│   │       ├── leave_form.dart
│   │       ├── leave_detail.dart
│   │       ├── leave_widgets.dart
│   │       └── leave_pdf.dart
│   └── shared/{pixel_widgets.dart,student_profile_avatar.dart}
├── test/
│   ├── app_startup_test.dart
│   ├── auth_service_test.dart
│   ├── supabase_auth_test.dart
│   ├── password_reset_widget_test.dart
│   ├── widget_test.dart
│   ├── profile_test.dart
│   ├── profile_widget_test.dart
│   ├── profile_export_test.dart
│   ├── biodata_test.dart
│   ├── biodata_widget_test.dart
│   ├── dashboard_data_test.dart
│   ├── dashboard_widget_test.dart
│   ├── executive_menu_test.dart
│   ├── chat_connection_test.dart
│   ├── chat_launcher_test.dart
│   ├── chat_quality_test.dart
│   ├── chatbot_logic_test.dart
│   ├── chatbot_widget_test.dart
│   ├── student_intents_test.dart
│   ├── draft_editor_test.dart
│   ├── leave_workflow_test.dart
│   ├── leave_widget_test.dart
│   ├── support/{fake_auth_service.dart,supabase_fixture.dart}
│   └── fixtures/chatbot_quality.json
├── assets/
│   ├── images/pixel-campus.png
│   ├── fonts/ [PressStart2P-Regular, SpaceMono-Regular/Bold, lisensi OFL]
│   └── local_ai/default.json
├── supabase/
│   ├── config.toml
│   ├── seed_profile.sql
│   ├── functions/login-with-nim/index.ts
│   ├── functions/password-reset/{index.ts,handler.ts,otp.ts,services.ts}
│   ├── functions/password-reset/{handler_test.ts,services_test.ts}
│   ├── migrations/
│   │   ├── 20261030080318_student_profiles.sql
│   │   ├── 20261031082459_session_rpc_boundaries.sql
│   │   ├── 20261101015234_student_biodata_sections.sql
│   │   └── 20261102065453_password_reset_otp.sql
│   └── tests/{profile_access.sql,password_reset.sql}
├── tool/
│   ├── android/configure_emulator.ps1
│   ├── verify_profile_photo.dart
│   └── local_ai/
│       ├── flutter_hook.ps1
│       ├── install_autostart.ps1
│       ├── runtime.ps1
│       ├── setup.ps1
│       ├── start.ps1
│       ├── stop.ps1
│       ├── firewall.ps1
│       ├── test_autostart.ps1
│       ├── test_recovery.ps1
│       ├── smoke.dart
│       └── evaluate.dart
├── docs/
│   ├── android_emulator.md
│   ├── student_profile.md
│   ├── profile_test_checklist.md
│   ├── smart_chatbot.md
│   ├── chatbot_quality.md
│   ├── local_ai_autostart.md
│   └── izin_online.md
├── android/ [Gradle, manifest, runner, ikon]
├── ios/ [Runner, Info.plist, Xcode scaffold]
├── macos/ [Runner, entitlement, Xcode scaffold]
├── windows/ [CMake, runner, ikon]
├── linux/ [CMake, runner]
├── web/{index.html,manifest.json,favicon.png,icons/}
├── .vscode/settings.json
├── .github/ [artefak alat modernisasi; bukan workflow CI aplikasi]
├── .gitignore
├── .metadata
├── analysis_options.yaml
├── campus_app.code-workspace
├── pubspec.yaml
├── pubspec.lock
├── README.md
└── project_progress.md
```

### Tanggung jawab file dan kelompok penting

| Path | Tanggung jawab |
|---|---|
| `lib/main.dart` | Inisialisasi, `CampusApp`, `AuthGate`, pergantian login/dashboard, timer sesi, pembersihan halaman privat |
| `lib/core/config/app_startup.dart` | Menangani inisialisasi async dan keadaan gagal sebelum aplikasi utama |
| `lib/core/config/supabase_config.dart` | URL/publishable key melalui konfigurasi, inisialisasi Supabase; token tidak dipersistenkan |
| `lib/core/app_theme.dart`, `app_motion.dart`, `responsive_layout.dart` | Tema aktif, transisi, pengurangan animasi, breakpoint dan grid |
| `lib/data/auth_service.dart`, `profile_repository.dart` | Kontrak service/repository agar UI dan tes tidak bergantung langsung pada backend tertentu |
| `lib/data/supabase_auth_service.dart` | Login NIM melalui Edge Function, sesi, logout, recovery, penggantian password |
| `lib/data/supabase_profile_repository.dart` | Membaca identitas serta mengubah atribut profil/foto dengan JWT pengguna |
| `lib/data/biodata_fields.dart` | Definisi field, bagian formulir, pilihan, dan validasi; pusat perubahan skema UI |
| `lib/data/biodata_repository.dart` | CRUD bagian biodata dan dokumen, konflik versi, nama berkas aman, pembacaan keuangan |
| `lib/data/profile_phone.dart`, `profile_photo.dart` | Normalisasi telepon dan pipeline pembacaan/konversi foto |
| `lib/data/dashboard_models.dart` | Model jadwal, pengumuman, konseling, panduan, hasil semester, dan progres |
| `lib/data/dashboard_repository.dart` | Kontrak sumber dashboard dan implementasi kosong yang aktif |
| `lib/features/dashboard/*` | Halaman induk, menu desktop/mobile, detail, kartu dan grafik; bukan sumber data akademik |
| `lib/features/profile/*` | Ringkasan profil, preferensi foto/nama, formulir lima bagian, berkas dan riwayat biaya |
| `lib/features/chatbot/*` | Pengendali percakapan, routing maksud, koneksi model, protokol jawaban, draf dan UI |
| `lib/features/leave/*` | Model dan workflow izin lokal, UI mahasiswa/BAP/dosen, lampiran serta PDF |
| `lib/shared/pixel_widgets.dart` | Komponen visual bersama: latar, tanda fakultas, layout autentikasi, panel, input, tombol dan status |
| `lib/shared/student_profile_avatar.dart` | Foto atau avatar pixel pria/perempuan/netral untuk profil |
| `supabase/migrations/*` | Riwayat DDL, privilege, RLS, fungsi sesi, bucket, dan perluasan biodata |
| `supabase/seed_profile.sql` | Provisioning profil pengembangan yang terkait akun Auth; bukan data awal universal untuk semua pengguna |
| `supabase/tests/profile_access.sql` | Pemeriksaan akses menggunakan fixture dalam transaksi yang di-rollback |
| `tool/local_ai/*` | Instalasi/pemulihan/runtime lokal dan pengait perintah Flutter pada host Windows |
| `tool/android/configure_emulator.ps1` | Mengatur cold boot pada AVD pilihan di host Windows, menolak emulator yang masih aktif, dan membuat cadangan konfigurasi sebelum perubahan |
| `docs/android_emulator.md` | Bukti diagnosis layar hitam, cara menerapkan pengaturan lokal, pemeriksaan startup, dan pemulihan konfigurasi AVD |
| `docs/profile_test_checklist.md` | Checklist manual profil, dokumen, sesi, foto, recovery dan perangkat |

`lib/data/demo_data.dart` dan `lib/features/auth/services/auth_service.dart` tercatat **dihapus pada working tree**, bukan file aktif. Fixture di `test/support/` tetap diperlukan untuk tes. `demoLecturers` masih berada di `lib/features/leave/leave_models.dart`; jangan menyatakan seluruh dummy sudah hilang.

Folder `.local-ai/`, `build/`, `.dart_tool/`, `.idea/`, `.widget_preview/`, `.git/`, serta file `assets/local_ai/connection.json` adalah data lokal/cache/hasil alat dan tidak dirinci di pohon. `.gitignore` mengabaikan runtime/model, konfigurasi koneksi LAN hasil proses, rahasia lokal, cache Supabase CLI, dan beberapa registrant plugin platform. Aturan ignore tidak otomatis menghapus file yang sudah dilacak Git.

Modul IDE lokal sekarang bernama `campus_app.iml` dan `android/campus_app_android.iml`; `.idea/modules.xml` menunjuk kedua nama tersebut. Metadata `.widget_preview/web/` juga telah diselaraskan. Berkas IDE/cache yang diabaikan Git tidak otomatis dibagikan saat push. Konfigurasi cold boot berada pada direktori AVD masing-masing komputer, di luar repository; yang dibagikan adalah skrip dan panduannya.

### Dependensi langsung

Versi di tabel adalah **deklarasi pubspec**, bukan klaim seluruh package berada pada versi terbaru. `pubspec.lock` adalah sumber versi hasil resolusi yang harus dipertahankan untuk aplikasi.

| Package/alat | Deklarasi | Fungsi |
|---|---|---|
| Dart SDK | `^3.13.3` | Rentang kompatibilitas bahasa/SDK proyek |
| Flutter SDK / Material | SDK | UI, navigasi, rendering, aksesibilitas |
| `cupertino_icons` | `^2.0.0` | Ikon tambahan |
| `http` | `^1.6.0` | HTTP Ollama dan kebutuhan transport |
| `file_selector` | `^1.1.0` | Memilih dan menyimpan berkas |
| `share_plus` | `13.3.1` | Ekspor melalui lembar berbagi perangkat |
| `shared_preferences` | `^2.5.6` | Preferensi alamat AI, bukan penyimpanan sesi Auth |
| `pdf`, `printing` | `^3.13.1`, `^5.15.1` | Pembuatan dan pembagian/pratinjau PDF |
| `supabase_flutter` | `2.18.3` | Auth, Data API, RPC, Storage, Edge Function |
| `image` | `4.12.0` | Dekode, orientasi, ukuran dan konversi foto |
| `flutter_test`, `flutter_lints` | SDK, `^6.0.0` | Tes dan analisis Dart |
| `share_plus_platform_interface` | `7.2.0`, dev dependency | Pengujian integrasi antarmuka berbagi |

## D. Current Development Progress

**Makna status:** COMPLETED berarti selesai untuk cakupan yang disebut dan memiliki bukti verifikasi; bukan berarti siap produksi keseluruhan. PARTIALLY COMPLETED berarti ada implementasi dengan pekerjaan tersisa. IN PROGRESS menunjukkan pengembangan aktif yang belum ditutup. PLANNED berasal dari tujuan yang telah dibahas. NOT IMPLEMENTED berarti kapabilitas belum ditemukan. NEEDS VERIFICATION menunjukkan bukti belum cukup. Tidak digunakan persentase agregat.

| No. | Fitur/Modul | Status | Implementasi Aktual | Bukti File | Pekerjaan Selanjutnya |
|---|---|---|---|---|---|
| 1 | Startup dan penanganan gagal inisialisasi | COMPLETED | Startup async dengan tampilan kegagalan; tes tersedia dalam suite lulus | `lib/core/config/app_startup.dart`, `test/app_startup_test.dart` | Pertahankan regresi |
| 2 | Login mahasiswa Supabase | COMPLETED | NIM dipetakan privat ke Auth; login nyata dikonfirmasi pengguna | `supabase/functions/login-with-nim/index.ts`, `lib/data/supabase_auth_service.dart` | Verifikasi akun kedua dan provisioning tim |
| 3 | Logout dan sesi absolut | COMPLETED | Batas 30 menit, pencabutan, timer/resume, pembersihan UI; pengujian kontrak/RLS tersedia | `lib/main.dart`, `supabase/migrations/*`, `test/supabase_auth_test.dart` | Uji waktu nyata lintas perangkat tetap diperlukan |
| 4 | Forgot/change password | PARTIALLY COMPLETED | OTP campuran 6 karakter, Resend adapter, RPC service-only, rate limit, TTL, revoke sesi; backend deployed; satu email uji delivered pada 3 November | `lib/features/auth/*`, `supabase/functions/password-reset/`, `docs/password_reset_otp.md` | Uji reset/login nyata dan sesi lama lintas perangkat; verifikasi domain pengirim sebelum penggunaan umum |
| 5 | Dashboard responsif | PARTIALLY COMPLETED | Layout, kartu, ringkasan, grafik dan keadaan kosong; belum data akademik nyata | `lib/features/dashboard/*`, `lib/data/dashboard_repository.dart` | Repository backend akademik |
| 6 | Executive Menu | COMPLETED | Menu bertingkat desktop/mobile, teks konsisten, scroll/keyboard; tes widget lulus | `executive_menu.dart`, `test/executive_menu_test.dart` | Isi modul tujuan yang masih kosong |
| 7 | Akses Cepat | COMPLETED | Tujuan bersama menu; profil/izin/chat/jadwal mendapat handler khusus | `dashboard_page.dart`, `test/dashboard_widget_test.dart` | Tambahkan tujuan nyata saat modul siap |
| 8 | Profil resmi dan preferensi | PARTIALLY COMPLETED | Profil dari Supabase; panggilan/foto/telepon dapat disimpan; field resmi dibatasi | `supabase_profile_repository.dart`, `features/profile/*` | Konfirmasi persistensi terbaru dari browser pengguna |
| 9 | Lima formulir biodata | PARTIALLY COMPLETED | Biodata, pendidikan, keluarga, pekerjaan, disabilitas; validasi dan konflik versi | `biodata_fields.dart`, `biodata_repository.dart`, `biodata_form.dart` | Uji nyata seluruh bagian dan katalog wilayah |
| 10 | Foto multi-format dan avatar | PARTIALLY COMPLETED | Konversi raster, tiga avatar, desain perempuan terpisah; tes dan probe web | `profile_photo.dart`, `student_profile_avatar.dart`, `tool/verify_profile_photo.dart` | Uji foto kamera/HEIC/AVIF pada perangkat target |
| 11 | Telepon fleksibel | COMPLETED | Input lokal termasuk 08 dan kode negara dinormalisasi sebelum disimpan | `profile_phone.dart`, `test/biodata_test.dart` | Pertahankan uji seluruh field kontak |
| 12 | Pemisahan email kampus/pribadi/Auth | PARTIALLY COMPLETED | Email kampus read-only; kontak pribadi terpisah dari akun pemulihan | `biodata_fields.dart`, migrasi biodata, `profile_answers.dart` | Uji perubahan kontak tanpa mengubah Auth |
| 13 | Berkas persyaratan | PARTIALLY COMPLETED | Lima kategori, private Storage, ganti/hapus/ekspor, validasi | `profile_records.dart`, `biodata_repository.dart` | Uji operasi nyata/mobile; template resmi dan pembersihan orphan |
| 14 | Riwayat keuangan profil | PARTIALLY COMPLETED | Tabel dan UI baca kelompok periode/kategori; belum berisi catatan | migrasi biodata, `profile_records.dart` | Sumber resmi dan proses pengelola |
| 15 | Pembayaran/virtual account | NOT IMPLEMENTED | Tujuan menu/halaman kosong tersedia | `dashboard_page.dart`, `dashboard_detail_page.dart` | Tentukan backend, penyedia dan rekonsiliasi |
| 16 | Jadwal perkuliahan | PARTIALLY COMPLETED | Model, panel hari ini, daftar/detail dan pemilihan kelas aktif | `dashboard_models.dart`, `information_panels.dart` | Data jadwal dan otorisasi kelas |
| 17 | KRS | PLANNED | Menu dan halaman kosong; belum pengisian/persetujuan | `executive_menu.dart`, `dashboard_page.dart` | Skema, prasyarat, kuota dan workflow resmi |
| 18 | Nilai, KHS, IPK/IPS, presensi | PARTIALLY COMPLETED | Ringkasan/grafik dan tujuan halaman; nilai nyata belum dihubungkan | `academic_charts.dart`, `study_progress_panel.dart` | Backend hasil studi/presensi dan perhitungan tervalidasi |
| 19 | Konseling | PARTIALLY COMPLETED | Panel/model dan halaman tujuan; tidak ada booking backend | `information_panels.dart`, `dashboard_page.dart` | Jadwal konselor, permohonan, akses sensitif |
| 20 | Pengumuman/panduan | PARTIALLY COMPLETED | Komponen daftar/detail tanpa sumber nyata | `information_panels.dart`, `dashboard_repository.dart` | Pengelolaan konten dan publikasi |
| 21 | Kalender akademik/notifikasi | PLANNED | Konsep informasi harian; belum kalender resmi/push notification | `dashboard_models.dart`, tidak ada service push | Definisikan event, preferensi dan kanal |
| 22 | Program akademik/tugas akhir | PLANNED | KKN, KKP, praktik, proyek, tugas akhir dan layanan lain terdaftar di menu | `executive_menu.dart` | Modul data, persyaratan dan workflow per layanan |
| 23 | Chatbot: routing pesan singkat/glosarium | COMPLETED | Pola terkurasi, pilihan ?, konteks topik, izin/ijin, semester 1–14; tes lulus | `student_intents.dart`, `student_topics.dart`, `test/student_intents_test.dart` | Tambah variasi berbasis kegagalan nyata, bukan klaim semua bahasa |
| 24 | Chatbot: tutor Ollama dan draf | PARTIALLY COMPLETED | API lokal, konteks terbatas, JSON tervalidasi, retry/cancel, penyunting terbatas | `ollama_service.dart`, `chat_protocol.dart`, `draft_editor.dart` | Evaluasi kualitas semantik dan perangkat |
| 25 | Launcher chatbot lintas halaman | COMPLETED | Tombol kanan bawah pada halaman yang mengintegrasikan controller; desktop panel/mobile layar penuh | `chat_launcher.dart`, `test/chat_launcher_test.dart` | Audit ulang setiap halaman baru dan akun staf nyata |
| 26 | Auto-install/start Ollama | PARTIALLY COMPLETED | Hook PowerShell, download lanjut, checksum, mutex, health/model check | `tool/local_ai/*`, `.vscode/settings.json` | Verifikasi clone baru, jaringan terbatas, shell/OS lain |
| 27 | Chatbot dengan data profil | PARTIALLY COMPLETED | Profil sesi dijawab deterministik tanpa profil otomatis dikirim ke model | `profile_answers.dart`, `chat_controller.dart` | Perluas hanya melalui service berotorisasi |
| 28 | RAG dan AI dengan data akademik | NOT IMPLEMENTED | Belum indeks dokumen/vektor atau API akademik untuk AI | `chat_policy.dart`, `chat_protocol.dart` | Sumber resmi, izin akses, provenance dan evaluasi |
| 29 | Izin Online lokal | PARTIALLY COMPLETED | Form, bukti, status, review, PDF dan penerima unik dalam memori | `lib/features/leave/*`, `test/leave_workflow_test.dart` | Persistensi/backend/peran nyata |
| 30 | Komunikasi mahasiswa–dosen/BAP | PLANNED | Distribusi objek izin lokal; belum komunikasi antarakun server | `leave_repository.dart` | Akun staf, inbox, notifikasi, audit trail |
| 31 | CI/CD, hosting dan release produksi | NOT IMPLEMENTED | Build lokal berhasil; tidak ditemukan pipeline CI aplikasi | `.github/`, scaffold platform | Pipeline, staging, konfigurasi release dan operasional |
| 32 | Profil sesuai seluruh referensi | IN PROGRESS | Struktur tujuh tab dan kartu mengikuti referensi; tema aplikasi dipertahankan sebagian | `features/profile/*`, `docs/profile_test_checklist.md` | Uji penerimaan visual/flow; jangan klaim identik 100% |
| 33 | Verifikasi perangkat dan recovery nyata | PARTIALLY COMPLETED | Startup/login UI dan keyboard emulator sudah tampil; login backend di emulator, recovery dan semua target belum diuji lengkap | `docs/profile_test_checklist.md`, `docs/android_emulator.md` | Jalankan dan catat hasil per perangkat dan alur |
| 34 | Stabilisasi startup Android emulator | COMPLETED pada AVD yang diuji | Identitas native konsisten; APK yang sama tampil setelah cold boot; startup normal setelah konfigurasi juga berhasil | `android/app/`, `tool/android/configure_emulator.ps1`, `docs/android_emulator.md` | Validasi AVD/perangkat anggota tim dan profil kinerja; pengaturan host tidak ikut Git |
| 35 | Penyeragaman nama teknis proyek | COMPLETED pada source dan konfigurasi lokal yang diperiksa | Nama proyek/platform/modul IDE seragam; pemindaian berkas tidak menemukan nama lama; analyze dan build Windows lulus | Konfigurasi Android/iOS/macOS/Linux/Windows, modul IDE lokal | Build iOS/macOS/Linux pada host yang sesuai; tinjau signing sebelum distribusi |

## E. Application Architecture

### Susunan aktual

```text
main → AppStartup → Supabase.initialize → CampusApp → AuthGate
                                             │
                      belum login/recovery ──┼── Login / Forgot / Reset
                                             │
                      sesi mahasiswa valid ──└── DashboardPage
                                                   ├── ProfilePage → ProfileRepository
                                                   │                    ├── SupabaseProfileRepository
                                                   │                    └── BiodataRepository
                                                   ├── DashboardRepository → EmptyDashboardRepository
                                                   ├── ChatController → aturan / ProfileAnswers
                                                   │                    └── OllamaService → host lokal
                                                   └── LeaveRepository → memori proses → PDF

Flutter Supabase client → Edge login + Auth + Data API/RPC + private Storage
                         PostgreSQL RLS memeriksa UUID dan sesi aplikasi
```

Arsitektur memisahkan beberapa tanggung jawab melalui service/repository dan folder fitur. Ini bukan penerapan formal seluruh lapisan Clean Architecture. Model, repository, dan widget masih menggunakan kombinasi objek bertipe dengan `Map<String, dynamic>` untuk bagian biodata.

### State, model, dan navigasi

- `SupabaseAuthService` adalah `ChangeNotifier` yang menyimpan `StudentProfile`, status pemulihan, waktu sesi, dan penanda generasi permintaan. `AuthGate` berlangganan perubahan dan menjadi batas akses UI.
- Profil tersimpan diperbarui melalui `acceptProfile`; dashboard/chat menerima identitas terbaru. `StudentProfile` memuat identitas, peran, atribut mahasiswa, preferensi avatar dan foto dalam memori.
- `BiodataForm` mengelola controller input, mode baca/edit, loading, error, dirty state dan versi rekaman. Definisi field terpusat di `biodata_fields.dart`.
- `DashboardData` memuat kumpulan model akademik. Implementasi kosong yang dipakai `CampusApp` tidak mengambil data Supabase akademik.
- `ChatController` memegang percakapan dan draf selama sesi; widget tidak langsung membentuk permintaan model. Preferensi endpoint saja disimpan melalui `SharedPreferences`.
- `LeaveRepository` memegang map pengajuan/draf dan pemeriksaan peran lokal. Injeksi `currentUser` menentukan siapa yang sedang memakai objek tersebut.
- Navigasi memakai `Navigator`, `MaterialPageRoute`/transisi khusus dan dialog. Tidak ditemukan router deklaratif atau pemetaan URL lengkap untuk semua halaman.
- Akses Cepat dan Executive Menu menggunakan `_quickAction` yang sama. Biodata membuka `ProfilePage`; Izin Online membuka `LeavePage`; chatbot membuka dialog; jadwal membuka daftar. Modul lain membuka detail kosong.
- Navigasi bawah dashboard menggunakan `_navigate` dan `Scrollable.ensureVisible` sebagai pintasan gulir. `GlobalKey` menandai panel profil, jadwal, dan Kemajuan Belajar. Beranda memakai `ScrollController.animateTo` untuk kembali ke atas. Panel yang belum tampil saat pemuatan/error memberikan pesan. Akses Cepat dan Executive Menu tetap membuka halaman layanan masing-masing.
- `openSmartChat` mengingat route berdasarkan controller agar dialog tidak bertumpuk. Controller harus diteruskan ketika membuat halaman baru.

### Alur autentikasi dan API

1. Pengguna mengirim NIM dan password melalui form login.
2. `SupabaseAuthService.login` memanggil Edge Function `login-with-nim` dengan timeout.
3. Edge memvalidasi masukan dan pembatasan percobaan. RPC privat memetakan NIM mahasiswa aktif ke identitas Auth.
4. Password diperiksa oleh Supabase Auth. Edge mendaftarkan sesi aplikasi berdasarkan sesi Auth, lalu mengembalikan token yang diperlukan beserta waktu server/kedaluwarsa.
5. Client membentuk sesi SDK, membaca `profiles` dan `students`, serta mengunduh avatar privat jika ada. Gagal memuat profil tidak menghasilkan fallback akun dummy.
6. Client menghitung waktu tersisa dengan `Stopwatch` dan mengurangi durasi jaringan. Aktivitas/refresh token tidak menambah masa 30 menit.
7. Permintaan data profil memakai JWT pengguna. RLS pada server memeriksa pemilik dan sesi aktif.
8. Logout menghapus state lokal, mencoba mencabut sesi server, membersihkan halaman privat dan draft. Ketika offline, batas waktu server tetap berlaku.

### Arsitektur berikutnya — belum diterapkan

Repository akademik perlu menggantikan implementasi kosong setelah kontrak data, otorisasi kelas, dan sumber resmi siap. Izin perlu repository server dengan transaksi dan event review. AI tahap 3 memerlukan service terbatas yang menerima identitas dari sesi server, bukan UUID/NIM bebas dari prompt. Semua ini merupakan rencana, bukan komponen aktif.

## F. Database & Backend Development

### Keputusan database terakhir

**Supabase/PostgreSQL adalah backend yang benar-benar digunakan sekarang.** Source memuat `supabase_flutter`, inisialisasi client, migrasi SQL PostgreSQL, RLS, Storage, Auth, dan Edge Function yang aktif. Tidak ditemukan integrasi MySQL atau Firebase pada source/dependensi/dokumentasi yang diperiksa.

MySQL adalah mesin database relasional. MySQL Workbench adalah aplikasi administrasi/pemodelan untuk MySQL, bukan backend API aplikasi. PostgreSQL adalah mesin database yang digunakan Supabase. Supabase menambahkan Auth, API, Storage, fungsi server dan dashboard administrasi di atas layanan tersebut. Pembahasan MySQL/Workbench sebelumnya tidak menjadi bukti bahwa proyek ini memakai dua engine sekaligus.

Proyek Supabase yang diaudit bernama `campus-app`, berada pada organisasi yang telah dikonfirmasi pengguna, region Singapore. Konfigurasi client dapat diberikan melalui `SUPABASE_URL` dan `SUPABASE_PUBLISHABLE_KEY`. Nilai kunci tidak dicantumkan di dokumen ini. Service-role/secret key hanya boleh dipakai pada lingkungan server yang sesuai.

### Tabel dan relasi

Metadata backend pada tanggal audit mengonfirmasi seluruh tabel di bawah dan RLS aktif. Jumlah baris adalah snapshot yang dapat berubah, bukan isi data pribadi.

| Tabel | Kunci/relasi utama | Isi dan akses | Baris saat audit |
|---|---|---|---:|
| `public.profiles` | `id` → `auth.users.id` | Nama resmi, peran, enabled/verification, preferensi, telepon, avatar. Mahasiswa hanya memperbarui kolom tertentu | 1 |
| `public.students` | `user_id` → `profiles.id`; NIM unik | Identitas akademik, universitas/fakultas/prodi, status dan atribut pendaftaran; baca milik sendiri | 1 |
| `public.student_biodata` | `user_id` → mahasiswa | Identitas pribadi, alamat, kontak, kewarganegaraan dan atribut biodata | 1 |
| `public.student_education` | `user_id` → mahasiswa | Asal sekolah, kontak, nilai, NISN, ijazah | 0 |
| `public.student_family` | `user_id` → mahasiswa | Orang tua, alamat, pendidikan/pekerjaan dan kontak darurat | 0 |
| `public.student_employment` | `user_id` → mahasiswa | Status kerja, perusahaan, jabatan dan sumber dana | 0 |
| `public.student_accessibility` | `user_id` → mahasiswa | Pilihan disabilitas, deskripsi dan akomodasi | 0 |
| `public.student_finance` | `id`; `user_id` → mahasiswa | Periode, kategori, nominal, dibayar, tanggal; mahasiswa hanya SELECT | 0 |
| `public.student_documents` | `(user_id, kind)` | Metadata dokumen, path, MIME, ukuran, versi; hanya pemilik dengan sesi sah | 0 |
| `private.app_sessions` | `session_id` → `auth.sessions`; `user_id` → Auth | Batas waktu dan pencabutan sesi, tidak untuk akses tabel langsung oleh client | 3 |
| `private.login_limits` | hash key | Penghitung percobaan per jendela waktu; bukan daftar password | 2 |

Relasi utama: `auth.users → profiles → students → bagian biodata/keuangan/dokumen`. Bagian profil satu per mahasiswa menggunakan kunci pemilik; keuangan dapat memiliki banyak baris; dokumen satu metadata per jenis. Fungsi trigger memperbarui `updated_at`. Telepon pada biodata disinkronkan ke `profiles` melalui trigger dengan hak pemanggil.

### Storage dan operasi data

- Bucket `student-avatars`: privat, maksimal 2 MiB per objek, MIME JPEG/PNG. Pipeline foto aplikasi menyiapkan JPEG, sehingga format input pengguna tidak sama dengan format yang disimpan.
- Bucket `student-documents`: privat, maksimal 524.288 byte atau 0,5 MiB, PDF/JPEG/PNG/DOC (`application/msword`). DOCX tidak tercantum sebagai format yang diterima saat audit.
- Path objek harus berada di folder UUID pemilik. Akses baca/unggah/hapus memeriksa sesi dan pemilik; aplikasi tidak membuat URL publik untuk dokumen pribadi.
- Penyimpanan bagian biodata memakai whitelist kolom dan pembandingan `updated_at` untuk mendeteksi konflik edit. Field kosong menjadi data belum diisi, bukan nilai rekaan.
- Ganti foto/dokumen mengunggah objek baru, menyimpan metadata, lalu berusaha menghapus objek lama. Jika metadata gagal, objek baru dibersihkan sejauh memungkinkan. Operasi Storage dan SQL bukan satu transaksi atomik; kegagalan cleanup berpotensi meninggalkan objek orphan.
- Dokumen yang dipilih langsung diunggah melalui aksi berkas; tidak menunggu tombol Simpan formulir biodata. Penghapusan memiliki konfirmasi.
- Unduhan/ekspor menghasilkan salinan pada perangkat pengguna. Logout tidak dapat menarik kembali salinan yang sudah diekspor.

### API, fungsi, dan batas peran

| Komponen | Fungsi | Batas |
|---|---|---|
| `login-with-nim` | Login sebelum pengguna memiliki JWT; rate limit, Auth, pendaftaran sesi | Metadata cloud: ACTIVE, versi 1, `verify_jwt=false`; validasi password dilakukan di dalam fungsi |
| `resolve_student_login` | Resolusi identitas NIM pada server | Hanya service role; query memerlukan peran student dan akun enabled |
| `consume_login_attempt` | Pembatasan atomik percobaan | Hanya service role; batas dari Edge, jendela 15 menit |
| `register_profile_session` | Tenggat absolut berdasarkan sesi Auth | Hanya service role; tidak dapat dipanggil client untuk memperpanjang sesi |
| `profile_session_status` | Membaca waktu sesi sendiri | Wrapper publik security invoker, implementasi privat terikat JWT |
| `revoke_profile_session` | Mencabut sesi sendiri | Tidak menerima UUID sesi arbitrary dari UI |
| Data API dan Storage | Baca/tulis milik pengguna | JWT, RLS, privilege kolom, validasi dan batas file |

Enum role dan kolom database memuat `student`, `bap`, `lecturer`, tetapi **resolusi login saat ini khusus mahasiswa** dan pemuatan profil mengharapkan baris `students`. Label login NIM/NIP atau cabang UI staf bukan bukti login staf sudah terintegrasi.

### Data nyata, contoh, dan kosong

Profil pengembangan terhubung ke akun Supabase Auth yang dibuat pengguna, dan login akun tersebut pernah berhasil. Nama persona pengembangan tidak berarti seluruh informasi sudah diverifikasi oleh institusi. Email kampus yang diminta pengguna adalah alamat tampilan demo; email Auth/pemulihan adalah email pengguna yang nyata. Kontak pribadi yang dapat diedit dipisahkan dari keduanya.

Tidak ada seed nilai, jadwal, tagihan, atau dokumen pribadi dari screenshot referensi yang boleh diasumsikan telah dimasukkan. Dashboard tetap kosong. Tabel keuangan dan sebagian tabel biodata kosong saat audit. Penerima izin contoh masih didefinisikan dalam source; fixture pengujian sengaja tetap ada.

### Riwayat migrasi yang perlu diselaraskan

| Nama logis | File lokal | Versi yang dilaporkan Supabase |
|---|---|---|
| `student_profiles` | `20261030080318_student_profiles.sql` | `20261030080557` |
| `session_rpc_boundaries` | `20261031082459_session_rpc_boundaries.sql` | `20261031082535` |
| `student_biodata_sections` | `20261101015234_student_biodata_sections.sql` | `20261101020002` |
| `password_reset_otp` | `20261102065453_password_reset_otp.sql` | `20261102071019` |

Nama migrasi berpadanan, tetapi timestamp berbeda. Ledger diperiksa kembali pada 2 November; migrasi OTP diterapkan melalui plugin dan tidak perlu diterapkan ulang. Kesetaraan seluruh migrasi lama secara lengkap belum dibandingkan. **Jangan langsung menjalankan db push atau repair history** sebelum mencocokkan schema, isi migrasi, dan ledger remote. Pengerjaan OTP tidak memperbaiki ledger historis.

### Backend pemulihan OTP — 2 November 2026

- Tabel `private.password_reset_challenges` menyimpan HMAC email/kode, ID challenge, pemilik opsional, waktu penerbitan/expiry, jumlah percobaan, dan konsumsi. Tidak ada kode asli atau password baru tersimpan di tabel.
- RPC `issue_password_reset`, `consume_password_reset`, `cancel_password_reset`, dan `revoke_password_reset_sessions` hanya dapat dieksekusi service-role. RLS tabel tidak memberi akses client; konsumsi mengunci baris sehingga kode tidak dapat dipakai dua kali bersamaan.
- Edge Function `password-reset` versi 1 **ACTIVE**, `verify_jwt=false` karena form berjalan sebelum login. Otorisasi perubahan tetap memakai OTP sah. `login-with-nim` tidak diganti.
- Akun harus terkonfirmasi, tidak dihapus/diblokir, memiliki profil aktif, dan tidak mempunyai MFA terverifikasi. Email dicek ulang saat konsumsi. Respons permintaan umum untuk mencegah pengungkapan akun terdaftar.
- Resend mengirim kode sebagai tugas latar Edge Runtime. `RESEND_API_KEY`, `RESET_EMAIL_FROM`, dan `RESET_OTP_SECRET` hanya di Secrets server; belum tersedia pada 2 November. Probe saat itu membuktikan respons konfigurasi kosong 503. Pada pemeriksaan 3 November, fungsi `password-reset` versi 2 ACTIVE dan pengiriman nyata delivered; lihat bagian J. Tidak ada deploy atau perubahan migrasi pada pemeriksaan 3 November.
- Panduan pengirim/domain, konfigurasi, batas keamanan, dan 12 langkah penerimaan: [Pemulihan OTP](docs/password_reset_otp.md).

## G. AI Chatbot Development

### Kemampuan yang tersedia

Chatbot bertujuan membantu mahasiswa dari berbagai tahap studi, termasuk pilihan semester 1–14. Pilihan semester merupakan konteks bantuan, bukan penetapan aturan masa studi resmi. Routing aplikasi didahulukan sebelum model agar istilah singkat tidak berubah menjadi definisi yang salah atau fakta akademik rekaan.

| Masukan | Perilaku yang dimaksud dan diimplementasikan |
|---|---|
| `jadwal`, `ujian`, `tugas`, `pengumuman` | Kebutuhan informasi hari ini; ketika sumber belum terhubung menyatakan keterbatasan tersebut |
| `ipk`, `krs`, `nilai`, `tagihan` | Kebutuhan catatan terbaru; tidak menghasilkan angka/status buatan |
| `jadwal?`, `ipk?` | Menawarkan pilihan pemeriksaan data/pengertian; pilihan waktu jika relevan |
| `jadwal besok?`, `ipk saya?` | Maksud eksplisit tetap didahulukan; tanda tanya tidak selalu meminta pilihan |
| `apa itu KRS?` | Glosarium terkurasi; definisi tidak diperlakukan sebagai kebijakan resmi kampus |
| `jdwl bsk`, `ksr`, variasi tertentu | Normalisasi pola yang memang dikenal; bukan pengenal seluruh salah ketik |
| `izin`, `ijin`, `surat izin` | Jalur Izin Online; pilihan pengajuan/status/penjelasan jika sesuai |
| `1`, `2`, `besok`, `pengertiannya` | Menggunakan pilihan/topik aktif; konteks lama dihapus ketika percakapan/topik berubah |
| Pertanyaan identitas sendiri | `ProfileAnswers` membaca `StudentProfile` sesi; tidak meminta model menebak |
| Pertanyaan belajar/penulisan umum | Ollama bila tersedia dan mode AI aktif; tetap mempunyai batas validasi/error |

Tanggal relatif dihitung dari waktu lokal perangkat, bukan kalender akademik resmi. “Sumber belum terhubung” harus dibedakan dari “pencarian berhasil dan hasilnya kosong”. Chat status izin tidak boleh mengaku membaca antrean server yang belum ada.

### Ollama, protokol dan respons

- Model terverifikasi dari source: `qwen2.5:1.5b`. Runtime portable dikunci oleh `runtime.ps1` pada rilis `v0.40.5` beserta checksum SHA-256. Ini versi yang dikonfigurasi proyek, bukan klaim rilis terbaru.
- Endpoint default `http://127.0.0.1:11435`; kandidat dapat berasal dari pilihan manual, `OLLAMA_URL`, host web, alamat emulator Android `10.0.2.2`, dan aset koneksi hasil startup.
- Pilihan manual/konfigurasi eksplisit tidak diam-diam dialihkan ke host lain. HTTP dibatasi ke alamat lokal/private yang diterima validator; endpoint tidak menerima userinfo, query, fragment atau path arbitrary.
- Pemeriksaan layanan memakai `/api/tags` dan memerlukan model yang sesuai. Generasi memakai `/api/chat`, `stream: false`, timeout 120 detik, `keep_alive` 5 menit.
- Parameter source: temperature 0,2; repeat penalty 1,2; repeat last n 512; konteks model 8.192; batas generasi 1.536. Perubahan parameter perlu evaluasi ulang.
- `chat_protocol.dart` membatasi konteks percakapan sekitar 6.500 karakter; ini bukan perhitungan token yang presisi. Pertanyaan awal dan pasangan pesan terbaru dipertahankan sesuai anggaran.
- Respons harus sesuai skema kategori/status/jawaban/informasi kurang/referensi/tindakan. Referensi resmi yang belum tersedia tidak boleh dibuat; tindakan harus `none` untuk jawaban model umum.
- Keluaran tidak lengkap, JSON rusak, atau status model tidak selesai ditolak. Controller menyediakan retry/cancel dan mengabaikan hasil permintaan yang sudah dibatalkan/berganti generasi.
- Instruksi dan pola penolakan membatasi perilaku, tetapi bukan pengganti otorisasi server. Model kecil masih dapat menghasilkan penjelasan umum kurang akurat.

### Draf dan penyuntingan bahasa

`draft_page.dart` menyediakan draf lokal dan kebutuhan formulir; `draft_editor.dart`/`draft_language.dart` membatasi perbaikan bahasa ke pasangan frasa yang diizinkan. AI memilih perubahan yang mungkin, lalu aplikasi menerapkannya dan pengguna meninjau. Teks asli dipertahankan bila gagal atau input berubah selama permintaan.

Nama, tanggal, dan lampiran tidak dikumpulkan otomatis untuk prompt penyunting. Namun isi alasan atau chat bebas yang diketik sendiri tetap dapat mengandung data pribadi dan ikut dikirim ke endpoint AI yang dipilih. Fitur ini bukan pemindai atau penyamaran PII otomatis. AI tidak menyetujui izin, tidak menandatangani surat, dan tidak mengunggah draf ke unit kampus.

### Auto-install, auto-start, dan batas jaringan

`flutter_hook.ps1` membuat fungsi `flutter` pada terminal yang memuatnya. Hanya ketika direktori berada pada proyek ini dan argumen pertama adalah `run`, hook memanggil `start.ps1 -RequireModel -Repair`, lalu meneruskan argumen ke `flutter.bat`. Perintah lain diteruskan langsung; tidak ada modifikasi SDK Flutter.

Pada penggunaan pertama, instalasi yang belum lengkap diunduh/dipulihkan: runtime sekitar 1,5 GB dan model sekitar 1 GB menurut pesan skrip. Unduhan pertama memerlukan internet dan kapasitas disk yang memadai. File parsial dapat dilanjutkan; checksum diperiksa sebelum ekstraksi; model diperiksa ulang melalui layanan. Penggunaan berikutnya memakai instalasi yang sudah lengkap dan menyalakan atau menggunakan kembali server proyek.

Mutex berdasarkan path proyek mencegah dua terminal mengunduh/menyiapkan server bersamaan. Pesan tunggu sekarang ditulis sekali dengan progres, tetapi tidak ada batas tunggu total untuk pemilik mutex yang masih hidup dan macet. Jika AI gagal disiapkan, hook saat ini **menghentikan kelanjutan Flutter run**. Gangguan DNS GitHub yang pernah terlihat merupakan kegagalan jaringan unduhan, bukan bukti source Dart gagal.

Server dijalankan tersembunyi dengan model/log/PID khusus `.local-ai/`, cloud dinonaktifkan melalui konfigurasi, dan port 11435 diperiksa agar proses lain tidak diambil alih. Host dipilih dari satu IP LAN fisik atau loopback. Aturan firewall dibatasi oleh skrip proyek; hak administrator mungkin diperlukan untuk akses LAN. Aset `connection.json` diperbarui sebelum Flutter membundel aplikasi.

**Batas penting:** auto-start ini bukan fitur bawaan semua `flutter run`. Ia berlaku jika hook termuat, misalnya terminal VS Code “Campus App (AI otomatis)” saat root proyek/workspace dibuka. Pull/clone sendiri tidak menjalankan installer. Terminal lain, Run/Debug IDE, `flutter.bat` langsung, macOS/Linux, dan aplikasi yang sudah diinstal pada HP tidak otomatis menjalankan hook PowerShell tersebut. HP/emulator memerlukan host Ollama yang menyala dan jaringan/alamat/izin yang sesuai. Browser HTTPS ke server HTTP lokal juga memerlukan evaluasi kebijakan browser sebelum deployment.

### Tahapan chatbot

| Tahap | Status | Implementasi dan pekerjaan tersisa |
|---|---|---|
| 1 — Prompting, konteks dan respons tanpa database | PARTIALLY COMPLETED | Prompt terpisah, batas data, glosarium, JSON dan error handling tersedia serta pernah diuji. Kualitas semantik model belum dapat dinyatakan selesai untuk seluruh pertanyaan |
| 2 — Percakapan dan layanan tanpa data mahasiswa | PARTIALLY COMPLETED | Pesan pendek, pilihan, lanjutan topik, semester, draf dan pintasan izin tersedia. Variasi bahasa dan workflow layanan masih perlu diperluas berdasarkan pengujian |
| 3 — Data akademik melalui backend/API aman | IN PROGRESS | Fondasi Auth/profil Supabase dan jawaban profil deterministik sudah ada. Jadwal/nilai/KRS/tagihan, RAG, akses staf dan tindakan backend AI belum terimplementasi |

Rencana tahap 3: buat API baca dengan otorisasi sesi/role, batas data per tugas, sumber/waktu pembaruan yang terlihat, dan pengujian lintas pengguna. Integrasikan sumber akademik hanya setelah repository terkait benar-benar tersedia. Tool/tindakan tulis harus eksplisit, tervalidasi dan dapat diaudit; jangan memberikan service-role key atau SQL bebas kepada model.

## H. UI/UX Development

### Identitas visual

Tema aktif adalah `AppTheme`: merah `#BD2134`, biru `#174C8A`, tinta `#08142A`, kertas `#EEF9FB`, hijau `#22D866`, muted `#697581`. Judul menggunakan PressStart2P, isi/form SpaceMono. Font beserta lisensi disertakan sebagai aset, sehingga tidak bergantung pada pemuatan font dari layanan eksternal.

`pixel-campus.png`, bingkai tegas, bayangan pixel, simbol fakultas dan avatar menciptakan gaya retro. `RetroTheme` alternatif masih ada dan menyebut font `CampusPixel` yang tidak terdaftar; tema tersebut bukan tema utama `CampusApp`. Komponen alternatif jangan dianggap sebagai desain aktif tanpa memeriksa pemanggil.

Komentar `app_theme.dart` menyebut referensi `index.css` Figma. Namun tidak ditemukan file desain/tautan Figma terverifikasi yang cukup untuk merekonstruksi spesifikasi lengkap. Referensi visual paling jelas dalam percakapan adalah screenshot SIAKAD pengguna. Tidak ada dasar mengklaim UI identik pixel demi pixel dengan Figma atau website referensi.

### Halaman dan pola interaksi

| Bagian | Implementasi visual/perilaku |
|---|---|
| Login/lupa password | Layout autentikasi bersama, input dan status konsisten, tombol proses, validasi, navigasi recovery |
| Dashboard | Header merah, kartu profil biru, Akses Cepat, panel informasi, progres dan grafik; data kosong ditampilkan secara eksplisit |
| Executive Menu | Desktop memakai menu/submenu; HP/tablet memakai drawer/expansion yang dapat digulir |
| Navigasi bawah dashboard HP | Beranda menggulir ke awal dashboard; Jadwal ke panel jadwal hari ini; Akademik ke Kemajuan Belajar; Profil ke kartu informasi mahasiswa. Chatbot tetap menjadi tombol utama di tengah |
| Halaman Akademik | Pilihan layanan memakai struktur menu Akademik yang sama dengan Executive Menu, termasuk Program Akademik bertingkat |
| Halaman akademik belum siap | Halaman detail kosong dengan pesan ketersediaan, bukan halaman transaksi palsu |
| Profil | Ringkasan kiri dengan foto dan informasi akademik; tujuh bagian: Biodata, Pendidikan, Keluarga, Pekerjaan, Disabilitas, Riwayat Keuangan, Berkas |
| Edit bagian biodata | Mode baca/edit, Simpan/Batal, field dikelompokkan, date picker, konfirmasi ketika meninggalkan perubahan |
| Edit preferensi | Halaman terpisah untuk panggilan, telepon, foto/varian avatar; bukan editor identitas akademik resmi |
| Berkas | Kategori, status tersedia, unggah/ganti/hapus dan ekspor; template resmi yang belum ada tidak dipalsukan |
| Chatbot | Dashboard HP memakai tombol tengah navigasi bawah; dashboard layar lebar dan halaman lain memakai tombol kanan bawah. Layar lebar membuka panel, HP/teks besar memakai layar penuh; sesi percakapan tetap dibagi dengan Akses Cepat |
| Izin | Form tanggal/kelas/bukti, daftar status, detail review, PDF; label simulasi perlu tetap jelas |

### Responsivitas, avatar, dan animasi

- Breakpoint umum: tablet 600 px, desktop 1.100 px; lebar konten maksimum umum 1.600 px. Tablet tidak lagi menggunakan empat menu rail kiri.
- Grid Akses Cepat menyesuaikan lebar dan ukuran teks; konfigurasi dasar mencapai 2/3/4/7 kolom pada rentang yang ditetapkan `responsive_layout.dart`.
- Profil dua kolom pada lebar sekitar 1.000 px ke atas bila skala teks memungkinkan; formulir menjadi dua kolom sekitar 640 px dan alamat dapat empat kolom sekitar 800 px.
- Chat panel pada lebar minimal 700 px dan skala teks sampai 1,3; ukuran panel maksimum 440 × 640 dengan ruang keyboard/padding diperhitungkan.
- Avatar pria, perempuan, netral adalah pilihan ilustrasi, bukan inferensi jenis kelamin. Avatar perempuan telah dibedakan melalui wajah/pakaian, bukan rambut saja. Foto pengguna memiliki prioritas; memilih varian tidak otomatis menghapus foto.
- Transisi bersama menggunakan fade/slide dan entrance bertahap; `MediaQuery.disableAnimations` dihormati. Durasi route utama sekitar 380 ms, reverse 280 ms.
- Tombol/input/status bersama memiliki dukungan fokus/semantics tertentu. Audit aksesibilitas lengkap dan uji pembaca layar belum tersedia.

### Kekurangan yang masih terlihat dari source

1. Struktur profil mengikuti referensi, tetapi warna header/font dan beberapa bentuk masih mengikuti tema aplikasi; kesamaan visual 100% belum dibuktikan.
2. Provinsi/kota masih masukan teks; belum dropdown bertingkat berbasis katalog wilayah resmi.
3. Halaman preferensi profil terpisah dari editor tujuh bagian; ini perlu dijelaskan kepada pengguna agar dua fungsi tidak dianggap duplikat.
4. Menu berisi layanan yang belum mempunyai backend. Pesan kosong harus tetap jelas dan konsisten.
5. Navigasi bawah menjadi pintasan gulir ke informasi dashboard. Indikator aktif mengikuti tombol terakhir yang diketuk, belum mengikuti guliran jari secara otomatis. Pengguna mengonfirmasi perubahan berhasil; posisi panel pada layar kecil, teks besar, dan kondisi pemuatan/error masih perlu diverifikasi lengkap.
6. Foto “semua format” tidak dapat dijamin: format tambahan bergantung decoder/codec perangkat dan batas sumber daya.
7. Belum ada bukti uji visual seluruh HP/iPad, keyboard virtual, pembaca layar, dan tema teks ekstrem pada aplikasi nyata.

## I. Authentication & Security

### Kontrol yang sudah diterapkan

| Area | Kontrol aktual | Bukti |
|---|---|---|
| Password | Diperiksa Supabase Auth; tidak disimpan sebagai password aplikasi; perubahan baru minimum 12 karakter pada service | `supabase_auth_service.dart`, Edge login |
| Login | Validasi NIM/password, POST, batas body yang diperiksa, pesan gagal generik, rate limit atomik | `supabase/functions/login-with-nim/index.ts` |
| Pemulihan OTP | Acak kriptografis 6 karakter campuran, HMAC-SHA-256, TTL 10 menit, sekali pakai, 5 percobaan; password 12–256 karakter dan kebijakan Auth | `password-reset/`, migrasi OTP, `password_reset.sql` |
| Batas pemulihan | 40/IP, 5 permintaan/email, 10 konfirmasi/email per 15 menit; kirim ulang minimal 60 detik | Edge handler + RPC rate limit/OTP |
| Rate limit | Batas konfigurasi Edge 40 per IP dan 8 per NIM dalam 15 menit; identitas pembatas di-hash | Edge + `consume_login_attempt` |
| Sesi | Tenggat 30 menit dari waktu sesi Auth di server; refresh/aktivitas tidak memperpanjang | SQL sesi, `SupabaseAuthService`, `AuthGate` |
| Penyimpanan token | `persistSession: false`; restart/refresh meminta login ulang | `supabase_config.dart` |
| Logout | State lokal langsung dibersihkan, route privat ditutup, revoke server dicoba | `main.dart`, `supabase_auth_service.dart` |
| Hak akses data | UUID pemilik + sesi valid pada RLS; kolom resmi tidak diberi UPDATE mahasiswa | Migrasi dan `profile_access.sql` |
| Berkas | Bucket privat, pembatasan path/MIME/ukuran, unduhan berotorisasi, nama ekspor disanitasi | Migrasi, `biodata_repository.dart` |
| Foto | Dekode, pembatasan input/dimensi pada jalur yang mendukung, resize, JPEG baru tanpa metadata asli | `profile_photo.dart` |
| Request terlambat | Penanda generasi/identitas dan disposal mencegah hasil lama mengganti sesi baru pada alur terkait | Auth/controller/repository dan tes |
| AI | Data profil tidak diambil otomatis untuk prompt; tindakan model dibatasi, jawaban personal memakai aplikasi | `profile_answers.dart`, `chat_protocol.dart` |
| Transport backend | Konfigurasi Supabase mewajibkan HTTPS | `supabase_config.dart` |

Batas dimensi foto terukur pada decoder raster adalah 40 megapiksel dan sisi 16.000 px; input maksimal 20 MiB, hasil utama maksimal sisi 1.024 px JPEG kualitas 88. Fallback codec platform memiliki perilaku decoder sendiri dan perlu diuji untuk format tambahan. Validasi file bukan pemindaian malware atau jaminan semua input berbahaya tertangani.

### Temuan dan hal yang belum dibuktikan

- Security advisor Supabase saat audit masih mengeluarkan **WARN leaked password protection disabled**. Evaluasi pengaktifan sesuai kemampuan paket: [panduan keamanan password Supabase](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection).
- Pemeriksaan advisor 2 November menunjukkan tiga **INFO RLS enabled no policy** pada `private.app_sessions`, `private.login_limits`, dan `private.password_reset_challenges`, sesuai desain tanpa akses langsung client. Jangan menambahkan policy permisif hanya untuk menghilangkan informasi advisor. Pemeriksaan akses melalui fungsi tetap diperlukan: [penjelasan linter Supabase](https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy).
- Pengiriman OTP nyata sudah delivered pada 3 November; reset password dan login ulang end-to-end belum diuji. Tidak memerlukan port web tetap/deep link; konfigurasi callback hanya relevan untuk handler tautan Auth lama. Kegagalan provider membatalkan challenge pengiriman itu, dan respons request 200 sendiri bukan bukti email sampai.
- Reset mencabut sesi aplikasi melalui RLS dan refresh session Auth melalui global sign-out. JWT lama dapat tetap berlaku sampai expiry pada layanan yang hanya memeriksa JWT. Kode dikonsumsi sebelum perubahan Auth; kegagalan/timeout memerlukan pemeriksaan hasil login dan kode baru, bukan pemakaian ulang OTP.
- Konfigurasi menggunakan implicit flow dan token memori. Perubahan strategi Auth harus dievaluasi bersama kebutuhan platform, callback, sesi absolut dan tes; jangan mengganti hanya karena preferensi library.
- Ollama LAN menggunakan HTTP tanpa autentikasi aplikasi tersendiri. Firewall/CORS bukan pengganti otorisasi pengguna. Jangan mengekspos port ke internet atau menganggap layanan host aman untuk data produksi hanya karena lokal.
- Android mengizinkan cleartext traffic untuk kebutuhan AI lokal; iOS mengaktifkan local networking; macOS memiliki entitlement network client. Konfigurasi release perlu ditinjau per platform.
- Pengiriman salinan dokumen ke perangkat tidak dapat dibatalkan oleh logout. Kebijakan retensi, backup, akses staf, audit trail dan penghapusan data produksi belum ditetapkan lengkap.
- Tidak ada hasil audit penetrasi menyeluruh, uji beban rate limit nyata, atau bukti bahwa seluruh attack surface bebas masalah. Status analyzer bersih bukan sertifikat keamanan.

## J. Testing & Quality Assurance

### Struktur pengujian

| Kelompok | File utama | Yang diperiksa |
|---|---|---|
| Startup/Auth | `app_startup_test.dart`, `auth_service_test.dart`, `supabase_auth_test.dart`, `widget_test.dart` | Startup gagal, login, error HTTP, profil hilang, sesi, race login/logout dan navigasi |
| Profil/data | `profile_test.dart`, `biodata_test.dart` | Nilai kosong, whitelist, foto, telepon, validasi, konflik, kegagalan simpan dan urutan penggantian berkas |
| Profil/UI/ekspor | `profile_widget_test.dart`, `biodata_widget_test.dart`, `profile_export_test.dart` | Form, layout, interaksi dan pemilihan mekanisme simpan/berbagi dengan fixture |
| Dashboard/menu | `dashboard_data_test.dart`, `dashboard_widget_test.dart`, `executive_menu_test.dart` | Pemilihan jadwal, keadaan kosong, route/menu, layar kecil dan teks besar |
| Chatbot | `chatbot_logic_test.dart`, `chatbot_widget_test.dart`, `chat_quality_test.dart`, `student_intents_test.dart` | Routing, glosarium, pilihan singkat, konteks waktu, batas data dan respons UI |
| Koneksi/launcher | `chat_connection_test.dart`, `chat_launcher_test.dart` | Kandidat endpoint, pilihan eksplisit, penempatan dan penggunaan ulang route |
| Penyunting | `draft_editor_test.dart` | Perubahan bahasa terbatas, input berubah, kegagalan dan pembatalan |
| Izin | `leave_workflow_test.dart`, `leave_widget_test.dart` | Validasi, role lokal, keputusan, revisi, PDF, penerima kode unik dan UI |
| RLS/backend | `supabase/tests/profile_access.sql` | Pemilik/lintas akun/anon, kolom resmi, sesi habis/dicabut, Storage, biodata/keuangan |
| Skrip host | `tool/local_ai/test_autostart.ps1`, `test_recovery.ps1` | Pengait dan skenario pemulihan terisolasi; bukan bukti semua komputer sudah terpasang |
| Model nyata | `tool/local_ai/smoke.dart`, `evaluate.dart`, fixture kualitas | Koneksi dan skenario respons model; membutuhkan runtime/model yang aktif |
| Foto web | `tool/verify_profile_photo.dart` | Probe pipeline format foto pada runtime web |

Tidak ditemukan direktori suite `integration_test` lengkap. Fixture HTTP dan widget bukan pengganti uji login/penyimpanan pada backend nyata. SQL berbasis rollback merupakan pengujian integrasi akses database, bukan alur browser lengkap.

### Bukti hasil terakhir

| Bukti | Hasil yang dapat dibaca | Batas kesimpulan |
|---|---|---|
| Audit awal terhadap `build/profile-final-tests.log`, 1 November sekitar 14:19 | `+208: All tests passed!` | Bukti historis; file log sudah tidak tersedia pada 2 November; seluruh suite tidak dijalankan ulang untuk revisi nama |
| Audit awal terhadap `build/profile-final-analyze.log`, sekitar 14:18 | `No issues found!`, 5,4 detik | Bukti historis; file log sudah tidak tersedia; ada hasil analyze lebih baru di bawah |
| Audit awal terhadap `build/profile-final-build.log`, sekitar 20:23 | Build web selesai, kompilasi 163 detik; Wasm dry run succeeded | Bukti historis; log sudah tidak tersedia; bukan bukti deployment publik |
| Hasil sesi perbaikan emulator, 2 November: `test/app_startup_test.dart` dan `test/widget_test.dart` | Enam tes lulus | Subset startup/login, bukan seluruh suite dan bukan login nyata ke backend |
| Hasil sesi perbaikan emulator dan `build/app/outputs/flutter-apk/app-debug.apk`, 2 November | Build debug Android berhasil; APK dipasang dan UI tampil pada AVD | Tidak membuktikan build release, semua fitur, atau semua perangkat |
| `build/diagnostics/fixed-normal-run.png`, `fixed-keyboard.png`, dan `forgot-password.png` | Login, keyboard, dan tampilan lupa password teramati selama diagnosis | Screenshot lokal; email recovery tidak dikirim untuk tes tampilan dan login akun nyata di emulator belum diuji ulang |
| Hasil perintah setelah revisi nama, 2 November: `flutter analyze --no-pub` | `No issues found!`, 185,4 detik | Analisis Flutter/Dart pada source saat itu; bukan pemeriksaan TypeScript atau bukti runtime |
| Hasil perintah `flutter build windows --debug --no-pub`, 2 November | Build berhasil, 244,1 detik; `build/windows/x64/runner/Debug/campus_app.exe` tersedia | Build Windows debug; aplikasi Windows belum diuji secara interaktif |
| Revisi navigasi halaman, 2 November: empat file tes dashboard/navigasi/chatbot/Executive Menu | `+31: All tests passed!` | Bukti historis sebelum navigasi bawah dikembalikan menjadi pintasan gulir; bukan hasil pengujian revisi terakhir |
| Analisis revisi navigasi halaman sebelumnya | `No issues found!`, 82,6 detik | Bukti historis sebelum revisi pintasan gulir |
| `build/navigation-verification/dashboard-phone.png` pada pemeriksaan sebelumnya | Render widget 390 × 844 diperiksa; tombol Chatbot berada di tengah dan empat menu tertata tanpa overflow | Artefak lokal dapat ditimpa ketika tes dijalankan ulang; pemeriksaan sebelumnya tidak membuktikan perilaku gulir terbaru |
| Screenshot pengguna setelah revisi pintasan gulir | Format tiga file selesai tanpa perubahan; `flutter analyze --no-pub` menghasilkan `No issues found!`, 3,4 detik | Analisis Flutter/Dart bersih; bukan bukti seluruh tes atau build berhasil |
| Screenshot tes setelah revisi pintasan gulir | Empat file tes saat itu terlihat pada tahap `loading` | Bukti historis tidak lengkap; suite 218 terbaru di bawah sudah mencakup tes navigasi |
| Konfirmasi pengguna setelah revisi pintasan gulir | Pengguna menyatakan perubahan berhasil | Konfirmasi penggunaan; belum merupakan verifikasi lengkap seluruh perangkat dan kondisi pemuatan/error |
| Pemeriksaan metadata EXE, XML, dan penamaan setelah revisi | ProductName/FileDescription/InternalName `campus_app`, OriginalFilename `campus_app.exe`; XML terkait dapat diparse; nama lama tidak ditemukan pada pemindaian proyek | Pencarian tidak mencakup riwayat/objek `.git`, isi biner model, dan dependensi melalui symlink; bukan pengujian runtime seluruh platform |
| Konfirmasi pengguna pada percakapan | Login nyata menampilkan profil akun pengembangan yang dimaksud | Tidak otomatis membuktikan seluruh edit terbaru sudah diuji |
| Riwayat pengerjaan sebelumnya | Uji akses SQL rollback dan probe foto web dilaporkan berhasil | Tidak dijalankan ulang; log lengkap hasil tersebut tidak dipersistenkan sebagai bukti versi dalam dokumen ini |
| Screenshot editor pengguna terakhir | Deno terpasang; error merah hilang, tersisa satu lint deklarasi fungsi | Bukti editor pengguna, bukan hasil CI/deploy baru |
| `build/otp-flutter-test.log`, 2 November | **218 tes lulus**, `All tests passed!` | Seluruh suite Flutter, termasuk navigasi gulir dan OTP; jaringan/Auth/email memakai fixture |
| `build/otp-analyze.log` | `No issues found!`, 6,6 detik | Analisis Dart; bukan uji runtime |
| `build/otp-build-web.log` | Build web berhasil, 76,7 detik | Source terbaru termasuk OTP; bukan deploy publik atau uji email |
| `deno check`, `deno lint`, dan tes `password-reset/` | Pemeriksaan bersih; **15 tes lulus** | Handler, crypto, dan adapter SDK asli dengan transport HTTP tiruan; tidak mengirim email |
| `supabase/tests/password_reset.sql` pada proyek development | PASS; transaksi rollback | Hak akses, cooldown, salah/replay/expiry, batas percobaan, resend/cancel, email berubah, akun nonaktif/MFA, revoke; fixture tidak dipertahankan |
| Deploy dan `build/otp-remote-probe.json` | Fungsi v1 ACTIVE; OPTIONS 200, email invalid 400, Resend belum diatur 503 | Uji HTTP cloud tanpa reset akun atau email nyata |
| `build/otp-build-android.log` | Build gagal menunggu lock Gradle milik proses lain | Tidak menghentikan proses IDE pengguna |
| `build/otp-build-android-isolated.log` | Cache proyek terpisah melewati lock; gagal `JdkImageTransform` memakai JDK 26 | Masalah toolchain saat kompilasi `app_links`; bukan bukti error OTP Dart |
| `build/otp-build-android-jbr.log` | **BUILD SUCCESSFUL**, 1 menit 52 detik, 304 task; `assembleDebug` dengan JBR 25.0.3 Android Studio | Source OTP terbaru; cache proyek terpisah, JAVA_HOME hanya pada proses tes; pengaturan JDK global tidak diubah |

Probe foto pada pengerjaan sebelumnya mencakup JPG, PNG, GIF, BMP, TIFF, ICO, WebP dan penolakan byte invalid. Tes browser Flutter sempat terhambat pemuatan CanvasKit lokal/404 dan tidak boleh dilaporkan lulus; verifikasi memakai probe web terpisah sebagai bukti terbatas.

`docs/chatbot_quality.md` mencatat evaluasi terdahulu 12 alur dan suite 151 tes. Angka tersebut bersifat historis sebelum pengembangan profil terbaru, bukan konflik dengan log 208 tes. Tidak ada skor akurasi chatbot menyeluruh yang dapat dinyatakan dari hasil routing tersebut.

### Verifikasi aktivasi Resend — 3 November 2026

Pengguna mengonfirmasi penyimpanan tiga secrets melalui dashboard Supabase. Nilai secrets tidak dibaca, disalin ke repository, atau dicantumkan dalam laporan. Pengujian mengirim **satu** email OTP ke akun pengembangan milik pengguna melalui endpoint `password-reset`, bukan langsung melalui API pengiriman Resend.

| Pemeriksaan | Hasil | Batas bukti |
|---|---|---|
| Metadata Supabase | `password-reset` v2 ACTIVE; `login-with-nim` v2 ACTIVE | Tidak ada deploy atau migrasi baru pada pemeriksaan ini |
| Permintaan OTP cloud, sekitar 11:04 WIB | HTTP 200 dengan pesan umum; `build/otp-nov3-remote-probe.json` | Respons ini sendiri tidak menjamin delivery |
| Plugin Resend: metadata email hasil permintaan | **delivered**, waktu kirim 04:04:51 UTC / 11:04:51 WIB | Server email penerima menerima pesan; belum membuktikan posisi inbox/spam atau dibaca pengguna |
| Pemeriksaan isi email secara terbatas | Kode enam karakter, hanya huruf besar/angka, memuat keduanya; informasi berlaku 10 menit dan sekali pakai tersedia | Kode dan isi email privat tidak ditampilkan atau disimpan dalam laporan |
| `flutter analyze --no-pub` | **No issues found**, 4,5 detik; `build/otp-nov3-analyze.log` | Analisis Dart, bukan pengujian runtime perangkat |
| `flutter test --no-pub` | **218 lulus, 0 gagal**, sekitar 54 detik; `build/otp-nov3-flutter-test.log` | Seluruh suite otomatis; integrasi Auth/email pada tes memakai fixture |
| `deno check`, `deno lint`, `deno test supabase/functions/password-reset` | Check/lint bersih; **15 lulus, 0 gagal** | Tes handler dan adapter memakai transport tiruan |
| `supabase/tests/password_reset.sql` pada proyek development | **PASS**, transaksi rollback | Permissions, cooldown, kode salah/replay, batas percobaan, resend/cancel/expiry, email berubah, akun nonaktif/unknown/MFA, dan revoke; fixture tidak dipertahankan |

Pengujian Flutter sempat tertahan oleh pembatasan lingkungan eksekusi. Proses tes milik sesi ini dihentikan setelah command line diverifikasi, lalu perintah dijalankan ulang dengan akses yang diperlukan. Hasil di atas berasal dari pengulangan yang selesai; proses IDE pengguna tidak dihentikan.

**Belum diuji pada sesi ini:** memasukkan OTP melalui UI, mengganti password akun nyata, login dengan password baru, penolakan password lama, dan pencabutan sesi nyata lintas perangkat. Password pengguna tetap. Tidak ada build web/APK baru atau uji emulator interaktif pada 3 November; bukti build 2 November tetap bersifat historis. Domain pengirim untuk pemakaian umum juga belum diverifikasi dalam pengujian ini. Log `build/` diabaikan Git dan dapat hilang ketika `flutter clean`.

### Skill dan plugin yang tersedia — 3 November 2026

| Skill/plugin | Penggunaan dalam sesi |
|---|---|
| `caveman` | Tersedia dan digunakan untuk komunikasi ringkas; kelengkapan kode, pengujian, dan dokumentasi tidak dikurangi |
| `supabase:supabase` | Tersedia; connector digunakan untuk memeriksa fungsi cloud dan menjalankan tes SQL dengan rollback |
| `app-6a3c407853888191beddc2151c2b6f8b:resend-cli` / Resend | Skill tersedia dan digunakan; **integrasi plugin baru yang dicatat pada pembaruan ini**. Connector Resend digunakan untuk memeriksa email uji dan status delivered |

Executable `resend` belum ditemukan pada PATH lokal. Pemeriksaan memakai connector yang tersedia, sehingga tidak memasang CLI tambahan. Skill/plugin ini milik lingkungan asisten; tidak otomatis terpasang pada komputer anggota tim lewat clone/merge, dan ketersediaannya harus diperiksa kembali pada sesi/akun lain. Backend aplikasi memakai secrets server dan integrasi Resend dalam Edge Function, bukan bergantung pada plugin asisten.

### Matriks verifikasi platform (build 2 November; status tindak lanjut 3 November 2026)

| Target | Build | Runtime yang teramati | Pekerjaan tersisa |
|---|---|---|---|
| Web/Chrome | Build terbaru OTP berhasil pada 2 November | Login nyata pernah dikonfirmasi pengguna; probe foto terpisah tersedia; delivery OTP via endpoint terverifikasi 3 November | Uji penerimaan profil lengkap, reset OTP melalui UI, login ulang dan sesi lama |
| Android emulator | APK OTP terbaru berhasil dengan JBR Android Studio/cache terpisah | Pada diagnosis sebelumnya `Medium_Phone`, image Android 37.2 x86_64, GPU host; login, lupa password lama, keyboard tampil. APK OTP terbaru belum dijalankan interaktif | Verifikasi APK OTP terbaru, login nyata, persistensi, upload/ekspor, delivery OTP, kinerja |
| Android fisik | Belum diuji ulang | Belum ada bukti terbaru | Instalasi, jaringan Ollama, input, foto/berkas, dan seluruh alur utama |
| Windows desktop | Debug berhasil pada 2 November | Belum diuji interaktif | Startup, Auth, ekspor, koneksi AI, dan callback pada desktop |
| iOS/macOS | Konfigurasi identitas diperbarui; build belum diuji di host ini | Belum ada bukti terbaru | Build pada macOS/Xcode, signing, provisioning, callback dan alur fitur |
| Linux | CMake dan judul jendela diperbarui; build belum diuji di host ini | Belum ada bukti terbaru | Toolchain native, build dan alur fitur |

Seluruh durasi di atas merupakan hasil satu eksekusi pada host pengembangan, bukan benchmark atau batas waktu penerimaan. Artefak di `build/` tidak ikut Git dan dapat dibuat ulang. Untuk serah terima, gunakan hasil tertulis ini bersama source; jangan menganggap anggota tim menerima screenshot, log, atau executable lokal melalui merge.

### Analisis, format dan pemeriksaan berikutnya

Perintah untuk verifikasi ketika source berubah. Suite Flutter 218 tes, analisis, Deno, dan SQL OTP dijalankan ulang pada 3 November; delivery email nyata juga terverifikasi. Build web/Android berasal dari 2 November. Reset password dan login ulang melalui UI masih perlu pemeriksaan manual:

```powershell
flutter analyze
flutter test
dart format --output=none --set-exit-if-changed lib test
deno check .\supabase\functions\login-with-nim\index.ts
deno check .\supabase\functions\password-reset\index.ts
deno lint .\supabase\functions\password-reset
deno test .\supabase\functions\password-reset\handler_test.ts .\supabase\functions\password-reset\services_test.ts
flutter build web --no-web-resources-cdn
```

Tidak ada log pemeriksaan `dart format` terbaru yang cukup untuk mengklaim seluruh file sudah sesuai formatter. Pemeriksaan format di atas tidak menulis source. Jalankan tes terarah terlebih dahulu sesuai perubahan, lalu suite yang diwajibkan; jangan menjalankan build berat berulang tanpa alasan.

Checklist manual terbaru berada di `docs/profile_test_checklist.md`. Prioritas verifikasi: simpan–muat ulang–logout/login tiap bagian, foto nyata, dua jendela mengedit versi yang sama, jaringan terputus, dokumen, sesi 30 menit, akun kedua, password recovery, serta HP/emulator.

## K. Development History & Technical Decisions

### Pemulihan OTP dan Resend — 2 November 2026

Permintaan pengguna mengganti link email pada form Lupa password menjadi kode enam karakter campuran huruf besar dan angka. Kode dibuat di server dengan generator kriptografis, disimpan sebagai HMAC, berlaku 10 menit, maksimal lima percobaan, dan dikonsumsi atomik sebelum perubahan password. Form memeriksa format email; server memeriksa akun yang memenuhi syarat tanpa mengungkap keberadaan akun kepada pemohon.

Resend dipilih karena pengguna belum memiliki layanan email. Migrasi dan Edge Function sudah diterapkan, tetapi tiga secrets pengirim belum tersedia. Tes HTTP memakai transport tiruan dan tes SQL melakukan rollback; tidak ada email nyata atau password pengguna yang diubah. Panduan aktivasi dan penerimaan lengkap tersedia di `docs/password_reset_otp.md`.

Build APK terbaru sempat terhalang lock Gradle milik proses lain dan JDK 26. Build akhirnya berhasil dengan cache proyek terpisah serta JBR 25.0.3 Android Studio yang dipilih hanya pada proses build. Proses IDE pengguna tidak dihentikan dan pengaturan Java global tidak diubah. Karena itu keberhasilan build terisolasi belum menjamin terminal tim dengan JDK berbeda langsung berhasil.

### Riwayat yang didukung Git

| Tanggal | Commit | Catatan yang dapat diverifikasi dari riwayat |
|---|---|---|
| 11 Oktober 2026 | `7ea822a` | Pengisian README |
| 11 Oktober 2026 | `cc02aeb` | Penambahan komentar untuk membantu pemahaman kode |
| 11 Oktober 2026 | `b028037` | Perubahan remember-me/sesi 30 menit dan UI lupa password; implementasi Auth kini sudah berubah lagi |
| 11 Oktober 2026 | `e7a382d` | Penambahan submenu/executive menu sesuai referensi dengan desain aplikasi |
| 16 Oktober 2026 | `0cbd9f5` | Perubahan UI |
| 19 Oktober 2026 | `125b9bc` | Instalasi/integrasi Ollama |
| 23 Oktober 2026 | `697e56d` | Pengembangan chatbot dan Izin Online |
| 26 Oktober 2026 | `18a661c` | Berhenti melacak sebagian registrant plugin Flutter |
| 26 Oktober 2026 | `cfa04f2` | Pembaruan dependensi hasil pub get |
| 29 Oktober 2026 | `a4d7239` | Perbaikan Ollama dan pemasangan otomatis |
| 30 Oktober 2026 | `5c9acc0` | Perubahan gitignore; HEAD saat audit |

Riwayat commit di atas menjelaskan tonggak yang terlihat, bukan rekonstruksi setiap perubahan. Pada 2 November 2026, penamaan proyek, konfigurasi platform, dan modul IDE diseragamkan menjadi `campus_app`. Bundle identifier iOS/macOS memakai `com.example.campusApp` karena format Apple tidak menerima underscore. Tanggal dan alasan penamaan awal tidak ditetapkan dari konfigurasi saat ini.

### Keputusan setelah HEAD dan konteks kerja

1. Pengguna memilih branch `marcell-works` untuk pendataan nyata. Proyek Supabase dibuat setelah konfirmasi organisasi/region; akun Auth dibuat langsung oleh pengguna tanpa membagikan password.
2. Login dummy diganti Supabase; source data demo profil dan auth lama ditandai dihapus. Kode tes tetap mempunyai fake service.
3. Data akademik belum diberikan sehingga dashboard tetap memakai repository kosong. Nilai dan tagihan dari screenshot bukan seed data.
4. Profil diperluas menjadi tujuh bagian mengikuti referensi. Foto menerima lebih banyak format dengan konversi, telepon lokal diterima, avatar perempuan diperbaiki, dan email tampilan/kontak/Auth dipisahkan.
5. Masalah Deno di VS Code berkaitan dengan pengenalan runtime/workspace: saat folder induk dibuka, setting `.vscode` proyek tidak otomatis menjadi setting root. Membuka root `campus_app` dan mengaktifkan ekstensi Deno menyelesaikan error merah yang ditunjukkan pengguna; satu lint masih terlihat.
6. Auto-start AI diterapkan pada sisi host melalui hook PowerShell, karena aplikasi web/HP tidak dapat diasumsikan memiliki izin menyalakan executable host. Runtime/model dipisahkan per proyek dan diabaikan Git.
7. Pemilihan kode dosen pada izin ditujukan menghindari ambiguitas nama sama. Penerima contoh dengan nama sama sengaja dipertahankan untuk menguji logika tersebut.
8. Perbaikan Android memisahkan masalah identitas native dari layar hitam emulator. `namespace`, `applicationId`, package Kotlin, dan manifest kini konsisten. Layar hitam yang tersisa dipulihkan dengan cold boot pada AVD yang diuji.
9. Penyeragaman nama proyek mencakup konfigurasi platform, metadata executable, modul IDE lokal, dan metadata widget preview. Identitas Apple memakai camelCase untuk mengikuti format bundle identifier. Riwayat Git tidak ditulis ulang.

Perubahan Supabase/profil/platform/dependensi/test yang sedang berada di working tree belum dapat diidentifikasi oleh satu commit final. Sebelum berbagi dengan anggota tim, tinjau diff, pisahkan data sensitif, dan pastikan file baru yang diperlukan ikut dalam perubahan yang disetujui. Dokumen ini tidak melakukan commit, push, merge, atau perpindahan branch.

### Revisi Android dan emulator — 2 November 2026

**Masalah pertama: activity tidak ditemukan.** Log pengguna sebelumnya menunjukkan `ClassNotFoundException` saat Android mencoba membuka activity. Kondisi source yang diperiksa sekarang:

- `android/app/build.gradle.kts`: `namespace` dan `applicationId` adalah `com.example.campus_app`.
- `android/app/src/main/kotlin/com/example/campus_app/MainActivity.kt`: package `com.example.campus_app`, class `MainActivity` mewarisi `FlutterActivity`.
- `android/app/src/main/AndroidManifest.xml`: activity `.MainActivity`.
- Runner Kotlin pada path lama ditandai dihapus di Git; runner pada path baru masih untracked saat pembaruan ini. Keduanya perlu ditinjau dalam perubahan yang akan dibagikan agar clone tidak kehilangan runner.

**Masalah kedua: layar hitam setelah APK berhasil berjalan.** Pada AVD `Medium_Phone`, Flutter dan inisialisasi Supabase sudah berjalan, tetapi tampilan tidak terlihat ketika memakai kondisi Quick Boot lama. APK yang sama menampilkan login dan lupa password setelah cold boot dengan GPU host dan renderer bawaan. Percobaan menonaktifkan Impeller tidak menyelesaikan kondisi boot yang bermasalah. Bukti tersebut mengarah pada keadaan emulator yang dipulihkan, bukan membuktikan bahwa semua layar hitam selalu berasal dari Quick Boot.

Perbaikan yang disediakan melalui `tool/android/configure_emulator.ps1`:

1. Menerima nama AVD eksplisit dan memvalidasi format namanya.
2. Menolak perubahan ketika proses emulator masih aktif.
3. Menghormati `ANDROID_AVD_HOME`/`ANDROID_USER_HOME`, lalu membaca lokasi AVD dari berkas indeksnya.
4. Mengubah hanya `fastboot.forceChosenSnapshotBoot=no`, `fastboot.forceColdBoot=yes`, dan `fastboot.forceFastBoot=no`.
5. Membuat cadangan `config.ini.campus-backup-*` sebelum menulis; pemanggilan ulang tidak menulis jika konfigurasi sudah sesuai.
6. Tidak menghapus data pengguna/snapshot atau mengubah GPU, RAM, dan renderer Flutter.

Setelah konfigurasi, emulator dibuka secara normal tanpa flag pemulihan khusus. Perintah `flutter run -d emulator-5554 --no-pub` melalui hook proyek berhasil menyiapkan Ollama dan menampilkan login beserta keyboard. Model tetap berada di host; keberhasilan startup server bukan bukti evaluasi ulang kualitas semua jawaban AI. Frame terlewat masih tercatat saat startup debug, sehingga optimasi kinerja belum dinyatakan selesai. Panduan dan cara mengembalikan konfigurasi tersedia di `docs/android_emulator.md`.

### Penyeragaman nama proyek — 2 November 2026

| Bagian | Hasil akhir | Bukti konfigurasi |
|---|---|---|
| Package Dart | `campus_app` | `pubspec.yaml`; nama sudah sesuai sebelum revisi native terakhir |
| Android | `com.example.campus_app` | Gradle, package/path `MainActivity.kt`, manifest |
| Windows | Proyek/binary/judul `campus_app`; executable `campus_app.exe` | `windows/CMakeLists.txt`, `runner/main.cpp`, `runner/Runner.rc` |
| Linux | Binary/judul `campus_app`; application ID `com.example.campus_app` | `linux/CMakeLists.txt`, `runner/my_application.cc` |
| iOS | Display name dan CFBundleName `campus_app`; ID `com.example.campusApp` | `ios/Runner/Info.plist`, `Runner.xcodeproj/project.pbxproj` |
| macOS | Produk `campus_app.app`; ID `com.example.campusApp`; test host mengikuti produk baru | `macos/Runner/Configs/AppInfo.xcconfig`, project Xcode dan scheme Runner |
| Modul IDE lokal | `campus_app.iml`, `android/campus_app_android.iml` | Kedua berkas dan referensi `.idea/modules.xml` |
| Widget preview lokal | Nama/title `campus_app` | `.widget_preview/web/index.html` dan `manifest.json` |

Bundle identifier Apple menggunakan `campusApp` karena underscore tidak diterima pada identifier tersebut; nama produk tetap `campus_app`. Identifier target `RunnerTests` ikut diselaraskan. Identitas visual SIAKAD/EsaFIK dan skema callback Auth `campusapp` tetap dipertahankan. Penggantian nama teknis tidak mengganti proyek Supabase, akun, ataupun isi database.

Pemindaian ulang source, konfigurasi, berkas lokal yang relevan, dan nama path tidak menemukan sisa nama proyek lama. Riwayat Git tetap menyimpan nama terdahulu; tampilan diff/penghapusan path lama pada Source Control merupakan bagian normal perubahan sebelum commit. File IDE/cache yang diabaikan Git tetap bersifat lokal. Untuk Apple, perubahan bundle ID perlu dicocokkan dengan signing/provisioning pada host rilis sebelum distribusi; build Apple belum diverifikasi di Windows.

### Dokumentasi lama yang perlu dibaca secara kritis

`docs/izin_online.md` masih menjelaskan akun demo dan perilaku sesi simulasi. `docs/chatbot_quality.md`/`smart_chatbot.md` masih memiliki kalimat dari fase tanpa backend yang kini tidak berlaku bagi profil. Komentar `_quickAction` menyebut Biodata belum siap meskipun handler sudah membuka profil nyata; komentar repository dashboard juga masih menyebut login simulasi. Source yang aktif, tes, dan backend harus didahulukan ketika terjadi pertentangan tersebut. File lama tidak diubah dalam audit ini.

## L. Known Issues & Technical Debt

Prioritas merupakan penilaian kebutuhan pengembangan, bukan klaim semua risiko sudah dieksploitasi. “Terverifikasi” berarti keadaan terlihat pada source/metadata/log; dampak potensial tetap dibedakan dari kejadian yang sudah terjadi.

| ID/Prioritas | Masalah dan komponen | Penyebab/status bukti | Risiko | Solusi yang disarankan | Status penyelesaian |
|---|---|---|---|---|---|
| L01 CRITICAL untuk handover | Integrasi terbaru belum berada dalam commit | Terverifikasi dari status Git: banyak M/D/untracked | Anggota tim meng-clone versi yang belum memuat fitur/dokumen baru | Tinjau dan simpan perubahan yang disetujui secara lengkap; jangan commit rahasia | Terbuka; tidak dimutasi audit |
| L02 HIGH | Timestamp migrasi lokal/cloud berbeda | Terverifikasi dari file vs metadata Supabase | Penerapan ulang/urutan migrasi salah atau kegagalan db push | Bandingkan isi/schema/ledger dan selaraskan secara terencana sebelum migrasi berikutnya | Terbuka |
| L03 HIGH | Data akademik belum terhubung | `EmptyDashboardRepository` aktif | Dashboard/chat tidak dapat memberikan informasi kuliah nyata | Kontrak data resmi dan repository berotorisasi | Belum diimplementasikan |
| L04 HIGH | Izin hanya memori dan penerima contoh | `LeaveRepository`, `demoLecturers`; logout akun nyata membersihkan data sesi | Pengajuan hilang; tidak sampai kepada BAP/dosen perangkat lain | Backend izin, transaksi review, Storage bukti dan inbox | Simulasi terimplementasi; backend belum |
| L05 HIGH | Login staf belum tersedia | RPC hanya `student`; profil mengharapkan `students` | UI BAP/dosen tidak dapat digunakan sebagai layanan nyata melalui login sekarang | Provisioning staf, pemetaan identitas dan akses role server | Belum diimplementasikan |
| L06 HIGH | Reset OTP dan persistensi belum uji nyata lengkap | Backend OTP deployed; satu email nyata delivered 3 November; checklist tersedia | Delivery tidak membuktikan reset/login/pencabutan sesi pada perangkat | Jalankan checklist OTP/profil tanpa membagikan rahasia; verifikasi domain untuk pemakaian umum | NEEDS VERIFICATION |
| L07 HIGH sebelum produksi | Leaked password protection nonaktif | WARN security advisor saat audit | Password yang bocor tidak memperoleh perlindungan tambahan tersebut | Aktifkan bila tersedia; verifikasi kebijakan password backend | Terbuka |
| L08 HIGH sebelum deployment | AI LAN HTTP tanpa Auth aplikasi; cleartext Android luas | Terverifikasi konfigurasi; eksploitasi tidak diuji | Akses jaringan tidak diinginkan/mixed content dan kegagalan pada web publik | Rancang gateway terautentikasi/TLS atau batasi mode development; uji platform | Rekomendasi belum diterapkan |
| L09 MEDIUM | Hook AI menghalangi Flutter ketika unduhan gagal | Source hook; gangguan DNS pernah dilaporkan | Pengembang tidak bisa menjalankan UI melalui hook saat model belum siap | Putuskan mode gagal yang jelas; opsi bantuan terpandu/offline tanpa mengaku AI aktif | Perilaku sekarang terverifikasi |
| L10 MEDIUM | Auto-start terbatas terminal Windows yang memuat hook | `.vscode`, workspace, PowerShell | Klaim “semua flutter run di semua komputer” menyesatkan | Panduan bootstrap lintas shell/OS dan tes clone baru | Sebagian; perlu validasi |
| L11 MEDIUM | Mutex menunggu tanpa timeout total | Loop `start.ps1`; abandoned mutex ditangani | Proses hidup yang macet membuat terminal lain menunggu lama | Tambahkan diagnosis pemilik/progres dan strategi batas waktu terukur | Terbuka; bukan bukti deadlock sekarang |
| L12 MEDIUM | Storage dan metadata tidak atomik | Cleanup best effort pada repository | Objek orphan atau status operasi tidak pasti saat jaringan putus | Rekonsiliasi/pembersihan server, idempotensi, pengujian kegagalan | Mitigasi sebagian |
| L13 MEDIUM | Validasi dokumen bukan malware scan | Pemeriksaan tipe/signature/ukuran | Isi berkas berbahaya belum disaring menyeluruh | Kebijakan unduh, pemindaian/quarantine sesuai kebutuhan institusi | Belum diimplementasikan |
| L14 MEDIUM | Format foto tambahan dan batas decoder platform | Fallback codec HEIC/AVIF tergantung platform | File valid di satu perangkat gagal di perangkat lain; risiko sumber daya belum diuji menyeluruh | Matriks format/perangkat, pesan konversi dan batas yang konsisten | Sebagian; NEEDS VERIFICATION |
| L15 MEDIUM | Katalog wilayah dan template resmi belum tersedia | Form teks provinsi/kota; tanpa template resmi | Variasi penulisan/kebutuhan dokumen belum sesuai final | Sumber wilayah resmi dan template yang disetujui | PLANNED |
| L16 MEDIUM | Dokumentasi/komentar lama bertentangan dengan source baru | Contoh di bagian K | Pengembang mengaktifkan kembali dummy atau salah menilai fitur | Perbarui dokumen/komentar pada tugas terpisah | Terbuka; audit hanya mencatat |
| L17 MEDIUM | LLM kecil dan pengenal pola tidak mencakup semua bahasa | Evaluasi historis pernah salah definisi/pengulangan | Jawaban umum kurang tepat/maksud pesan terlewat | Glosarium, corpus regresi dan penilaian manusia; jangan hanya memperpanjang prompt | Mitigasi sebagian |
| L18 MEDIUM | Belum CI/CD dan uji perangkat lengkap | Tidak ada workflow aplikasi atau suite integration_test; startup satu AVD dan build Windows kini terverifikasi | Regresi/perbedaan platform tidak segera terdeteksi | CI analyze/test/build, staging, dan perluasan matriks perangkat pada bagian J | Verifikasi manual sebagian; CI belum diimplementasikan |
| L19 LOW | Satu lint TypeScript deklarasi fungsi dalam blok | Screenshot terakhir pada `allowed()` di Edge | Noise editor; bukan bukti runtime gagal | Refactor kecil dengan parameter/scope tetap benar pada tugas kode berikutnya | Belum diperbaiki; perlu cek ulang diagnostik |
| L20 LOW | Tema alternatif/font tidak terdaftar dan ignore duplikat | `retro_theme.dart`, `.gitignore`; bagian penamaan lama sudah diselesaikan pada 2 November | Kebingungan pemeliharaan | Audit pemanggil dan rapikan hanya setelah cakupan jelas | Terbuka sebagian; penamaan proyek selesai pada cakupan bagian K |
| L21 MEDIUM | Konsistensi visual referensi dan penerimaan navigasi bawah | Navigasi gulir/Chatbot tercakup suite 218 tes yang lulus | Posisi gulir dan tampilan perangkat nyata masih perlu diperiksa | Uji Beranda, Jadwal, Kemajuan Belajar, kartu Profil, serta Chatbot | Pengguna mengonfirmasi berhasil; penerimaan lintas perangkat tetap diperlukan |
| L22 HIGH sebelum produksi | Backup, retensi, audit kegiatan dan operasi pengelola belum lengkap | Tidak ditemukan implementasi/panduan operasional lengkap | Data dan keputusan layanan sulit dipulihkan/dilacak | Tetapkan kebijakan, backup/restore drill, audit trail dan pemantauan | PLANNED |
| L23 MEDIUM | Layar hitam dari kondisi boot AVD yang diuji | APK yang sama tampil setelah cold boot; startup normal setelah konfigurasi berhasil | Host anggota tim masih dapat mengalami masalah emulator berbeda | Terapkan panduan per AVD yang bermasalah; kumpulkan log jika tetap terjadi | Terselesaikan pada `Medium_Phone`; pengaturan host tidak ikut merge |
| L24 MEDIUM | Kinerja startup debug dan matriks build native belum lengkap | Frame terlewat pada emulator; build Windows berhasil tetapi runtime belum diuji; Apple/Linux belum dibangun | Build sukses disalahartikan sebagai kesiapan semua perangkat | Profil kinerja dan uji alur lintas platform sesuai matriks J | NEEDS VERIFICATION |

## M. Development Roadmap

Roadmap berikut adalah rencana dari kondisi audit, bukan instruksi otomatis mengubah sistem. Nomor fase mengikuti struktur yang diminta; sebagian pekerjaan backend fase 3 sudah mendahului penyelesaian akademik fase 2 dan tidak perlu diulang.

| Fase | Tujuan | Pekerjaan utama | Dependensi | Kriteria selesai | Status aktual |
|---|---|---|---|---|---|
| PHASE 1 — Foundation & Stabilization | Fondasi dapat diteruskan tim secara konsisten | Handover perubahan belum commit, selaraskan history migrasi, bersihkan dokumentasi basi, validasi lingkungan/hook | Working tree lengkap dan akses repo/backend yang sah | Clone baru mendapat source yang benar; setup terdokumentasi; tidak ada ketidakjelasan sumber aktif; regresi inti lulus | PARTIALLY COMPLETED: struktur/tema/tes ada; handover dan sinkronisasi tersisa |
| PHASE 2 — Core Academic Features | Jadwal, KRS, hasil studi, presensi dan informasi benar-benar berfungsi | Definisikan model/layanan akademik, halaman nyata, empty/error/loading states, aturan studi resmi | Sumber data dan backend fase 3; keputusan kampus | Mahasiswa hanya melihat catatannya; alur akademik disetujui; data dan perhitungan teruji | PARTIALLY COMPLETED: UI/model/menu tersedia; data/workflow belum |
| PHASE 3 — Database & Backend Integration | Penyimpanan dan hak akses semua modul | Pertahankan Auth/profil; lanjutkan schema akademik, staf, izin, keuangan, provisioning dan audit | Rekonsiliasi migrasi, model domain dan otorisasi | RLS/akses negatif lulus; persistensi lintas sesi/perangkat; migrasi dapat diulang pada lingkungan baru | IN PROGRESS: profil nyata sudah terintegrasi, domain lain belum |
| PHASE 4 — AI Chatbot Integration | Bantuan berbasis sumber yang akurat dan terbatas hak akses | Pertahankan routing/glosarium; tambah API baca resmi, evaluasi, provenance, gateway sesuai deployment; RAG jika sumber tersedia | Backend akademik, dokumen resmi, kontrak privasi | Jawaban dapat ditelusuri; tidak membocorkan lintas akun; fallback jujur; skenario pendek dan adversarial lulus | PARTIALLY COMPLETED: AI lokal/routing/profil tersedia; akademik/RAG belum |
| PHASE 5 — Advanced Features | Layanan kampus dan komunikasi lengkap | Izin mahasiswa–BAP–dosen nyata, notifikasi, kalender, konseling, tugas akhir/program lain; pembayaran bila masuk scope | Peran staf, backend transaksi, kebijakan layanan | Pengajuan dan keputusan tercatat/terkirim tepat; PDF konsisten; notifikasi dan layanan dapat diuji lintas akun | PARTIALLY COMPLETED hanya prototipe izin; sebagian besar PLANNED |
| PHASE 6 — Security, Testing & Optimization | Sistem stabil dan aman sesuai target penggunaan | Recovery nyata, multiuser, perangkat, aksesibilitas, kinerja, file besar, backup, hardening jaringan dan CI | Modul siap, staging dan data uji yang aman | Bukti uji terarsip; temuan penting ditutup; performa/aksesibilitas memenuhi target yang disepakati | IN PROGRESS: unit/widget/RLS ada; belum audit produksi lengkap |
| PHASE 7 — Finalization & Deployment | Paket demonstrasi/rilis dan operasional | Identitas app, signing, hosting, config environment, monitoring, runbook, onboarding staf dan acceptance | Fase relevan selesai dan persetujuan pemilik sistem | Release dapat dipasang; konfigurasi aman; rollback/restore diketahui; scope demo/produksi tertulis | PLANNED untuk rilis; penamaan seragam, build web historis serta APK/Windows debug berhasil; deployment belum |

## N. Priority Tasks & Next Development Steps

### CRITICAL

1. **Amankan kesinambungan source sebelum pindah akun/komputer.** Periksa `git status`, seluruh file untracked, perubahan penghapusan demo, konfigurasi publik vs rahasia, dan diff. Lakukan commit/push hanya pada tugas yang diotorisasi pengguna; jangan mengira master sudah memuat working tree ini. Bukti utama: root, `lib/core/config/`, `lib/features/profile/`, `supabase/`, `test/support/`.
2. **Sebelum memakai data produksi, hentikan asumsi bahwa semua modul sudah nyata.** Tetapkan lingkungan development dan ruang lingkup demo; jangan menjalankan simulasi izin sebagai pengiriman resmi. Periksa `main.dart`, `dashboard_repository.dart`, `leave_repository.dart` dan `resolve_student_login`.

### HIGH

1. Rekonsiliasi isi/versi migrasi lokal dengan ledger remote **sebelum DDL berikutnya**: `supabase/migrations/`, metadata Supabase, `supabase/config.toml`.
2. Selesaikan uji penerimaan profil terbaru memakai `docs/profile_test_checklist.md`: simpan/relogin, foto, berkas, konflik, email recovery dan sesi. Catat hasil per perangkat, bukan klaim umum.
3. Putuskan domain pertama yang dihubungkan berikutnya; rekomendasi teknis adalah jadwal/read-only akademik setelah kontrak sumber resmi disepakati. Periksa `dashboard_models.dart`, `dashboard_repository.dart`, `profile_answers.dart`.
4. Jika prioritas layanan adalah izin, selesaikan akun/peran staf dan backend izin sebelum notifikasi/PDF resmi: `supabase/functions/login-with-nim/index.ts`, `student_profile.dart`, seluruh `features/leave/`.
5. Tindak lanjuti keamanan sebelum rilis: leaked-password protection, pemulihan akun, akses dua pengguna, retensi/backup, dan arsitektur AI jaringan. Periksa migrasi, config platform dan `tool/local_ai/firewall.ps1`.

### MEDIUM

1. Validasi clone baru dan auto-start pada terminal yang benar; tentukan perilaku ketika AI/download gagal. Periksa `flutter_hook.ps1`, `runtime.ps1`, `start.ps1`, `.vscode/settings.json`, workspace.
2. Sediakan katalog wilayah dan template dokumen resmi setelah sumber disetujui: `biodata_fields.dart`, `biodata_form.dart`, `profile_records.dart`.
3. Perbarui dokumentasi/komentar yang tertinggal dan label simulasi; pertahankan fakta bahwa profil nyata dan akademik kosong adalah dua kondisi berbeda.
4. Tambah CI serta tes integrasi yang relevan, matriks platform, error upload dan cleanup Storage. Periksa `.github/`, `test/`, `supabase/tests/`.
5. Evaluasi chatbot dengan pesan nyata yang dianonimkan, tingkatkan pola berdasarkan bukti, lalu integrasikan data berotorisasi. Jangan memberi akses SQL langsung pada model.
6. Uji visual terhadap referensi dan konsistensi navigasi; perubahan UX harus mempertahankan aksesibilitas dan fungsi yang sudah diuji.

### LOW

1. Perbaiki lint `allowed()` pada Edge tanpa mengubah scope secret/client atau semantik rate limit.
2. Audit tema alternatif, nama package/platform lama dan aturan `.gitignore` berulang; lakukan perubahan terpisah yang mudah ditinjau.
3. Lengkapi komentar yang membantu pemahaman alasan kode; jangan hanya menambah komentar yang mengulang sintaks.

Urutan langsung yang direkomendasikan: **handover source → rekonsiliasi migrasi → verifikasi profil/recovery → kontrak data/peran → implementasi modul berikutnya → integrasi AI data → hardening/release**.

## O. Project Handover — New Codex Account

> AI/Codex yang baru wajib membaca file project_progress.md dan memeriksa source code aktual sebelum melanjutkan pengembangan. Jangan mengulang implementasi yang sudah selesai, jangan mengubah arsitektur tanpa alasan teknis yang jelas, dan jangan membuat asumsi mengenai fitur yang belum diverifikasi.

### O.1 Ringkasan mandiri untuk penerus

Anda melanjutkan Flutter Campus App, SIAKAD FASILKOM Esa Unggul, pada branch kerja `marcell-works` saat audit. Tujuannya layanan mahasiswa dengan profil, akademik, izin, dan chatbot. Source saat audit lebih baru daripada HEAD yang sudah di-commit. Pengguna mengutamakan komentar Indonesia yang mudah dipahami, organisasi file menurut tanggung jawab, UI konsisten, dan komunikasi singkat tanpa mengurangi mutu implementasi.

Login/profil menggunakan **Supabase nyata**, bukan auth dummy. Sesi aplikasi absolut 30 menit dan token tidak dipersistenkan. Tabel/bucket profil memiliki RLS dan pembatasan kolom. Profil mempunyai tujuh bagian; data resmi read-only. Foto dikonversi sebelum disimpan, telepon 08 diterima melalui normalisasi, email kampus/kontak/Auth berbeda fungsi. Pertahankan validasi, deteksi konflik dan cleanup berkas.

Dashboard akademik masih kosong melalui `EmptyDashboardRepository`. Izin masih workflow memori dengan penerima contoh; jangan mengaku sudah mengirim ke unit kampus. Chatbot lokal menggunakan `qwen2.5:1.5b`; aturan aplikasi menjawab pesan singkat dan profil, model membantu tutor/penulisan. Tidak ada RAG atau database akademik lengkap. Auto-install/start merupakan hook host Windows, bukan perilaku semua shell atau perangkat.

Per 2 November, penamaan teknis sudah seragam menjadi `campus_app`; ID Apple `com.example.campusApp`. Emulator `Medium_Phone` berhasil menampilkan login/keyboard setelah konfigurasi cold boot. Enam tes startup/login lulus, analyze setelah revisi nama bersih, dan build Windows debug berhasil. Bukti ini tidak menggantikan uji login nyata/persistensi pada emulator maupun uji runtime Windows. Jangan mengulang diagnosis dengan asumsi bahwa runner masih hilang; periksa kondisi terbaru dan baca bagian J/K serta `docs/android_emulator.md`.

### O.2 Pemeriksaan awal sebelum mengubah kode

1. Baca dokumen ini, `README.md`, `docs/student_profile.md`, `docs/profile_test_checklist.md`, dan `docs/android_emulator.md`. Perlakukan dokumen chatbot/izin lama sebagai konteks yang harus dicocokkan dengan source.
2. Jalankan pemeriksaan baca `git status --short`, `git branch --show-current`, `git rev-parse HEAD`. Jangan menimpa perubahan pengguna, menghidupkan kembali file yang sengaja dihapus, atau berpindah branch otomatis.
3. Baca instruksi `AGENTS.md`/skill yang tersedia pada lingkungan baru. Pada audit ini tidak ditemukan AGENTS yang menambah aturan proyek. Caveman, Supabase, dan Resend (`resend-cli` skill serta connector) tersedia pada sesi 3 November. Ketersediaan plugin/skill tidak dijamin melekat selamanya antar akun: verifikasi, lalu beri tahu pengguna jika tidak tersedia.
4. Mulai alur code dari `main.dart` dan kontrak `data/`; periksa pemanggil sebelum mengubah widget. Jangan mengganti backend/state management hanya demi merapikan struktur.
5. Jika menyentuh database, pastikan proyek/lingkungan yang benar, tinjau schema/RLS, dan selesaikan selisih versi migrasi. Jangan menjalankan seed development pada akun/lingkungan lain tanpa kebutuhan jelas.
6. Gunakan akun uji yang dibuat pemilik. Jangan meminta password di chat, membaca token untuk dilaporkan, atau memasukkan service-role key ke Flutter.

### O.3 Persiapan lingkungan

- Host pengujian 2 November memakai Flutter 3.47.5/Dart 3.13.4. Constraint proyek tetap `^3.13.3`; periksa versi dan `flutter doctor` pada komputer tujuan. Hasil pada host ini tidak menjamin setiap kombinasi SDK/toolchain anggota tim sudah teruji.
- Buka root `campus_app` di VS Code atau `campus_app.code-workspace`, agar pengaturan terminal proyek berlaku. Membuka induk `Repositories` saja dapat menyebabkan konfigurasi nested tidak digunakan.
- Sediakan Chrome untuk web. Android memerlukan SDK/emulator atau perangkat; Windows desktop memerlukan toolchain C++ yang sesuai. Peringatan toolchain Windows tidak sama dengan error build Chrome.
- Deno dan ekstensi resmi Deno dibutuhkan untuk pemeriksaan/editor Edge Functions; `.vscode/settings.json` membatasi Deno ke `supabase/functions`. Deno bukan pengganti Flutter SDK.
- Supabase proyek sudah ada. Config client menggunakan URL/publishable key, bukan secret. Backend memerlukan migrasi, Edge dan akun/profil yang benar; jangan membuat proyek baru bila proyek yang sama masih menjadi target.
- Ollama otomatis saat ini berorientasi Windows amd64, membutuhkan internet untuk instalasi pertama, disk/RAM memadai, dan port 11435 yang bebas atau milik runtime proyek. Model tidak ikut clone.
- Jangan memasang package/toolchain tanpa kebutuhan atau kewenangan yang sesuai pada tugas berikutnya. Perintah di bawah merupakan panduan, bukan tindakan yang telah dijalankan selama audit dokumentasi.

### O.4 Menjalankan aplikasi

Dari root proyek setelah source lengkap tersedia:

```powershell
flutter pub get
flutter run -d chrome --web-port 3000
```

Gunakan terminal **Campus App (AI otomatis)** untuk pemulihan/start model sebelum Flutter. OTP tidak membutuhkan port web tetap; allowlist redirect hanya untuk alur tautan Auth lama. Untuk target lain:

```powershell
flutter devices
flutter run
flutter run -d <device-id>
```

`<device-id>` harus diganti hasil `flutter devices`; `flutter run -d` tanpa nilai perangkat bukan perintah lengkap. Emulator tidak otomatis berarti model berjalan di emulator; ia menghubungi host.

Jika AVD mengalami layar hitam seperti kasus `Medium_Phone`, tutup semua emulator lalu terapkan pengaturan sekali pada host yang bermasalah:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tool\android\configure_emulator.ps1 -AvdName Medium_Phone
```

Ganti nama AVD sesuai Device Manager. Buka emulator kembali dan tunggu Android selesai boot, kemudian gunakan `flutter run -d <device-id>`. Skrip menyimpan cadangan sebelum mengubah pengaturan; petunjuk rollback ada di `docs/android_emulator.md`. Jangan menganggap merge otomatis mengubah konfigurasi AVD komputer teman. Setelah perubahan identitas native, hentikan run lama dan build ulang; hot reload tidak mengganti identitas Android.

Jika terminal tidak memuat hook, alternatif manual yang sudah tersedia:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tool\local_ai\start.ps1 -RequireModel -Repair
flutter run -d chrome --web-port 3000
```

`setup.ps1` tetap tersedia untuk bootstrap; `install_autostart.ps1` berkaitan dengan pemasangan pengait lingkungan dan harus ditinjau sebelum mengubah profil shell. Pull Git saja tidak mengeksekusi salah satunya. Jangan menyarankan bahwa semua anggota tim cukup mengetik perintah yang sama tanpa memastikan hook/SDK/jaringan mereka.

Setelah selesai memakai server lokal, skrip penghentian tersedia:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tool\local_ai\stop.ps1
```

HP nyata perlu berada pada jaringan yang dapat menjangkau host, host tetap hidup, dan firewall sesuai. Endpoint manual dapat diatur pada koneksi chatbot bila deteksi tidak sesuai. Alamat hasil build dapat kedaluwarsa ketika jaringan host berubah; jalankan startup/bundling ulang atau perbarui pilihan koneksi sesuai kebutuhan.

### O.5 Memeriksa kualitas dan penerimaan

1. Jalankan tes yang berhubungan dengan perubahan, lalu `flutter analyze` dan `flutter test` untuk penerimaan. Bukti terbaru 218 tes pada revisi OTP tidak otomatis berlaku setelah source berikutnya berubah.
2. Gunakan `dart format --output=none --set-exit-if-changed lib test` untuk pemeriksaan tanpa penulisan; formatter penulisan hanya pada tugas perubahan kode yang diizinkan.
3. Periksa Edge dengan `deno check` dan konfigurasi Deno yang benar. Satu lint pemindahan deklarasi fungsi tidak sama dengan error runtime.
4. Uji SQL `supabase/tests/profile_access.sql` hanya pada development dengan pemahaman bahwa script membuat fixture dan rollback; jangan menjalankannya secara otomatis pada produksi.
5. Jalankan `tool/local_ai/smoke.dart`/`evaluate.dart` hanya saat perlu memverifikasi model nyata. Bedakan keberhasilan routing aplikasi dari ketepatan jawaban LLM.
6. Untuk profil, jalankan checklist manual. Penerimaan minimal: simpan data/foto/berkas, muat ulang, login ulang, batal edit, konflik dua jendela, gagal jaringan, akses akun lain ditolak, dan sesi habis benar.
7. Resend sudah mengirim satu OTP nyata berstatus delivered pada 3 November. Lanjutkan `docs/password_reset_otp.md` untuk reset melalui UI, login ulang, dan sesi lama. Ekspor HP, format foto tambahan, layout perangkat, dan kesesuaian visual referensi masih memerlukan hasil tertulis. Callback Auth lama diuji terpisah bila tetap digunakan.
8. Saat mengubah startup/platform, gunakan enam tes terarah `flutter test test/app_startup_test.dart test/widget_test.dart` dan build target yang relevan. Periksa juga tampilan nyata; build Windows berhasil tidak membuktikan login atau callback desktop berjalan.
9. Bukti lama di `build/` dapat hilang saat pembersihan. Tiga log audit 1 November sudah tidak tersedia pada pembaruan ini. Catat tanggal, perintah, hasil dan batas verifikasi baru tanpa mengubah hasil historis menjadi klaim pengujian ulang.

### O.6 Keputusan yang tidak boleh hilang

- Pertahankan Supabase/PostgreSQL sebagai backend aktual sampai ada keputusan perubahan yang eksplisit; MySQL Workbench bukan komponen aktif.
- Pertahankan sesi absolut, RLS pemilik+sesi, privilege kolom, private Storage, dan pemisahan identitas resmi dari preferensi.
- Jangan mengembalikan login dummy atau menanam contoh nilai/jadwal untuk menyamarkan data kosong. Fixture tes boleh tetap ada; penerima izin contoh harus dikenali sebagai simulasi.
- Jangan kirim seluruh profil/dokumen ke model; akses akademik berikutnya harus melalui API yang membatasi pemilik dan peran.
- Jangan menyatakan AI menyetujui surat atau mengirim layanan jika hanya menghasilkan draf/objek lokal.
- Pertahankan seluruh kebutuhan SIAKAD, komentar yang jelas, desain yang sudah disetujui, dan struktur file seimbang.
- Jangan memperbarui dependency, database, branch, atau konfigurasi host tanpa kaitan jelas dengan tugas yang diminta.
- Pertahankan nama teknis `campus_app`, ID Android/Linux `com.example.campus_app`, dan ID Apple `com.example.campusApp`. Skema callback `campusapp` bukan salah penamaan dan tidak perlu diganti hanya untuk menyeragamkan underscore.
- Perbaikan layar hitam yang terbukti memakai cold boot pada host AVD; renderer Flutter bawaan tetap digunakan. Jangan menghapus data emulator atau mematikan Impeller tanpa diagnosis baru.

### O.7 Pekerjaan pertama yang direkomendasikan

Mulai dari peninjauan working tree dan penyelarasan sumber untuk tim, lalu cocokkan migrasi remote/lokal. Setelah itu selesaikan verifikasi profil terbaru menggunakan checklist yang sudah ada. Jangan membangun ulang formulir/profil dari nol. Tentukan bersama pemilik apakah modul berikutnya adalah jadwal akademik atau backend izin; keduanya membutuhkan sumber data dan otorisasi yang belum lengkap.

Dokumen ini harus diperbarui ketika ada implementasi atau bukti pengujian baru, dengan tanggal/commit yang sesuai. Tandai rencana sebagai rencana sampai source, backend, dan verifikasi benar-benar mendukung status selesai.

## P. Prosedur Manajemen Token — GPT-6 Astra High

**Ditetapkan:** 4 November 2026. Prosedur ini menjadi pedoman pengembangan dan serah terima lintas sesi maupun akun Codex. Efisiensi token tidak boleh mengurangi kelengkapan kebutuhan SIAKAD, keamanan, akurasi, kualitas implementasi, atau validasi penting.

### 1. Model dan Efisiensi

- Model utama yang ditetapkan pengguna adalah **GPT-6 Astra High**. Jangan mengganti model tanpa instruksi pengguna. Ketentuan ini merupakan preferensi pengguna; pencatatan di dokumen tidak mengubah konfigurasi model pada antarmuka Codex atau membuktikan model yang sedang aktif.
- Minimalkan token dari input, output, pembacaan file, dan pemanggilan tools dengan memilih informasi yang langsung mendukung tugas.
- Gunakan instruksi singkat. Hindari analisis dan penjelasan berulang yang tidak menambah bukti atau keputusan.
- Prioritaskan ketepatan dan kualitas hasil dibanding sekadar mengurangi token. Dokumentasi atau penjelasan detail yang diminta pengguna tetap harus lengkap.

### 2. Manajemen Konteks dan Sesi

- Pada sesi baru, baca ringkasan eksekutif, keputusan teknis, dan tugas aktif dari dokumen ini; gunakan bagian K, N, dan O sesuai kebutuhan. Periksa apakah status tersebut masih cocok dengan keadaan proyek sebelum melanjutkan.
- Baca bagian dokumentasi tambahan dan source code hanya jika berhubungan dengan tugas. Hindari membaca ulang file yang tidak berubah dan masih tersedia dalam konteks.
- Setelah satu fitur atau milestone selesai, perbarui bagian progres yang terdampak, termasuk hasil validasi dan pekerjaan yang belum selesai.
- Setelah pekerjaan selesai dan dokumentasi tersimpan, pengguna dapat memulai sesi baru melalui **New Chat** atau `/clear` apabila tersedia pada antarmuka yang digunakan. Pastikan ringkasan serah terima sudah tersimpan terlebih dahulu.
- Untuk sesi panjang yang masih memerlukan konteks sebelumnya, gunakan `/compact` apabila tersedia. Ketersediaan perintah harus diperiksa pada antarmuka yang digunakan, bukan diasumsikan sama di semua akun.
- Jangan menghapus konteks ketika tugas masih berjalan atau pekerjaan belum diverifikasi. Catat status sementara bila sesi harus terputus.

### 3. Pembatasan Pembacaan File

- Cari nama file, fungsi, class, atau simbol sebelum membuka source code; utamakan `rg --files` dan `rg -n` untuk mempersempit lokasi.
- Baca bagian yang diperlukan terlebih dahulu. Lakukan pemeriksaan seluruh repository hanya jika cakupan tugas atau bukti masalah memerlukannya.
- Kecualikan cache, hasil build, dependensi, file model AI berukuran besar, dan log yang tidak relevan dari pencarian rutin. Buka artefak tersebut secara terarah hanya ketika dibutuhkan untuk diagnosis.
- Jangan membuka dokumentasi atau memanggil plugin/MCP yang tidak berkaitan dengan tugas. Pilih alat yang memberi bukti paling langsung.
- Jangan mengulang operasi yang sudah berhasil kecuali ada perubahan, hasil kedaluwarsa, kegagalan baru, atau kebutuhan verifikasi yang jelas.

### 4. Perubahan Source Code

- Terapkan perubahan sekecil mungkin melalui edit atau patch terarah. Jangan menulis ulang seluruh file jika perubahan lokal sudah mencukupi.
- Pertahankan arsitektur, fitur, desain yang telah disetujui, dan perilaku yang tidak berkaitan dengan permintaan.
- Jangan melakukan refactoring tambahan atau membuat file baru tanpa kebutuhan teknis. Pertahankan pembagian tanggung jawab file yang seimbang dan komentar yang mudah dipahami.
- Hemat token dengan membatasi cakupan perubahan, bukan dengan menghilangkan validasi, penanganan error, kontrol akses, atau kebutuhan pengguna.

### 5. Pengujian dan Validasi

- Jalankan pengujian yang relevan dengan bagian yang berubah. Gunakan analisis atau pengujian menyeluruh bila perubahan memengaruhi banyak modul atau diperlukan untuk keamanan dan stabilitas.
- Jangan mengulang pengujian yang telah lulus tanpa perubahan baru, kegagalan, atau persoalan yang belum terjawab.
- Batasi keluaran log ke hasil dan bagian relevan, terutama error serta warning. Simpan rincian bila diperlukan sebagai bukti tanpa menyalin seluruh log ke percakapan.
- Jangan mengorbankan validasi penting demi penghematan token. Bedakan hasil pengujian aktual, bukti historis, dan skenario yang belum diuji.
- Untuk pembaruan dokumentasi saja, cukup periksa perubahan teks, struktur, tautan internal, dan whitespace; jangan menjalankan suite aplikasi tanpa alasan terkait perubahan.

### 6. Format Respons

- Gunakan gaya Caveman: jawaban singkat, jelas, langsung ke hasil, tanpa pengulangan informasi yang sudah diketahui. Tetap gunakan penjelasan lengkap ketika pengguna memintanya.
- Jangan menampilkan seluruh source code yang sudah tersimpan. Untuk perubahan kode, laporkan nama file, ringkasan perubahan, hasil pengujian, dan batas verifikasi yang material.
- Tampilkan code diff hanya jika diminta pengguna atau diperlukan untuk menjelaskan perubahan.
- Jangan mengklaim pekerjaan selesai, integrasi aktif, atau pengujian lulus tanpa bukti yang sesuai.

### 7. Verifikasi Teknologi dan Plugins

Verifikasi penggunaan berdasarkan source code, konfigurasi, dan dokumentasi proyek. Ketersediaan plugin pada akun Codex tidak membuktikan integrasi aplikasi. Gunakan dokumentasi resmi atau skill yang relevan untuk API yang belum pasti; jangan menebak sintaks.

Gunakan status berikut secara konsisten:

- **Aktif:** penggunaan atau integrasi memiliki bukti; jelaskan cakupan dan batas verifikasinya.
- **Direncanakan:** tercatat dalam roadmap, tetapi implementasi belum tersedia.
- **Tidak Digunakan:** hasil pemeriksaan menunjukkan teknologi tidak dipakai dalam cakupan yang dinilai.
- **Belum Terverifikasi:** bukti belum cukup; jangan menyimpulkan aktif maupun tidak digunakan.

| Teknologi/skill | Status | Bukti dan batas penggunaan |
| --- | --- | --- |
| Flutter/Dart | **Aktif** | `pubspec.yaml` menetapkan package `campus_app` dan Flutter SDK; `lib/main.dart` menjadi titik masuk aplikasi. |
| Supabase | **Aktif** | Dependency `supabase_flutter` pada `pubspec.yaml` dan penggunaan `SupabaseAuthService(Supabase.instance.client)` pada `lib/main.dart` mendukung integrasi Auth/profil yang dijelaskan di bagian F dan I. Status ini tidak berarti seluruh modul akademik sudah mempunyai data nyata. |
| Resend | **Aktif** | `supabase/functions/password-reset/index.ts` membaca `RESEND_API_KEY`; `services.ts` menggunakan endpoint `https://api.resend.com/emails`. Bukti pengiriman nyata terakhir bertanggal 3 November ada di bagian J; tidak dilakukan pengiriman ulang pada pembaruan dokumentasi ini. |
| Ollama lokal | **Aktif** | `lib/features/chatbot/ollama_service.dart` memuat model `qwen2.5:1.5b` dan endpoint `/api/chat`. Integrasi source tersedia; server/model tetap harus siap pada host. Status proses dan koneksi runtime tidak diperiksa ulang pada 4 November. |
| Caveman | **Aktif** | Skill tersedia dan dibaca dari `C:/Users/Marcell/.agents/skills/caveman/SKILL.md` pada sesi ini. Fungsinya mengatur gaya komunikasi Codex yang ringkas; bukan framework aplikasi atau dependency Flutter. |

**Batas pemeriksaan 4 November 2026:** pemeriksaan source/configuration dan dokumentasi secara baca-saja. Tidak ada pemeriksaan cloud langsung, instalasi, migrasi, atau pengujian fungsional baru. Status historis pengujian tetap memakai tanggal aslinya. Pada akun/sesi baru, periksa kembali ketersediaan skill Caveman, plugin Supabase, dan plugin/skill Resend beserta aksesnya; jangan menganggapnya ikut terpasang melalui clone Git. Jika tidak tersedia, beri tahu pengguna tanpa menyatakan integrasi aplikasi otomatis hilang.

### 8. Dokumentasi dan Serah Terima

- Perbarui bagian terkait dalam `project_progress.md` setelah perubahan fitur signifikan atau milestone selesai. Hindari penulisan ulang dokumen secara keseluruhan.
- Pertahankan informasi historis dan roadmap yang masih relevan. Tandai keputusan yang diganti dengan status terbaru agar sejarah tetap dapat ditelusuri.
- Catat fitur selesai, keputusan teknis, file/modul terkait, bukti validasi beserta tanggal, masalah tersisa, dan pekerjaan berikutnya.
- Bedakan perubahan lokal, commit/push, migrasi database, deploy Edge Function, dan konfigurasi layanan eksternal. Satu tahap tidak otomatis membuktikan tahap lainnya selesai.
- Pastikan akun Codex berikutnya dapat menemukan tujuan aktif, batas pekerjaan, status source/backend, dan langkah validasi tanpa membaca ulang seluruh percakapan. Jangan menyimpan password, API key, OTP, atau nilai secret dalam dokumen serah terima.
- Pembaruan 4 November ini hanya menambahkan prosedur dan catatan verifikasi teknologi. Tidak mengubah source aplikasi, memasang dependency, memigrasikan database, menjalankan pengujian menyeluruh, atau melakukan commit/push. Pekerjaan produk berikutnya tetap mengacu pada bagian N dan O.
