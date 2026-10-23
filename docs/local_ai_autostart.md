# Ollama otomatis saat flutter run

Setelah pemasangan sekali, **buka terminal PowerShell baru**, masuk ke folder `campus_app`, lalu gunakan perintah biasa:

```powershell
flutter run -d chrome
# Atau biarkan Flutter memilih/menanyakan perangkat:
flutter run
# Atau gunakan ID dari flutter devices:
flutter run -d emulator-5554
```

Pengait yang dimuat profil PowerShell menyalakan Ollama proyek, menunggu API siap, memeriksa model `qwen2.5:1.5b`, dan memperbarui alamat koneksi sebelum meneruskan perintah ke Flutter SDK. Cold boot tidak menghapus profil atau model. Tidak perlu mengetik `start.ps1` setiap kali. Server yang sudah aktif dipakai kembali, bukan digandakan. Menutup Flutter tidak menghentikan server; `stop.ps1` tetap tersedia untuk menghentikannya.

## Pemasangan dan terminal lama

Pada komputer ini, pengait sudah dipasang untuk Windows PowerShell 5.1 dan PowerShell 7. Terminal yang terbuka sebelum pemasangan belum memuatnya: tutup terminal tersebut lalu buka terminal PowerShell baru. Tidak perlu restart komputer. Terminal PowerShell bawaan VS Code juga didukung jika memuat profil.

Untuk teman/clone baru:

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

Saat `flutter run`, terminal seharusnya menampilkan **[campus_app] Menyiapkan Ollama...**, lalu **Ollama campus_app siap...** sebelum Flutter berjalan. Jika persiapan gagal, Flutter belum diluncurkan dan pesan penyebab ditampilkan. Model yang belum ada perlu `setup.ps1`; konflik port dengan proses lain tidak ditangani dengan mematikan proses tersebut.

Server memakai IP LAN fisik saat tersedia, atau loopback bila tidak ada. Alamat ditulis ke aset sebelum Flutter membangun aplikasi. Emulator Android standar juga mencoba `10.0.2.2`; perangkat fisik memerlukan jaringan yang sama dan izin firewall LAN. Jika Windows menolak pembaruan aturan firewall saat IP berganti, terminal menampilkan perintah administrator yang diperlukan. Pilihan alamat manual pada pengaturan chatbot tetap diutamakan; kosongkan pilihan lama bila ingin kembali ke deteksi otomatis.

## Menonaktifkan dan menguji

```powershell
# Hapus hanya blok pengait dari profil, lalu buka terminal baru.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tool\local_ai\install_autostart.ps1 -Uninstall
# Hentikan server proyek bila masih hidup; model tidak dihapus.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tool\local_ai\stop.ps1
# Tes pengait secara terisolasi dengan SDK/server tiruan.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tool\local_ai\test_autostart.ps1
```

Pembagian kode: `flutter_hook.ps1` meneruskan perintah, `install_autostart.ps1` mengelola blok profil, `start.ps1` mengurus proses/kesiapan/model/alamat, dan `test_autostart.ps1` memeriksa perilaku pengait. Penjelasan berbahasa Indonesia ada pada blok kode terkait.

Mekanisme profil mengikuti [dokumentasi profil PowerShell Microsoft](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles).
