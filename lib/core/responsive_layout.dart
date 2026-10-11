// Aturan memilih susunan tampilan berdasarkan ruang yang tersedia.
// Responsif berarti jumlah kolom menyesuaikan lebar jendela dan ukuran teks.
// Angka ukuran memakai satuan layout Flutter, bukan jumlah piksel fisik layar.

/// Breakpoint memakai lebar jendela, bukan nama perangkat.
/// Tablet dalam split screen bisa memakai susunan HP secara otomatis.
// Rumus bersama agar berbagai panel memakai aturan lebar yang konsisten.
abstract final class ResponsiveLayout {
  // Mulai lebar 600, beranda bisa memakai navigasi samping seperti tablet.
  static const tablet = 600.0;
  // Mulai lebar 1100, beranda bisa memakai menu atas seperti desktop.
  static const desktop = 1100.0;
  // Batasi lebar isi agar kartu tidak melebar berlebihan pada monitor besar.
  static const maxContentWidth = 1600.0;

  // Pilih 7, 4, 3, atau 2 kolom akses cepat dari ruang yang tersedia.
  // Bentuk kondisi ? hasilA : hasilB adalah penulisan singkat if/else.
  static int quickColumns(double width) => width >= 1200
      ? 7
      : width >= 700
      ? 4
      : width >= 430
      ? 3
      : 2;

  // Lebar minimum kartu mengikuti ukuran teks yang dipilih pengguna.
  // Hitung berapa kartu muat setelah memperhitungkan jarak 16 antar kartu.
  // floor membulatkan ke bawah; clamp menjaga jumlah antara 1 dan maximum.
  static int columns(double width, double minWidth, {int maximum = 4}) =>
      ((width + 16) / (minWidth + 16)).floor().clamp(1, maximum);
}
