import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../graphics/pixel_lab_painter.dart';
import '../theme/retro_theme.dart';

/// Latar, header fakultas, footer, dan posisi kartu yang sama pada dua halaman.
class RetroAuthScaffold extends StatelessWidget {
  const RetroAuthScaffold({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    // Tinggi body otomatis menyesuaikan keyboard; konten dapat digulir.
    resizeToAvoidBottomInset: true,
    body: Stack(
      fit: StackFit.expand,
      children: [
        const RepaintBoundary(child: CustomPaint(painter: PixelLabPainter())),
        // Lapisan tipis menjaga keterbacaan kartu, sementara lab tetap terlihat.
        ColoredBox(color: RetroTheme.ink.withValues(alpha: 0.10)),
        SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                decoration: const BoxDecoration(
                  color: RetroTheme.red,
                  border: Border(
                    top: BorderSide(color: Color(0xFFEA7885), width: 3),
                    bottom: BorderSide(color: RetroTheme.ink, width: 4),
                  ),
                ),
                child: Row(
                  children: [
                    const PixelLogo(size: 38, showLabel: false),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'FAKULTAS ILMU KOMPUTER',
                        style: RetroTheme.pixel(14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(18, 30, 22, 34),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: math.max(0.0, constraints.maxHeight - 64),
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 390),
                            child: child,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                width: double.infinity,
                color: RetroTheme.ink.withValues(alpha: 0.94),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Text(
                  'FASILKOM DIGITAL CAMPUS',
                  textAlign: TextAlign.center,
                  style: RetroTheme.pixel(9, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Logo geometris pengganti sementara, bukan logo resmi institusi.
class PixelLogo extends StatelessWidget {
  const PixelLogo({super.key, this.size = 64, this.showLabel = true});
  final double size;
  final bool showLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Ikon Fasilkom',
    image: true,
    child: ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4D8),
          border: Border.all(color: RetroTheme.ink, width: 2),
          boxShadow: const [
            BoxShadow(color: Color(0xFFA6B9C7), offset: Offset(2, 2)),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(size * 0.10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(
                    3,
                    (i) => Container(
                      width: size * 0.13,
                      height: size * (i == 1 ? 0.49 : 0.36),
                      margin: EdgeInsets.symmetric(horizontal: size * 0.025),
                      decoration: BoxDecoration(
                        color: RetroTheme.red,
                        border: Border.all(color: RetroTheme.ink, width: 2),
                      ),
                    ),
                  ),
                ),
              ),
              if (showLabel) ...[
                const SizedBox(height: 5),
                Text('FASILKOM', style: RetroTheme.pixel(size * 0.105)),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

/// Kartu seperti jendela komputer retro: title bar, brand biru, dan isi form.
class RetroWindow extends StatelessWidget {
  const RetroWindow({
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
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: RetroTheme.paper,
      border: Border.all(color: RetroTheme.ink, width: 4),
      boxShadow: const [
        BoxShadow(color: Color(0xFF071121), offset: Offset(6, 6)),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.only(left: 10, right: 4),
          decoration: const BoxDecoration(
            color: RetroTheme.titleBar,
            border: Border(bottom: BorderSide(color: RetroTheme.ink, width: 3)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  fileName,
                  style: RetroTheme.pixel(11, color: Colors.white),
                ),
              ),
              if (onBack != null)
                IconButton(
                  tooltip: 'Kembali ke login',
                  onPressed: onBack,
                  icon: const Icon(
                    Icons.close,
                    color: RetroTheme.ink,
                    size: 21,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: RetroTheme.paper,
                    shape: const RoundedRectangleBorder(
                      side: BorderSide(color: RetroTheme.ink, width: 2),
                    ),
                    minimumSize: const Size(44, 44),
                  ),
                )
              else
                // Halaman pertama tidak memiliki tujuan "tutup"; gunakan dekorasi
                // kotak, tanpa menampilkan tombol X yang tidak dapat bekerja.
                const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(Icons.crop_square, color: Colors.white, size: 20),
                ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF183D83), RetroTheme.blue],
            ),
            border: Border(bottom: BorderSide(color: RetroTheme.ink, width: 4)),
          ),
          child: Row(
            children: [
              const PixelLogo(),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subtitle,
                      style: RetroTheme.pixel(
                        9,
                        color: const Color(0xFFA4D5EF),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      title,
                      style: RetroTheme.pixel(23, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: child,
        ),
      ],
    ),
  );
}

/// Kemunculan kartu: transparan + geser 16px. child tidak dibangun ulang
/// pada setiap frame sehingga animasi lebih ringan.
class RetroEntrance extends StatelessWidget {
  const RetroEntrance({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Label di atas input + border persegi. TextFormField tetap mendukung
/// validasi, autofill, keyboard Android, dan pembaca layar.
class RetroField extends StatelessWidget {
  const RetroField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    required this.validator,
    required this.icon,
    this.obscureText = false,
    this.suffix,
    this.enabled = true,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.autofillHints,
    this.enableSuggestions = true,
  });
  final String label;
  final String hint;
  final TextEditingController controller;
  final String? Function(String?) validator;
  final IconData icon;
  final bool obscureText;
  final Widget? suffix;
  final bool enabled;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;
  final bool enableSuggestions;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: color, width: width),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: RetroTheme.pixel(12)),
        const SizedBox(height: 9),
        Semantics(
          label: label,
          child: TextFormField(
            controller: controller,
            enabled: enabled,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            onFieldSubmitted: onSubmitted,
            validator: validator,
            autofillHints: autofillHints,
            autocorrect: false,
            enableSuggestions: enableSuggestions,
            style: const TextStyle(fontSize: 14, color: RetroTheme.ink),
            decoration: InputDecoration(
              // Label semantik tetap tersedia meskipun label visual di luar input.
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 13, color: RetroTheme.muted),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 18,
              ),
              prefixIcon: Icon(icon, color: RetroTheme.blue, size: 21),
              suffixIcon: suffix,
              border: border(RetroTheme.ink, 3),
              enabledBorder: border(RetroTheme.ink, 3),
              disabledBorder: border(RetroTheme.muted, 2),
              focusedBorder: border(RetroTheme.titleBar, 3),
              errorBorder: border(RetroTheme.red, 2),
              focusedErrorBorder: border(RetroTheme.red, 3),
              errorMaxLines: 3,
            ),
          ),
        ),
      ],
    );
  }
}

/// Tombol pixel dengan efek ditekan 3px, bayangan tegas, dan loading.
class RetroButton extends StatefulWidget {
  const RetroButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon = Icons.chevron_right,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData icon;

  @override
  State<RetroButton> createState() => _RetroButtonState();
}

class _RetroButtonState extends State<RetroButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.loading || widget.onPressed == null;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 120);
    // Semantics membuat tombol custom dikenali TalkBack sebagai tombol.
    return Semantics(
      button: true,
      enabled: !disabled,
      label: widget.loading ? 'Sedang memproses' : widget.label,
      child: AnimatedContainer(
        duration: duration,
        transform: Matrix4.translationValues(0, _pressed ? 3 : 0, 0),
        decoration: BoxDecoration(
          color: disabled ? const Color(0xFF9BE4BB) : RetroTheme.green,
          border: Border.all(color: RetroTheme.ink, width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF75B895),
              offset: Offset(_pressed ? 1 : 4, _pressed ? 1 : 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: disabled ? null : widget.onPressed,
            onHighlightChanged: (value) => setState(() => _pressed = value),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 180),
                    child: widget.loading
                        ? const SizedBox(
                            key: ValueKey('loading'),
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: RetroTheme.ink,
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
                                  style: RetroTheme.pixel(18),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Icon(widget.icon, size: 23),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pesan hasil yang ikut dianimasikan tanpa menutupi form.
class RetroNotice extends StatelessWidget {
  const RetroNotice({super.key, required this.message, this.success = false});
  final String message;
  final bool success;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: success ? const Color(0xFFDFF8E9) : const Color(0xFFFFE9EC),
        border: Border.all(
          color: success ? const Color(0xFF257447) : RetroTheme.red,
          width: 2,
        ),
      ),
      child: Text(message, style: const TextStyle(fontSize: 13, height: 1.5)),
    ),
  );
}
