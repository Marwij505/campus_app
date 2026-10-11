// Uji aturan data beranda tanpa perlu menggambar halaman.
// Memeriksa data kosong, pembagian kemajuan, urutan jadwal, dan jumlah kolom.
// expect(nilai, harapan) membandingkan hasil dengan aturan yang kita tetapkan.
// Angka dan nama uji sengaja dibuat tetap agar hasil bisa diulang kapan saja.

import 'package:flutter_test/flutter_test.dart';

import 'package:campus_app/core/responsive_layout.dart';
import 'package:campus_app/data/dashboard_models.dart';
import 'package:campus_app/data/dashboard_repository.dart';

// Kumpulkan empat skenario pemeriksaan logika data.
void main() {
  // Pastikan sumber awal jujur mengembalikan data kosong, bukan profil atau nilai buatan.
  test('Repository awal tidak mengisi data akademik buatan', () async {
    // Minta paket beranda untuk akun uji seperti permintaan halaman asli.
    final data = await const EmptyDashboardRepository().load('akun-uji');
    // isNull menandakan informasi belum diketahui; berbeda dari angka nol.
    expect(data.student, isNull);
    expect(data.progress.gpa, isNull);
    expect(data.progress.currentSemester, isNull);
    expect(data.outstandingBillCount, isNull);
    // isEmpty menandakan daftar tidak memiliki anggota, bukan kegagalan koneksi.
    expect(data.classes, isEmpty);
    expect(data.announcements, isEmpty);
    expect(data.news, isEmpty);
    expect(data.counseling, isEmpty);
    expect(data.guides, isEmpty);
    expect(data.semesters, isEmpty);
    expect(data.gradeComposition, isEmpty);
    expect(data.courseStatus, isEmpty);
  });

  // Uji nilai hilang, target nol, angka tidak valid, dan batas rasio kemajuan.
  test('Progress yang belum diketahui tetap null dan pembagian aman', () {
    // Data atau target yang hilang tidak boleh menghasilkan persentase palsu.
    expect(safeRatio(null, 144), isNull);
    expect(safeRatio(86, null), isNull);
    expect(safeRatio(86, 0), isNull);
    // NaN berarti bukan angka yang sah untuk perhitungan, sehingga hasil harus null.
    expect(safeRatio(double.nan, 4), isNull);
    // Nilai melebihi target dibatasi menjadi 1 atau 100 persen.
    expect(safeRatio(200, 144), 1);
    // Nilai negatif dibatasi menjadi nol supaya panjang batang tidak negatif.
    expect(safeRatio(-1, 144), 0);
    // Contoh normal: 72 dari 144 adalah setengah atau 50 persen.
    expect(safeRatio(72, 144), .5);
  });

  // Uji pemilihan kelas aktif dan urutan waktu tanpa mengubah daftar masukan.
  test('Jadwal diurutkan, kelas aktif diutamakan, kelas selesai diabaikan', () {
    // Bekukan waktu acuan pada pukul 10 supaya status kelas tidak bergantung hari tes dijalankan.
    final now = DateTime(2026, 10, 11, 10);
    // Pembuat jadwal uji: tiap kelas berdurasi dua jam dari jam yang diberikan.
    ClassSchedule item(int hour) => ClassSchedule(
      code: 'uji',
      title: 'Kelas uji',
      startsAt: DateTime(2026, 10, 11, hour),
      endsAt: DateTime(2026, 10, 11, hour + 2),
      room: 'ruang uji',
      lecturer: 'dosen uji',
    );
    // Sediakan kelas selesai, sedang berlangsung, dan belum dimulai.
    final past = item(7), active = item(9), next = item(13);
    // Masukkan dalam urutan acak agar tes benar-benar memeriksa proses pengurutan.
    final items = [next, past, active];
    // Hasil hari ini harus berurutan: kelas jam 7, jam 9, lalu jam 13.
    expect(todayClasses(items, now).map((s) => s.startsAt.hour), [7, 9, 13]);
    // same memeriksa objek yang sama: kelas jam 9 harus dipilih sebagai kelas aktif.
    expect(activeOrNextClass(items, now), same(active));
    // Pada hari berikutnya semua kelas uji sudah berakhir sehingga hasil harus null.
    expect(activeOrNextClass(items, DateTime(2026, 10, 12)), isNull);
    expect(items.first, same(next)); // Fungsi tidak mengubah daftar asli.
  });

  // Periksa jumlah kolom pada ruang sempit, sedang, dan lebar.
  test('Grid mengikuti ruang yang tersedia dan tetap minimal satu kolom', () {
    // Meskipun ruang kurang dari ukuran ideal, tetap sediakan minimal satu kolom.
    expect(ResponsiveLayout.columns(100, 220), 1);
    expect(ResponsiveLayout.columns(460, 220), 2);
    // Uji batas jumlah kolom khusus menu akses cepat pada beberapa lebar.
    expect(ResponsiveLayout.quickColumns(300), 2);
    expect(ResponsiveLayout.quickColumns(900), 4);
    expect(ResponsiveLayout.quickColumns(1400), 7);
  });
}
