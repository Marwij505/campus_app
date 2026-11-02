# Menjalankan Campus App pada Android Emulator

## Perbaikan layar hitam pada Medium_Phone

Pengujian 2 November 2026 pada AVD `Medium_Phone` (image Android 37.2, x86_64) menunjukkan:

- APK berhasil dibangun dan dijalankan sebagai `com.example.campus_app`.
- Saat emulator dibuka dengan alur Quick Boot yang lama, layar aplikasi hitam walaupun proses Flutter dan inisialisasi Supabase berjalan.
- APK yang sama, dengan GPU host dan renderer Flutter bawaan, menampilkan login dan halaman lupa password setelah emulator di-cold-boot.
- Percobaan mematikan Impeller tidak menyelesaikan masalah pada kondisi boot yang bermasalah.

Hasil ini mengarah pada keadaan emulator yang dipulihkan saat Quick Boot. Perbaikan memakai **cold boot**, tanpa menghapus data emulator atau mematikan renderer aplikasi. Ini bukan jaminan bahwa setiap layar hitam memiliki penyebab yang sama.

Setelah pengaturan disimpan, emulator dibuka kembali dengan `emulator -avd Medium_Phone` tanpa flag pemulihan khusus. `flutter run -d emulator-5554 --no-pub` melalui pengait proyek berhasil menyalakan Ollama, membangun/memasang APK, menampilkan login, dan membuka keyboard. Enam tes pada `test/app_startup_test.dart` dan `test/widget_test.dart` lulus. Pengujian ini memverifikasi startup dan interaksi awal; login akun nyata di emulator belum diuji ulang.

Mode debug masih mencatat beberapa frame terlewat saat startup. Keberhasilan render tidak berarti seluruh kinerja aplikasi sudah diprofilkan. Cold boot, kompilasi awal, dan banyak aplikasi lain yang memakai RAM dapat membuat pembukaan pertama lebih lambat.

## Pengaturan sekali pada komputer yang mengalami masalah

Tutup Android Emulator. Dari direktori proyek, jalankan:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tool\android\configure_emulator.ps1 -AvdName Medium_Phone
```

Ganti `Medium_Phone` dengan nama AVD di Android Studio → Device Manager. Script menolak berjalan jika masih ada proses emulator. Script hanya mengubah tiga pengaturan boot pada AVD yang dipilih, membuat cadangan `config.ini.campus-backup-*`, dan tidak menghapus snapshot maupun data pengguna. Mengulang perintah aman ketika pengaturan sudah sesuai.

Buka emulator seperti biasa. Tunggu Android selesai boot, lalu jalankan:

```powershell
flutter devices
flutter run -d emulator-5554
```

Gunakan ID yang tercantum pada `flutter devices`. Jika hanya ada satu target yang sesuai, `flutter run` juga bisa digunakan. Terminal **Campus App (AI otomatis)** tetap menyiapkan Ollama melalui pengait proyek. Pengaturan emulator ini berada pada komputer masing-masing; Git tidak membagikannya ke anggota tim.

Alternatif melalui Android Studio: Edit AVD → pengaturan lanjutan → Boot option → **Cold boot**. Lokasi/nama pengaturan dapat berbeda antarversi. Boot pertama bisa lebih lambat karena Android tidak memulihkan snapshot.

## Pemeriksaan dan pemulihan

1. Pastikan login terlihat, kolom NIM/password dapat disentuh, dan keyboard dapat ditutup.
2. Buka Lupa password, lalu kembali ke login. Tidak perlu mengirim email untuk tes tampilan.
3. Tutup dan buka ulang emulator; jalankan aplikasi lagi untuk memeriksa bahwa perbaikan bertahan.
4. Jika ingin kembali ke konfigurasi lama, tutup emulator lalu salin cadangan `config.ini.campus-backup-*` ke `config.ini` pada folder AVD yang sama.

Jika masalah tetap muncul pada perangkat lain, kumpulkan log terbaru dan periksa GPU/system image emulator. Jangan langsung menghapus data atau mengubah autentikasi Supabase. Peringatan Java/Gradle bukan bukti kegagalan build jika terminal sudah menampilkan `Built ... app-debug.apk`.

Identitas Android harus konsisten: `namespace` dan `applicationId` di `android/app/build.gradle.kts` memakai `com.example.campus_app`; package `MainActivity.kt` sama, dan manifest menunjuk `.MainActivity`. Setelah mengubah identitas native, hentikan run lama lalu build ulang; hot reload tidak mengganti konfigurasi Android.
