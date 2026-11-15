# Proposal transaksi telepon M1

Status: migrasi lokal dan integrasi RPC diotorisasi pengguna; implementasi lokal selesai 10 November 2026. RPC development dan koreksi PT409 telah diterapkan dengan otorisasi nomor 1 pada 10 November. Bukti final: [laporan M1](m1_account_foundation.md).

## Bukti dan dampak

Probe terisolasi `build/m1_phone_probe_test.dart` dengan SDK Supabase asli/fake HTTP mereproduksi: Biodata membuka nomor A; editor preferensi menyimpan B; Biodata menyimpan snapshot A dengan versi baris biodata yang masih cocok; trigger `private.sync_biodata_phone` mengembalikan telepon profil ke A. Probe gagal terhadap invariant bahwa B harus bertahan. Tidak ada data nyata diubah. Kode trigger lokal dan checksum migrasi remote mendukung mekanisme tersebut; pada tahap awal reproduksi database nyata belum diotorisasi; verifikasi cloud berikutnya kini tercatat di laporan M1.

P1 M1-07/M1-01: konflik versi hanya dalam satu tabel belum cukup untuk kolom bersama `phone`.

## Kontrak yang diusulkan

Tambahkan RPC `public.save_student_biodata(p_values jsonb, p_expected_profile_version timestamptz, p_expected_biodata_version timestamptz)` dengan `SECURITY INVOKER` dan `search_path=''`. Hanya `authenticated` boleh mengeksekusi; RLS pemilik+sesi dan privilege kolom tetap berlaku.

1. Ambil `auth.uid()` server; jangan menerima user_id/peran dari klien.
2. Kunci baris profil pemilik terlebih dahulu (`SELECT ... FOR UPDATE`) dan cocokkan versi profil asal editor. Versi tidak cocok/akses hilang harus menolak seluruh transaksi.
3. Kunci/cocokkan versi baris biodata. Versi null berarti editor melihat baris belum ada; INSERT harus menolak jika baris sudah dibuat editor lain.
4. Validasi whitelist field biodata; jangan memberi UPDATE kolom resmi. Simpan biodata dengan kolom eksplisit dalam transaksi yang sama. Trigger sinkronisasi telepon yang ada berjalan di bawah kunci profil tersebut.
5. Kembalikan row biodata serta versi profil baru. Gunakan kode konflik yang dipetakan klien tanpa mengekspos detail internal.
6. Form membawa kedua versi dari snapshot yang konsisten; konflik mempertahankan input dan meminta tinjau/muat ulang. Semua penulisan Biodata dari aplikasi memakai RPC tersebut.

Kunci profil harus didapat lebih dahulu untuk menyelaraskan urutan dengan editor preferensi. Jangan mengganti RLS, mengaktifkan bucket publik, atau memakai service_role di klien.

## Validasi yang wajib menyertai

- Editor profil A lalu biodata B, termasuk saat baris biodata belum ada.
- Biodata A lalu profil B.
- Dua transaksi bersamaan: satu konflik; tidak ada overwrite diam-diam.
- Rollback lengkap jika penulisan salah satu tabel gagal.
- Pengguna kedua, anon, sesi habis/dicabut ditolak; role/NIM/user_id tidak bisa diubah.
- Uji UI input tetap ada, muat ulang eksplisit, dan persistensi setelah relogin.

## Otorisasi dan penerapan

AGENTS.md melarang perubahan database, termasuk file migrasi, tanpa instruksi pengguna. Pengguna telah mengotorisasi migrasi lokal + implementasi RPC/client/test. File migrasi dibuat melalui Supabase CLI; penerapan development tetap langkah terpisah kecuali diotorisasi eksplisit. Ledger empat migrasi lama harus direkonsiliasi lebih dahulu sesuai laporan M1; jangan menjalankan db push/repair otomatis.

Pembaruan 10 November: konflik final memakai `PT409` agar PostgREST tidak melakukan retry `40001`. Delapan pasangan request HTTP serentak dan rollback constraint lulus. Filename migrasi lokal kini cocok ledger cloud; empat SQL lama tidak dijalankan ulang.
