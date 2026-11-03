# Checklist pengujian profil SIAKAD

Gunakan backend development. Password tidak perlu dikirim kepada siapa pun. Saat mengetes edit, gunakan nama panggilan/nomor/foto milik sendiri; kembalikan perubahan percobaan setelah selesai.

## Mulai

1. Hentikan aplikasi lama dengan `q` di terminal Flutter.
2. Jalankan `flutter pub get`, kemudian `flutter run -d chrome` dari folder proyek. OTP diketik langsung di aplikasi, jadi port web tetap tidak diperlukan.
3. Login NIM **20240801001** dengan password Auth yang sudah dibuat. Tidak memakai password demo lama.

## Login, profil, dan persistensi

| Tes | Langkah | Hasil yang diharapkan |
| --- | --- | --- |
| Login benar | Masuk dengan akun Dante | Beranda menyapa Dante; nama resmi Prismatine Dante Viergo; NIM benar |
| Login salah | Coba satu password yang salah | Pesan kredensial salah, tidak masuk; jangan sengaja mengulang berkali-kali karena ada rate limit |
| Biodata | Buka Akses Cepat → Biodata, lalu coba menu Biodata | Keduanya membuka profil akun yang sama |
| Identitas kosong | Buka Biodata dan baca kartu ringkasan biru | Universitas/fakultas/prodi benar; data yang belum diberikan tetap kosong, tanpa IPK/semester rekaan |
| Field resmi | Buka Biodata → Edit atau Edit foto / nama panggilan | Nama resmi/NIM/peran/fakultas/prodi tidak dapat diedit |
| Nama panggilan | Ganti sementara menjadi Dante Uji, simpan | Sapaan beranda ikut berubah; kartu profil tetap menampilkan nama resmi |
| Simpan permanen | Logout lalu login ulang | Nama panggilan yang disimpan tetap ada |
| Panggilan kosong | Kosongkan panggilan, simpan | Sapaan memakai nama lengkap; kemudian boleh kembalikan menjadi Dante |
| Telepon valid | Isi nomor sendiri dengan 08..., 62..., atau +kode negara, lalu simpan | Tersimpan sebagai format internasional +62... untuk nomor lokal; kosong juga diterima |
| Telepon invalid | Isi huruf atau nomor terlalu pendek | Ditolak dengan pesan, profil lama tidak berubah |
| Batal edit | Ubah panggilan tanpa simpan, tekan Batal | Data tersimpan tetap seperti sebelumnya |
| Jaringan putus | Buka editor, matikan internet, simpan | Tidak mengaku berhasil; input tetap ada. Jaringan/SDK mungkin membutuhkan waktu sebelum melaporkan gagal. Aktifkan internet lalu coba kembali |
| Muat ulang gagal | Putuskan internet lalu tekan Muat ulang | Data terakhir tetap tampil dengan pesan kesalahan |

## Avatar dan foto

| Tes | Langkah | Hasil yang diharapkan |
| --- | --- | --- |
| Tiga avatar | Tanpa foto, pilih Pria/Perempuan/Netral bergantian lalu simpan | Pilihan tampil konsisten di profil/beranda dan bertahan setelah login ulang |
| Unggah foto | Pilih JPG, PNG, WebP, GIF, BMP, TIFF, atau ICO valid, maksimal 20 MiB/40 MP/sisi 16000 piksel | Pratinjau terlihat; setelah simpan foto tampil dan tetap tersedia setelah login ulang |
| Ganti foto | Unggah foto lain dan simpan | Foto baru digunakan; bukan foto lama dari cache |
| Pilih varian saat ada foto | Ganti varian dan simpan | Foto tetap digunakan; memilih varian tidak menghapus foto |
| Hapus foto | Tekan Hapus foto, lalu simpan | Kembali ke avatar yang dipilih, termasuk setelah login ulang |
| Foto invalid | Coba berkas >20 MiB, gambar rusak, atau format tanpa codec | Ditolak tanpa mengganti foto tersimpan |
| Batal pemilih | Buka pemilih foto lalu Cancel | Editor tetap dapat digunakan, tidak terus loading |

## Lima formulir pribadi

Untuk **setiap tab Biodata, Pendidikan, Keluarga, Pekerjaan, dan Disabilitas**:

1. Tekan Edit, isi nilai yang benar milik sendiri, lalu Simpan. Pesan sukses harus tampil dan editor kembali menjadi tampilan baca.
2. Tekan Muat ulang, lalu logout/login ulang. Nilai tersimpan harus tetap sama.
3. Tekan Edit, ubah satu nilai, lalu Batal. Nilai sebelumnya harus kembali.
4. Saat mengedit, pilih tab lain atau tombol kembali. Pilih Tetap mengedit: input bertahan. Pilih Buang perubahan: nilai yang belum disimpan tidak terkirim.
5. Putuskan jaringan saat menyimpan. Aplikasi harus memberi galat dan mempertahankan input. Pulihkan jaringan; muat ulang jika hasil penyimpanan sebelumnya belum pasti.
6. Buka bagian sama pada dua jendela yang sudah login. Simpan di jendela pertama, kemudian kedua. Penyimpanan kedua yang versinya lama harus ditolak, bukan menimpa diam-diam. Salin perubahan penting sebelum Muat ulang.

| Tes khusus | Hasil yang diharapkan |
| --- | --- |
| NIK kurang/lebih dari 16 digit; NISN bukan 10 digit | Ditolak; kosong masih boleh karena pendataan bertahap |
| RT/RW huruf; kode pos bukan 5 digit | Pesan validasi muncul |
| Tanggal lahir | Kalender tersedia; tanggal masa depan tidak bisa dipilih; tombol kosongkan menghapus nilai |
| Nilai sekolah `82,5` atau `82.5` | Diterima; nilai negatif, lebih dari 100, dan teks ditolak |
| Telepon pada orang tua, darurat, sekolah, perusahaan | Nomor lokal 0… serta +kode negara diterima dan dinormalisasi |
| Disabilitas Ya | Rincian dan kebutuhan akomodasi muncul serta tersimpan |
| Ganti Disabilitas menjadi Tidak | Rincian disembunyikan dan dikosongkan saat Simpan |
| Provinsi/kota | Bisa diisi teks; katalog pilihan wilayah resmi belum terhubung |
| Field resmi | NIM, nama resmi, status, prodi, semester, IPK dan email kampus tidak menjadi input mahasiswa |

## Tiga fungsi email

1. Biodata → Kontak harus menampilkan email kampus demo `dantevirgo7@esaunggul.ac.id`.
2. Email pribadi awal adalah `marcelljuniar5@gmail.com`. Ubah sementara ke email lain milik sendiri, Simpan, muat ulang: nilai baru bertahan.
3. Email login/pemulihan tetap `marcelljuniar5@gmail.com`. Perubahan kontak pribadi tidak boleh mengubah Auth. Kembalikan kontak pribadi setelah tes.
4. Email tanpa format sah ditolak. Email kampus tidak bisa diedit mahasiswa.
5. Chat `email kampus` harus menjawab alamat kampus, bukan lokasi kampus. Chat `email pribadi` mengarahkan ke Kontak.

## Foto tambahan

- Uji beberapa format, foto dari HP yang berotasi, dan PNG transparan. Hasil tampil tegak dengan latar putih untuk transparansi.
- GIF animasi menjadi foto bingkai pertama. Hasil foto disimpan sebagai JPEG kecil, bukan file asli dengan metadata lokasi.
- HEIC/HEIF/AVIF hanya dapat dipakai bila codec perangkat mendukung. Jika gagal, pesan harus meminta konversi ke JPG; foto lama tetap aman.
- Avatar perempuan harus berbeda pada wajah dan pakaian, bukan hanya rambut. Uji di profil, beranda, dan sesudah masuk ulang.

## Berkas persyaratan

Berkas langsung tersimpan setelah dipilih; tidak menunggu tombol Simpan formulir. Gunakan dokumen uji tanpa informasi sensitif untuk pemeriksaan awal.

1. Unggah PDF/JPG/PNG/DOC maksimal 0,5 MiB pada satu kategori. Status berubah menjadi Terunggah, nama berkas tampil.
2. Muat ulang dan masuk ulang. Berkas harus tetap tersedia hanya pada akun yang sama.
3. Klik nama berkas. Web mengunduh; desktop meminta lokasi; HP membuka lembar berbagi/simpan sistem. Batal tidak menghapus dokumen server.
4. Ganti berkas. Versi lama hanya diganti sesudah unggahan dan metadata baru berhasil.
5. Putus jaringan saat mengganti. Jangan menganggap sukses; setelah koneksi pulih, muat ulang dan periksa berkas yang tersedia.
6. Hapus file → Batal: berkas tetap ada. Hapus file → Hapus: status kembali Belum ada.
7. Coba berkas >0,5 MiB atau isi tidak cocok format yang diterima: pesan validasi, berkas lama tetap ada.
8. Periksa lima kategori: KTP, KK, ijazah, pernyataan pembayaran, paspor. Template resmi pernyataan belum tersedia; tidak ada tautan palsu.
9. Berkas yang diekspor ke HP/desktop tidak hilang saat logout. Hapus salinan lokal uji sendiri bila tidak diperlukan.

## Riwayat keuangan

- Tanpa tagihan resmi, tampil “Belum ada riwayat keuangan”; tidak muncul angka dari screenshot referensi.
- Jika pengelola telah menerbitkan data sungguhan, periksa pengelompokan periode/kategori, subtotal, total dibayar/sisa, status dan tanggal.
- Mahasiswa tidak dapat menambah/mengedit tagihan. Buka Pembayaran hanya menuju halaman Pembayaran; virtual account/pembayaran nyata belum terintegrasi.

## Integrasi dan sesi

| Tes | Langkah | Hasil yang diharapkan |
| --- | --- | --- |
| Identitas chatbot | Kirim nama, nim, jurusan | Menggunakan profil akun yang benar, bukan jawaban rekaan AI |
| Data belum terhubung | Kirim ipk, jadwal, semester | Menjelaskan data belum tersedia/diintegrasikan sesuai statusnya |
| Draf/izin | Buka draf surat atau Izin Online | Nama/NIM berasal dari profil dan tidak bisa diganti bebas; alur izin tetap ditandai simulasi lokal |
| Logout dari detail | Keluar dari akun setelah membuka halaman/detail/chat | Kembali ke login, halaman privat tidak dapat dibuka dengan tombol kembali |
| Refresh/restart | Refresh browser saat login | Meminta login kembali, tetapi data profil yang sudah disimpan tetap ada di server |
| Batas 30 menit | Login baru, catat waktu, biarkan melewati 30 menit; boleh tetap beraktivitas | Sesi tetap berakhir, aktivitas tidak memperpanjang. Tab yang ditangguhkan browser harus meminta login saat kembali aktif |
| Tampilan | Ubah lebar browser sekitar 320, 800, 1440 px; coba zoom/teks besar | Konten dapat digulir, tidak terpotong horizontal; tombol dan input tetap terjangkau |

## Password — lakukan paling akhir

1. **Ubah password saat login:** buka Biodata → Ubah password. Konfirmasi berbeda/password <12 karakter harus ditolak. Password baru yang memenuhi kebijakan harus tersimpan, lalu pengguna keluar. Login ulang menggunakan password baru.
2. **Lupa password:** selesaikan [aktivasi Resend](password_reset_otp.md), lalu ajukan kode ke email Auth sendiri. Periksa inbox/spam, masukkan OTP enam karakter beserta password baru dan konfirmasi di aplikasi. Setelah sukses, login dengan password baru; password lama harus gagal. Pesan umum saat meminta kode tidak membuktikan email sudah sampai.
3. **Kode salah/kedaluwarsa:** kode salah, lebih dari lima percobaan, sudah dipakai, atau melewati 10 menit harus ditolak. Setelah kirim ulang, kode lama tidak berlaku. Ikuti checklist OTP lengkap agar tidak melampaui rate limit tanpa sengaja.
4. **Android/iOS/desktop:** gunakan form OTP yang sama; tidak perlu membuka tautan email. Uji keyboard, layar kecil, kirim ulang, dan kembali ke login. Uji persistensi/edit profil tetap dilakukan terpisah.

Jika email belum sampai, periksa secrets Edge Function dan status pengiriman Resend. Satu pengiriman nyata melalui endpoint aplikasi sudah delivered pada 3 November 2026; reset password dan login ulang akun nyata belum diuji. Alur tautan Auth lama masih tersedia untuk kompatibilitas dan memiliki konfigurasi callback tersendiri.

## Pemeriksaan pengelola

- Uji akses lintas akun, kolom resmi, Storage, sesi habis, akun dinonaktifkan, dan pencabutan tersedia di `supabase/tests/profile_access.sql`. Jalankan hanya di database development; seluruh fixture di-rollback.
- Jangan membuat akun produksi palsu atau membagikan service-role key untuk mencoba RLS.
- Advisory leaked password protection masih perlu diaktifkan bila tersedia pada paket Supabase.
- Catat masalah dengan nama langkah, pesan kesalahan, ukuran layar, dan hasil yang diharapkan. Hindari password, token, serta foto/dokumen pribadi dalam screenshot laporan.
