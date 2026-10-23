# Smart Chatbot lokal — Campus App

Modul berada di Akses Cepat → Smart Chatbot dan Layanan → Smart Chatbot.
Semua akun yang sudah login juga memiliki tombol robot mengambang di kanan bawah dashboard, halaman detail, dan halaman draf. Tablet/desktop membuka panel chat di kanan bawah; HP atau teks besar memakai layar penuh. Tombol tutup mengembalikan pengguna ke halaman asal. Semua akses memakai riwayat sesi yang sama; tombol pada draf kembali ke chat yang sudah terbuka tanpa membuat duplikat. Login/pemulihan akun tidak menampilkan chatbot mahasiswa.
Versi ini belum memakai database kampus, akun dosen nyata, dokumen kebijakan, atau layanan pengiriman antarperangkat. Akun BAP/dosen uji tersedia untuk [simulasi Izin Online](izin_online.md).

## Kemampuan yang sudah dibuat

Pengembangan berdasarkan materi 19 Oktober 2026 dijelaskan pada [catatan kualitas chatbot](chatbot_quality.md), termasuk batas implementasi setiap tahap dan cara menjalankan evaluator nyata.

- Chat responsif dengan pilihan bantuan dan penanda sumber jawaban.
- Bantuan terpandu tetap berjalan ketika Ollama mati.
- AI lokal dicoba otomatis ketika chat dibuka atau aplikasi kembali aktif. Bantuan terpandu tetap bisa dipakai selama pencarian. Pilihan manual **Gunakan terpandu** dihormati selama sesi login.
- Izin Online: form dengan kalender, bukti, perkuliahan/kode dosen, pratinjau, pemeriksaan BAP, serta PDF keputusan yang tersedia bagi mahasiswa dan dosen tujuan dalam simulasi lokal.
- Draf kendala: kategori, ringkasan, kronologi, lampiran opsional, pratinjau lokal.
- Pemilihan, penghapusan, serta tinjauan gambar/lampiran. Izin Online mendukung pratinjau PDF untuk pemeriksa; form draf kendala hanya menampilkan nama dan ukuran PDF. AI tidak membaca lampiran.
- Maksimal 3 lampiran, masing-masing 5 MB; ekstensi dan penanda awal PDF/JPEG/PNG diperiksa. Ini bukan verifikasi keaslian atau pemeriksaan lengkap struktur berkas.
- Percakapan dan draf belum diajukan berada di memori sesi login; logout/kedaluwarsa menghapusnya. Pengajuan izin yang sudah diajukan bertahan saat berganti akun dalam proses aplikasi yang sama untuk simulasi BAP/dosen. Refresh/restart menghapus seluruh data simulasi.

Data akademik tidak dikarang. Pertanyaan layanan kampus yang dikenali diarahkan ke jawaban terpandu. AI umum tetap dapat keliru, sehingga jawaban diberi label untuk diperiksa. Nomor dan keputusan Izin Online hanya berasal dari tindakan pengguna dalam simulasi dan tidak menjadi dokumen resmi. Chatbot tidak menyatakan telah mengirim pengajuan atau menyetujui izin.

## Ollama khusus proyek di Windows

Jalankan dari akar proyek menggunakan Windows PowerShell bawaan. Tidak perlu memasang PowerShell 7. Skrip juga mendukung PowerShell 7 bila sudah tersedia.

```powershell
# Sekali saat pemasangan: unduh runtime resmi dan model (~2,5 GB unduhan total).
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tool\local_ai\setup.ps1

# Setelah setup, buka terminal PowerShell baru. Ollama dimulai otomatis sebelum Flutter.
flutter run -d chrome
# Bisa juga: flutter run, atau flutter run -d emulator-5554 (sesuaikan ID perangkat).

# Pemeriksaan nyata melalui service yang sama dengan aplikasi.
dart run tool/local_ai/smoke.dart

# Setelah selesai menggunakan AI.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tool\local_ai\stop.ps1
```

Runtime portable v0.40.5 (SHA-256 diverifikasi), model `qwen2.5:1.5b`, log, dan PID disimpan di `.local-ai/`, yang diabaikan Git. `start.ps1` memilih satu IP LAN fisik yang memiliki gateway (Wi-Fi/Ethernet); jika tidak ada, memakai `127.0.0.1`. Server memakai port 11435 dan tidak bind ke semua antarmuka/VPN. Penyimpanan model khusus proyek dan cloud dinonaktifkan. Tidak mengubah PATH, tidak memasang layanan/startup Windows, dan tidak memakai API key.

`setup.ps1` juga memasang pengait pada profil pengguna Windows PowerShell 5.1 dan PowerShell 7. Pengait hanya menyiapkan AI untuk `flutter run` di proyek ini, lalu meneruskan argumen dan kontrol interaktif ke SDK asli. Model tidak diunduh ulang saat menjalankan aplikasi. Profil lama dicadangkan jika perlu diubah. Untuk instalasi yang sudah punya Ollama, cukup jalankan `install_autostart.ps1` sekali; lihat [panduan autostart](local_ai_autostart.md), termasuk cara menonaktifkan dan batas terminal yang didukung.

Internet diperlukan saat unduhan awal. Setelah model tersedia, jawaban lokal tidak memerlukan internet; komputer dan proses Ollama tetap harus menyala. Model ringan dipilih untuk prototipe, bukan jaminan kualitas jawaban bahasa Indonesia atau aturan akademik.

## Sambungan otomatis lintas perangkat

Dengan pengait terpasang dan terminal PowerShell baru, `flutter run` otomatis menjalankan `start.ps1` terlebih dahulu. Untuk build APK, terminal `-NoProfile`, Command Prompt, atau tombol Run/F5 IDE, jalankan skrip secara manual terlebih dahulu. Skrip menulis alamat komputer ke `assets/local_ai/connection.json` (diabaikan Git, ikut dibundel Flutter). `default.json` menjaga folder aset tetap tersedia pada clone baru. Aplikasi memeriksa keberadaan model sebelum menampilkan status aktif, bukan sekadar menganggap server menyala.

| Perangkat | Cara menemukan komputer AI |
|---|---|
| Chrome/Edge/desktop | IP LAN dari aset startup, lalu localhost; browser dengan host LAN juga mencoba host halaman |
| Emulator Android standar | `10.0.2.2`, kemudian IP LAN dari aset dan localhost |
| HP Android/iPhone/iPad | IP LAN dari aset; harus terhubung ke jaringan komputer AI |
| Alamat yang diatur sendiri | Pengaturan koneksi (ikon roda gigi) atau `--dart-define=OLLAMA_URL=...` |

Alamat manual tersimpan pada perangkat/browser dan diprioritaskan di atas dart-define maupun pencarian otomatis. Kosongkan kolom untuk kembali otomatis. Pencarian memeriksa paling banyak delapan alamat, dua detik per alamat; alamat eksplisit tidak diam-diam dialihkan ke server lain. Ketersediaan server diperiksa kembali sebelum pesan AI dikirim. Jika gagal, pengguna dapat mencoba lagi atau tetap menggunakan bantuan terpandu. Tidak ada pemindaian semua perangkat dalam jaringan atau polling tanpa henti.

Ketika IP komputer berubah, jalankan ulang `start.ps1` lalu hentikan dan jalankan ulang `flutter run`/build agar aset alamat diperbarui. Aplikasi yang sudah terpasang juga dapat memasukkan IP baru melalui pengaturan tanpa build ulang. `start.ps1 -LocalOnly` membatasi server kembali ke komputer itu saja. `stop.ps1` menghentikan server proyek.

Skrip menyiapkan aturan Windows Firewall khusus executable Ollama proyek, IP terpilih, TCP 11435, dan sumber `LocalSubnet`. Pembuatan/perubahan aturan membutuhkan Administrator; bila ada peringatan, jalankan `tool/local_ai/firewall.ps1 -Address IP_KOMPUTER` dari PowerShell Administrator, kemudian ulangi koneksi. Tidak perlu mematikan firewall. Untuk menghapus aturan ketika tidak lagi diperlukan, jalankan `Remove-NetFirewallRule -Name CampusApp-LocalAI-11435` sebagai Administrator.

Chrome/iOS/macOS mungkin meminta izin **jaringan lokal**; izinkan untuk app ini. Android menyertakan izin INTERNET dan HTTP untuk Ollama lokal; service membatasi HTTP ke loopback, IPv4 privat, atau nama `.local`. iOS/macOS menyertakan deskripsi izin LAN/ATS lokal dan macOS izin network client. Build dan pengujian iOS tetap memerlukan Mac/Xcode. Router yang mengisolasi perangkat tamu dapat menghalangi sambungan meskipun nama Wi-Fi sama.

**Lingkup koneksi:** otomatis berarti aplikasi mencari alamat yang telah disiapkan, bukan menyalakan komputer/server dari HP atau menjangkau komputer di jaringan lain. Ollama ini tanpa autentikasi; gunakan LAN yang dipercaya karena perangkat lain dalam subnet dapat mengakses API-nya. Jangan port-forward ke internet. Hosting HTTPS/penggunaan lintas internet memerlukan backend HTTPS dengan autentikasi yang disiapkan terpisah; alamat HTTPS dapat diatur tetapi versi ini belum menyediakan autentikasi backend tersebut. Browser dari halaman HTTPS juga dapat membatasi HTTP lokal.

## Pembagian kode (hybrid)

| File | Tanggung jawab |
|---|---|
| `chat_models.dart` | Pesan, kategori bantuan, aturan lampiran, dan template draf |
| `chat_controller.dart` | Sesi percakapan, mode, proses kirim, retry, pembatalan |
| `ollama_service.dart` | Status model dan permintaan HTTP ke AI lokal |
| `chat_policy.dart` | Rute pertanyaan, glosarium umum, dan batas sumber kampus |
| `chat_protocol.dart` | Prompt per tugas, anggaran konteks, dan validasi JSON |
| `draft_language.dart` | Daftar penggantian bahasa yang boleh dipilih AI |
| `draft_editor.dart` | Proses penyuntingan, tinjauan, dan penerapan usulan |
| `chat_connection.dart` | Kandidat alamat perangkat, aset startup, dan penyimpanan alamat pilihan |
| `connection_settings.dart` | Form pengaturan koneksi dan validasi alamat |
| `chat_page.dart` | Susunan halaman chat dan kolom pesan |
| `chat_launcher.dart` | Tombol mengambang, panel responsif, dan pencegahan chat duplikat |
| `chat_widgets.dart` | Pilihan bantuan dan gelembung pesan yang dipakai ulang |
| `draft_page.dart` | Form kendala dan cadangan draf mandiri |
| `../leave/` | Form izin, akses peran, pemeriksaan, kotak masuk, dan PDF |

Form izin dari chatbot membuka modul Izin Online yang sama dengan dashboard. Modul dibagi menurut tanggung jawab, tanpa satu file per tombol atau menumpuk logika AI di beranda. Komentar berbahasa Indonesia menjelaskan tujuan blok kode.

## Data dan batas layanan

Hanya percakapan pada mode AI yang diteruskan ke model lokal. Form draf, lampiran, dan profil login tidak otomatis dikirim. Tidak ada riwayat persisten atau unggahan berkas. Permintaan yang dibatalkan atau selesai setelah halaman/sesi dibuang tidak menampilkan balasan.

Pengecualian berdasarkan tindakan pengguna: tombol **Rapikan bahasa dengan AI** mengirim teks alasan/kronologi yang sedang disunting. Kolom identitas, tanggal, dan berkas formulir tidak ikut diambil; teks yang pengguna ketik sendiri dalam alasan tetap termasuk input penyuntingan. Hasil harus ditinjau sebelum diterapkan dan tidak menjadi pengajuan resmi.

Sesi login masih sesi demo aplikasi. Koneksi Ollama lokal bukan backend akademik yang menerapkan autentikasi produksi. Saat integrasi kampus dibuat, pemeriksaan sesi, akses data, pengiriman, dan penyimpanan harus dipindahkan ke backend resmi. Instruksi sistem AI dan pencocokan kata bukan pengganti pemeriksaan hak akses.

Belum tersedia: RAG/panduan resmi, OCR/pembacaan isi PDF oleh AI, data mahasiswa, direktori kontak resmi, chat dosen, pengiriman pengajuan antarperangkat, simulator KRS, ekspor percakapan ke PDF/DOCX, atau persetujuan kampus nyata. Ekspor PDF hasil keputusan khusus Izin Online sudah tersedia dalam simulasi lokal.

Referensi implementasi: [Ollama Windows portable](https://docs.ollama.com/windows), [API chat](https://docs.ollama.com/api/chat), [konfigurasi lokal/cloud](https://docs.ollama.com/faq), [model Qwen2.5 1.5B](https://ollama.com/library/qwen2.5:1.5b).

Referensi jaringan: [alamat emulator Android](https://developer.android.com/studio/run/emulator-networking-address), [ATS jaringan lokal Apple](https://developer.apple.com/documentation/bundleresources/information-property-list/nsapptransportsecurity/nsallowslocalnetworking), [izin jaringan lokal Apple](https://developer.apple.com/documentation/technotes/tn3179-understanding-local-network-privacy).
