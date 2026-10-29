# Ollama otomatis saat flutter run

## Langsung dari clone/pull di VS Code Windows

Flutter SDK harus sudah tersedia di PATH. Buka **folder `campus_app` sebagai folder utama VS Code**, atau buka file `campus_app.code-workspace`. Jika VS Code menanyakan kepercayaan workspace, tinjau proyek lalu percayai hanya jika sumbernya dipercaya. Buat terminal baru dengan tombol **+**; profil default proyek bernama **Campus App (AI otomatis)**. Terminal lama perlu ditutup karena belum memuat konfigurasi baru.

Di terminal proyek ini, **tidak perlu mengetik `setup.ps1` atau memasang profil pengguna**. Jalankan perintah biasa:

```powershell
flutter run -d chrome
# Atau biarkan Flutter memilih/menanyakan perangkat:
flutter run
# Atau gunakan ID dari flutter devices:
flutter run -d emulator-5554
```

Terminal VS Code memuat `flutter_hook.ps1` langsung melalui `-File` dan mempertahankan terminal dengan `-NoExit`. Konfigurasi ini ikut Git; tidak menyimpan path komputer pembuat proyek. Membuka terminal saja belum mengunduh AI. Pada `flutter run`, pengait memasang runtime/model jika belum ada, menyalakan Ollama proyek, menunggu API siap, lalu memperbarui alamat sebelum meneruskan semua argumen ke Flutter SDK. Unduhan pertama membutuhkan internet dan sekitar 2,5 GB unduhan; tunggu sampai selesai. `-d` tetap memerlukan ID perangkat sesuai aturan Flutter.

Cold boot tidak menghapus instalasi. Server yang sudah aktif dipakai kembali, bukan digandakan. Menutup Flutter tidak menghentikan server; `stop.ps1` tetap tersedia untuk menghentikannya. Konfigurasi hanya memakai Windows PowerShell pada Windows; pemasangan portable ini belum mendukung host macOS/Linux.

Membuka folder induk seperti `Repositories` saja tidak memuat konfigurasi terminal anak `campus_app`. Buka workspace yang disediakan. `git pull` sendiri hanya mengambil file; instalasi baru dimulai ketika perintah dijalankan melalui terminal proyek. Mekanisme profil terminal mengikuti [dokumentasi VS Code](https://code.visualstudio.com/docs/terminal/profiles).

## PowerShell di luar terminal proyek VS Code

Pada komputer ini, pengait sudah dipasang untuk Windows PowerShell 5.1 dan PowerShell 7. Terminal yang terbuka sebelum pemasangan belum memuatnya: tutup terminal tersebut lalu buka terminal PowerShell baru. Tidak perlu restart komputer. Terminal PowerShell bawaan VS Code juga didukung jika memuat profil.

Jika ingin memakai PowerShell biasa di luar VS Code, pasang pengait sekali. Cara ini tetap tersedia sebagai alternatif:

```powershell
# Pasang runtime/model sekaligus pengait. Unduhan awal memerlukan internet.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tool\local_ai\setup.ps1
```

Jika runtime dan model sudah terpasang, atau folder proyek dipindahkan:

```powershell
# Pasang/perbarui pengait tanpa mengunduh runtime/model.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tool\local_ai\install_autostart.ps1
```

Pengait terpasang per pengguna Windows, bukan ikut tersimpan pada akun kampus. Installer menambahkan satu blok bertanda ke `profile.ps1` pada folder Documents/WindowsPowerShell dan Documents/PowerShell pengguna. Isi pribadi tetap dipertahankan dan profil lama dicadangkan sebelum perubahan. Pemasangan ulang tidak menggandakan blok. Pengait menolak menimpa fungsi/alias `flutter` pribadi yang berbeda; sesuaikan profil jika muncul peringatan tersebut.

## Ruang lingkup

- Berlaku untuk `flutter run ...` dari PowerShell yang memuat profil, dalam proyek ini atau subfoldernya. Argumen `-d`, target, dan `--dart-define` diteruskan; kontrol `r`, `R`, `q`, dan pemilihan perangkat tetap ditangani Flutter.
- `flutter test`, `flutter analyze`, `flutter devices`, `flutter run --help`, serta perintah di proyek lain langsung memakai SDK tanpa menyalakan AI.
- Ini pengait terminal, bukan kemampuan browser menjalankan program Windows. SDK, PATH, kebijakan eksekusi, layanan Windows, dan Windows Startup tidak diubah.
- Command Prompt/Git Bash, terminal `-NoProfile`, pemanggilan langsung `C:\flutter\bin\flutter.bat`, serta tombol Run/F5 IDE melewati pengait. Gunakan terminal PowerShell biasa atau jalankan `start.ps1` dahulu untuk jalur tersebut.
- APK yang dibuka langsung dari HP tidak dapat menyalakan Ollama pada komputer yang mati. HP/emulator tetap memerlukan akses ke alamat komputer AI; pengait menyiapkan server pada komputer pengembang, bukan memasang model ke perangkat.
- Jika profil diblokir kebijakan organisasi, pengait tidak dapat dimuat. Installer tidak melonggarkan kebijakan tersebut.

## Jika belum tersambung

Saat `flutter run`, terminal seharusnya menampilkan **[campus_app] Menyiapkan Ollama...**, lalu **Ollama campus_app siap...** sebelum Flutter berjalan. Jika persiapan gagal, Flutter belum diluncurkan dan pesan penyebab ditampilkan. Konflik port dengan proses lain tidak ditangani dengan mematikan proses tersebut.

Pengait kini menjalankan `start.ps1 -RequireModel -Repair`. Runtime yang hilang atau belum selesai diekstrak dipulihkan dari ZIP yang lolos SHA-256, atau diunduh kembali jika cache tidak tersedia. Model yang belum terdaftar di server proyek diunduh melalui Ollama. Instalasi lengkap digunakan kembali tanpa unduhan. Internet diperlukan hanya untuk unduhan awal/pemulihan; runtime sekitar 1,5 GB dan model sekitar 1 GB. Proses pertama dapat lama sesuai koneksi. Jangan menghapus folder `.local-ai` jika ingin tetap dapat bekerja offline.

Unduhan terputus disimpan untuk dilanjutkan pada percobaan berikutnya. Ekstraksi baru ditandai selesai setelah berhasil; arsip dengan checksum berbeda tidak dijalankan. Dua terminal yang menyiapkan AI bersamaan bergiliran, termasuk selama unduhan. `setup.ps1` memakai alur pemulihan yang sama, lalu memasang pengait profil. Setelah memperbarui kode pengait, buka terminal PowerShell baru agar fungsi versi lama tidak tertinggal di memori.

Server memakai IP LAN fisik saat tersedia, atau loopback bila tidak ada. Alamat ditulis ke aset sebelum Flutter membangun aplikasi. Emulator Android standar juga mencoba `10.0.2.2`; perangkat fisik memerlukan jaringan yang sama dan izin firewall LAN. Jika Windows menolak pembaruan aturan firewall saat IP berganti, terminal menampilkan perintah administrator yang diperlukan. Pilihan alamat manual pada pengaturan chatbot tetap diutamakan; kosongkan pilihan lama bila ingin kembali ke deteksi otomatis.

## Menonaktifkan dan menguji

```powershell
# Hapus hanya blok pengait dari profil, lalu buka terminal baru.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tool\local_ai\install_autostart.ps1 -Uninstall
# Hentikan server proyek bila masih hidup; model tidak dihapus.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tool\local_ai\stop.ps1
# Tes pengait secara terisolasi dengan SDK/server tiruan.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tool\local_ai\test_autostart.ps1
# Tes pemulihan instalasi dengan unduhan/ekstraksi tiruan, tanpa internet.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tool\local_ai\test_recovery.ps1
```

Pembagian kode: `flutter_hook.ps1` meneruskan perintah, `install_autostart.ps1` mengelola blok profil, `start.ps1` mengurus proses/kesiapan/model/alamat, `runtime.ps1` memulihkan runtime, dan kedua skrip tes memeriksa pengait serta pemulihan. Penjelasan berbahasa Indonesia ada pada blok kode terkait.

Mekanisme profil mengikuti [dokumentasi profil PowerShell Microsoft](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles).
