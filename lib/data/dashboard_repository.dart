import 'dashboard_models.dart';

/// Kontrak untuk mengambil data. UI tidak perlu mengetahui database apa yang dipakai.
/// Kelak buat ApiDashboardRepository yang memanggil API HTTPS milik backend.
abstract class DashboardRepository {
  Future<DashboardData> load(String nim);
}

/// Tahap sekarang: hasil benar-benar kosong, tanpa data dummy akademik.
/// Login masih simulasi, tetapi beranda tidak mengarang data mahasiswa.
class EmptyDashboardRepository implements DashboardRepository {
  const EmptyDashboardRepository();
  @override
  Future<DashboardData> load(String nim) async => const DashboardData();
}
