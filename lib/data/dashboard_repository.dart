// Jembatan antara halaman beranda dan sumber datanya.
// Halaman cukup meminta load(nim), seperti memesan paket data dengan nomor mahasiswa.
// Sumber bawaan masih kosong; implementasi API nantinya dapat menggantikan sumber ini.

import 'dashboard_models.dart';

/// Kontrak untuk mengambil data. UI tidak perlu mengetahui database apa yang dipakai.
/// Kelak buat ApiDashboardRepository yang memanggil API HTTPS milik backend.
// Aturan yang harus diikuti oleh setiap penyedia data beranda.
abstract class DashboardRepository {
  // Kontrak: setiap sumber data wajib menyediakan cara mengambil paket beranda menurut NIM.
  Future<DashboardData> load(String nim);
}

/// Tahap sekarang: hasil benar-benar kosong, tanpa data dummy akademik.
/// Login masih simulasi, tetapi beranda tidak mengarang data mahasiswa.
// Penyedia awal yang menyatakan data belum tersedia, tanpa mengarang isi beranda.
class EmptyDashboardRepository implements DashboardRepository {
  // Objek tanpa pengaturan tambahan ini dapat dibuat sebagai konstanta.
  const EmptyDashboardRepository();
  @override
  // Segera selesai dengan paket kosong. Tidak ada koneksi jaringan atau database di sini.
  Future<DashboardData> load(String nim) async => const DashboardData();
}
