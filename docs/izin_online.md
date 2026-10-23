# Izin Online: mahasiswa, BAP, dan dosen

Fitur ini memakai desain pixel SIAKAD yang sudah ada. Buka **Akses Cepat → Izin Online**, tepat setelah Konseling, atau **Layanan → Izin Online**. Chatbot menawarkan tombol layanan yang sama untuk pesan `izin`, `ijin`, `surat izin`, `mau izin`, `izin sakit hari ini`, atau `gak masuk kuliah`. `izin?` menawarkan tiga pilihan, termasuk pengertian dan status. Pesan layanan ini dijawab aplikasi tanpa menunggu model atau mengarang data.

## Batas versi tanpa data

Ini **simulasi lokal satu proses aplikasi**, belum layanan kampus sebenarnya. Tidak ada data akademik, pengajuan, atau keputusan awal. Pengguna memasukkan isian sendiri dan memakai dua akun dosen uji. Beralih akun lewat tombol Keluar mempertahankan pengajuan yang sudah diajukan. Refresh browser, hot restart, atau menutup proses menghapus semuanya. Browser/perangkat lain tidak berbagi kotak masuk ini.

BAP berperan sebagai **unit pemeriksa administrasi pembelajaran**. Berita Acara Perkuliahan merupakan dokumen kegiatan mengajar, bukan akun yang mengambil keputusan. Penyebutan dan kewenangan resmi tetap perlu disesuaikan dengan kampus ketika integrasi dilakukan.

## Alur yang bisa dicoba

1. Login mahasiswa `20240801001` (password `123456`). Buka Izin Online, lalu **Buat pengajuan izin**.
2. Isi nama, program studi, jenis/alasan izin, rentang tanggal dari kalender, serta bukti. NIM mengikuti akun, bukan isian bebas.
3. Tambahkan perkuliahan yang terdampak: kode/nama mata kuliah, kode kelas, tanggal, serta dosen tujuan. Pilih `DOS001` atau `DOS002`; kedua akun bernama **Dosen Uji** agar perbedaan kode terlihat jelas. Nama/kode mata kuliah masih isian manual, bukan jadwal resmi.
4. Periksa pratinjau lalu **Ajukan ke BAP (simulasi)**. Status menjadi Menunggu BAP. Tombol kembali edit tidak mengirim pengajuan.
5. Keluar tanpa refresh. Login `BAP001` / `123456`. Buka pengajuan, lihat bukti, cocokkan tanggal dan penerima, isi catatan, lalu pilih **Disetujui BAP**, **Ditolak BAP**, atau **Perlu perbaikan**. Konfirmasikan keputusan.
6. Jika perlu perbaikan, mahasiswa membuka pengajuan yang sama dan memilih **Perbaiki & ajukan ulang**. Nomor tetap, versi bertambah; dosen belum menerima hasil final.
7. Persetujuan maupun penolakan menghasilkan PDF berisi keputusan, alasan, identitas, rentang izin, dan kode dosen. PDF tersedia untuk mahasiswa agar dapat disimpan/dibagikan secara manual. PDF bertanda **SIMULASI LOKAL**, tanpa tanda tangan resmi atau perubahan presensi otomatis.
8. Login sebagai kode dosen yang dipilih (`DOS001` atau `DOS002`, password `123456`). Hasil final sudah muncul di kotak masuk akun tujuan. Dosen lain tidak melihatnya. Tombol **Tandai hasil sudah dibaca** memperbarui tanda baca; ketersediaan dokumen tidak otomatis dianggap sudah dibaca.

Akun mahasiswa kedua `20240801002` dapat dipakai untuk mengecek bahwa pengajuan mahasiswa pertama tidak muncul pada akunnya. Lampiran bukti hanya terlihat oleh pemilik dan BAP; dosen menerima informasi izin dan hasil keputusan, tanpa lampiran bukti.

## Validasi dan kegagalan

- Bukti wajib 1–3 berkas PDF/JPG/PNG, maksimal 5 MB per berkas. Aplikasi memeriksa ekstensi, ukuran, dan penanda awal berkas; BAP tetap memeriksa isi dan keabsahannya. Ini belum pemindai berkas berbahaya.
- Kalender menyimpan tanggal `YYYY-MM-DD`; tanggal akhir tidak boleh sebelum awal. Setiap tanggal perkuliahan harus berada dalam rentang izin.
- Maksimal delapan perkuliahan per pengajuan, tanpa duplikat mata kuliah/kelas/tanggal/dosen yang sama. Ini batas teknis prototipe, bukan aturan resmi kampus.
- Hanya BAP dapat menentukan keputusan. Catatan dan konfirmasi pemeriksaan wajib diisi.
- PDF gagal dibuat atau sesi pemeriksa berakhir: keputusan final belum disimpan. Klik ganda tidak menggandakan pengajuan/pemeriksaan.
- Draf belum diajukan dibuang saat logout. Pengajuan yang telah diajukan tetap ada selama proses aplikasi hidup.
- **Rapikan bahasa dengan AI** tetap opsional dan perlu ditinjau pengguna. Hanya teks alasan yang diproses; AI tidak menetapkan keabsahan bukti, penerima, ataupun persetujuan.

## Pembagian kode

`lib/features/leave/` membagi tanggung jawab menjadi model/validasi, repository/hak akses, form, kotak masuk, detail/pemeriksaan, komponen bersama, dan pembuat PDF. Komentar berbahasa Indonesia menjelaskan blok penting. `AuthGate` memiliki repository agar pergantian akun tidak menghapus pengajuan.

Untuk produksi, ganti penyimpanan memori dengan backend yang memeriksa identitas/peran di server, direktori dosen dan relasi kelas resmi, penyimpanan bukti, transaksi keputusan/pengiriman, audit, serta penerbitan dokumen resmi. Hak akses di aplikasi demo bukan pengganti autentikasi server. Chatbot tidak menyatakan sudah membaca status pengajuan; tombolnya membuka halaman yang memuat status sesuai akun.

## Menjalankan dan memeriksa

Setelah pembaruan dependensi, hentikan Flutter yang sedang berjalan lalu jalankan kembali:

```powershell
flutter pub get
flutter run -d chrome
```

Ollama hanya diperlukan untuk jawaban AI umum/penyuntingan opsional, bukan pengajuan dan pemeriksaan izin.

```powershell
flutter analyze
flutter test
flutter build web
```

Pengujian mencakup akses lintas akun, dosen bernama sama, revisi, penolakan, kegagalan PDF/sesi, formulir HP/tablet/desktop, dan pesan izin singkat. PDF pendek serta banyak halaman dibuat dari data sintetis untuk pemeriksaan visual.

PDF dibuat di perangkat dengan paket [pdf](https://pub.dev/packages/pdf), dan disimpan/dibagikan melalui [printing](https://pub.dev/packages/printing).
