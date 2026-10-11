import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/responsive_layout.dart';
import '../../shared/pixel_widgets.dart';

/// Panel beranda: judul dapat pindah baris agar tidak terpotong di layar kecil.
class DashboardPanel extends StatelessWidget {
  const DashboardPanel({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.action,
  });
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) => PixelPanel(
    padding: EdgeInsets.zero,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, bounds) {
              final heading = Row(
                children: [
                  Icon(icon, color: AppTheme.blue, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTheme.pixel(8, color: AppTheme.blue),
                    ),
                  ),
                ],
              );
              // Tombol panjang tidak dipaksa berdampingan dengan judul pada HP.
              return bounds.maxWidth < 440 ||
                      MediaQuery.textScalerOf(context).scale(1) > 1.3
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        heading,
                        if (action != null) ...[
                          const SizedBox(height: 10),
                          action!,
                        ],
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: heading),
                        if (action != null) ...[
                          const SizedBox(width: 12),
                          action!,
                        ],
                      ],
                    );
            },
          ),
        ),
        const Divider(height: 1, color: Color(0xFFDBE4E6)),
        Padding(padding: const EdgeInsets.all(16), child: child),
      ],
    ),
  );
}

/// Kosong adalah kondisi normal: tidak ada animasi loading yang berputar selamanya.
class DashboardEmpty extends StatelessWidget {
  const DashboardEmpty({
    super.key,
    required this.title,
    this.message = 'Data belum tersedia.',
    this.icon = Icons.inbox_outlined,
  });
  final String title, message;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 8),
    child: Column(
      children: [
        Icon(icon, size: 32, color: AppTheme.blue.withValues(alpha: .45)),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: AppTheme.muted),
        ),
      ],
    ),
  );
}

/// Wrap tidak mengunci tinggi kartu. Teks besar bisa menambah tinggi secara alami.
class ResponsiveCards extends StatelessWidget {
  const ResponsiveCards({
    super.key,
    required this.children,
    this.minWidth = 220,
    this.maximum = 4,
  });
  final List<Widget> children;
  final double minWidth;
  final int maximum;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
      final count = ResponsiveLayout.columns(
        bounds.maxWidth,
        minWidth * scale,
        maximum: maximum,
      );
      final width = (bounds.maxWidth - 16 * (count - 1)) / count;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}

class InfoChip extends StatelessWidget {
  const InfoChip(
    this.label, {
    super.key,
    this.color = AppTheme.blue,
    this.onDark = false,
  });
  final String label;
  final Color color;
  final bool onDark;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: onDark
          ? Colors.white.withValues(alpha: .14)
          : color.withValues(alpha: .08),
      border: Border.all(
        color: onDark
            ? Colors.white.withValues(alpha: .3)
            : color.withValues(alpha: .2),
      ),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 10,
        color: onDark ? Colors.white : color,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

/// Tombol menyediakan area sentuh yang cukup untuk HP dan tablet.
class DashboardAction extends StatelessWidget {
  const DashboardAction(this.label, this.onPressed, {super.key, this.icon});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => TextButton(
    style: TextButton.styleFrom(
      minimumSize: const Size(48, 44),
      foregroundColor: AppTheme.blue,
      backgroundColor: const Color(0xFFEDF3FA),
      shape: const RoundedRectangleBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 12),
    ),
    onPressed: onPressed,
    child: Wrap(
      spacing: 7,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (icon != null) Icon(icon, size: 17),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}
