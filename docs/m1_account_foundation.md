# M1 — Penutupan Fondasi Akun — Laporan implementasi

Pengerjaan dan pengujian: 9–15 November 2026; finalisasi serah terima: 15 November 2026 (Asia/Jakarta). Status: **ACCEPTED WITH TEST EXCEPTIONS** — 56 kriteria PASS sesuai bukti dan 4 pengecualian pengujian disetujui pengguna. Validasi salinan bersih dengan lockfile terbaru selesai. Bukan klaim seluruh tes lulus; M2/M3 belum dimulai.

## Baseline dan otorisasi

Branch `marcell-works`, HEAD `733f6bf`. Pada awal tugas hanya `AGENTS.md` dan `project_progress.md` sudah berubah; perubahan pengguna dipertahankan. Tidak ada commit/push. Otorisasi awal hanya migrasi lokal + RPC. Pada 10 November pengguna meminta nomor 1 (Supabase development) diselesaikan penuh, termasuk penerapan dan fixture terkontrol. Pada tahap tersebut nomor 2–3 masih direncanakan manual; tidak ada email dikirim atau akun pengguna diubah oleh tahap nomor 1. Otorisasi berikutnya mencakup uji akun nyata, salinan bersih, dan serah terima. Uji perangkat serta tunggu 10/30 menit diterima dengan pengecualian oleh pengguna; tidak dicatat sebagai PASS.

## Hasil implementasi

| Bagian | Hasil lokal | Batas |
|---|---|---|
| M1-01 Konflik preferensi | `ProfileChanges.expectedVersion` membawa timestamp mentah editor; UPDATE bersyarat, konflik mempertahankan input, reload dikonfirmasi | Delapan pasangan request HTTP bersamaan lulus (empat RPC/RPC dan empat profil/RPC) |
| M1-02 Foto/dokumen | ID acak, cleanup hanya penolakan pasti, objek hasil tidak pasti dipertahankan, gagal reload dibedakan dari commit gagal | Objek privat yatim tetap membutuhkan cleanup terkontrol; tidak ada cleanup otomatis baru |
| M1-03 Password | Validasi 12–256 karakter bersama, tanpa trim; penolakan Auth/hasil tidak pasti dibedakan; respons sesi lama tidak logout sesi baru | Perubahan password akun nyata telah diverifikasi pada nomor 2 |
| M1-04 Login/OTP | Regresi SDK, UI, handler dan adapter; jalur NIM/OTP dipertahankan | Reset/login nyata dan uji negatif OTP dicatat di bawah; TTL terisolasi dikecualikan |
| M1-05 Sesi | Guard generasi+session_id pada operasi bertahap, read dan cleanup; expiry/logout diuji lokal | Resume, refresh dan akses JWT nyata lintas perangkat perlu penerimaan |
| M1-06 Akses | RLS/privilege lama dipertahankan; RPC invoker; hak pemilik diuji lewat JWT fixture dan API cloud; unduhan memakai gateway sesi | Dua akun fixture nyata lulus; bukan pentest menyeluruh |
| M1-07 Identitas/biodata | RPC snapshot bersama + transaksi kunci profil lalu biodata menutup konflik telepon lintas editor | RPC dan koreksi PT409 sudah aktif di development |
| M1-08 Tanpa AI | `$env:CAMPUS_SKIP_AI='1'` melewati persiapan AI pada terminal; autostart normal tetap diuji | Tidak mematikan AI yang sudah berjalan atau mengubah profil host |
| M1-09 Kesinambungan | Pemetaan ledger dan kesamaan isi empat migrasi dibuktikan; source/package review disiapkan | Snapshot source bersih terverifikasi; clone Git lama tidak memuat patch yang belum di-commit |
| M1-10 Bukti | Laporan ini, matriks 60 ID, panduan profil/OTP/startup dan progres diperbarui | 56 kriteria PASS sesuai bukti; 4 diterima dengan pengecualian pengujian |

## Berkas utama yang berubah

- `lib/data/{profile_repository,student_profile,supabase_profile_repository,account_operation}.dart`: versi editor, kategori konflik/tidak pasti, guard sesi, cleanup aman.
- `lib/data/{biodata_repository,supabase_auth_service}.dart`: RPC dua versi, read/operasi sesi, klasifikasi perubahan password.
- `lib/features/profile/{edit_profile_page,biodata_form,profile_records}.dart` dan `lib/features/auth/reset_password_page.dart`: reload eksplisit, snapshot konsisten, pesan dan validasi UI.
- `supabase/migrations/20261109204541_m1_biodata_profile_transaction.sql`: dua fungsi invoker, tanpa memperluas privilege tabel.
- `test/m1_account_test.dart`, `test/change_password_widget_test.dart`, fixture Supabase dan tes profil/biodata/ekspor: regresi HTTP/widget dan fault injection.
- `tool/m1_biodata_sql_test.ts`: harness PostgreSQL memori dengan package terpatok; `tool/local_ai/{flutter_hook,test_autostart}.ps1`: mode tanpa persiapan AI beserta uji.
- README, panduan profil/OTP/autostart, laporan/proposal M1, dan bagian terkait `project_progress.md`: status implementasi dan batas verifikasi. `AGENTS.md` yang sudah berubah sejak awal tidak diedit oleh implementasi ini.

## Kontrak RPC dan urutan penerapan

Migrasi CLI `supabase/migrations/20261109204541_m1_biodata_profile_transaction.sql` menambahkan `load_student_biodata()` dan `save_student_biodata(jsonb,timestamptz,timestamptz)`. Keduanya SECURITY INVOKER dengan search_path kosong; EXECUTE hanya authenticated; owner berasal dari auth.uid(), whitelist mencegah field resmi masuk.

Probe awal mereproduksi telepon baru tertimpa editor Biodata lama. RPC membaca profil+Biodata dalam satu snapshot, mengunci profil terlebih dahulu, membandingkan kedua versi, dan menyimpan keduanya dalam transaksi. Regression test sekarang mencakup baris awal belum ada maupun sudah ada, arah perubahan sebaliknya, dan layanan belum dipasang. [Proposal/keputusan](m1_phone_transaction_proposal.md).

**Klien baru memerlukan RPC dan Edge Function `private-file`.** Keduanya kini aktif pada development. Cloud lain harus menerapkan seluruh migrasi dan fungsi sebelum memakai klien baru. Tidak ada fallback penulisan lama/unduhan langsung. Empat tab biodata lainnya tetap memakai kontrak lama dengan pemeriksaan versi.

Urutan development selesai: verifikasi hash → terapkan tiga migrasi M1 → selaraskan nama file lokal dengan timestamp ledger → deploy gateway → uji REST/Storage dua akun → cleanup. Empat migrasi lama tidak dieksekusi ulang; ledger cloud tidak ditulis ulang, tidak ada db reset/db push. Berikutnya penerimaan manual nomor 2–3.

## Verifikasi development — 10 November 2026

- **95 assertion cloud lulus** melalui `tool/m1_cloud_probe.ts`: JWT Auth fixture nyata (tanpa service-role pada request mahasiswa), snapshot/load/insert/update, konflik dua arah, **8 pasangan request bersamaan**, rollback constraint, whitelist/kolom resmi, anon/pemilik lain, foto/dokumen, unduhan byte identik, sesi expired/revoked dengan JWT yang masih berlaku. Angka termasuk assertion persiapan dan snapshot; bukan 95 skenario pengguna independen.
- Percobaan SQL terpisah juga menolak snapshot setelah transaksi profil lain commit dengan `PT409`. Observer lock tidak menangkap wait aktif, sehingga tidak diklaim sebagai bukti blocking lock serentak; bukti konkurensi utama adalah pasangan request HTTP nyata di atas.
- **33 assertion SQL lokal** lulus dengan migrasi terkini (24 sebelumnya + 9 kebijakan operasi Storage). Infrastruktur Auth/Storage PGlite tetap tiruan; suite tidak menggantikan hasil cloud.
- **248 tes Flutter lulus** setelah gateway; `dart analyze --fatal-infos` bersih. **22 tes Deno lulus** (15 OTP + 7 gateway), check/lint bersih. Build web final gateway lulus (93,4 detik), APK debug lulus (54 detik, 215 task); tidak dilakukan smoke perangkat/akun nyata. Tes ekspor perangkat menggunakan transport fixture khusus; pemanggilan gateway SDK dan penolakan tanpa fallback diuji terpisah.
- Probe menemukan dua masalah yang tidak terlihat pada mock: `40001` memicu retry PostgREST sampai timeout; URL Storage terautentikasi tetap memberi cache setelah expiry bahkan dengan `no-store`. Keduanya diperbaiki, bukan dilabeli PASS dari hasil awal.
- `20261110032150_m1_biodata_conflict_http409.sql` mengganti konflik bisnis menjadi `PT409`/HTTP 409. Klien mengenal PT409; kode lama tetap dikenali untuk kompatibilitas error.
- `private-file` versi 1 memvalidasi JWT melalui Auth.getUser, owner path, metadata RLS, dan status sesi lagi sesudah fetch. Respons POST berupa byte + `Cache-Control: private, no-store, max-age=0`; tidak mengeluarkan signed URL. Service-role hanya di Edge untuk mengambil path yang telah diotorisasi. `verify_jwt=false` dipakai karena handler melakukan autentikasi server sendiri, bukan karena endpoint publik tanpa pemeriksaan.
- `20261110033954_m1_private_file_gateway.sql` membatasi SELECT Storage mahasiswa ke operasi delete/delete_many. Direct read, signing, transform, S3 read, dan list tidak membuka byte; upload/delete owner tetap lulus. Flutter mengambil foto dan dokumen melalui gateway. Kedua bucket kosong sebelum gateway diterapkan; tidak ada objek pengguna yang perlu dipindah atau cache lama milik pengguna yang menjadi bagian migrasi ini.
- Seluruh fixture percobaan dibersihkan melalui Storage API lalu penghapusan Auth terarah. Pemeriksaan akhir: **0 akun fixture, 0 objek pada kedua bucket**; sesi/metadata fixture ikut terhapus lewat FK. Tidak ada reset password/OTP akun pengguna.
- Advisor sesudah perubahan: tiga INFO pada tabel private tanpa policy memang menutup akses langsung; WARN leaked-password protection nonaktif sudah ada sebelum M1. Tidak mengubah pengaturan Auth di luar lingkup.

Gateway/policy harus dipasang bersama versi klien ini. Klien lama yang mengunduh langsung tidak kompatibel dengan kebijakan baru. Berkas yang sudah diunduh ke perangkat tidak dapat ditarik kembali; jaminan gateway berlaku untuk request baru, bukan menghapus salinan lokal pengguna.

## Bukti otomatis dan build sebelum verifikasi cloud

- Source final: **247 tes Flutter lulus**, `flutter --no-version-check --suppress-analytics test --no-pub --reporter expanded`, exit 0. Subset 47 dan suite 244 sebelum RPC tidak dijumlahkan.
- `dart analyze --fatal-infos`: **No issues found**, exit 0. Flutter analyze sebelum RPC juga bersih; analyzer Dart langsung dipakai untuk hasil final karena startup wrapper Flutter sempat tertahan.
- Format source/test Dart yang diubah serta `deno fmt`/`deno lint` harness SQL telah diperiksa. `git diff --check` bersih.
- `deno check` login-with-nim dan password-reset: lulus. `deno lint supabase/functions/password-reset`: lulus. 15 tes Deno OTP: lulus, transport tiruan.
- `deno test --allow-read --allow-env --no-lock tool/m1_biodata_sql_test.ts`: lulus, **24 assertion** dalam 1 suite. PGlite 0.5.15 menjalankan SQL PostgreSQL dengan tiga migrasi aplikasi lama dan migrasi M1; infrastruktur Auth/Storage di-fixture. Menguji whitelist, versi hilang/stale, rollback setelah trigger, foreign owner, anon, expiry/revocation/disabled. Tidak menguji dua koneksi serentak atau layanan Supabase nyata.
- `powershell.exe -NoProfile -ExecutionPolicy Bypass -File tool/local_ai/test_autostart.ps1`: lulus. Tidak mengunduh model, tidak membuka browser, tidak mengubah hook global.
- Build web final: `flutter --no-version-check --suppress-analytics build web --no-pub` **lulus**, exit 0 (203,5 detik kompilasi); wasm dry run lulus. Ini build JavaScript biasa, bukan penerimaan runtime Wasm.
- Build Android final: `android/gradlew.bat -p android --offline --no-daemon --project-cache-dir <workspace>/build/m1-gradle-project :app:assembleDebug` **BUILD SUCCESSFUL**, exit 0; 215 task, 2 menit. JBR 25.0.3 dipilih hanya lewat JAVA_HOME proses; memakai cache dependency pengguna dan cache proyek terisolasi. Cache terpisah lama semula tidak lengkap; percobaan awal bukan bukti build final. Ada peringatan deprecation Gradle/AGP dan versi XML SDK, tanpa kegagalan build akhir. APK: `build/app/outputs/apk/debug/app-debug.apk`.
- Smoke web final pada Chrome, konteks browser terisolasi dan server loopback: login tampil, Lupa password terbuka, kembali ke login berhasil; tidak ada console error. Tidak ada kredensial diisi, email dikirim, atau sesi akun nyata diubah.
- `adb devices` pada 10 November tidak menemukan perangkat/emulator aktif. APK tidak dipasang; smoke dan penerimaan Android **NOT RUN**.
- Pemindaian 264 file source paket final tidak menemukan pola token administratif/Resend/GitHub/private-key. Paket mengecualikan .git, cache, model AI, .env, konfigurasi host, build, APK, dan log. Ini pemeriksaan pola dan ruang lingkup paket, bukan sertifikasi bebas semua data sensitif.
- Log rinci lokal di `build/m1-*.log` bersifat sementara. Hasil ringkas di dokumen ini tetap tersedia setelah clean. Screenshot test menggunakan identitas fixture, bukan dokumen/foto pribadi.

## Ledger dan pemeriksaan cloud

Proyek yang cocok dengan konfigurasi: `campus-app` (`taqmosufhapstehgeonz`). Pemeriksaan 9 November: ACTIVE_HEALTHY; login-with-nim dan password-reset ACTIVE versi 2. Sembilan tabel akun/profil/biodata/keuangan/berkas memiliki RLS; `student-avatars` dan `student-documents` privat. Ini metadata, bukan bukti bahwa semua request end-to-end telah lulus.

| Migrasi | Versi lokal awal | Versi remote/filename lokal final | MD5 setelah normalisasi CRLF/LF dan newline ujung, isi lain utuh |
|---|---|---|---|
| student_profiles | 20261030080318 | 20261030080557 | d6714fae6a5566bdc5110a906e63e2e5 |
| session_rpc_boundaries | 20261031082459 | 20261031082535 | 8be04ab7c8aaf611b368d6db0cbd0744 |
| student_biodata_sections | 20261101015234 | 20261101020002 | f73d0cf300dba24554d889de282fc191 |
| password_reset_otp | 20261102065453 | 20261102071019 | 4460abbc22e7eaaf7f2ae63b4fe4289b |

Hash lokal/remote cocok untuk setiap pasangan. Pada 10 November keempat filename lokal diselaraskan ke versi remote di atas tanpa mengubah SQL. Hash membandingkan normalisasi CRLF/LF dan newline ujung saja, bukan mengabaikan seluruh whitespace. Kesamaan history bukan bukti tidak pernah ada perubahan schema di luar migrasi.

| Migrasi M1 final (lokal = cloud) | MD5 normalisasi sama |
|---|---|
| `20261109204541_m1_biodata_profile_transaction.sql` | `047cb4a0c05c2432d993ad5997124604` |
| `20261110032150_m1_biodata_conflict_http409.sql` | `591747edfefa3b2cded2a7cf1b57681c` |
| `20261110033954_m1_private_file_gateway.sql` | `f54c4119882fe94bfa05b9b3558acf28` |

## Penerimaan akun nyata — uji terpilih selesai, batas waktu ditunda, 10–11 November 2026

Pengguna kemudian mengotorisasi Codex menjalankan nomor 2 melalui Chrome lokal, dengan password/OTP diisi langsung oleh pengguna. Nomor 3 tetap manual. Catatan tidak adanya perubahan akun pengguna di bagian development di atas berlaku untuk tahap nomor 1.

- Login akun development dikonfirmasi pengguna dan dashboard/Biodata diamati melalui UI (sekitar 17.03 WIB).
- Pada 17.12 WIB, simpan nama panggilan uji dan PNG sintetis berhasil kembali ke Biodata; foto pribadi tampil. Editor yang dibuka ulang mempertahankan nama uji dan avatar Pria. Telepon tidak diedit.
- Uji Batal: nama diubah menjadi penanda batal dan avatar Netral dipilih, lalu Batal. Editor dibuka kembali: nama uji tersimpan sebelumnya, avatar Pria, dan foto tetap ada. Perubahan batal tidak tersimpan.
- Dokumen PDF sintetis 608 byte diunggah pengguna melalui pemilih berkas; UI menampilkan Terunggah. Klik unduh berhasil melalui `private-file` (HTTP 200); blob unduhan browser bernama `m1-document.pdf` mempunyai SHA-256 `455f4768ea8e8a17fcb05ebaeef37faa2c34319bb83673d57f101522a5faf14a`, identik dengan fixture lokal. Penyimpanan fisik oleh browser belum dikonfirmasi. Dialog Hapus file dibatalkan, lalu Muat ulang: dokumen tetap Terunggah (sekitar 17.16–17.18 WIB).
- Reload browser mengembalikan aplikasi ke formulir login kosong. Setelah pengguna masuk lagi (sekitar 17.19 WIB), dashboard menampilkan nama/foto uji, editor mempertahankan avatar Pria, dan Berkas menampilkan PDF Terunggah. Persistensi lintas restart aplikasi web terbukti; restart native dan expiry absolut 30 menit belum dibuktikan.
- Form Ubah password menolak Simpan dengan isian kosong: "Password baru harus 12–256 karakter." Password/OTP dan sesi nyata masih berjalan/belum dibuktikan. Foto/nama uji dan PDF belum dipulihkan/dihapus; dipertahankan untuk uji akses sesi setelah reset, kemudian cleanup. Tidak ada password atau OTP dicatat.
- Pada kelanjutan 11 November, pengguna mengonfirmasi sudah kembali ke login setelah instruksi perubahan password. Browser pengujian lama dan server lokal tidak lagi aktif; server build yang sama dan konteks browser baru dibuka. Keberhasilan perubahan belum dinyatakan PASS sebelum penolakan password lama dan login password baru terbukti. Berakhirnya browser lama bukan bukti expiry/revocation aplikasi.
- Pengguna mengonfirmasi password lama ditolak pada 11 November. Pemeriksaan UI berikutnya masih menunjukkan halaman login, tetapi pesan penolakan tidak lagi terlihat setelah pengosongan input; bukti penolakan ini berasal dari konfirmasi pengguna. Kemudian dashboard diamati dan pengguna mengonfirmasi login terakhir memakai password baru setelah perubahan. Pada 11 November sekitar 15.44 WIB, foto/nama uji dan metadata PDF tetap terbaca. Sesi ini dipertahankan untuk uji revocation; konteks browser terpisah disiapkan untuk OTP.
- Pada 11 November sekitar 15.49 WIB, pengguna mengonfirmasi OTP diterima dan password diganti melalui pemulihan. Pemeriksaan berikutnya menunjukkan halaman login; pesan sukses sudah tidak terlihat. Bukti delivery/reset berasal dari konfirmasi pengguna. Konteks sesi sebelum reset tidak lagi terdaftar pada alat browser, sehingga tidak ada bukti revocation UI dari percobaan ini. Login password terbaru, penolakan password sebelum reset, dan skenario OTP negatif masih menunggu.
- Setelah reset OTP, pengguna mengonfirmasi password sebelumnya ditolak dan password terbaru berhasil. Dashboard serta metadata PDF diamati sekitar 15.54 WIB. Untuk mengulangi bukti revocation, tab sesi login dipertahankan dan tab pemulihan terpisah dibuka dalam konteks browser yang sama (sesi aplikasi hanya memori tiap tab).
- Sekitar 15.59–16.01 WIB pada 11 November, lima percobaan UI dengan kode sintetis salah menghasilkan lima respons HTTP 400 dan pesan kode salah/kedaluwarsa/sudah dipakai. Kode uji memakai karakter yang tidak pernah dihasilkan generator, tetapi lolos format input. Tidak membaca password pengguna. Penolakan kode asli setelah lima percobaan, TTL, replay, serta invalidasi setelah resend belum dibuktikan. Countdown resend dalam keadaan disabled juga teramati; ini baru bukti UI, belum bukti cooldown server.
- Sekitar 16.10 WIB, kode asli ditolak setelah pengguna menunggu sekitar 11 menit. Karena challenge sudah terkena lima percobaan salah sekaligus melewati TTL, hasil ini tidak membuktikan batas percobaan atau TTL secara terpisah. Kode baru diminta sekali melalui UI; respons permintaan diterima dan cooldown 59 detik disabled terlihat. Sesi sebelum reset masih diuji dengan unduhan dokumen baru sebelum reset.
- Uji revocation ulang berhasil: sesi yang dipakai login setelah reset pertama (setelah 15.49 WIB) masih mengunduh PDF HTTP 200 sekitar 16.10 WIB; setelah reset berikutnya yang dikonfirmasi pengguna, permintaan dari tab sama menghasilkan HTTP 401 sekitar 16.13 WIB, sebelum batas absolut 30 menit. Tab tidak di-refresh/logout. Pembacaan Biodata melalui UI menampilkan Akses biodata tidak tersedia. Masuk ulang. HTTP 200 pada metadata/RPC tidak membuktikan data dikembalikan; body tidak diperiksa. Auto-review menolak pengambilan detail request karena potensi token/data privat, sehingga verifikasi memakai UI dan metadata status yang aman. Login password terakhir dan cleanup masih menunggu.
- Setelah reset terakhir, login password terbaru dikonfirmasi pengguna dan dashboard diamati sekitar 16.24 WIB. Pengguna mengonfirmasi PDF unduhan tersimpan dan bisa dibuka. Sekitar 16.26–16.28 WIB, profil dipulihkan ke nama Dante, tanpa foto, avatar Pria; telepon tidak diedit. PDF uji dihapus melalui konfirmasi UI; DELETE metadata/Storage HTTP 200, reload lima slot kosong. Dashboard menampilkan nama awal. Pengamatan sesi absolut baru dimulai; jangan menyamakan revocation sebelumnya dengan expiry 30 menit.
- Pada 16.34 WIB, hanya tab OTP tersisa; tab sesi 30 menit sebelumnya tidak lagi terdaftar, sehingga pengamatan itu tidak dianggap lulus. Pengamatan diulang: pengguna login dan dashboard teramati 16.36 WIB, kedua tab diminta tetap terbuka. Challenge OTP terpisah hanya memiliki satu permintaan HTTP 200, belum ada konfirmasi; pengujian kedaluwarsa dijadwalkan setelah sekurangnya 11 menit dari pengamatan 16.34 WIB, tanpa resend/percobaan salah.
- Pengujian lanjutan kemudian ditunda atas permintaan pengguna sebelum hasil tunggu TTL OTP dan sesi absolut diamati. Jadwal pengamatan di atas dibatalkan; waktu yang berlalu sendiri bukan bukti PASS. Tidak ada reset tambahan dari form uji TTL. Hasil yang sudah terbukti dipertahankan; AT-006/008/043/044 tetap belum terverifikasi lengkap. Nomor 2 belum ditutup sebagai lulus penuh.
- Pada kelanjutan sekitar 22.33 WIB, pengguna meminta uji batas percobaan, replay/resend/cooldown dan resume/simulasi jam dilanjutkan; tunggu TTL 10 menit dan sesi 30 menit tetap dikesampingkan. Browser/server dibuka kembali. Cooldown server teramati melalui dua form terpisah: permintaan pertama menerbitkan challenge pada 15:33:35 UTC, permintaan kedua pada umur sekitar 9 detik tidak mengubah issued_at/expires_at; attempts tetap 0 dan belum dikonsumsi. Pemeriksaan SQL hanya baca waktu/status/jumlah percobaan untuk akun uji, tanpa OTP, hash, password, atau token.
- Batas lima percobaan terisolasi lulus pada kelanjutan malam: lima submit kode salah ditolak, SQL read-only menunjukkan attempts=5, unexpired=true, consumed=false. Submit kode asli yang telah diisi pengguna di form kedua ditolak dengan kondisi server yang tetap sama. Tidak ada ketergantungan pada kedaluwarsa untuk hasil ini. Kode baru kemudian diminta untuk uji penggantian/replay.
- Invalidasi setelah resend terisolasi lulus sekitar 22.41 WIB: challenge terbit 15:39:03 UTC masih unexpired, attempts=0, consumed=false. Resend Form A menerbitkan challenge pengganti 15:41:23 UTC. Form B mengirim kode sebelumnya dan ditolak; challenge baru unexpired, consumed=false, attempts=1. Kode sebelumnya belum kedaluwarsa atau habis percobaan saat diganti. Replay kode yang telah dipakai masih menunggu uji terpisah.
- Replay terisolasi lulus sekitar 22.44 WIB: Form A memakai kode terbaru dan menampilkan Password berhasil diganti; SQL menunjukkan consumed=true, attempts=2, unexpired=true. Form B memakai kode sama, ditolak tanpa rate-limit, dan status tetap consumed=true/attempts=2/unexpired=true. Jadi penolakan terjadi setelah pemakaian, bukan TTL atau lima kesalahan. Form B kemudian ditutup ke login untuk membersihkan isian rahasia. Login terbaru untuk uji resume/simulasi jam masih menunggu.
- Login dengan password terakhir diamati untuk uji resume. Baseline sesi server started_at=2026-11-11 15:47:01 UTC, expires_at=16:17:01 UTC. Simulasi JavaScript Date +2 jam lalu -2 jam disertai Muat ulang beranda: aplikasi memanggil clock simulasi masing-masing 3 dan 2 kali, dashboard tetap tampil; expires_at server tidak berubah, revoked=false, unexpired=true. Override dipulihkan pada finally dan dilindungi watchdog. Ini simulasi jam browser, bukan perubahan jam Windows/perangkat fisik atau bukti melewati 30 menit. Perintah pindah tab otomatis tidak menghasilkan event visibility/focus. Pengguna kemudian mengonfirmasi minimalkan Chrome 5–10 detik, kembali, dan Muat ulang beranda normal; dashboard diamati kembali, expires_at tetap sama. Event visibility/focus tetap tidak terekam oleh alat, sehingga bukti resume adalah konfirmasi pengguna + UI/status server, bukan bukti callback lifecycle Flutter. Listener diagnostik dibersihkan.
- Uji terpilih pada akhir 11 November selesai: batas lima percobaan, cooldown server, invalidasi kode lama oleh resend, replay kode bekas, simulasi jam browser ±2 jam, serta smoke resume berdasarkan konfirmasi pengguna. Tidak ada perubahan source aplikasi/schema/deploy pada tahap penerimaan ini. AT-006 tetap ditunda; AT-044 belum lengkap karena TTL; AT-008 belum lengkap untuk jam perangkat fisik dan pembuktian pascabatas. AT-057/059 tetap nomor 3. Saat uji tersebut selesai M1 belum diterima penuh; keputusan penerimaan dengan pengecualian dicatat pada bagian serah terima berikut.
- ZIP 10 November merupakan arsip development historis. Paket 15 November pada bagian akhir memuat pembaruan penerimaan dan serah terima.

## Matriks penerimaan

PASS berarti **bukti sesuai lingkup yang disebut**, bukan penerimaan semua perangkat. BLOCKED berarti bukti wajib belum lengkap. Hasil akhir penerimaan: **56 PASS sesuai lingkup bukti, 4 ACCEPTED EXCEPTION** (AT-006/008/044/057). ACCEPTED EXCEPTION berarti pengguna menerima tanpa menyelesaikan subuji yang disebut, bukan tes berhasil. Tidak ada kolom kosong. Semua uji akun nyata yang belum dilaksanakan tetap NOT RUN; tidak berubah menjadi PASS karena mock lulus.

| ID | Kriteria | Status | Bukti / pekerjaan tersisa |
|---|---|---|---|
| M1-AT-001 | Login akun pengembangan dengan NIM/password benar. | PASS (web nyata) | Pengguna memasukkan kredensial langsung; dashboard dan Biodata teramati 10 November |
| M1-AT-002 | Identitas/password salah ditolak tanpa detail pemetaan akun. | PASS (lokal) | supabase_auth_test; penolakan 401/429/503 |
| M1-AT-003 | Profil hilang/nonaktif tidak membuka dashboard palsu. | PASS (lokal) | supabase_auth_test + m1_account_test; profil hilang/nonaktif |
| M1-AT-004 | Klik ganda/race login-logout tidak menghidupkan sesi lama. | PASS (lokal) | supabase_auth_test; login/logout race |
| M1-AT-005 | Restart meminta login; profil server tetap tersimpan. | PASS (web nyata) | Reload web meminta login; setelah masuk kembali nama/foto dan dokumen tetap ada. Restart native belum diuji |
| M1-AT-006 | Batas 30 menit ditegakkan UI dan backend. | ACCEPTED EXCEPTION | Expiry backend fixture sudah diuji pada nomor 1; pengamatan UI akun nyata 30 menit belum selesai dan ditunda atas permintaan pengguna |
| M1-AT-007 | Refresh/aktivitas tidak memperpanjang batas. | PASS (lokal) | supabase_auth_test; status tidak memperpanjang budget |
| M1-AT-008 | Resume dan perubahan jam perangkat tidak memperpanjang akses. | ACCEPTED EXCEPTION | Simulasi Date browser ±2 jam tidak mengubah expires_at server dan dashboard tetap bekerja. Pengguna mengonfirmasi resume singkat normal; UI/status server cocok, tetapi event lifecycle tidak terekam alat. Perubahan jam OS/perangkat fisik dan penolakan setelah batas waktu belum diuji |
| M1-AT-009 | Logout menutup halaman privat dan membersihkan state. | PASS (lokal) | widget_test, profile_test, supabase_auth_test; state lokal |
| M1-AT-010 | Respons lama tidak mencemari akun berikutnya. | PASS (lokal) | m1_account_test; respons password/upload sesi lama; regresi chatbot |
| M1-AT-011 | Simpan preferensi sah berhasil dan terbaca setelah login ulang. | PASS (web nyata) | Nama panggilan uji tampil di dashboard setelah reload dan login ulang |
| M1-AT-012 | Dua editor berurutan menolak snapshot lama. | PASS (lokal) | m1_account_test + SQL lokal; dua snapshot profil/Biodata |
| M1-AT-013 | Dua simpan bersamaan tidak menimpa versi tanpa kontrol. | PASS (cloud) | 8 pasangan request HTTP serentak; hanya satu penulisan sukses, hasil pemenang dibaca kembali |
| M1-AT-014 | Konflik mempertahankan input dan data yang sudah sah. | PASS (lokal) | profile_widget_test; input bertahan, dialog reload batal/lanjut |
| M1-AT-015 | Batal edit tidak menyimpan. | PASS (web nyata) | Nama dan avatar diubah lalu Batal; editor dibuka ulang mempertahankan nama, avatar, dan foto sebelumnya |
| M1-AT-016 | Pergantian tab/back pada biodata menghormati perubahan belum disimpan. | PASS (lokal) | profile_widget_test + biodata_widget_test; konfirmasi pindah tab |
| M1-AT-017 | Field resmi dan role tidak dapat diedit melalui request mahasiswa. | PASS (cloud) | PT409/whitelist + PATCH role/NIM ditolak pada JWT mahasiswa |
| M1-AT-018 | Email kontak tidak mengubah email Auth. | PASS (lokal) | biodata_test + SQL lokal; tidak memanggil Auth saat edit kontak |
| M1-AT-019 | Identitas dashboard/Biodata/chat/form tetap konsisten. | PASS (lokal) | RPC dua versi + m1_account_test + SQL lokal; regresi identitas/widget |
| M1-AT-020 | Null akademik tetap belum tersedia, bukan nilai contoh. | PASS (lokal) | dashboard_data_test + profile_test; null tetap belum tersedia |
| M1-AT-021 | Dante tanpa foto menampilkan avatar male. | PASS (lokal) | profile_test + avatar render; fixture tanpa foto |
| M1-AT-022 | female/neutral dan varian lama fallback bekerja. | PASS (lokal) | profile_test + profile_widget_test |
| M1-AT-023 | Foto sah mendapat prioritas; ganti varian tidak menghapusnya. | PASS (lokal) | profile_test; varian mempertahankan foto |
| M1-AT-024 | Hapus foto kembali ke varian yang dipilih. | PASS (lokal) | profile_test; hapus foto memakai avatar pilihan |
| M1-AT-025 | Foto rusak/besar/format tidak didukung ditolak tanpa kehilangan foto lama. | PASS (lokal) | biodata_test + profile_test; decode, ukuran dan format |
| M1-AT-026 | Metadata commit dengan respons hilang tidak menyebabkan foto aktif dihapus. | PASS (lokal) | m1_account_test; PATCH commit lalu respons hilang |
| M1-AT-027 | Penolakan metadata yang pasti ditangani dan cleanup sesuai hasil. | PASS (lokal) | m1_account_test; 42501/conflict cleanup hanya objek baru |
| M1-AT-028 | Gagal hapus foto lama tidak merusak referensi baru. | PASS (lokal) | m1_account_test; kegagalan DELETE objek lama |
| M1-AT-029 | Gagal reload setelah commit memberi pesan tersimpan/perlu muat ulang. | PASS (lokal) | m1_account_test; commit sukses lalu reload gagal |
| M1-AT-030 | Pilihan/foto konsisten setelah simpan dan login ulang. | PASS (web nyata) | Foto sintetis tampil setelah reload/login ulang; editor masih memilih avatar Pria |
| M1-AT-031 | Upload, baca, unduh/ekspor, dan hapus dokumen uji bekerja. | PASS (web + konfirmasi pengguna) | PDF diunggah lewat UI, blob identik dengan fixture, pengguna mengonfirmasi unduhan tersimpan/bisa dibuka. Hapus lewat dialog UI berhasil; muat ulang menampilkan lima slot kosong, DELETE metadata/Storage HTTP 200 |
| M1-AT-032 | Pembatalan pemilih file atau ekspor tidak menghapus data. | PASS (lokal) | profile_export_test; pembatalan share mempertahankan metadata |
| M1-AT-033 | Ganti dokumen mempertahankan versi lama sampai penggantian sah. | PASS (lokal) | biodata_test + m1_account_test; penggantian setelah metadata |
| M1-AT-034 | Respons metadata hilang tidak membuat objek aktif dibersihkan. | PASS (lokal) | m1_account_test; INSERT/PATCH commit respons hilang |
| M1-AT-035 | Konflik dokumen ditangani tanpa penimpaan diam-diam. | PASS (lokal) | m1_account_test; versi dokumen lama ditolak |
| M1-AT-036 | Batas tipe/ukuran diperiksa dan pesan sesuai. | PASS (lokal) | biodata_test; MIME, ukuran, nama aman |
| M1-AT-037 | Akses akun lain/anon ke metadata dan objek ditolak. | PASS (cloud) | Dua akun fixture: metadata, download, upload, delete, signed URL dan anon diuji; foto juga terisolasi |
| M1-AT-038 | Sesi habis/dicabut menolak akses berkas. | PASS (cloud) | Gateway menolak dokumen/foto dengan JWT valid setelah app session expired/revoked; direct Storage ditutup |
| M1-AT-039 | Hasil operasi tidak pasti mengarahkan verifikasi/reload. | PASS (lokal) | ProfileUncertain + widget/profile tests |
| M1-AT-040 | Tidak ada perubahan ke bucket publik. | PASS (lokal) | metadata remote 9 November: kedua bucket public=false; tidak diubah |
| M1-AT-041 | Validasi email/kode/password/konfirmasi sesuai aturan. | PASS (lokal) | password_reset_widget_test + change_password_widget_test + supabase_auth_test |
| M1-AT-042 | Request kode terdaftar/tidak terdaftar mempunyai respons aman. | PASS (lokal) | handler_test.ts; respons request aman |
| M1-AT-043 | Cooldown dan batas percobaan ditegakkan server. | PASS (web + status server) | Dua form/request berjarak 9 detik tidak mengubah issued_at/expires_at. Lima kode salah meningkatkan attempts dari 0 ke 5; kode asli dari form lain kemudian ditolak saat unexpired=true dan consumed=false, attempts tetap 5. Verifikasi 11 November sekitar 22.33–22.38 WIB |
| M1-AT-044 | Salah/kedaluwarsa/replay ditolak; kode baru menggantikan kode lama. | ACCEPTED EXCEPTION | Kode salah, invalidasi setelah resend, dan replay terbukti terpisah lewat UI/status server. Replay ditolak saat consumed=true, unexpired=true, attempts=2. Kriteria gabungan belum PASS penuh karena TTL terisolasi tetap ditunda atas permintaan pengguna |
| M1-AT-045 | Kegagalan email/config tidak mengaku email sudah sampai. | PASS (lokal) | handler_test.ts + services_test.ts; kegagalan pengiriman/config |
| M1-AT-046 | Uji UI nyata yang diotorisasi menerima kode dan menyelesaikan reset. | PASS (konfirmasi pengguna) | 11 November: pengguna menerima OTP dan mengganti password; halaman login diamati sesudahnya. Pesan sukses tidak ditangkap; login terbaru diverifikasi terpisah pada AT-047 |
| M1-AT-047 | Password baru berhasil login; password lama ditolak. | PASS (web + konfirmasi pengguna) | 11 November sekitar 15.54 WIB: pengguna mengonfirmasi password sebelum reset OTP ditolak dan password terbaru berhasil; dashboard serta metadata PDF diamati sesudah login |
| M1-AT-048 | Sesi sebelum reset tidak dapat membaca data privat. | PASS (web nyata) | Percobaan ulang 11 November: unduhan tab sebelum reset HTTP 200 sekitar 16.10, sesudah reset HTTP 401 sekitar 16.13; tab tidak di-refresh/logout. Pembacaan Biodata menampilkan Akses biodata tidak tersedia. Masuk ulang. Respons HTTP 200 RPC sendiri tidak dianggap bukti akses |
| M1-AT-049 | Perubahan password saat login bekerja dan meminta login ulang. | PASS (web nyata) | Pengguna mengubah password dan mengonfirmasi kembali ke login; password lama ditolak menurut pengguna, login password baru dikonfirmasi dan dashboard diamati 11 November |
| M1-AT-050 | Gangguan respons password tidak memberi kepastian palsu. | PASS (lokal) | m1_account_test + change_password_widget_test; tidak ada kepastian palsu |
| M1-AT-051 | Fondasi aplikasi dapat dijalankan tanpa model Ollama siap. | PASS (lokal) | test_autostart.ps1; CAMPUS_SKIP_AI; smoke login web |
| M1-AT-052 | Autostart normal, argumen, exit code, dan isolasi proyek tetap benar. | PASS (lokal) | test_autostart.ps1; help/test/subfolder/proyek lain/argumen/exit code |
| M1-AT-053 | HP/teks besar/keyboard dapat digunakan tanpa overflow penghalang. | PASS (lokal) | widget suites 320/800/1440, teks 200%, keyboard; inspeksi render profil 320 |
| M1-AT-054 | Flutter format/analyze/test pada perubahan akhir mempunyai hasil aktual. | PASS (lokal) | lihat hasil validasi final di atas |
| M1-AT-055 | Edge check/lint/test yang relevan mempunyai hasil aktual. | PASS (lokal) | Deno check/lint dan 15 tes OTP |
| M1-AT-056 | Tes akses database development yang relevan tercatat. | PASS (cloud) | 95 assertion API cloud + 33 assertion SQL lokal; fixture bersih |
| M1-AT-057 | Web dan Android development build serta smoke test tercatat. | ACCEPTED EXCEPTION | Build web/APK dari source dan cache dependensi bersih berhasil. Pengguna mengecualikan uji runtime HP/emulator; build bukan smoke perangkat |
| M1-AT-058 | Dokumentasi tidak lagi mengarahkan penggunaan auth dummy sebagai produksi. | PASS (lokal) | README dan panduan akun membedakan dummy pengujian, produksi, simulasi izin |
| M1-AT-059 | Paket source dan konfigurasi tim dapat dipahami/reproduksi. | PASS (salinan bersih) | Snapshot 270 file tanpa hasil build/cache dipulihkan memakai cache Pub/Gradle baru; analyze, 248 tes, web dan APK berhasil. Paket/manifest diverifikasi. SDK/JDK/Android SDK sudah terpasang; bukan provisioning mesin kosong atau clone HEAD lama |
| M1-AT-060 | Tidak ada secret, password, OTP, atau dokumen pribadi pada bukti/ZIP. | PASS (lokal) | pemindaian paket sebelum penyerahan; tidak memasukkan secret/akun nyata/log mentah |

## Salinan bersih dan serah terima — finalisasi 15 November 2026

Pemeriksaan paket pada 15 November menemukan lockfile working tree berbeda dari snapshot 11 November. Lockfile terbaru dipertahankan; snapshot baru `build/m1-clean-final` beserta cache Pub/Gradle baru diuji sampai selesai sebelum pengemasan. Hasil awal 11 November tetap historis: 248 tes (51 detik), kompilasi web 157 detik, dan Gradle 563 detik. Artefak final menggunakan hasil pengulangan 15 November berikut.

- Sumber: 270 file Git tracked/untracked yang masih ada pada working tree `marcell-works`, HEAD dasar `733f6bf`. Snapshot di `build/m1-clean-final` tidak membawa `.git`, `.dart_tool`, output build, `.env`, `android/local.properties`, model AI, atau cache dependency. Patch belum di-commit/push; clone HEAD lama tidak setara dengan paket ini.
- Lingkungan yang sudah terpasang: Flutter 3.47.5, Dart 3.13.4, Android SDK, JBR Android Studio 25. Gradle 9.3.1 diunduh ke cache baru. Cache `PUB_CACHE=build/m1-final-pub-cache` dan `GRADLE_USER_HOME=build/m1-final-gradle-cache` awalnya kosong. Pengujian ini membuktikan reproduksi source/dependency, bukan pemasangan SDK/JDK/OS dari nol.
- `flutter pub get --enforce-lockfile`: berhasil, hash `pubspec.lock` tidak berubah: SHA-256 `3ff0a6e48ff0f69fdbad9f7ca8bc6d89f67282daf478b0341e541b1a64548a45`. `dart --suppress-analytics analyze --fatal-infos`: tidak ada masalah, exit 0. Gangguan izin metadata telemetry pada percobaan historis 11 November telah terselesaikan dengan analytics dinonaktifkan.
- `flutter test --no-pub --reporter expanded`: **248 lulus**, sekitar 74 detik. `flutter build web --no-pub`: berhasil, kompilasi 227 detik. `flutter build apk --debug --no-pub`: berhasil, Gradle 758,5 detik. Ketiga proses exit 0. Perintah Flutter memakai `--no-version-check --suppress-analytics` dan `CAMPUS_SKIP_AI=1`. Seluruh hasil ini berasal dari eksekusi 15 November terhadap lockfile terbaru; durasi bukan benchmark.
- Android masih memberi warning native-access Java, SDK XML, serta source/target Java 8 dari dependency. Tidak ada kegagalan build. Tidak ada perangkat/emulator dijalankan pada tahap ini.
- Source aplikasi/config/test yang dikemas cocok hash snapshot teruji; hanya dokumentasi berubah sesudah build. Panduan ekstraksi/setup berada di README. CRC arsip dan SHA-256 seluruh file pada manifest diperiksa saat pengemasan; pemeriksaan pola secret dibatasi pada file source paket. Tidak menyertakan password, OTP, token privat, screenshot akun, log mentah, cache, atau APK di ZIP source.
- Log lokal: `build/m1-final-pub-get.log`, `m1-final-analyze.log`, `m1-final-tests.log`, `m1-final-web.log`, `m1-final-android.log`. File build/log dapat hilang saat clean; ringkasan ini adalah bukti handover yang dipertahankan di source.

Pengguna menerima pengecualian: tunggu OTP 10 menit, sesi absolut 30 menit, dan pengujian perangkat (termasuk perubahan jam OS/runtime HP/emulator). Bukti simulasi browser/resume tetap dicatat sesuai batasnya. Empat kriteria gabungan yang terkait diberi ACCEPTED EXCEPTION, bukan PASS. Penerimaan M1 ini tidak menyatakan kesiapan produksi atau menghapus kebutuhan pemeriksaan apabila lingkup/perangkat berubah.

## Pekerjaan berikutnya

1. Gunakan paket source/APK 15 November dan backend development yang sudah mempunyai seluruh migrasi serta `private-file`.
2. Commit/push patch dan sinkronisasi clone tim hanya setelah otorisasi pengguna; tidak dilakukan pada handover ini.
3. M2 Jadwal Nyata dan M3 Chatbot Jadwal masih roadmap. Mulai hanya setelah tugas berikutnya diberikan; pertahankan riwayat pengecualian tes M1.

## Referensi implementasi

- [Supabase: SQLSTATE 40001 menyebabkan retry](https://supabase.com/kb/troubleshooting/high-cpu-and-infinite-transaction-retries-when-using-custom-error-codes-in-rpc-functions-77326b), [PostgREST custom HTTP errors](https://docs.postgrest.org/en/stable/references/errors.html#raise-errors-with-http-status-codes).
- [Supabase: cache privat sesudah logout](https://supabase.com/kb/troubleshooting/storage-private-bucket-files-still-accessible-after-remove-access-or-logout) mendasari gateway; [operation-aware Storage policies](https://supabase.com/docs/guides/storage/schema/helper-functions) menutup jalur langsung.
- [Advisor leaked-password protection](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection) tetap catatan konfigurasi sebelum M1.

- Perilaku Auth Dart dikonfirmasi dengan [dokumentasi updateUser](https://supabase.com/docs/reference/dart/auth-updateuser) dan [signOut](https://supabase.com/docs/reference/dart/auth-signout).
- [Dokumentasi RLS Supabase](https://supabase.com/docs/guides/database/postgres/row-level-security) mendukung keputusan mempertahankan policy dan hak pemanggil.
- [PGlite API](https://pglite.dev/docs/api) dan [filesystem memori](https://pglite.dev/docs/filesystems) mendasari harness PostgreSQL lokal; bukan teknologi backend aplikasi baru.
- Changelog Markdown Supabase gagal diambil pada awal sesi (content-type tool/DNS shell); API yang digunakan diverifikasi melalui dokumentasi resmi dan versi SDK proyek. Tidak ada upgrade dependency Flutter.

## Paket review

Paket lokal: `build/review/campus_app_M1_20261115.zip`. Berisi source/configuration/assets/tests/docs yang diperlukan, termasuk migrasi RPC dan harness SQL. `MANIFEST.sha256` memetakan setiap file ke hash; `REVIEW_METADATA.json` mencatat branch/HEAD, lingkup verifikasi, dan tiga migrasi M1 + gateway sudah diterapkan dan hasil cloud lulus. Paket tidak berisi build/cache/model/downloaded dependency atau artefak akun nyata. Uji ekstraksi/CRC dan verifikasi seluruh hash dilakukan sebelum penyerahan.

APK debug disediakan terpisah di `build/review/campus_app_M1_20261115-debug.apk` (hasil salinan bersih). SHA-256 kedua artefak tersedia di `build/review/campus_app_M1_20261115.sha256`. Jangan menyamakan keberhasilan build atau ZIP dengan penerimaan M1. Build/ZIP dapat hilang saat clean; laporan ini tetap di source.
