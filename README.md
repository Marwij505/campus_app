# Campus App — SIAKAD Fasilkom

Aplikasi Flutter SIAKAD dengan tema retro/pixel. **Login dan profil mahasiswa memakai Supabase Auth, Postgres, serta Storage privat.** Data akademik, keuangan, dan administrasi kampus masih dikembangkan; data yang belum tersedia tidak dibuat-buat.

**Periode milestone:** pekerjaan sebelum Penutupan Fondasi Akun termasuk **Milestones Oktober 2026**. Penutupan Fondasi Akun adalah **M1 November 2026**, berstatus **ACCEPTED WITH TEST EXCEPTIONS** (56 PASS sesuai bukti dan 4 pengecualian pengujian). Semua sebutan M1 di README ini merujuk pada M1 November 2026. Tanggal pelaksanaan/pengujian historis tetap mengikuti kejadian sebenarnya; rincian ada di [project_progress.md](project_progress.md).

## Fitur dan status

- **Login nyata:** NIM/password melalui Edge Function, pembatasan percobaan, pesan kesalahan umum, logout, dan sesi absolut 30 menit yang ditegakkan server.
- **Biodata:** tujuh tab untuk biodata, pendidikan, keluarga, pekerjaan, disabilitas, riwayat keuangan, dan berkas privat. Formulir pribadi tersimpan di Supabase; data resmi/keuangan hanya dibaca. Foto lintas format dikonversi ke JPEG, nomor `08…` diterima, email kampus/pribadi/login dipisahkan.
- **Profil bersama:** dashboard, Biodata, chatbot, draf surat, dan form izin menggunakan identitas yang sama. Logout membersihkan state privat.
- **Pemulihan password:** kode OTP enam karakter campuran huruf besar dan angka melalui Resend, diverifikasi server sebelum Supabase Auth mengganti password. Penerimaan 10–11 November membuktikan reset/login nyata, pencabutan akses sesi lama, batas lima percobaan, cooldown server, invalidasi setelah kirim ulang, dan penolakan kode bekas. Uji tunggu kedaluwarsa terisolasi dikecualikan oleh pengguna; rincian bukti ada pada [laporan M1 November 2026](docs/m1_account_foundation.md).
- **Dashboard:** akses cepat, menu Akademik/Tugas Akhir/Layanan, tampilan responsif, halaman layanan, serta keadaan kosong untuk data akademik yang belum terintegrasi.
- **Chatbot:** bantuan terpandu dan Ollama lokal. Identitas dijawab langsung dari profil tanpa dikirim ke model AI.
- **Izin Online:** alur pengajuan → BAP → PDF → dosen masih simulasi lokal. Backend Auth saat ini melayani mahasiswa; akun staf dummy hanya dipakai dalam pengujian.

## Menjalankan

Gunakan Flutter dengan Dart sesuai `pubspec.yaml` (`>=3.13.3 <4.0.0`). Android memerlukan Android SDK; iOS memerlukan macOS/Xcode; build Windows memerlukan Visual Studio dengan workload C++.

```sh
flutter doctor
flutter pub get
flutter devices
flutter run -d chrome
```

Target lain: `flutter run -d <device-id>` atau `flutter run`. Internet diperlukan untuk login dan menyimpan/membaca profil. Ollama tidak menggantikan backend profil.

Untuk menjalankan fondasi tanpa menyiapkan/mengunduh Ollama pada terminal PowerShell proyek:

```powershell
$env:CAMPUS_SKIP_AI = '1'
flutter run -d chrome
# Aktifkan kembali persiapan AI otomatis:
Remove-Item Env:CAMPUS_SKIP_AI
```

Pilihan ini hanya melewati persiapan AI pada proses terminal. Login/profil tetap membutuhkan Supabase; bantuan terpandu tersedia. AI yang sudah berjalan tetap dapat tersambung. Laporan dan batas penerimaan M1 November 2026: [docs/m1_account_foundation.md](docs/m1_account_foundation.md).

Jika Android Emulator menampilkan layar hitam setelah Quick Boot, lihat [panduan pemulihan emulator](docs/android_emulator.md). Script `tool/android/configure_emulator.ps1` mengatur cold boot pada AVD yang dipilih tanpa menghapus data.

URL dan **publishable key** proyek development sudah tersedia di `lib/core/config/supabase_config.dart`. Kunci klien tersebut boleh dibagikan; hak akses tetap dijaga server. **Secret/service-role key, password database, dan password pengguna tidak boleh masuk source code.**

Backend terpisah harus menerapkan seluruh migrasi, Edge Function (`login-with-nim`, `password-reset`, `private-file`), dan provisioning akun. Klien ini mengambil foto/dokumen lewat `private-file`; kebijakan Storage M1 menutup unduhan langsung. Ganti konfigurasi saat build:

```sh
flutter run -d chrome --dart-define=SUPABASE_URL=https://PROJECT.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
```

Pemulihan OTP diketik langsung di aplikasi; tidak memerlukan port web tetap atau deep link. Konfigurasi Redirect URLs hanya diperlukan bila menguji alur tautan Auth lama.

## Akun development

**Prismatine Dante Viergo**, panggilan **Dante**, NIM **20240801001**, terhubung ke akun Auth yang dibuat pemilik proyek. Gunakan password akun tersebut; tidak ada password demo pada aplikasi produksi. Identitas tetap **belum diverifikasi kampus**.

Angkatan, semester, kampus, status akademik, telepon, dan nilai tetap kosong sampai datanya tersedia. NIM tidak digunakan untuk menebak semester/tahun masuk. Akun baru memerlukan Auth user dan profil mahasiswa yang diprovisikan pengelola; clone repository tidak otomatis membuat akun.

Refresh/restart meminta login kembali. Sesi tidak disimpan permanen atau diperpanjang aktivitas, sedangkan profil tetap tersimpan di Supabase. Lihat [panduan profil mahasiswa](docs/student_profile.md) untuk skema, keamanan, provisioning, pemulihan password, dan pengujian.

## Struktur

```text
lib/
  main.dart                         # Startup, AuthGate, sesi, dan logout
  core/config/                      # Konfigurasi Supabase dan layar startup
  data/                             # Kontrak/model/repository Auth dan profil
  features/auth/                    # Login dan pemulihan password
  features/profile/                 # Biodata dan editor
  features/dashboard/               # Beranda serta menu
  features/chatbot/                  # Bantuan terpandu dan Ollama
  features/leave/                    # Alur Izin Online lokal
  shared/                           # Widget pixel dan avatar bersama
supabase/
  migrations/                       # Skema, RLS, sesi, dan bucket privat
  functions/login-with-nim/          # Autentikasi/pemetaan NIM di server
  tests/profile_access.sql          # Tes SQL dengan rollback
  seed_profile.sql                  # Template provisioning pengelola
test/support/                       # Fake Auth/HTTP, hanya untuk pengujian
```

## Pemeriksaan dan build

Langkah uji manual dan hasil yang diharapkan tersedia di [checklist profil](docs/profile_test_checklist.md).

```sh
flutter analyze
flutter test
dart format --output=none --set-exit-if-changed lib test
flutter build web
```

Tes mencakup Auth produksi dengan SDK asli dan HTTP terkendali, isolasi sesi, profil/foto, kegagalan simpan, chatbot, izin lokal, dan layout HP/tablet/desktop. Uji database dijalankan terpisah sesuai panduan profil. Tes buatan tidak menggantikan pengujian email/perangkat nyata.

Build Android: `flutter build apk --release`; hasil di `build/app/outputs/flutter-apk/app-release.apk`. Hasil web: `build/web/`. Folder platform tersedia bukan berarti seluruh platform telah diuji.

### Memeriksa salinan bersih dan serah terima M1 November 2026

Patch M1 November 2026 masih berada di working tree, belum di-commit/push. Clone dari HEAD lama belum memuat patch tersebut. Gunakan paket source terbaru yang dirujuk [laporan M1 November 2026](docs/m1_account_foundation.md), verifikasi `MANIFEST.sha256`, lalu ekstrak ke folder kosong. Jangan salin `.dart_tool`, hasil build, cache, `android/local.properties`, `.env`, atau model AI dari komputer pengembang.

Lingkungan verifikasi: Flutter 3.47.5 / Dart 3.13.4, Android SDK, dan JBR bawaan Android Studio. SDK/JDK tetap prasyarat host; ini bukan installer mesin kosong. Untuk pemeriksaan dependensi yang tidak memakai cache pengguna, tentukan dua folder cache kosong di luar folder ekstraksi:

```powershell
$env:CAMPUS_SKIP_AI = '1'
$env:PUB_CACHE = 'C:\path\to\empty-pub-cache'
$env:GRADLE_USER_HOME = 'C:\path\to\empty-gradle-cache'
flutter --no-version-check --suppress-analytics pub get --enforce-lockfile
dart --suppress-analytics analyze --fatal-infos
flutter --no-version-check --suppress-analytics test --no-pub
flutter --no-version-check --suppress-analytics build web --no-pub
flutter --no-version-check --suppress-analytics build apk --debug --no-pub
```

Ganti path contoh sesuai mesin. Variabel tersebut hanya berlaku pada proses terminal; jangan commit path lokal atau kredensial. Flutter membuat ulang konfigurasi platform yang diabaikan Git. APK debug bukan rilis produksi; pengujian HP/emulator dan pengujian waktu yang dikecualikan harus tetap dibedakan dari hasil build. Backend development sudah diprovisikan; salinan source tidak otomatis menerapkan migrasi/Edge Function ke proyek lain.

## Aset dan lisensi

Latar: `assets/images/pixel-campus.png`. Font lokal: [Press Start 2P](assets/fonts/PressStart2P-OFL.txt) dan [Space Mono](assets/fonts/SpaceMono-OFL.txt), juga didaftarkan dalam `LicenseRegistry`. Avatar bawaan digambar lokal memakai `CustomPainter`; tidak mengunduh gambar dari layanan lain.

## Smart Chatbot lokal

Smart Chatbot tersedia melalui Akses Cepat dan menu Layanan. Pesan singkat seperti `izin`, `ijin`, dan `surat izin` menawarkan akses Izin Online; `izin?` menyediakan pilihan pengajuan, status, atau pengertian/alur. [Izin Online](docs/izin_online.md) tersedia tepat setelah Konseling pada Akses Cepat serta submenu Layanan. Bantuan terpandu dan alur izin simulasi berjalan meskipun Ollama mati. AI lokal menggunakan Ollama khusus proyek tanpa API key.

Chatbot membedakan pertanyaan umum, data pribadi, aturan kampus, dan permintaan tindakan. Ada glosarium akademik umum, konteks percakapan, validasi respons, serta penyuntingan alasan/kronologi dengan tinjauan pengguna. Lihat [upgrade dan pengujian kualitas](docs/chatbot_quality.md).

Di **VS Code Windows**, buka folder `campus_app` atau file `campus_app.code-workspace`, lalu buat terminal baru **Campus App (AI otomatis)**. Cukup jalankan `flutter run -d chrome`, `flutter run`, atau `flutter run -d <id-perangkat>`: runtime/model Ollama yang belum ada dipasang otomatis, lalu server disiapkan sebelum Flutter. Tidak perlu mengetik `setup.ps1` di terminal proyek ini. Unduhan awal sekitar 2,5 GB membutuhkan internet; instalasi lengkap dipakai kembali, termasuk setelah cold boot. Terminal PowerShell di luar VS Code tetap perlu pemasangan pengait sekali. Lihat [pengaturan autostart proyek](docs/local_ai_autostart.md).

Chat mencoba menyambung otomatis saat dibuka. HP fisik harus berada di jaringan komputer AI; komputer dan Ollama tetap menyala. Alamat dapat diperbarui melalui ikon pengaturan chatbot jika Wi-Fi/IP berubah.

Lihat [panduan Smart Chatbot dan pemasangan Ollama](docs/smart_chatbot.md) untuk menjalankan server, batas kemampuan, struktur kode, dan pengujian.



Catatan integrasi: bagian akun demo pada panduan izin merupakan riwayat simulasi. Login aplikasi sekarang mengikuti Supabase. Instalasi Ollama otomatis bergantung pengait terminal proyek; perintah Flutter standar sendiri tidak memasang Ollama.
