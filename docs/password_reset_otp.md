# Pemulihan password dengan OTP — Campus App

Pembaruan 3 November 2026. Form Flutter, migrasi database, dan Edge Function `password-reset` sudah tersedia pada proyek development `campus-app`. **Satu pengiriman OTP nyata melalui endpoint aplikasi sudah berstatus delivered di Resend.** Format enam karakter campuran huruf besar dan angka sesuai. Password pengguna tidak diubah; reset dan login ulang nyata melalui aplikasi masih perlu diuji.

## Alur mahasiswa

1. Buka **Lupa password**, isi email akun login/pemulihan Supabase Auth.
2. Aplikasi memeriksa format email. Server memeriksa akun terkonfirmasi, profil aktif, dan kelayakan pemulihan.
3. Respons dibuat umum untuk alamat terdaftar maupun tidak terdaftar. Ini mencegah orang mencoba daftar email untuk menemukan akun mahasiswa.
4. Akun yang memenuhi syarat menerima kode enam karakter, misalnya `AB3C4D`, melalui Resend. Kode selalu mengandung huruf besar **dan** angka. Huruf I/O dan angka 0/1 tidak digunakan agar mudah dibaca.
5. Mahasiswa mengetik kode di aplikasi, password baru 12–256 karakter, dan konfirmasinya. Huruf kecil pada input kode diterima lalu diubah menjadi huruf besar.
6. Setelah sukses, mahasiswa kembali login menggunakan password baru. Form tidak memberikan sesi login otomatis.

Email tujuan berasal dari **Supabase Auth**, bukan email kampus tampilan atau kolom kontak pribadi yang diedit pada Biodata. Pada akun pengembangan yang telah disiapkan pemilik proyek, email Auth adalah email pribadi asli yang dipakai saat membuat akun. Perubahan kontak Biodata tidak memindahkan tujuan pemulihan.

OTP diketik langsung dalam aplikasi, sehingga alur ini tidak bergantung pada port web tetap, Redirect URLs, atau deep link perangkat. Penanganan tautan recovery lama tetap ada untuk kompatibilitas, tetapi form Lupa password sekarang menggunakan OTP.

## Aktivasi Resend oleh pemilik proyek

### 1. Siapkan pengirim

- Buat akun Resend. Tambah domain atau subdomain yang kamu miliki dan dapat kamu atur DNS-nya.
- Pasang record DNS yang diberikan Resend, lalu tunggu verifikasi berhasil. Jangan menggunakan domain universitas sebagai pengirim tanpa akses dan izin pengelolaan domain tersebut.
- Pilih pengirim, misalnya `Campus App <noreply@auth.domain-milikmu.id>`. Ini contoh, bukan alamat yang sudah dikonfigurasi.
- Buat API key Resend dengan izin pengiriman dan cakupan domain yang diperlukan. Tidak perlu memberikan akses pengelolaan penuh.

Resend menjelaskan verifikasi domain pada [panduan domain resmi](https://resend.com/docs/dashboard/domains/introduction). Endpoint pengiriman yang digunakan adalah [Send Email](https://resend.com/docs/api-reference/emails/send-email). Memiliki akun Gmail sebagai penerima tidak otomatis memberi domain pengirim untuk Resend.

### 2. Simpan tiga secrets di Supabase

Buka proyek `campus-app` → **Edge Functions → Secrets**, kemudian tambahkan:

| Nama | Isi |
|---|---|
| `RESEND_API_KEY` | API key pengiriman dari Resend |
| `RESET_EMAIL_FROM` | Alamat pengirim terverifikasi, boleh berbentuk `Campus App <alamat@domain-milikmu.id>` |
| `RESET_OTP_SECRET` | Rahasia acak kuat untuk HMAC; buat dari setidaknya 32 byte acak |

Secrets hanya disimpan di server. Jangan memasukkannya ke Flutter, `--dart-define`, Git, screenshot, atau chat. Kunci bawaan `SUPABASE_URL`, `SUPABASE_ANON_KEY`, dan `SUPABASE_SERVICE_ROLE_KEY` disediakan lingkungan Edge Function; jangan menyalin service-role ke klien.

Contoh membuat rahasia HMAC secara lokal di PowerShell; hasil hanya disalin ke dashboard Secrets:

```powershell
$otpSecretBytes = New-Object byte[] 32
$otpRandom = [System.Security.Cryptography.RandomNumberGenerator]::Create()
try {
  $otpRandom.GetBytes($otpSecretBytes)
  [Convert]::ToBase64String($otpSecretBytes)
} finally {
  $otpRandom.Dispose()
  [Array]::Clear($otpSecretBytes, 0, $otpSecretBytes.Length)
}
```

Mengganti `RESET_OTP_SECRET` membuat kode yang masih beredar tidak dapat diverifikasi; pengguna harus meminta kode baru. Jangan melakukan rotasi ketika tidak diperlukan. Setelah secrets tersedia, lakukan pengujian manual di bawah. Pada proyek terpisah milik tim, migrasi dan Edge Function juga harus diterapkan; `flutter pub get` tidak membuat backend.

### 3. Konfigurasi Supabase Auth

Atur kebijakan password sesuai kebutuhan proyek. Kode menggunakan sesi recovery internal agar penggantian tetap melewati kebijakan Auth; tidak langsung menulis password ke database. Advisory pada 2 November masih menunjukkan **Leaked Password Protection Disabled**. Aktifkan jika tersedia pada paket proyek; validasi panjang aplikasi tidak menggantikan pemeriksaan kebocoran password. [Dokumentasi kebijakan password](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection).

SMTP/template recovery bawaan Supabase tidak digunakan untuk email OTP kustom ini. Link recovery internal dari Supabase tidak dikirim lewat email dan tidak dikembalikan ke Flutter. Akun dengan faktor MFA terverifikasi tidak menerima OTP dari jalur ini; gunakan proses pemulihan MFA yang ditetapkan pengelola, bukan menonaktifkan MFA melalui form email.

## Batas keamanan dan kegagalan

| Aturan | Perilaku |
|---|---|
| Masa berlaku | 10 menit menurut waktu database |
| Pemakaian | Sekali pakai; konsumsi memakai kunci baris database |
| Percobaan kode | Maksimal 5 pada satu challenge |
| Kirim ulang | Minimal 60 detik, ditegakkan server dan dibantu penghitung UI |
| Batas per email | 5 permintaan kode dan 10 konfirmasi per 15 menit |
| Batas IP | 40 permintaan per 15 menit; tidak menggantikan pembatas email |
| Kode baru | Menggantikan kode lama |
| Penyimpanan | HMAC-SHA-256 email/kode; tidak menyimpan OTP asli atau password baru |
| Akses database | Tabel private dengan RLS; RPC hanya untuk service-role |
| Resend gagal | Challenge pengiriman itu dibatalkan; kegagalan lama tidak membatalkan challenge baru |
| Konfigurasi kosong | HTTP 503, pesan layanan belum siap untuk semua alamat |
| Respons request 200 | Permintaan diterima; **bukan bukti email sudah sampai** |
| Password ditolak Auth | Kode sudah dikonsumsi; minta kode baru sebelum mengulang |
| Timeout saat konfirmasi | Hasil mungkin belum diketahui; coba login dengan password baru, lalu minta kode baru bila perlu |

Email berjalan sebagai tugas latar Edge Runtime. Resend dibatasi timeout 15 detik; body respons provider tidak dicatat. Log aplikasi hanya mencatat jenis kegagalan statis, tanpa alamat, OTP, password, token, atau detail database.

Setelah pemulihan, sesi aplikasi dicabut melalui `private.app_sessions`; kebijakan RLS menolak sesi yang dicabut. Refresh session Auth juga dicabut melalui global sign-out. Access token JWT Supabase dapat tetap berlaku sampai kedaluwarsa untuk layanan lain yang hanya memeriksa JWT; jangan menganggap global sign-out menghapus semua JWT seketika. [Semantik sign-out Supabase](https://supabase.com/docs/reference/javascript/auth-admin-signout).

## Struktur implementasi

| File | Tanggung jawab |
|---|---|
| `lib/data/password_reset_validation.dart` | Normalisasi email/kode dan validasi password |
| `lib/data/supabase_auth_service.dart` | Memanggil endpoint request/confirm dan menerjemahkan error |
| `lib/features/auth/forgot_password_page.dart` | Form dua tahap, kirim ulang, konfirmasi, dan kembali login |
| `supabase/functions/password-reset/index.ts` | Membaca secrets server dan menjalankan handler |
| `supabase/functions/password-reset/handler.ts` | Validasi HTTP, pembatasan, penerbitan/verifikasi kode |
| `supabase/functions/password-reset/otp.ts` | Acak kriptografis dan HMAC |
| `supabase/functions/password-reset/services.ts` | Adapter Supabase Auth, RPC database, dan Resend |
| `supabase/migrations/20261102065453_password_reset_otp.sql` | Tabel private dan empat RPC pemulihan |
| `supabase/tests/password_reset.sql` | Uji akses dan siklus OTP; transaksi diakhiri rollback |

`verify_jwt=false` hanya untuk endpoint pemulihan sebelum login. Aksi mengganti password tetap memerlukan OTP sah; request kode dibatasi dan tidak mengungkap keberadaan akun.

## Hasil otomatis pada 2 November 2026

- Seluruh **218 tes Flutter lulus**, termasuk navigasi bawah kembali menggulir dashboard, launcher Chatbot, dan form OTP pada layar sempit.
- `flutter analyze --no-pub`: tidak ada masalah.
- **15 tes Deno lulus**; SDK Supabase asli diuji dengan transport HTTP tiruan untuk identitas recovery, kebijakan password, logout, dan kegagalan Resend. `deno check` dan `deno lint` bersih untuk fungsi baru.
- Tes SQL pada proyek development lulus dalam transaksi rollback: hak akses, cooldown, kode salah, replay, batas percobaan, kirim ulang, pembatalan, expiry, perubahan email, akun nonaktif, MFA, serta pencabutan sesi. Akun fixture tidak dipertahankan.
- Build web dan APK debug berhasil. Android memakai JBR 25.0.3 Android Studio dan cache proyek terpisah setelah kendala lock/JDK 26; APK OTP belum diuji interaktif. Rincian dicatat di `project_progress.md`.
- Endpoint cloud versi 1 berstatus ACTIVE. Probe tanpa email nyata: OPTIONS 200, format email salah 400, konfigurasi Resend kosong 503 sesuai rancangan.
- Belum mengirim email nyata atau mengganti password akun pengguna. Tes HTTP tiruan tidak menggantikan pemeriksaan pengiriman dan login nyata.

Perintah pengujian ulang ketika source berubah:

```powershell
flutter analyze --no-pub
flutter test --no-pub
deno check supabase/functions/password-reset/index.ts
deno lint supabase/functions/password-reset
deno test supabase/functions/password-reset/handler_test.ts supabase/functions/password-reset/services_test.ts
flutter build web --no-pub --no-web-resources-cdn
```

## Verifikasi setelah secrets diisi — 3 November 2026

- `password-reset` versi 2 ACTIVE. Tiga nama secrets terlihat pada dashboard pengguna; nilai rahasia tidak disalin ke repository atau laporan.
- Satu permintaan OTP nyata sekitar 11:04 WIB mendapat HTTP 200 dengan pesan umum. Email yang terkait tercatat **delivered**, dikirim pada 11:04:51 WIB. Pemeriksaan menggunakan connector Resend dengan skill `resend-cli` yang tersedia.
- Isi email diperiksa tanpa menampilkan/menyimpan kode: enam karakter huruf besar dan angka, mengandung keduanya, serta informasi masa berlaku 10 menit dan sekali pakai.
- **218 tes Flutter lulus**, analisis bersih; Deno check/lint bersih dan **15 tes Deno lulus**. Tes SQL OTP pada Supabase kembali lulus dengan rollback; fixture tidak dipertahankan.
- Bukti lokal: `build/otp-nov3-remote-probe.json`, `build/otp-nov3-analyze.log`, dan `build/otp-nov3-flutter-test.log`. Folder build tidak ikut Git dan bisa terhapus oleh `flutter clean`.
- Delivered membuktikan server email penerima menerima pesan, bukan posisi inbox/spam, pembacaan pesan, atau keberhasilan reset. Password nyata tidak diubah; uji UI, reset, login ulang, dan pencabutan sesi nyata masih menunggu checklist berikut. Tidak ada build atau uji emulator interaktif baru pada sesi ini.

## Checklist manual setelah secrets diisi

Gunakan akun pengembangan sendiri, bukan akun mahasiswa produksi. Jangan bagikan kode atau password saat melaporkan hasil.

1. Masukkan email format salah: aplikasi menolak sebelum request.
2. Ajukan kode ke email Auth sendiri: pesan umum tampil, kotak kode/password muncul, inbox atau spam menerima kode enam karakter campuran.
3. Coba alamat tidak terdaftar yang kamu kendalikan: pesan permintaan sama dan tidak ada email reset dikirim. Jangan menguji alamat orang lain.
4. Coba kode salah: password tidak berubah. Setelah lima percobaan, challenge tidak dapat dipakai lagi.
5. Tunggu 60 detik, kirim ulang: kode lama ditolak dan kode terbaru diterima. Periksa juga email yang terlambat agar tidak memakai kode lama.
6. Biarkan kode melewati 10 menit: ditolak, minta kode baru.
7. Masukkan password kurang dari 12 karakter atau konfirmasi berbeda: form menolak. Password yang melanggar kebijakan Auth juga tidak boleh dilaporkan sukses.
8. Dengan kode terbaru, ubah password: kembali login; password baru berhasil dan password lama gagal.
9. Coba pakai ulang kode sukses: ditolak. Jendela/perangkat yang masih memakai sesi lama harus kehilangan akses data privat.
10. Uji jaringan terputus ketika request dan confirm: tampil pesan jelas, tombol pulih, tidak ada klaim sukses palsu.
11. Ulangi pada Chrome dan emulator/HP: keyboard, gulir, tombol kirim ulang, tombol kembali, serta layout kecil tetap dapat digunakan. Tidak perlu membuka link email.
12. Periksa log Resend untuk status delivery bila email belum masuk. Jangan menganggap respons 200 dari aplikasi sebagai laporan delivery.

Catat perangkat, langkah, hasil, dan waktu pengujian tanpa rahasia. Delivery satu email ke akun pengembangan telah diverifikasi; uji akun kedua, ketahanan jaringan, reset dan login ulang lintas perangkat tetap menjadi syarat penerimaan berikutnya.
