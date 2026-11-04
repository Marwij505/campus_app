# Instruksi Codex — campus_app

1. Pertahankan pilihan pengguna **GPT-6 Astra High**; jangan mengganti model tanpa instruksi. File ini tidak mengatur model secara otomatis.
2. Hemat token pada pembacaan, tools, dan respons tanpa mengurangi kualitas, keamanan, kelengkapan fitur, atau validasi penting. Komunikasikan hasil secara ringkas (gaya Caveman); detail yang diminta tetap lengkap.
3. Pada sesi pertama setelah migrasi, baca ringkasan eksekutif, keputusan teknis (K), roadmap (M), tugas aktif (N), dan serah terima (O) di `project_progress.md`.
4. Untuk tugas berikutnya, baca hanya bagian dokumentasi dan source yang relevan. Cari file/simbol dengan `rg` sebelum membuka isinya.
5. Hindari pemindaian seluruh repository, pembacaan ulang file yang tidak berubah, operasi berulang, dan keluaran kode/log lengkap tanpa kebutuhan. Kecualikan cache, build, dependensi, serta model AI besar dari pencarian rutin.
6. Gunakan patch minimal; pertahankan perilaku dan arsitektur yang tidak terkait. Jangan melakukan refactoring atau membuat file tambahan tanpa kebutuhan.
7. Jalankan pengujian relevan; perluas bila dampak lintas modul, keamanan, atau stabilitas menuntutnya. Laporkan ringkasan hasil dan batas verifikasi; jangan mengklaim tes yang belum dijalankan.
8. Setelah milestone atau perubahan signifikan, perbarui hanya bagian `project_progress.md` yang terdampak, kecuali batas tugas pengguna melarangnya. Pertahankan riwayat dan roadmap; jangan menduplikasi dokumentasi di sini.
9. Verifikasi teknologi dari source, konfigurasi, dan bukti proyek. Plugin tersedia bukan bukti integrasi layanan. Periksa ketersediaan skill/plugin saat dibutuhkan, laporkan jika tidak tersedia, dan gunakan referensi resmi untuk API yang belum pasti.
10. Jangan melakukan commit, push, atau perubahan database (termasuk schema, migrasi, dan data) tanpa instruksi pengguna. Jangan mencatat kredensial atau secret dalam kode, log, maupun dokumentasi.
