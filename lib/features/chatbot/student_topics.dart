// Kamus kebutuhan mahasiswa. Ini nama layanan dan penjelasan umum, bukan rekam
// mahasiswa, jadwal contoh, atau ketentuan resmi kampus.
class StudentTopic {
  const StudentTopic(
    this.id,
    this.label,
    this.aliases,
    this.definition, {
    this.daily = false,
  });
  final String id;
  final String label;
  final String aliases;
  final String definition;
  final bool daily;

  RegExp get matcher => RegExp('\\b(?:$aliases)\\b');
}

const studentTopics = [
  StudentTopic(
    'izin',
    'Izin Online',
    r'surat izin|izin online|izin',
    'Surat izin perkuliahan adalah permohonan mahasiswa untuk tidak mengikuti perkuliahan pada tanggal tertentu, disertai alasan dan bukti. '
        'Dalam rancangan aplikasi ini mahasiswa mengajukan ke BAP sebagai unit pemeriksa. BAP menyetujui, menolak, atau meminta perbaikan. '
        'Hasil final berupa PDF tersedia bagi mahasiswa dan dosen sesuai kode; mahasiswa juga dapat meneruskannya manual. Saat ini alurnya simulasi lokal, bukan pengiriman kampus atau perubahan presensi otomatis.',
  ),
  StudentTopic(
    'krs',
    'KRS',
    r'krs|kartu rencana studi',
    'KRS (Kartu Rencana Studi) adalah daftar mata kuliah yang direncanakan untuk satu semester.',
  ),
  StudentTopic(
    'ipk',
    'IPK',
    r'ipk|indeks prestasi kumulatif',
    'IPK (Indeks Prestasi Kumulatif) menggambarkan hasil belajar kumulatif mahasiswa.',
  ),
  StudentTopic(
    'ips',
    'IPS',
    r'ips|indeks prestasi semester',
    'IPS (Indeks Prestasi Semester) menggambarkan hasil belajar dalam satu semester.',
  ),
  StudentTopic(
    'jadwal',
    'Jadwal kuliah',
    r'jadwal kuliah|jadwal|kuliah',
    'Jadwal kuliah memuat waktu dan tempat kegiatan perkuliahan.',
    daily: true,
  ),
  StudentTopic(
    'nilai',
    'Nilai dan KHS',
    r'nilai|khs|transkrip',
    'Nilai menunjukkan hasil penilaian mata kuliah. KHS adalah Kartu Hasil Studi untuk satu semester; transkrip merangkum riwayat nilai.',
  ),
  StudentTopic(
    'presensi',
    'Presensi',
    r'presensi|absensi|absen|kehadiran',
    'Presensi adalah pencatatan kehadiran dalam kegiatan perkuliahan.',
  ),
  StudentTopic(
    'tagihan',
    'Tagihan',
    r'tagihan|ukt|spp',
    'Tagihan adalah rincian kewajiban pembayaran yang ditetapkan kampus.',
  ),
  StudentTopic(
    'pembayaran',
    'Pembayaran',
    r'pembayaran|bayar',
    'Riwayat pembayaran memuat transaksi dan status verifikasinya.',
  ),
  StudentTopic(
    'ujian',
    'Jadwal ujian',
    r'jadwal ujian|ujian|uts|uas',
    'Jadwal ujian memuat waktu dan tempat ujian. UTS dan UAS merujuk pada ujian tengah dan akhir semester.',
    daily: true,
  ),
  StudentTopic(
    'tugas',
    'Tugas kuliah',
    r'tugas kuliah|tugas|deadline|tenggat',
    'Tugas kuliah adalah pekerjaan pembelajaran dengan instruksi dan tenggat dari pengajar.',
    daily: true,
  ),
  StudentTopic(
    'pengumuman',
    'Pengumuman',
    r'pengumuman|info hari ini|info kampus',
    'Pengumuman kampus adalah informasi yang diterbitkan oleh pihak kampus.',
    daily: true,
  ),
  StudentTopic(
    'sks',
    'SKS',
    r'sks',
    'SKS (Satuan Kredit Semester) menyatakan bobot kegiatan pembelajaran mata kuliah.',
  ),
  StudentTopic(
    'skripsi',
    'Tugas akhir',
    r'tugas akhir|skripsi|tesis|disertasi|ta',
    'Tugas akhir adalah karya pada tahap akhir studi. Bentuk, pembimbing, dan prosedurnya mengikuti program studi.',
  ),
  StudentTopic(
    'bimbingan',
    'Bimbingan',
    r'jadwal bimbingan|bimbingan|dpa|dosen wali',
    'Bimbingan adalah konsultasi dengan pembimbing tentang studi atau tugas akhir.',
  ),
  StudentTopic(
    'magang',
    'Magang / KKP',
    r'magang|kkp|pkl',
    'Magang atau praktik kerja memberi pengalaman belajar di lingkungan kerja. Penamaan dan pengakuannya mengikuti program studi.',
  ),
  StudentTopic(
    'kkn',
    'KKN',
    r'kkn',
    'KKN (Kuliah Kerja Nyata) adalah kegiatan pembelajaran dan pengabdian kepada masyarakat.',
  ),
  StudentTopic(
    'beasiswa',
    'Beasiswa',
    r'beasiswa',
    'Beasiswa adalah bantuan pendidikan dengan persyaratan dari penyelenggara.',
  ),
  StudentTopic(
    'cuti',
    'Cuti kuliah',
    r'cuti kuliah|cuti',
    'Cuti kuliah adalah penghentian studi sementara melalui prosedur kampus.',
  ),
  StudentTopic(
    'kelulusan',
    'Kelulusan',
    r'kelulusan|yudisium|wisuda|lulus',
    'Kelulusan merupakan penetapan penyelesaian studi. Yudisium dan wisuda mengikuti proses yang ditentukan kampus.',
  ),
  StudentTopic(
    'progres',
    'Progres studi',
    r'progres studi|progres|progress|masa studi|batas studi',
    'Progres studi merangkum kemajuan perkuliahan. Batas masa studi perlu diperiksa pada pedoman resmi sesuai program dan angkatan.',
  ),
  StudentTopic(
    'biodata',
    'Biodata',
    r'biodata|profil|nim',
    'Biodata adalah informasi identitas mahasiswa yang tercatat di sistem kampus.',
  ),
  StudentTopic(
    'konseling',
    'Konseling',
    r'konseling',
    'Konseling adalah layanan pendampingan melalui konsultasi dengan petugas yang sesuai.',
  ),
];
