import 'package:flutter/material.dart';
import 'package:gateway_config/core/constants/app_color.dart';

/// Compact Icon Button Widget
///
/// Example:
/// ```dart
/// CompactIconButton(
///   icon: Icons.edit,
///   color: AppColor.primaryColor,
///   onPressed: () => print('Edit clicked'),
/// )
/// CompactIconButton(
///   icon: Icons.delete,
///   color: AppColor.redColor,
///   onPressed: null, // Disabled state
/// )
/// ```
class CompactIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final double? size;
  final double? iconSize;
  final String? tooltip;

  const CompactIconButton({
    super.key,
    required this.icon,
    required this.color,
    this.onPressed,
    this.size,
    this.iconSize,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final buttonSize = size ?? 32;
    final buttonIconSize = iconSize ?? 16;
    final isDisabled = onPressed == null;
    final buttonColor = isDisabled ? AppColor.grey : color;

    final button = Container(
      width: buttonSize,
      height: buttonSize,
      decoration: BoxDecoration(
        color: buttonColor,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: buttonColor.withValues(alpha: 0.25),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: buttonIconSize, color: AppColor.whiteColor),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }

    return button;
  }
}

/// Compact Icon Button Row
///
/// Widget untuk membuat row dari compact icon buttons dengan spacing konsisten.
///
/// Example:
/// ```dart
/// CompactIconButtonRow(
///   buttons: [
///     CompactIconButton(
///       icon: Icons.edit,
///       color: AppColor.primaryColor,
///       onPressed: () {},
///     ),
///     CompactIconButton(
///       icon: Icons.delete,
///       color: AppColor.redColor,
///       onPressed: () {},
///     ),
///   ],
/// )
/// ```
class CompactIconButtonRow extends StatelessWidget {
  final List<Widget> buttons;
  final double? spacing;
  final MainAxisSize mainAxisSize;

  const CompactIconButtonRow({
    super.key,
    required this.buttons,
    this.spacing,
    this.mainAxisSize = MainAxisSize.min,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: mainAxisSize,
      children: List.generate(buttons.length * 2 - 1, (index) {
        if (index.isOdd) {
          return SizedBox(width: spacing ?? 6);
        }
        return buttons[index ~/ 2];
      }),
    );
  }
}

/// Compact Icon Button Column
///
/// Widget untuk membuat column dari compact icon buttons dengan spacing konsisten.
///
/// Example:
/// ```dart
/// CompactIconButtonColumn(
///   buttons: [
///     CompactIconButton(
///       icon: Icons.edit,
///       color: AppColor.primaryColor,
///       onPressed: () {},
///     ),
///     CompactIconButton(
///       icon: Icons.delete,
///       color: AppColor.redColor,
///       onPressed: () {},
///     ),
///   ],
/// )
/// ```
class CompactIconButtonColumn extends StatelessWidget {
  final List<Widget> buttons;
  final double? spacing;
  final MainAxisSize mainAxisSize;

  const CompactIconButtonColumn({
    super.key,
    required this.buttons,
    this.spacing,
    this.mainAxisSize = MainAxisSize.min,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: mainAxisSize,
      children: List.generate(buttons.length * 2 - 1, (index) {
        if (index.isOdd) {
          return SizedBox(height: spacing ?? 6);
        }
        return buttons[index ~/ 2];
      }),
    );
  }
}
