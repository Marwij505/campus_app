# Profil mahasiswa dan Supabase

## Ruang lingkup

Profil memakai Supabase Auth, Postgres, dan Storage privat. Halaman mengikuti susunan referensi: ringkasan biru/foto di kiri, tujuh tab, kartu isian terang, dan tombol Edit atau Simpan/Batal di atas. Header merah dan tipografi SIAKAD tetap digunakan. Pada layar kecil, panel disusun ke bawah; pembesaran teks tidak memaksa dua kolom.

Tujuh tab tersedia: **Biodata, Pendidikan, Keluarga, Pekerjaan, Disabilitas, Riwayat Keuangan, Berkas**. Data pribadi screenshot tidak disalin menjadi data Dante. Data akademik dan keuangan yang belum diterbitkan tetap kosong.

## Data awal

| Field | Nilai |
| --- | --- |
| Nama resmi | Prismatine Dante Viergo |
| Panggilan | Dante |
| NIM | 20240801001, teks |
| Universitas | Universitas Esa Unggul |
| Fakultas / prodi | FASILKOM / Teknik Informatika |
| Peran / avatar | student / male |
| Verifikasi | unverified, belum disahkan kampus |

Auth user dibuat pemilik proyek melalui Supabase Authentication. Password tidak disimpan dalam source code, seed, dokumentasi, atau profil. Data yang belum diberikan tetap NULL; NIM tidak digunakan untuk menebak angkatan/semester dan varian avatar tidak digunakan untuk menyimpulkan jenis kelamin.

## Arsitektur dan izin

`auth.users.id` → `profiles.id` → `students.user_id` memakai UUID yang sama. NIM unik berada di `students`; pemetaan NIM ke email hanya dilakukan server.

| Penyimpanan | Isi |
| --- | --- |
| `public.profiles` | Nama resmi, panggilan, peran, varian/path foto, telepon, aktif/nonaktif, verifikasi, timestamps |
| `public.students` | NIM, universitas, fakultas, prodi, kampus, angkatan, semester, status akademik |
| `private.app_sessions` | UUID sesi Auth, pemilik, awal, tenggat, pencabutan |
| `private.login_limits` | Hash identitas/IP dan penghitung percobaan; tidak menyimpan password |
| Storage `student-avatars` | Bucket privat, JPG/PNG, maksimal 2 MiB |

RLS aktif pada seluruh tabel. Tabel private sengaja tidak memiliki kebijakan pengguna: akses melalui fungsi internal berizin. Profil hanya dapat dibaca pemilik dengan sesi aplikasi aktif. Hak UPDATE hanya untuk `preferred_name`, `phone`, `avatar_variant`, dan `avatar_path`. Nama resmi, UUID, NIM, peran, fakultas/prodi, status aktif, serta verifikasi tidak dapat diubah mahasiswa.

RPC administratif hanya dapat dieksekusi service_role. Fungsi SECURITY DEFINER memakai search_path kosong. RPC sesi publik memakai wrapper SECURITY INVOKER yang memanggil fungsi private; pengguna hanya dapat memeriksa/mencabut sesi JWT sendiri. Kunci service-role tetap di lingkungan Edge Function, tidak di Flutter.

## Login dan sesi

1. Flutter mengirim NIM/password melalui HTTPS ke `login-with-nim`.
2. Edge Function membatasi percobaan per NIM (8/15 menit) dan IP (40/15 menit), mencari email di server, lalu memverifikasi password melalui Supabase Auth.
3. Server mencatat tenggat **waktu pembuatan sesi Auth + 30 menit**. Pendaftaran ulang sesi yang sama tidak memperpanjangnya.
4. Flutter memperoleh sesi lalu membaca profil dengan JWT pengguna.
5. Stopwatch/timer mengatur UI. RLS database dan Storage tetap menolak akses setelah tenggat, meskipun JWT belum kedaluwarsa.

Tidak ada ingat sesi. Refresh/restart meminta login ulang. Logout segera menghapus profil, chatbot/draf, data izin lokal pengguna nyata, dan cache foto, kemudian mencoba mencabut sesi server. Saat jaringan putus, tenggat server tetap berlaku dan token lokal dibuang. Respons login/pemeriksaan lama tidak boleh menghidupkan sesi yang dibatalkan.

Durasi JWT Supabase dapat berbeda dari 30 menit; JWT saja tidak cukup mengakses profil. Password recovery adalah sesi Auth khusus yang tidak didaftarkan sebagai sesi data mahasiswa. Sesi dapat diperpendek berdasarkan server, tetapi tidak diperpanjang aktivitas.

## Formulir tujuh bagian

| Bagian | Isi dan perilaku |
| --- | --- |
| Biodata | NIK, paspor, jenis kelamin, agama, golongan darah, tempat/tanggal lahir, alamat lengkap, WhatsApp, email pribadi, status pernikahan, kewarganegaraan |
| Pendidikan | Nama/alamat/telepon sekolah, nilai rata-rata, NISN, nomor ijazah |
| Keluarga | Nama/pendidikan/pekerjaan orang tua, alamat lengkap, telepon, kontak darurat |
| Pekerjaan | Status kerja, pekerjaan, perusahaan, jenis instansi, alamat, provinsi/kota, telepon, jabatan, penanggung dana |
| Disabilitas | Ya/Tidak/Tidak ingin menyampaikan; rincian dan kebutuhan akomodasi hanya saat Ya |
| Riwayat Keuangan | Baca tagihan terbitan kampus, kelompok periode/kategori, subtotal, jumlah dibayar/sisa, tanggal, dan tautan menu Pembayaran |
| Berkas | Unggah, ganti, unduh, dan hapus KTP, KK, ijazah, surat pernyataan pembayaran, paspor |

Lima formulir pribadi memakai tabel `student_biodata`, `student_education`, `student_family`, `student_employment`, dan `student_accessibility`. Kolom menggunakan UUID mahasiswa yang sama dengan `students`. Baris dibuat saat pertama menyimpan; penyimpanan berikutnya memeriksa `updated_at` untuk mencegah perubahan tab lain tertimpa. Batal mengembalikan nilai server; pindah tab atau kembali meminta konfirmasi bila masih mengedit. Kegagalan simpan mempertahankan isian. Semua data boleh dilengkapi bertahap, sehingga kosong disimpan sebagai NULL.

Validasi klien dan constraint database mencakup NIK 16 digit, NISN 10 digit, RT/RW 1–3 digit, kode pos 5 digit, nilai 0–100, tanggal lahir kalender sah tahun 1900 sampai hari ini, email, panjang teks, dan enum. Provinsi/kota serta pekerjaan orang tua masih berupa isian teks: belum ada katalog wilayah/pekerjaan resmi yang terhubung. Pengaturan verifikasi kampus tidak dapat diubah mahasiswa.

`student_finance` hanya boleh dibaca mahasiswa pemilik. Tidak ada tagihan contoh yang disimpan di proyek. Menu Pembayaran belum memproses pembayaran/virtual account. Ringkasan akademik membaca data resmi `students`; IPK/semester/SKS tidak dihitung dari NIM dan tidak disalin dari referensi.

## Telepon dan email

- Semua kolom telepon menerima `08…`, `0kode area…`, `62…`, dan `+kode negara…`. Spasi, tanda kurung, dan tanda hubung dibersihkan. Nomor lokal Indonesia disimpan sebagai `+62…`; nomor internasional tetap menggunakan kode negaranya. Nomor harus berisi 8–15 digit setelah normalisasi, tanpa huruf. Validasi format bukan verifikasi kepemilikan nomor.
- Telepon Biodata disinkronkan ke `profiles.phone` oleh trigger, sehingga beranda/chat memakai nilai yang sama. Editor foto/nama panggilan juga dapat mengubah telepon; Biodata membaca nilai profil terbaru saat halaman dimuat.
- **Email kampus** berasal dari `students.campus_email`, hanya dapat diubah pengelola. Untuk akun demo Dante, pemilik meminta `dantevirgo7@esaunggul.ac.id`; alamat ini hanya label demo, bukan kotak surat kampus yang dibuat aplikasi.
- **Email pribadi** berasal dari `student_biodata.private_email` dan dapat diedit. Nilai awal Dante adalah `marcelljuniar5@gmail.com` sesuai instruksi pemilik.
- **Email login/pemulihan** tetap berasal dari Supabase Auth. Mengedit email pribadi tidak mengubah Auth, password, atau tujuan pemulihan. Email Auth ditampilkan terpisah agar pengguna tidak salah memahami.

## Avatar dan foto

- Nama panggilan opsional, maksimal 50 karakter; kosong berarti memakai nama lengkap sebagai sapaan.
- Avatar `male`, `female`, `neutral` digambar lokal. Avatar perempuan memiliki bentuk wajah, mata, gaya rambut, serta blazer/blus tersendiri. Pilihan avatar tidak menentukan data jenis kelamin.
- Foto diprioritaskan. Mengganti varian tidak menghapus foto; Hapus foto mengembalikan ilustrasi.
- Pemilih menerima JPG/JPEG/JFIF, PNG, WebP, GIF, BMP, TIFF, ICO, HEIC/HEIF, dan AVIF. Format raster umum didekode dengan pustaka `image`; HEIC/HEIF/AVIF bergantung codec perangkat. Jika codec tidak mendukung, aplikasi meminta ekspor ke JPG, tanpa merusak foto lama. SVG/RAW dan semua format gambar yang mungkin ada tidak dijamin.
- Batas masukan 20 MiB. Decoder raster memeriksa maksimum 40 megapiksel dan sisi 16000 piksel. Foto diputar sesuai orientasi, diperkecil ke sisi maksimal 1024 piksel, lalu dikonversi JPEG. Animasi memakai bingkai pertama. Transparansi menjadi putih; metadata EXIF/lokasi dibuang.
- Storage tetap membatasi foto 2 MiB dan MIME JPEG/PNG. Validasi klien bukan pemindai malware server; untuk upload publik skala luas tambahkan validasi/re-encoding server.
- Foto baru diunggah dalam folder UUID, lalu profil diubah dengan pemeriksaan versi. Foto lama dihapus sesudah commit. PATCH gagal memicu pembersihan unggahan baru sebisanya; profil lama dipertahankan. Sisa berkas akibat jaringan putus tetap privat dan perlu pembersihan pengelola.
- Jika commit berhasil tetapi pembacaan ulang gagal, UI menjelaskan bahwa data tersimpan dan meminta Muat ulang.
- Foto diunduh memakai JWT, tanpa public/signed URL yang melewati tenggat aplikasi. Byte foto untuk tampilan disimpan di memori.

## Berkas privat

Metadata berada di `student_documents`; isi berada di bucket privat `student-documents`. Batas 0,5 MiB per berkas, dengan PDF, JPG, PNG, atau DOC. Pemeriksaan signature menolak format yang tidak dikenali, tetapi bukan jaminan berkas bebas malware. DOC memakai signature kontainer OLE; pemindaian antivirus dan pemeriksaan isi dokumen mendalam belum tersedia.

Berkas **langsung diunggah setelah dipilih**, dengan penjelasan di halaman. Penggantian memakai path baru dan pemeriksaan versi metadata; berkas lama dihapus setelah metadata baru berhasil. Penghapusan meminta konfirmasi. Template pernyataan pembayaran resmi belum diberikan, sehingga aplikasi menampilkan status tersebut, bukan membuat template atas nama kampus.

Unduhan memakai sesi JWT yang sah. Browser menjalankan unduhan; Windows/macOS/Linux membuka pemilih lokasi; Android/iOS membuka lembar berbagi sistem untuk memilih tujuan simpan/ekspor. Tidak ada pengiriman otomatis kepada orang lain. Pada HP, plugin dapat membuat salinan sementara di cache privat aplikasi. Berkas yang sudah diekspor menjadi tanggung jawab pengguna dan tidak terhapus oleh logout. Pembatalan dialog tidak menghapus berkas server. Izin sandbox macOS untuk file yang dipilih pengguna sudah ditambahkan. Lihat [dokumentasi share_plus](https://pub.dev/packages/share_plus).

Semua tabel baru menggunakan RLS pemilik UUID **dan sesi aplikasi aktif**. Mahasiswa tidak dapat menulis riwayat keuangan, mengganti email kampus, mengalihkan pemilik baris, atau membaca berkas akun lain. Storage memakai pemeriksaan folder UUID dan sesi yang sama.

Nama/NIM draf dan izin diisi dari profil dan tidak dapat diganti bebas. Surat/antrean izin masih simulasi lokal. Chatbot menjawab identitas secara deterministik dari profil, tidak meneruskannya ke model Ollama. Data akademik yang belum terintegrasi mendapat respons belum tersedia.

## Memasang backend lain

Backend development saat ini: `campus-app`, ref `taqmosufhapstehgeonz`, organisasi Marwij_Hunt, Singapore. Migrasi dan fungsi login telah diterapkan. Untuk backend terpisah:

1. Buat proyek Supabase; simpan kredensial pengelola di luar repository.
2. Jalankan `supabase login`, lalu `supabase link --project-ref REF`.
3. Tinjau migrasi kemudian `supabase db push`. Jangan menjalankan ulang isi migrasi pada database yang sudah menerapkannya.
4. Jalankan `supabase functions deploy login-with-nim --no-verify-jwt`. Fungsi login menerima permintaan sebelum pengguna punya JWT dan memverifikasi password lewat Auth; ini bukan endpoint provisioning admin. Untuk pemulihan OTP, deploy juga `supabase functions deploy password-reset --no-verify-jwt` setelah migrasinya diterapkan, lalu isi secrets sesuai [panduan Resend](password_reset_otp.md).
5. Buat Auth user melalui Authentication → Users. Auto Confirm hanya untuk akun development yang disetujui pemilik; pengguna nyata memerlukan verifikasi email yang sesuai.
6. Ganti placeholder email di `supabase/seed_profile.sql`, periksa identitas/NIM, lalu jalankan sebagai administrator. Skrip tidak membuat password atau akun staf.
7. Atur URL/publishable key Flutter melalui dart-define sebagaimana README.

Login aplikasi tidak menerima akun dummy BAP001/DOS001/DOS002. Fake Auth hanya ada di test/support untuk tes simulasi izin. Backend staf dan data izin perlu dibangun sebelum akun staf nyata diaktifkan.

## Pemulihan password

Form Lupa password sekarang memanggil Edge Function `password-reset`: email Auth → kode enam karakter campuran huruf besar dan angka → password baru dan konfirmasi → login ulang. Respons permintaan dibuat umum agar tidak membocorkan email terdaftar. Kode berlaku 10 menit, sekali pakai, maksimal lima percobaan; kirim ulang minimal 60 detik. Password 12–256 karakter tetap diperiksa Supabase Auth.

Migrasi dan fungsi sudah dipasang pada proyek development. **Tiga secrets server telah dikonfigurasi oleh pengguna; satu email OTP nyata terverifikasi delivered pada 3 November 2026.** Reset password dan login ulang melalui aplikasi masih perlu diuji. Ikuti [panduan aktivasi Resend dan checklist OTP](password_reset_otp.md). Akun dengan MFA terverifikasi memerlukan proses pemulihan khusus pengelola.

Email tujuan adalah email akun Supabase Auth, bukan email kampus tampilan atau kontak pribadi yang dapat diedit. OTP diketik di aplikasi sehingga tidak memerlukan port web tetap, SMTP Supabase, atau deep link. Handler tautan lama tetap tersedia; hanya pengujian tautan lama yang memerlukan Site URL/Redirect URLs dan `campusapp://auth-callback` pada mobile. Pesan permintaan diterima bukan bukti email sampai.

Advisory Supabase masih menunjukkan leaked password protection belum aktif. Aktifkan melalui Auth jika tersedia pada paket proyek; validasi panjang klien tidak menggantikannya. [Dokumentasi keamanan password Supabase](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection).

## Pengujian

Untuk urutan klik dan hasil yang diharapkan, gunakan [checklist pengujian profil](profile_test_checklist.md). Pada verifikasi 1 November 2026, **208 tes Flutter lulus** dan `flutter analyze` tidak menemukan masalah. Uji transaksi RLS pada proyek development sudah lulus untuk lima bagian biodata, dokumen, keuangan, profil, dan sesi; seluruh fixture di-rollback. Pemeriksaan browser login dikonfirmasi pengguna; perubahan profil/foto dan email nyata menunggu uji penerimaan pengguna.

Probe build web terpisah pada Chrome nyata berhasil mengonversi JPG, PNG, GIF, BMP, TIFF, ICO, dan WebP menjadi JPEG serta menolak byte rusak. Probe tidak memakai akun atau gambar pribadi. Ini menguji codec web; tidak menyatakan HEIC/AVIF didukung semua perangkat. Runner `flutter test --platform chrome` pada SDK lokal gagal memuat CanvasKit, sehingga pemeriksaan browser memakai build statis terpisah berikut:

```sh
flutter build web -t tool/verify_profile_photo.dart --output build/photo-probe --no-web-resources-cdn
python -m http.server 3031 --bind 127.0.0.1 --directory build/photo-probe
```

Buka `http://127.0.0.1:3031` dan periksa seluruh hasil `PASS`. Build probe terpisah dari aplikasi utama. Build aplikasi utama (`flutter build web --no-web-resources-cdn`) juga berhasil setelah seluruh revisi, menghasilkan `build/web`. Pengujian dialog berbagi Android/iOS menggunakan platform tes; dialog sistem dan persistensi pada perangkat fisik tetap termasuk checklist manual.

```sh
flutter analyze
flutter test
flutter build web
```

- `supabase_auth_test.dart`: SDK asli dengan HTTP terkendali; login, layanan gagal, profil hilang, pembatalan, logout, respons terlambat, dan tenggat.
- `profile_test.dart`: payload edit, foto valid/rusak, commit/pembersihan foto, dan jawaban chatbot.
- `profile_widget_test.dart`: lebar 320/800/1440, teks 200%, isian tetap ada saat gagal, serta render avatar 48/64/128.
- `biodata_test.dart`: normalisasi nomor, konversi foto lintas format, validasi field, penyimpanan/konflik, dan penggantian dokumen.
- `biodata_widget_test.dart`: edit/simpan/batal semua formulir, kegagalan jaringan, panel kosong, dan tagihan di layar kecil.
- `profile_export_test.dart`: pemilihan jalur Android/iOS, byte/MIME/nama berkas, pembatalan, dan galat dialog sistem melalui platform tes.
- `app_startup_test.dart`: kegagalan startup dapat dicoba ulang tanpa menampilkan rincian internal.

Jalankan `supabase/tests/profile_access.sql` sebagai administrator pada **database development** dengan profil Dante. Semua sesi/objek uji di-ROLLBACK: baca/edit sendiri, penolakan field resmi, lookup email, identitas lain, Storage, sesi habis/dicabut, dan anonim. Skrip tidak mengirim email, menerbitkan token, atau mengunggah berkas nyata.

Pembaruan 2 November 2026: seluruh **218 tes Flutter lulus**, analisis bersih, build web berhasil, **15 tes Deno OTP lulus**, dan uji SQL OTP pada Supabase lulus dengan rollback. Pengiriman Resend dan penggantian password akun nyata belum diuji. Hasil Android terbaru dicatat di `project_progress.md`.

Pembaruan 3 November 2026: seluruh 218 tes Flutter dan 15 tes Deno kembali lulus, analisis/check/lint bersih, tes SQL OTP kembali lulus dengan rollback, serta satu email OTP nyata berstatus delivered. Password pengguna tidak diubah. Rincian dan batas bukti ada di `project_progress.md`.

Penerimaan manual: login → Biodata → edit/simpan → periksa beranda/chat → logout → login ulang → periksa persistensi; unggah/ganti/hapus foto; coba jaringan putus; uji reset OTP dan login ulang pada perangkat target; tunggu 30 menit; uji perangkat target. Login Dante di browser sudah dikonfirmasi pengguna. Tes SQL/HTTP tidak menggantikan seluruh pemeriksaan manual ini.
