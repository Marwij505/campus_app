# Upgrade Smart Chatbot tanpa data akademik

Implementasi 19 Oktober 2026 mengacu pada materi pengguna **Upgrading The Quality of Ollama AI.txt**. Fokusnya tahap 1–2 dan penjelasan kesiapan layanan tahap 3. Tidak ada database, mahasiswa dummy baru, dokumen kebijakan, penerima layanan, atau transaksi yang dibuat seolah nyata.

## Perubahan perilaku

| Contoh | Sebelumnya | Sekarang |
|---|---|---|
| Apa itu KRS? | Kata KRS selalu dianggap membutuhkan data | Glosarium umum menjelaskan Kartu Rencana Studi; bukan ketentuan kampus |
| Kenapa KRS saya ditolak? | Jawaban keterbatasan umum | Menjelaskan catatan belum terhubung, tidak menebak penyebab, menyediakan tombol draf kendala |
| knp ksr sy ditolak | Variasi kata mudah terlewat | Normalisasi singkatan/salah ketik terpilih lalu rute personal |
| Mau cuti | Respons panduan umum | Satu pertanyaan klarifikasi dan alternatif draf pertanyaan |
| Jelaskan lagi lebih sederhana | Hanya menyimpan 12 pesan terakhir | Pertanyaan awal dan pasangan percakapan terbaru dipertahankan dalam anggaran karakter |
| Topik baru atau percakapan baru | Riwayat bebas dapat bercampur | Konteks model direset; lanjutan tanpa konteks meminta penjelasan |
| Rapikan alasan izin | Template saja | AI memilih perbaikan bahasa terbatas; pengguna meninjau sebelum menerapkan |
| Model mengeluarkan JSON rusak/terpotong | Teks respons belum divalidasi terstruktur | Ditolak, tersedia retry, tidak dimasukkan sebagai jawaban lengkap |

## Pemetaan materi

| Poin | Kondisi implementasi |
|---|---|
| 1–4 | Peran, batas kemampuan, rute umum/personal/aturan/tindakan/penulisan, normalisasi terpilih, klarifikasi, tombol alternatif |
| 5 | Penyuntingan bahasa terbatas pada alasan/kronologi dengan tinjauan; bukti/tanggal tetap diperiksa aplikasi. Belum menyusun ulang paragraf secara bebas |
| 6 | Prompt tutor dengan contoh/latihan sesuai permintaan, jawaban singkat dan dukungan pertanyaan lanjutan |
| 7 | Status layanan ditampilkan terpisah dari status Ollama. Semua sumber kampus tetap belum terhubung; belum ada backend yang memperbarui status secara dinamis |
| 8–12 | Belum diaktifkan: dokumen/RAG, cakupan kebijakan, data personal, kalkulator resmi, pengiriman dan penerima manusia |
| 13 | Instruksi inti, tutor, penulisan, dan penyunting terbatas dipisahkan; hanya glosarium relevan ikut dalam prompt tutor |
| 14 | Anggaran 6.500 karakter untuk konteks, pertanyaan awal verbatim, pasangan tanya-jawab terbaru; bukan estimasi token presisi. Jika bagian terakhir tidak muat, pengguna diminta menyebutkan ulang bagian yang dimaksud |
| 15 | Skema JSON: kategori, status, jawaban, informasi kurang, referensi, tindakan. Referensi harus kosong dan tindakan harus `none`. Klarifikasi harus berupa satu pertanyaan; metadata pertanyaan tambahan pada jawaban biasa tidak ditampilkan |
| 16 | Paket acuan 35 pertanyaan, unit/widget tests, dan evaluator nyata yang dapat dijalankan ulang |

## Bantuan cepat mahasiswa (revisi pesan singkat)

Jalur layanan sekarang diperiksa sebelum tutor Ollama. Pesan singkat tidak
otomatis meminta definisi. Perilaku ini sama ketika AI aktif maupun tidak aktif.

| Pesan | Respons |
|---|---|
| `jadwal`, `ujian`, `tugas`, `pengumuman` | Kebutuhan hari ini; saat ini menjelaskan sumber kampus belum terhubung |
| `ipk`, `krs`, `nilai`, `tagihan`, `skripsi` | Kebutuhan catatan terbaru, tanpa mengarang nilai/status |
| `ipk?`, `krs?`, `jadwal?` | Pilihan bernomor: cek data atau pengertian; layanan harian juga menawarkan besok |
| `jadwal hari ini?`, `ipk saya?` | Langsung menjawab kebutuhan yang sudah jelas; tanda tanya tidak selalu memicu klarifikasi |
| `apa itu IPK?` | Definisi terkurasi: Indeks Prestasi Kumulatif |
| `jdwl bsk`, `ksr dong`, `brp ipkk sy` | Normalisasi variasi terpilih, lalu jalur layanan |
| `besok?` setelah `jadwal` | Melanjutkan topik jadwal; tanggal dihitung ulang dari perangkat |
| `1` atau `2` | Memilih opsi pada jawaban terakhir; tanpa opsi aktif meminta topik |
| `pengertiannya`, `datanya` | Memakai topik layanan terakhir; pergantian topik dan percakapan baru membuang rujukan lama |
| `semester 1` hingga `semester 14`, termasuk `smt8` | Pilihan kebutuhan sesuai tahap studi, tanpa menganggap semester isian sebagai profil terverifikasi |

Topik meliputi perkuliahan, KRS, IPK/IPS, nilai/KHS, presensi, pembayaran,
beasiswa, konseling, bimbingan, magang/KKP, KKN, tugas akhir, cuti,
kelulusan, dan progres studi. Pilihan tahap studi hanya pintasan bantuan:
tidak menetapkan kapan wajib magang/skripsi atau batas maksimal studi.

Tanggal **hari ini/besok/lusa/kemarin** mengikuti tanggal lokal perangkat,
bukan kalender akademik atau waktu server kampus. Tidak ada jadwal, tenggat,
atau nilai nyata yang ditambahkan. Sumber belum terhubung tetap dibedakan
dari hasil pencarian kosong, bukan dianggap tidak ada kuliah atau tagihan lunas.

`student_topics.dart` menyimpan kamus layanan; `student_intents.dart` memeriksa
pesan pendek dan periode; controller serta komponen chat menangani pilihan.
Tombol membawa pertanyaan lengkap sehingga tombol dari chat lama tidak memakai
topik baru. Variasi di luar pola yang dikenali tetap diperiksa aturan umum;
ini belum menjamin seluruh bahasa percakapan dapat dikenali.

Pengujian tambahan berada di `test/student_intents_test.dart`: variasi singkat,
pilihan tombol/angka, semester 1–14, perubahan topik, pergantian tanggal/tahun,
status belum terhubung, pemisahan pertanyaan belajar, dan tampilan HP.

## Data yang diteruskan ke model

Chat bebas mengirim bagian percakapan yang relevan, bukan profil login atau formulir lainnya. Tombol **Rapikan bahasa dengan AI** mengirim teks alasan/kronologi yang dipilih dan daftar perbaikan bahasa yang diperbolehkan. Kolom identitas, tanggal formulir, dan berkas tidak diambil otomatis; jika pengguna sendiri menulis identitas/tanggal dalam alasan, teks tersebut tetap ikut sebagai bagian alasan.

Model penyunting hanya memilih frasa yang benar-benar ada dari daftar aplikasi, misalnya `aku → saya`, `gak bisa → tidak dapat`, `makasih → terima kasih`. Aplikasi menerapkan penggantian itu sendiri, sehingga model tidak dapat menyisipkan diagnosis, tanggal, atau status persetujuan lewat hasil editor. Pengguna tetap menilai apakah perubahan sesuai makna. Teks asli dipertahankan saat gagal, dibatalkan, atau berubah selama permintaan berlangsung. Teks yang sudah dirapikan tidak melewati kewajiban bukti surat.

## Pengujian ulang

```powershell
flutter analyze
flutter test
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tool\local_ai\start.ps1
dart run tool/local_ai/evaluate.dart
```

Evaluator menulis `build/local-ai-quality.json`. Dua belas skenario mencakup definisi KRS, status KRS pribadi, aturan cuti, tutor pemrograman, pertanyaan lanjutan, pesan singkat, pilihan definisi/data, semester 14, dan penyuntingan alasan. Pertanyaan layanan yang tidak tersedia dijawab aplikasi; model hanya dipanggil untuk tutor dan pemilihan perbaikan bahasa. Laporan menyatakan sumber setiap hasil.

Pada pengujian awal, model `qwen2.5:1.5b` salah mengembangkan singkatan KRS dan sempat mengulang paragraf hingga keluaran terpotong. Definisi umum kini memakai glosarium aplikasi; prompt diberi acuan relevan, batas panjang, dan pengaturan pengulangan (`repeat_penalty=1.2`, `repeat_last_n=512`). Model tetap sama; tidak ada unduhan model baru atau pelatihan ulang. Konteks Ollama 8.192 token dengan batas generasi 1.536 token; keluaran tidak lengkap tetap ditolak.

Evaluasi terakhir menyelesaikan 12 alur dan mempertahankan batas data/pengiriman. Pesan singkat, lanjutan besok, pilihan definisi IPK, dan semester 14 dijawab aplikasi sesuai jalurnya. Pemeriksaan proyek menghasilkan 151 tes lulus, analisis tanpa temuan, dan build web berhasil. Ini bukan skor akurasi menyeluruh: penjelasan lanjutan model kecil masih dapat kurang presisi atau memakai analogi yang kurang tepat. Rute berbasis pola juga hanya menjamin kasus yang diuji, bukan seluruh variasi bahasa. Perluasan sumber resmi, autentikasi, dan tindakan backend harus diuji terpisah sebelum produksi.

Referensi teknis: [structured outputs Ollama](https://docs.ollama.com/capabilities/structured-outputs), [API Ollama](https://docs.ollama.com/api/chat).

## Perluasan pesan izin

`izin`, `ijin`, `surat izin`, `aku mau ijin`, `izin sakit hari ini`, dan `gak masuk kuliah` sekarang diarahkan aplikasi ke Izin Online. `izin?` menawarkan pengajuan, status, atau pengertian/alur; pilihan angka tetap berlaku. `status izin` menawarkan halaman status sesuai akun, tanpa mengaku membaca data yang belum diberikan kepada chat. Definisi surat izin memakai glosarium aplikasi, sehingga model tidak mengarang hubungan dengan KRS atau ujian sekolah. Lihat [alur BAP dan PDF](izin_online.md) untuk batas simulasi dan pengujiannya.
