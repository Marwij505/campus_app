/// Breakpoint memakai lebar jendela, bukan nama perangkat.
/// Tablet dalam split screen bisa memakai susunan HP secara otomatis.
abstract final class ResponsiveLayout {
  static const tablet = 600.0;
  static const desktop = 1100.0;
  static const maxContentWidth = 1600.0;

  static int quickColumns(double width) => width >= 1200
      ? 7
      : width >= 700
      ? 4
      : width >= 430
      ? 3
      : 2;

  // Lebar minimum kartu mengikuti ukuran teks yang dipilih pengguna.
  static int columns(double width, double minWidth, {int maximum = 4}) =>
      ((width + 16) / (minWidth + 16)).floor().clamp(1, maximum);
}
