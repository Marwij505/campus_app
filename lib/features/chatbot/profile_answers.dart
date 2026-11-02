// Jawaban identitas dirangkai dari sesi sah; model tidak perlu menebak atau mengingat PII.
import '../../data/student_profile.dart';

class ProfileAnswers {
  static String? reply(String input, StudentProfile? p) {
    if (p?.id == null) return null;
    final text = input
        .toLowerCase()
        .replaceAllMapped(
          RegExp(
            r'\b(nama|nim|jurusan|profil|semester|kampus|angkatan|fakultas)ku\b',
          ),
          (m) => '${m[1]} saya',
        )
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .trim();
    bool has(String pattern) => RegExp(pattern).hasMatch(text);
    final topic =
        has(
          r'\b(nama|panggil|panggilan|nim|jurusan|prodi|program studi|fakultas|kampus|semester|angkatan|biodata|profil|ipk|ips|sks|email|telepon)\b',
        ) ||
        has(r'\bsiapa (saya|aku)\b');
    if (!topic) return null;
    if (has(r'\b(dosen|pembimbing|rektor)\b')) return null;
    // Kata yang sama di soal belajar bukan permintaan identitas akun.
    if (has(
      r'\b(variabel|variable|fungsi|database|contoh kode|belajar|materi|algoritma|pemrograman|tutorial)\b',
    )) {
      return null;
    }
    if (has(r'\b(teman|orang lain|mahasiswa lain)\b')) {
      return 'Saya hanya dapat membantu informasi profil yang diizinkan untuk akunmu.';
    }
    if (has(r'\b(ubah|ganti|edit|panggil)\b')) {
      return 'NIM dan identitas resmi hanya dapat dikoreksi pengelola. Buka Biodata → Edit untuk data pribadi, atau Edit foto / nama panggilan untuk foto, avatar, dan panggilan.';
    }
    // Permintaan pengertian tetap masuk glosarium/tutor, bukan jawaban identitas.
    if (has(r'\b(apa itu|pengertian|definisi|jelaskan)\b')) return null;
    // Hanya pertanyaan pendek atau pertanyaan yang jelas merujuk diri sendiri.
    // Nama orang yang diketik tidak pernah mengganti profil ataupun menjadi lookup.
    final direct =
        has(
          r'\b(saya|aku|ku|namaku|nimku|jurusanku|profilku|siapa|berapa)\b',
        ) ||
        text.split(RegExp(r'\s+')).length <= 3;
    if (!direct) return null;
    if (input.trim().endsWith('?') && text.split(RegExp(r'\s+')).length <= 2) {
      return 'Untuk $text, pilih: cek $text saya, pengertian $text, atau buka Biodata. Profil akun tersedia; data akademik belum diintegrasikan.';
    }
    if (has(r'\b(ipk|ips|sks)\b')) {
      return 'Profilmu sudah terhubung, tetapi data nilai/IPK, IPS, dan SKS belum diintegrasikan.';
    }
    if (has(r'\b(email)\b')) {
      if (has(r'\b(kampus)\b')) {
        return 'Email kampusmu: ${p!.campusEmail ?? 'belum tersedia'}.';
      }
      if (has(r'\b(pribadi|kontak)\b')) {
        return 'Email pribadi dapat dilihat di Biodata → Kontak. Email login / pemulihan akunmu: ${p!.email ?? 'belum tersedia'}.';
      }
      return 'Email login / pemulihan: ${p!.email ?? 'belum tersedia'}. Email kampus: ${p.campusEmail ?? 'belum tersedia'}.';
    }
    if (has(r'\b(kampus)\b')) {
      return p!.campus == null
          ? 'Lokasi kampus belum tersedia pada profilmu.'
          : 'Lokasi kampusmu ${p.campus}.';
    }
    if (has(r'\b(semester)\b')) {
      return p!.semester == null
          ? 'Informasi semester belum tersedia pada profilmu.'
          : 'Semester pada profilmu: ${p.semester}.';
    }
    if (has(r'\b(angkatan)\b')) {
      return p!.entryYear == null
          ? 'Informasi angkatan belum tersedia pada profilmu.'
          : 'Angkatan pada profilmu: ${p.entryYear}.';
    }
    if (has(r'\b(nim)\b')) return 'NIM akunmu ${p!.nim}.';
    if (has(r'\b(telepon)\b')) {
      return 'Telepon pada profilmu: ${p!.phone ?? 'belum tersedia'}.';
    }
    if (has(r'\b(jurusan|prodi|program studi|fakultas)\b')) {
      return 'Program studimu ${p!.major ?? 'belum tersedia'}, ${p.faculty ?? 'fakultas belum tersedia'}, ${p.university ?? 'universitas belum tersedia'}.';
    }
    return 'Nama lengkapmu ${p!.name ?? 'belum tersedia'}${p.preferredName == null ? '' : ', dengan panggilan ${p.preferredName}'}. Identitas resmi mengikuti profil akun, bukan perubahan melalui chat.';
  }
}
