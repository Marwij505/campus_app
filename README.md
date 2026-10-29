# Campus App — SIAKAD Fasilkom

Aplikasi prototipe Sistem Informasi Akademik (SIAKAD) Fasilkom berbasis Flutter. Aplikasi menampilkan alur login dan dashboard mahasiswa dengan gaya retro/pixel, font lokal, serta animasi transisi.

Saat ini aplikasi menggunakan akun dan data contoh di dalam kode. Belum ada integrasi backend, database, atau layanan email.

## Fitur

- **Login demo:** validasi NIM/NIP dan password, tampil/sembunyikan password, indikator loading, pesan kesalahan, dan opsi ingat sesi.
- **Pemulihan password demo:** validasi email dan simulasi permintaan reset.
- **Dashboard mahasiswa:** profil, IPK, masa studi, SKS lulus, persentase nilai A, jadwal kuliah, dan grafik ringkasan akademik.
- **Informasi kampus:** contoh pengumuman, berita, jadwal konseling, serta daftar pedoman dan panduan.
- **Navigasi:** drawer, akses cepat, navigasi ke bagian dashboard, dan logout.
- **Tampilan:** tema Material 3 dengan komponen pixel, font Press Start 2P dan Space Mono, serta animasi yang mengikuti pengaturan pengurangan animasi perangkat.

## Teknologi

| Komponen | Implementasi |
| --- | --- |
| Framework | Flutter |
| Bahasa | Dart, constraint SDK `^3.13.3` |
| State UI | `StatefulWidget` dan `setState` |
| Grafik akademik | `CustomPainter` |
| Pengujian | `flutter_test` |
| Lint | `flutter_lints` |

Folder platform tersedia untuk Android, iOS, web, Windows, macOS, dan Linux. Build masing-masing platform memerlukan toolchain yang sesuai; keberadaan folder tersebut bukan jaminan seluruh platform telah diuji.

## Persiapan

1. Pasang Flutter SDK dengan Dart yang memenuhi constraint pada `pubspec.yaml` (`>=3.13.3 <4.0.0`).
2. Siapkan perangkat, emulator, atau browser untuk target yang ingin dijalankan. Untuk Android, siapkan Android SDK dan emulator/perangkat Android; untuk iOS, gunakan macOS dengan Xcode.
3. Dari direktori utama proyek, periksa lingkungan dan unduh dependensi:

   ```sh
   flutter doctor
   flutter pub get
   ```

Tidak diperlukan file `.env`, API key, maupun konfigurasi database untuk menjalankan demo.

## Menjalankan Aplikasi

Lihat perangkat yang tersedia, lalu jalankan aplikasi:

```sh
flutter devices
flutter run
```

Untuk memilih perangkat tertentu, gunakan `flutter run -d <device-id>` dengan ID dari `flutter devices`.

Contoh menjalankan versi web melalui Chrome:

```sh
flutter run -d chrome
```

### Akun Demo

| NIM/kode akun | Password | Peran |
| --- | --- | --- |
| `20240801001` | `123456` | Mahasiswa |
| `20240801002` | `123456` | Mahasiswa |
| `BAP001` | `123456` | Pemeriksa izin BAP |
| `DOS001` | `123456` | Dosen penerima hasil |
| `DOS002` | `123456` | Dosen penerima hasil |

Akun mahasiswa menampilkan keadaan tanpa data akademik. Akun BAP/dosen membuka kotak masuk Izin Online. Semua kredensial khusus simulasi. Kedua dosen uji sengaja bernama sama; penerima ditentukan oleh kode unik. Lihat [panduan mencoba alur izin](docs/izin_online.md).

### Batasan Demo

- Sesi berada di memori, berlaku 30 menit, dan aplikasi keluar otomatis ketika sesi berakhir. Refresh/restart menghapus sesi dan data simulasi.
- Form lupa password tidak mengirim email dan tidak mengubah password.
- Sumber akademik belum terhubung. Profil, statistik, jadwal, dan pengumuman menampilkan keadaan belum tersedia.
- Halaman biodata, KRS, nilai/presensi, tagihan, serta konseling belum berisi data layanan kampus.
- Izin Online menjalankan pengajuan → pemeriksaan BAP → PDF → kotak masuk dosen dalam satu proses aplikasi. Pengajuan bertahan saat berganti akun, tetapi belum tersimpan di server atau terkirim antarperangkat.
- Navigasi bawah mengarahkan pengguna ke bagian-bagian dashboard; belum semuanya memiliki halaman tersendiri.

## Struktur Proyek

```text
lib/
├── main.dart                       # Entry point, tema, dan perpindahan login/dashboard
├── core/                           # Tema, animasi, navigasi, dan elemen visual
├── data/
│   ├── auth_service.dart           # Layanan autentikasi demo yang dipakai aplikasi
│   └── demo_data.dart              # Model profil dan data akademik contoh
├── features/
│   ├── auth/
│   │   ├── login_page.dart         # Form login
│   │   ├── forgot_password_page.dart
│   │   └── services/               # Kontrak/implementasi demo terpisah
│   └── dashboard/
│       ├── dashboard_page.dart     # Dashboard mahasiswa
│       └── academic_charts.dart    # Grafik akademik
└── shared/
    └── pixel_widgets.dart          # Komponen UI bersama
assets/
├── images/                         # Latar kampus pixel
└── fonts/                          # Font lokal dan berkas lisensinya
test/
├── auth_service_test.dart          # Login, status sesi, dan logout
└── widget_test.dart                # Alur autentikasi dan layout form
```

Alur aplikasi dimulai dari `CampusApp` → `AuthGate` → `LoginPage`. Login berhasil mengganti halaman menjadi `DashboardPage`, sedangkan logout mengembalikannya ke login.

Layanan yang digunakan alur tersebut berada di `lib/data/auth_service.dart`. Berkas `lib/features/auth/services/auth_service.dart` berisi kontrak dan implementasi demo lain yang belum terhubung ke alur utama. Saat mengintegrasikan backend, perhatikan layanan yang benar-benar diimpor oleh halaman.

## Pemeriksaan Kode dan Pengujian

```sh
flutter analyze
flutter test
```

Tes yang tersedia mencakup penolakan kredensial salah, login berhasil, penghapusan sesi, logout, validasi email, simulasi reset password, layout form pada beberapa ukuran layar, dan kemampuan menggulir form saat keyboard terbuka.

Untuk memeriksa format kode tanpa mengubah berkas:

```sh
dart format --output=none --set-exit-if-changed lib test
```

## Build

Build APK Android:

```sh
flutter build apk --release
```

Hasil build: `build/app/outputs/flutter-apk/app-release.apk`.

Build web:

```sh
flutter build web
```

Hasil build: direktori `build/web/`.

## Aset dan Lisensi Font

Gambar latar berada di `assets/images/pixel-campus.png`. Font dimuat dari aset lokal sehingga penggunaannya tidak membutuhkan koneksi internet. Teks lisensi font tersedia di:

- [Press Start 2P](assets/fonts/PressStart2P-OFL.txt)
- [Space Mono](assets/fonts/SpaceMono-OFL.txt)

Kedua lisensi juga didaftarkan melalui `LicenseRegistry` saat aplikasi dimulai.


## Smart Chatbot lokal

Smart Chatbot tersedia melalui Akses Cepat dan menu Layanan. Pesan singkat seperti `izin`, `ijin`, dan `surat izin` menawarkan akses Izin Online; `izin?` menyediakan pilihan pengajuan, status, atau pengertian/alur. [Izin Online](docs/izin_online.md) tersedia tepat setelah Konseling pada Akses Cepat serta submenu Layanan. Bantuan terpandu dan alur izin simulasi berjalan meskipun Ollama mati. AI lokal menggunakan Ollama khusus proyek tanpa API key.

Chatbot membedakan pertanyaan umum, data pribadi, aturan kampus, dan permintaan tindakan. Ada glosarium akademik umum, konteks percakapan, validasi respons, serta penyuntingan alasan/kronologi dengan tinjauan pengguna. Lihat [upgrade dan pengujian kualitas](docs/chatbot_quality.md).

Di **VS Code Windows**, buka folder `campus_app` atau file `campus_app.code-workspace`, lalu buat terminal baru **Campus App (AI otomatis)**. Cukup jalankan `flutter run -d chrome`, `flutter run`, atau `flutter run -d <id-perangkat>`: runtime/model Ollama yang belum ada dipasang otomatis, lalu server disiapkan sebelum Flutter. Tidak perlu mengetik `setup.ps1` di terminal proyek ini. Unduhan awal sekitar 2,5 GB membutuhkan internet; instalasi lengkap dipakai kembali, termasuk setelah cold boot. Terminal PowerShell di luar VS Code tetap perlu pemasangan pengait sekali. Lihat [pengaturan autostart proyek](docs/local_ai_autostart.md).

Chat mencoba menyambung otomatis saat dibuka. HP fisik harus berada di jaringan komputer AI; komputer dan Ollama tetap menyala. Alamat dapat diperbarui melalui ikon pengaturan chatbot jika Wi-Fi/IP berubah.

Lihat [panduan Smart Chatbot dan pemasangan Ollama](docs/smart_chatbot.md) untuk menjalankan server, batas kemampuan, struktur kode, dan pengujian.
