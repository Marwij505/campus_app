// Definisi formulir mengikuti bagian pada biodata SIAKAD; tidak berisi data mahasiswa.
import 'profile_phone.dart';

class BiodataField {
  const BiodataField(
    this.key,
    this.label,
    this.group,
    this.kind, {
    this.options = const [],
  });
  final String key, label, group, kind;
  final List<String> options;
  int get maxLength => kind == 'long' ? 1000 : 150;
  String? validate(String input) {
    final value = input.trim();
    if (value.isEmpty) {
      return null; // Data boleh dilengkapi bertahap; kosong bukan nilai palsu.
    }
    if (value.length > maxLength ||
        RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]').hasMatch(value)) {
      return 'Isian terlalu panjang atau mengandung karakter tidak sah.';
    }
    if (options.isNotEmpty && !options.contains(value)) {
      return 'Pilih salah satu pilihan yang tersedia.';
    }
    if (kind == 'phone' && !validProfilePhone(value)) {
      return 'Gunakan nomor 08…, 0kode area…, atau +kode negara.';
    }
    if (kind == 'email' &&
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)) {
      return 'Email tidak valid.';
    }
    if (kind == 'nik' && !RegExp(r'^\d{16}$').hasMatch(value)) {
      return 'NIK harus 16 digit.';
    }
    if (kind == 'nisn' && !RegExp(r'^\d{10}$').hasMatch(value)) {
      return 'NISN harus 10 digit.';
    }
    if (kind == 'postal' && !RegExp(r'^\d{5}$').hasMatch(value)) {
      return 'Kode pos harus 5 digit.';
    }
    if (kind == 'digits' && !RegExp(r'^\d{1,3}$').hasMatch(value)) {
      return 'Isi 1–3 digit.';
    }
    if (kind == 'score') {
      final score = double.tryParse(value.replaceAll(',', '.'));
      if (score == null || !score.isFinite || score < 0 || score > 100) {
        return 'Nilai harus 0–100.';
      }
    }
    if (kind == 'date') {
      final date = DateTime.tryParse(value);
      if (date == null ||
          date.toIso8601String().substring(0, 10) != value ||
          date.isAfter(DateTime.now()) ||
          date.year < 1900) {
        return 'Tanggal lahir tidak valid.';
      }
    }
    return null;
  }

  Object? serialize(String input) {
    final value = input.trim();
    if (value.isEmpty) return null;
    if (kind == 'phone') return normalizeProfilePhone(value);
    if (kind == 'score') return double.parse(value.replaceAll(',', '.'));
    return value;
  }
}

class BiodataSection {
  const BiodataSection(this.key, this.label, this.fields);
  final String key, label;
  final List<BiodataField> fields;
  String get table => 'student_$key';
}

const biodataSections = <BiodataSection>[
  BiodataSection('biodata', 'Biodata', [
    BiodataField('nik', 'No induk kependudukan', 'Identitas', 'nik'),
    BiodataField('passport_number', 'No paspor', 'Identitas', 'text'),
    BiodataField(
      'gender',
      'Jenis kelamin',
      'Identitas',
      'choice',
      options: ['Laki-laki', 'Perempuan'],
    ),
    BiodataField(
      'religion',
      'Agama',
      'Identitas',
      'choice',
      options: [
        'Islam',
        'Kristen',
        'Katolik',
        'Hindu',
        'Buddha',
        'Konghucu',
        'Kepercayaan lainnya',
      ],
    ),
    BiodataField(
      'blood_type',
      'Golongan darah',
      'Identitas',
      'choice',
      options: ['A', 'B', 'AB', 'O', 'Tidak diketahui'],
    ),
    BiodataField('birth_place', 'Tempat lahir', 'Identitas', 'text'),
    BiodataField('birth_date', 'Tanggal lahir', 'Identitas', 'date'),
    BiodataField('street', 'Jalan', 'Alamat domisili', 'long'),
    BiodataField('rt', 'RT', 'Alamat domisili', 'digits'),
    BiodataField('rw', 'RW', 'Alamat domisili', 'digits'),
    BiodataField('village', 'Kelurahan', 'Alamat domisili', 'text'),
    BiodataField('district', 'Kecamatan', 'Alamat domisili', 'text'),
    BiodataField('province', 'Provinsi', 'Alamat domisili', 'text'),
    BiodataField('city', 'Kota / kabupaten', 'Alamat domisili', 'text'),
    BiodataField('postal_code', 'Kode pos', 'Alamat domisili', 'postal'),
    BiodataField('phone', 'No. WhatsApp', 'Kontak', 'phone'),
    BiodataField('private_email', 'Email pribadi', 'Kontak', 'email'),
    BiodataField(
      'marital_status',
      'Status nikah',
      'Lainnya',
      'choice',
      options: ['Belum menikah', 'Menikah', 'Cerai hidup', 'Cerai mati'],
    ),
    BiodataField(
      'citizenship',
      'Kewarganegaraan',
      'Lainnya',
      'choice',
      options: ['Warga Negara Indonesia', 'Warga Negara Asing'],
    ),
  ]),
  BiodataSection('education', 'Pendidikan', [
    BiodataField('school_name', 'Nama sekolah', 'Asal sekolah', 'text'),
    BiodataField('school_address', 'Alamat sekolah', 'Asal sekolah', 'long'),
    BiodataField('school_phone', 'Telepon sekolah', 'Asal sekolah', 'phone'),
    BiodataField('average_score', 'Nilai rata-rata', 'Asal sekolah', 'score'),
    BiodataField('nisn', 'NISN', 'Asal sekolah', 'nisn'),
    BiodataField('diploma_number', 'No. ijazah', 'Asal sekolah', 'text'),
  ]),
  BiodataSection('family', 'Keluarga', [
    BiodataField('father_name', 'Nama ayah', 'Orang tua', 'text'),
    BiodataField('mother_name', 'Nama ibu', 'Orang tua', 'text'),
    BiodataField('street', 'Jalan', 'Alamat orang tua', 'long'),
    BiodataField('rt', 'RT', 'Alamat orang tua', 'digits'),
    BiodataField('rw', 'RW', 'Alamat orang tua', 'digits'),
    BiodataField('village', 'Kelurahan', 'Alamat orang tua', 'text'),
    BiodataField('district', 'Kecamatan', 'Alamat orang tua', 'text'),
    BiodataField('province', 'Provinsi', 'Alamat orang tua', 'text'),
    BiodataField('city', 'Kota / kabupaten', 'Alamat orang tua', 'text'),
    BiodataField('postal_code', 'Kode pos', 'Alamat orang tua', 'postal'),
    BiodataField('phone', 'Telepon orang tua', 'Alamat orang tua', 'phone'),
    BiodataField(
      'father_education',
      'Pendidikan ayah',
      'Pendidikan dan pekerjaan',
      'choice',
      options: [
        'Tidak sekolah',
        'SD',
        'SMP',
        'SMA',
        'SMK',
        'D1',
        'D2',
        'D3',
        'D4',
        'S1',
        'S2',
        'S3',
      ],
    ),
    BiodataField(
      'mother_education',
      'Pendidikan ibu',
      'Pendidikan dan pekerjaan',
      'choice',
      options: [
        'Tidak sekolah',
        'SD',
        'SMP',
        'SMA',
        'SMK',
        'D1',
        'D2',
        'D3',
        'D4',
        'S1',
        'S2',
        'S3',
      ],
    ),
    BiodataField(
      'father_job',
      'Pekerjaan ayah',
      'Pendidikan dan pekerjaan',
      'text',
    ),
    BiodataField(
      'mother_job',
      'Pekerjaan ibu',
      'Pendidikan dan pekerjaan',
      'text',
    ),
    BiodataField('emergency_name', 'Nama kontak', 'Kontak darurat', 'text'),
    BiodataField(
      'emergency_phone',
      'Telepon kontak',
      'Kontak darurat',
      'phone',
    ),
  ]),
  BiodataSection('employment', 'Pekerjaan', [
    BiodataField(
      'employment_status',
      'Status kerja',
      'Pekerjaan',
      'choice',
      options: ['Belum kerja', 'Bekerja', 'Wiraswasta'],
    ),
    BiodataField('occupation', 'Pekerjaan', 'Pekerjaan', 'text'),
    BiodataField('company', 'Perusahaan', 'Pekerjaan', 'text'),
    BiodataField(
      'institution_type',
      'Jenis instansi',
      'Pekerjaan',
      'choice',
      options: [
        'Pemerintah',
        'Swasta',
        'BUMN',
        'BUMD',
        'Organisasi nirlaba',
        'Usaha sendiri',
        'Lainnya',
      ],
    ),
    BiodataField('company_address', 'Alamat perusahaan', 'Pekerjaan', 'long'),
    BiodataField('province', 'Provinsi', 'Pekerjaan', 'text'),
    BiodataField('city', 'Kota / kabupaten', 'Pekerjaan', 'text'),
    BiodataField('company_phone', 'Telepon perusahaan', 'Pekerjaan', 'phone'),
    BiodataField('position', 'Jabatan', 'Pekerjaan', 'text'),
    BiodataField('funding_party', 'Penanggung dana', 'Pekerjaan', 'text'),
  ]),
  BiodataSection('accessibility', 'Disabilitas', [
    BiodataField(
      'has_disability',
      'Apakah Anda penyandang disabilitas?',
      'Disabilitas',
      'choice',
      options: ['Ya', 'Tidak', 'Tidak ingin menyampaikan'],
    ),
    BiodataField(
      'description',
      'Keterangan disabilitas',
      'Disabilitas',
      'long',
    ),
    BiodataField(
      'accommodations',
      'Dukungan yang dibutuhkan',
      'Disabilitas',
      'long',
    ),
  ]),
];
