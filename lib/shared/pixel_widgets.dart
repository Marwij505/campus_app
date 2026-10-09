import 'package:flutter/material.dart';

import '../core/app_motion.dart';
import '../core/app_theme.dart';

/// Memuat background asli Figma.
///
/// Tidak menggambar ulang laboratorium menggunakan CustomPainter.
class CampusBackground extends StatelessWidget {
  const CampusBackground({super.key, this.dashboard = false});

  final bool dashboard;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Image.asset(
        AppTheme.backgroundAsset,
        fit: BoxFit.cover,
        alignment: dashboard ? Alignment.topCenter : Alignment.center,

        // Mengikuti image-rendering: pixelated pada CSS Figma.
        filterQuality: FilterQuality.none,

        // Form tetap terlihat jika PNG belum dipasang.
        // Latar polos ini bukan pengganti background desain.
        errorBuilder: (context, error, stackTrace) =>
            const ColoredBox(color: Color(0xFF07101D)),
      ),

      // Dashboard memakai overlay terang.
      // Login memakai overlay gelap tipis seperti CSS referensi.
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: dashboard
                ? [
                    const Color(0xFFF8F5E8).withValues(alpha: .95),
                    const Color(0xFFF2F7F4).withValues(alpha: .98),
                  ]
                : [
                    AppTheme.ink.withValues(alpha: .08),
                    AppTheme.ink.withValues(alpha: .28),
                  ],
          ),
        ),
      ),
    ],
  );
}

/// Logo tiga menara mengikuti FacultyMark pada App.tsx.
class FacultyMark extends StatelessWidget {
  const FacultyMark({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    width: compact ? 38 : 72,
    height: compact ? 38 : 64,
    decoration: BoxDecoration(
      color: const Color(0xFFF6F0DC),
      border: Border.all(color: AppTheme.ink, width: compact ? 2 : 3),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(
            3,
            (index) => Container(
              width: compact ? 5 : 8,
              height: index == 1 ? (compact ? 22 : 27) : 18,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                color: AppTheme.red,
                border: Border.all(color: AppTheme.ink, width: compact ? 1 : 2),
              ),
            ),
          ),
        ),
        if (!compact) ...[
          const SizedBox(height: 5),
          Text('FASILKOM', style: AppTheme.pixel(6)),
        ],
      ],
    ),
  );
}

/// Avatar geometris mengikuti kepala dan badan pada CSS Figma.
class StudentAvatar extends StatelessWidget {
  const StudentAvatar({super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: 56,
    height: 67,
    decoration: BoxDecoration(
      color: const Color(0xFFE6F2EF),
      border: Border.all(color: Colors.white, width: 3),
    ),
    child: Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned(
          top: 11,
          left: 18,
          width: 20,
          height: 21,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFB76E4B),
              border: Border(
                top: BorderSide(color: AppTheme.ink, width: 7),
                left: BorderSide(color: AppTheme.ink, width: 3),
                right: BorderSide(color: AppTheme.ink, width: 3),
                bottom: BorderSide(color: AppTheme.ink, width: 3),
              ),
            ),
          ),
        ),
        Positioned(
          left: 9,
          bottom: -5,
          width: 38,
          height: 34,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF164A91),
              border: Border.all(color: AppTheme.ink, width: 3),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Kerangka login dan lupa password.
///
/// Header tetap terlihat.
/// Area form dapat digulir ketika keyboard terbuka.
class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    resizeToAvoidBottomInset: true,
    backgroundColor: AppTheme.ink,
    body: Stack(
      fit: StackFit.expand,
      children: [
        const RepaintBoundary(child: CampusBackground()),
        SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 72),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(
                  color: AppTheme.red,
                  border: Border(
                    bottom: BorderSide(color: AppTheme.ink, width: 5),
                  ),
                ),
                child: Row(
                  children: [
                    const FacultyMark(compact: true),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'FAKULTAS ILMU KOMPUTER',
                        style: AppTheme.pixel(
                          11,
                          color: const Color(0xFFFFF5DC),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: LayoutBuilder(
                  builder: (context, bounds) => SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: (bounds.maxHeight - 56)
                            .clamp(0.0, double.infinity)
                            .toDouble(),
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 390),
                          child: child,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 18),
                child: Container(
                  color: AppTheme.ink.withValues(alpha: .78),
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    'FASILKOM DIGITAL CAMPUS · V2.4',
                    textAlign: TextAlign.center,
                    style: AppTheme.pixel(6, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Kartu seperti jendela komputer pada desain login.
class AuthWindow extends StatelessWidget {
  const AuthWindow({
    super.key,
    required this.fileName,
    required this.title,
    required this.subtitle,
    required this.child,
    this.onBack,
  });

  final String fileName;
  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => PixelPanel(
    color: AppTheme.paper,
    padding: EdgeInsets.zero,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.only(left: 10, right: 4),
          decoration: const BoxDecoration(
            color: Color(0xFF1677AD),
            border: Border(bottom: BorderSide(color: AppTheme.ink, width: 4)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  fileName,
                  style: AppTheme.pixel(8, color: Colors.white),
                ),
              ),
              if (onBack != null)
                IconButton(
                  onPressed: onBack,
                  tooltip: 'Kembali ke login',
                  icon: const Icon(Icons.close, size: 20, color: Colors.white),
                )
              else
                // Pada login, X adalah dekorasi seperti referensi Figma.
                ExcludeSemantics(
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    width: 27,
                    height: 25,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCECEF),
                      border: Border.all(color: AppTheme.ink, width: 2),
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 18,
                      color: AppTheme.ink,
                    ),
                  ),
                ),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF143C83), Color(0xFF1959A2)],
            ),
            border: Border(bottom: BorderSide(color: AppTheme.ink, width: 4)),
          ),
          child: Row(
            children: [
              const FacultyMark(),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF99CAE8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(title, style: AppTheme.pixel(16, color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(22, 25, 22, 22),
          child: child,
        ),
      ],
    ),
  );
}

/// Kotak reusable dengan border dan bayangan tegas.
/// Panel bergaya pixel dengan warna latar, border, dan bayangan.
/// Material di dalam panel menyediakan permukaan untuk menggambar
/// efek sentuhan ListTile, CheckboxListTile, dan InkWell.
class PixelPanel extends StatelessWidget {
  const PixelPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.color = Colors.white,
  });

  // Isi panel, misalnya form login atau daftar pengumuman.
  final Widget child;

  // Jarak antara isi panel dan tepinya.
  final EdgeInsetsGeometry padding;

  // Warna latar panel.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      // Panel menggunakan seluruh lebar yang tersedia.
      width: double.infinity,
      padding: padding,

      // Container tetap menggambar tampilan panel.
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: AppTheme.ink, width: 3),
        boxShadow: const [
          BoxShadow(color: Color(0xFFB9C3C4), offset: Offset(4, 4)),
        ],
      ),

      // Material harus berada DI DALAM Container berwarna.
      // Dengan begitu, efek sentuhan digambar di atas latar panel.
      child: Material(
        // Transparan agar warna latar panel tetap terlihat.
        type: MaterialType.transparency,
        child: child,
      ),
    );
  }
}

/// Input bersama untuk login dan lupa password.
class PixelField extends StatelessWidget {
  const PixelField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    required this.validator,
    this.icon,
    this.suffix,
    this.obscure = false,
    this.enabled = true,
    this.keyboardType = TextInputType.text,
    this.action = TextInputAction.next,
    this.onSubmitted,
    this.autofillHints,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final String? Function(String?) validator;
  final IconData? icon;
  final Widget? suffix;
  final bool obscure;
  final bool enabled;
  final TextInputType keyboardType;
  final TextInputAction action;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: AppTheme.pixel(9)),
      const SizedBox(height: 8),

      // Label juga diberikan kepada pembaca layar.
      Semantics(
        label: label,
        child: TextFormField(
          controller: controller,
          validator: validator,
          enabled: enabled,
          obscureText: obscure,
          keyboardType: keyboardType,
          textInputAction: action,
          onFieldSubmitted: onSubmitted,
          autofillHints: autofillHints,
          autocorrect: false,
          enableSuggestions: !obscure && label != 'PASSWORD',
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon == null
                ? null
                : Icon(icon, size: 20, color: AppTheme.blue),
            suffixIcon: suffix,
          ),
        ),
      ),
    ],
  );
}

/// Tombol hijau dengan efek ditekan dan pergantian loading.
class PixelButton extends StatefulWidget {
  const PixelButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  State<PixelButton> createState() => _PixelButtonState();
}

class _PixelButtonState extends State<PixelButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: AppMotion.duration(context, 100),

    // Tombol bergerak sedikit ketika ditekan.
    transform: Matrix4.translationValues(_pressed ? 2 : 0, _pressed ? 2 : 0, 0),

    decoration: BoxDecoration(
      color: widget.loading ? const Color(0xFF9BE8BA) : AppTheme.green,
      border: Border.all(color: AppTheme.ink, width: 3),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFFA8CBD1),
          offset: Offset(_pressed ? 1 : 4, _pressed ? 1 : 4),
        ),
      ],
    ),

    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.loading ? null : widget.onPressed,
        onHighlightChanged: (value) {
          setState(() {
            _pressed = value;
          });
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Center(
              child: AnimatedSwitcher(
                duration: AppMotion.duration(context, 180),
                child: widget.loading
                    ? const SizedBox(
                        key: ValueKey('loading'),
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.ink,
                        ),
                      )
                    : Row(
                        key: const ValueKey('label'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              widget.label,
                              textAlign: TextAlign.center,
                              style: AppTheme.pixel(13),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.chevron_right, size: 18),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Pesan hasil dibacakan pembaca layar sebagai perubahan status.
class StatusMessage extends StatelessWidget {
  const StatusMessage({super.key, required this.message, this.success = false});

  final String message;
  final bool success;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      padding: const EdgeInsets.all(10),
      color: success ? const Color(0xFFDFF7E8) : const Color(0xFFFFE5E8),
      child: Text(message, style: const TextStyle(fontSize: 11)),
    ),
  );
}
