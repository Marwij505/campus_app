import 'package:flutter_test/flutter_test.dart';

import 'package:campus_app/core/responsive_layout.dart';
import 'package:campus_app/data/dashboard_models.dart';
import 'package:campus_app/data/dashboard_repository.dart';

void main() {
  test('Repository awal tidak mengisi data akademik buatan', () async {
    final data = await const EmptyDashboardRepository().load('akun-uji');
    expect(data.student, isNull);
    expect(data.progress.gpa, isNull);
    expect(data.progress.currentSemester, isNull);
    expect(data.outstandingBillCount, isNull);
    expect(data.classes, isEmpty);
    expect(data.announcements, isEmpty);
    expect(data.news, isEmpty);
    expect(data.counseling, isEmpty);
    expect(data.guides, isEmpty);
    expect(data.semesters, isEmpty);
    expect(data.gradeComposition, isEmpty);
    expect(data.courseStatus, isEmpty);
  });

  test('Progress yang belum diketahui tetap null dan pembagian aman', () {
    expect(safeRatio(null, 144), isNull);
    expect(safeRatio(86, null), isNull);
    expect(safeRatio(86, 0), isNull);
    expect(safeRatio(double.nan, 4), isNull);
    expect(safeRatio(200, 144), 1);
    expect(safeRatio(-1, 144), 0);
    expect(safeRatio(72, 144), .5);
  });

  test('Jadwal diurutkan, kelas aktif diutamakan, kelas selesai diabaikan', () {
    final now = DateTime(2026, 10, 11, 10);
    ClassSchedule item(int hour) => ClassSchedule(
      code: 'uji',
      title: 'Kelas uji',
      startsAt: DateTime(2026, 10, 11, hour),
      endsAt: DateTime(2026, 10, 11, hour + 2),
      room: 'ruang uji',
      lecturer: 'dosen uji',
    );
    final past = item(7), active = item(9), next = item(13);
    final items = [next, past, active];
    expect(todayClasses(items, now).map((s) => s.startsAt.hour), [7, 9, 13]);
    expect(activeOrNextClass(items, now), same(active));
    expect(activeOrNextClass(items, DateTime(2026, 10, 12)), isNull);
    expect(items.first, same(next)); // Fungsi tidak mengubah daftar asli.
  });

  test('Grid mengikuti ruang yang tersedia dan tetap minimal satu kolom', () {
    expect(ResponsiveLayout.columns(100, 220), 1);
    expect(ResponsiveLayout.columns(460, 220), 2);
    expect(ResponsiveLayout.quickColumns(300), 2);
    expect(ResponsiveLayout.quickColumns(900), 4);
    expect(ResponsiveLayout.quickColumns(1400), 7);
  });
}
