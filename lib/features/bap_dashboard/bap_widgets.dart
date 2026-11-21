// Shared widgets untuk seluruh panel BAP Dashboard.

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';

/// Sidebar dashboard BAP dengan mode lebar dan ikon saja.
class BapSideBar extends StatelessWidget {
  const BapSideBar({
    super.key,
    required this.selectedIndex,
    required this.pendingKrsCount,
    required this.pendingBapCount,
    required this.expanded,
    required this.onToggle,
    required this.onTabSelected,
  });

  final int selectedIndex;
  final int pendingKrsCount;
  final int pendingBapCount;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<int> onTabSelected;

  static const _items = [
    (Icons.menu_book_outlined, 'Kurikulum & MK'),
    (Icons.calendar_month_outlined, 'Jadwal Kuliah'),
    (Icons.assignment_outlined, 'Administrasi KRS'),
    (Icons.fact_check_outlined, 'Presensi & BAP'),
    (Icons.quiz_outlined, 'Ujian & Nilai'),
    (Icons.manage_accounts_outlined, 'Status Mahasiswa'),
    (Icons.bar_chart_outlined, 'Rekap & PDDikti'),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showLabels = expanded && constraints.maxWidth >= 180;
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            border: Border.all(color: AppTheme.ink, width: 2),
            boxShadow: const [
              BoxShadow(color: Color(0x22000000), offset: Offset(3, 3)),
            ],
          ),
          child: Column(
            children: [
              Container(
                color: AppTheme.ink,
                padding: EdgeInsets.symmetric(
                  horizontal: showLabels ? 10 : 4,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    if (showLabels)
                      Expanded(
                        child: Text(
                          'MENU BAP',
                          style: AppTheme.pixel(7, color: Colors.white),
                        ),
                      )
                    else
                      const Spacer(),
                    IconButton(
                      tooltip: expanded
                          ? 'Sembunyikan menu navigasi'
                          : 'Tampilkan menu navigasi',
                      onPressed: onToggle,
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        expanded ? Icons.chevron_left : Icons.menu,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 5,
                  ),
                  child: Column(
                    children: List.generate(
                      _items.length,
                      (index) => _buildItem(
                        index: index,
                        icon: _items[index].$1,
                        label: _items[index].$2,
                        showLabel: showLabels,
                        badge: index == 2 && pendingKrsCount > 0
                            ? '$pendingKrsCount'
                            : index == 3 && pendingBapCount > 0
                            ? '$pendingBapCount'
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildItem({
    required int index,
    required IconData icon,
    required String label,
    required bool showLabel,
    String? badge,
  }) {
    final isSelected = selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Tooltip(
        message: showLabel ? '' : label,
        child: Material(
          color: isSelected ? AppTheme.blue : Colors.transparent,
          child: InkWell(
            key: ValueKey('bap-nav-$label'),
            onTap: () => onTabSelected(index),
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: EdgeInsets.symmetric(
                horizontal: showLabel ? 10 : 0,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? AppTheme.ink : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: showLabel
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 17,
                    color: isSelected ? Colors.white : AppTheme.ink,
                  ),
                  if (showLabel) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: isSelected ? Colors.white : AppTheme.ink,
                          fontFamily: 'SpaceMono',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 6),
                      _badge(badge),
                    ],
                  ] else if (badge != null)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDC2626),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _badge(String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
    color: const Color(0xFFDC2626),
    child: Text(
      value,
      style: const TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
  );
}

/// Header panel standar BAP dengan judul, subtitle, dan tombol aksi opsional.
class BapPanelHeader extends StatelessWidget {
  const BapPanelHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.color = AppTheme.blue,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 560;

        final button = actionLabel != null && onAction != null
            ? FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add, size: 14),
                label: Text(actionLabel!, style: const TextStyle(fontSize: 10.5)),
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  shape: const RoundedRectangleBorder(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              )
            : null;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10000000),
                offset: Offset(0, 2),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: color.withValues(alpha: 0.1),
                    child: Icon(icon, size: 18, color: color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTheme.pixel(7.5, color: color),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: AppTheme.muted,
                              fontFamily: 'SpaceMono',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!isNarrow && button != null) ...[
                    const SizedBox(width: 10),
                    button,
                  ],
                ],
              ),
              if (isNarrow && button != null) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: button,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Badge status berwarna.
class BapStatusBadge extends StatelessWidget {
  const BapStatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.textColor,
  });
  final String label;
  final Color color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final fg = textColor ?? color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          color: fg,
          fontFamily: 'SpaceMono',
        ),
      ),
    );
  }
}

/// Kartu section dengan border dan shadow retro ringan.
class BapSectionCard extends StatelessWidget {
  const BapSectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            offset: Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      padding: padding,
      child: child,
    );
  }
}

/// Baris info key-value ringkas.
class BapInfoRow extends StatelessWidget {
  const BapInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.muted,
                fontFamily: 'SpaceMono',
              ),
            ),
          ),
          const Text(
            ': ',
            style: TextStyle(fontSize: 11, color: AppTheme.muted),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppTheme.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip statistik kecil vertikal.
class BapMiniStat extends StatelessWidget {
  const BapMiniStat({
    super.key,
    required this.value,
    required this.label,
    required this.color,
  });
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
            fontFamily: 'SpaceMono',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9.5,
            color: AppTheme.muted,
            fontFamily: 'SpaceMono',
          ),
        ),
      ],
    );
  }
}

/// Dialog modal retro-modern yang elegan, rapi, dan terpadu untuk Dashboard BAP.
/// Menggantikan AlertDialog standar yang terlalu tebal garis hitamnya.
class BapDialogShell extends StatelessWidget {
  const BapDialogShell({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.tune_outlined,
    Color? headerColor,
    Color? accentColor,
    Widget? child,
    Widget? body,
    required this.actions,
    this.maxWidth = 540,
  }) : headerColor = accentColor ?? headerColor ?? const Color(0xFF0F4C81),
       child = body ?? child ?? const SizedBox();

  final String title;
  final String? subtitle;
  final IconData icon;
  final Color headerColor;
  final Widget child;
  final List<Widget> actions;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppTheme.ink, width: 2.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x35000000),
                offset: Offset(4, 5),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: headerColor,
                child: Row(
                  children: [
                    Icon(icon, color: Colors.white, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppTheme.pixel(8, color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle!,
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: Color(0xFFDCECEF),
                                fontFamily: 'SpaceMono',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Tutup',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Area konten form scrollable
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: child,
                ),
              ),

              // Area tombol aksi
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
                ),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 8,
                  children: actions,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kolom input form dengan label di atas, border 1.5px halus, dan SpaceMono.
class BapTextField extends StatelessWidget {
  const BapTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    String? hintText,
    this.numeric = false,
    TextInputType? keyboardType,
    this.maxLines = 1,
    this.enabled = true,
  }) : hintText = hintText ?? hint,
       keyboardType = keyboardType ?? (numeric ? TextInputType.number : TextInputType.text);

  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? hintText;
  final bool numeric;
  final TextInputType keyboardType;
  final int maxLines;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Color(0xFF475569),
            fontFamily: 'SpaceMono',
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 12, fontFamily: 'SpaceMono'),
          decoration: InputDecoration(
            isDense: true,
            hintText: hintText,
            hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            filled: true,
            fillColor: enabled ? Colors.white : const Color(0xFFF1F5F9),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
            ),
            enabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: Color(0xFF0F4C81), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

/// Dropdown form elegan dengan styling yang cocok dengan BapTextField.
class BapDropdownField<T> extends StatelessWidget {
  const BapDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Color(0xFF475569),
            fontFamily: 'SpaceMono',
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<T>(
          initialValue: value,
          isDense: true,
          style: const TextStyle(fontSize: 12, color: AppTheme.ink, fontFamily: 'SpaceMono'),
          decoration: const InputDecoration(
            isDense: true,
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: Color(0xFF0F4C81), width: 2),
            ),
          ),
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
