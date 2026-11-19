// Penyusun konteks internal SIAKAD agar AI lokal hanya menjawab dari isi
// SIAKAD yang tersedia pada aplikasi, tanpa mengambil informasi dari luar.

import '../../data/dashboard_models.dart';
import '../../data/lecturer_models.dart';
import '../../data/student_profile.dart';

class SiakadContextBuilder {
  static const appCatalog =
      'Layanan SIAKAD FASILKOM di aplikasi ini:\n'
      '- Mahasiswa: Beranda, Biodata, KRS, Jadwal Kuliah, Nilai & Presensi, Tagihan, Pembayaran, Konseling, Izin Online (diajukan ke BAP, hasil PDF diteruskan ke dosen sesuai kode), Tugas Akhir (Skripsi/Tesis/Business Plan/Disertasi), Pengumuman, Berita, dan Pedoman.\n'
      '- Dosen Akademik (DOS001): Beranda Dosen Akademik, Jadwal Mengajar, Mata Kuliah Diampu, Input Nilai, Presensi Kelas, Perwalian PA (filter/cari/ACC/revisi KRS), dan Hasil Izin.\n'
      '- Dosen Akademik + Pembimbing TA (DOS002): Semua menu Dosen Akademik ditambah Mahasiswa Bimbingan TA (filter/cari/log bimbingan/ACC tahap) dan Jadwal Bimbingan & Sidang TA.\n'
      '- BAP (BAP001): Pemeriksaan antrean Izin Online (setujui, tolak, atau minta perbaikan) serta penerbitan hasil PDF.';

  static String fromStudent({
    required StudentProfile student,
    required DashboardData data,
    int leaveCount = 0,
  }) {
    final p = data.student ?? student;
    final lines = <String>[
      'Peran pengguna aktif: Mahasiswa (NIM: ${p.nim}).',
      if (p.name != null) 'Nama: ${p.name}.',
      if (p.major != null) 'Program Studi: ${p.major}.',
      if (p.semester != null) 'Semester: ${p.semester}.',
      if (p.gpa != null) 'IPK: ${p.gpa!.toStringAsFixed(2)}.',
      if (p.passedCredits != null) 'SKS lulus: ${p.passedCredits}.',
      'Jumlah jadwal kuliah tersimpan di beranda: ${data.classes.length}.',
      'Jumlah pengumuman: ${data.announcements.length}, berita: ${data.news.length}, panduan: ${data.guides.length}.',
      'Jumlah pengajuan Izin Online di kotak masuk sesi ini: $leaveCount.',
      if (data.guides.isNotEmpty)
        'Judul panduan SIAKAD: ${data.guides.map((g) => g.title).join('; ')}.',
      appCatalog,
    ];
    return lines.join('\n');
  }

  static String fromLecturer({
    required StudentProfile user,
    required LecturerDashboardData data,
    int leaveCount = 0,
  }) {
    final prof = data.profile;
    final w = data.workload;
    final pendingPa = data.paAdvisees
        .where((a) => a.krsStatus != KrsApprovalStatus.approved)
        .length;
    final pendingGrades =
        data.courses.where((c) => !c.gradeSubmitted).length;
    final lines = <String>[
      'Peran pengguna aktif: ${prof?.roleLabel ?? 'Dosen Akademik'} (Kode: ${prof?.code ?? user.nim}).',
      if (prof != null)
        'Nama: ${prof.name}, NIDN: ${prof.nidn}, Prodi: ${prof.department}, Jabatan: ${prof.academicRank}.',
      'Ringkasan beban: ${w.totalCourses} mata kuliah, ${w.totalClasses} kelas, ${w.totalCredits} SKS, ${w.totalStudents} mahasiswa.',
      'Pertemuan terlaksana: ${w.completedMeetings}/${w.targetMeetings}. Kelas belum input nilai: $pendingGrades.',
      'Perwalian PA: ${w.paApproved}/${w.paTotal} disetujui ($pendingPa menunggu tindak lanjut).',
      if (prof?.isThesisAdvisor == true)
        'Bimbingan TA: ${w.thesisActive}/${w.thesisCapacity} mahasiswa aktif, ${w.thesisPendingReviews} review menunggu, ${w.thesisReadyDefense} siap sidang, ${data.thesisSchedules.length} jadwal TA.',
      if (data.courses.isNotEmpty)
        'Mata kuliah diampu: ${data.courses.map((c) => '${c.code} ${c.title} (Kelas ${c.classCode}, ${c.scheduleText}, ${c.room})').join('; ')}.',
      'Kotak masuk Hasil Izin dosen sesi ini: $leaveCount.',
      if (data.guides.isNotEmpty)
        'Panduan dosen: ${data.guides.map((g) => g.title).join('; ')}.',
      appCatalog,
    ];
    return lines.join('\n');
  }
}
