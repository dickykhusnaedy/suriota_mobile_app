import 'package:flutter/material.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/utils/extensions.dart';

/// Info Badge Widget
///
/// Example:
/// ```dart
/// InfoBadge(text: 'RTU')
/// InfoBadge(
///   text: 'Active',
///   icon: Icons.check_circle,
///   backgroundColor: Colors.green,
/// )
/// InfoBadge(
///   text: 'Premium',
///   backgroundColor: AppColor.primaryColor,
///   textColor: AppColor.whiteColor,
/// )
/// ```
class InfoBadge extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? textColor;
  final Color? iconColor;
  final double? fontSize;
  final EdgeInsets? padding;
  final double? borderRadius;
  final double? iconSize;

  const InfoBadge({
    super.key,
    required this.text,
    this.icon,
    this.backgroundColor,
    this.borderColor,
    this.textColor,
    this.iconColor,
    this.fontSize,
    this.padding,
    this.borderRadius,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ??
            AppColor.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(borderRadius ?? 8),
        border: Border.all(
          color: borderColor ??
              AppColor.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: iconColor ?? textColor ?? AppColor.primaryColor,
              size: iconSize ?? 12,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: context.bodySmall.copyWith(
              color: textColor ?? AppColor.primaryColor,
              fontSize: fontSize ?? 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Info Badge Variants
///
/// Preset badge variants untuk use case umum
class InfoBadgeVariants {
  /// Success Badge (Green)
  static Widget success(String text, {IconData? icon}) {
    return InfoBadge(
      text: text,
      icon: icon ?? Icons.check_circle,
      backgroundColor: Colors.green.withValues(alpha: 0.1),
      borderColor: Colors.green.withValues(alpha: 0.3),
      textColor: Colors.green.shade700,
      iconColor: Colors.green.shade700,
    );
  }

  /// Error Badge (Red)
  static Widget error(String text, {IconData? icon}) {
    return InfoBadge(
      text: text,
      icon: icon ?? Icons.error,
      backgroundColor: AppColor.redColor.withValues(alpha: 0.1),
      borderColor: AppColor.redColor.withValues(alpha: 0.3),
      textColor: AppColor.redColor,
      iconColor: AppColor.redColor,
    );
  }

  /// Warning Badge (Orange)
  static Widget warning(String text, {IconData? icon}) {
    return InfoBadge(
      text: text,
      icon: icon ?? Icons.warning,
      backgroundColor: Colors.orange.withValues(alpha: 0.1),
      borderColor: Colors.orange.withValues(alpha: 0.3),
      textColor: Colors.orange.shade700,
      iconColor: Colors.orange.shade700,
    );
  }

  /// Info Badge (Blue)
  static Widget info(String text, {IconData? icon}) {
    return InfoBadge(
      text: text,
      icon: icon ?? Icons.info,
      backgroundColor: Colors.blue.withValues(alpha: 0.1),
      borderColor: Colors.blue.withValues(alpha: 0.3),
      textColor: Colors.blue.shade700,
      iconColor: Colors.blue.shade700,
    );
  }

  /// Primary Badge
  static Widget primary(String text, {IconData? icon}) {
    return InfoBadge(
      text: text,
      icon: icon,
      backgroundColor: AppColor.primaryColor.withValues(alpha: 0.1),
      borderColor: AppColor.primaryColor.withValues(alpha: 0.3),
      textColor: AppColor.primaryColor,
      iconColor: AppColor.primaryColor,
    );
  }

  /// Secondary Badge (Grey)
  static Widget secondary(String text, {IconData? icon}) {
    return InfoBadge(
      text: text,
      icon: icon,
      backgroundColor: AppColor.grey.withValues(alpha: 0.1),
      borderColor: AppColor.grey.withValues(alpha: 0.3),
      textColor: AppColor.grey,
      iconColor: AppColor.grey,
    );
  }

  /// Live Badge (Green with animation dot)
  static Widget live({String text = 'Live'}) {
    return InfoBadge(
      text: text,
      icon: Icons.circle,
      iconSize: 8,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      iconColor: Colors.white,
      fontSize: 10,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      borderColor: Colors.transparent,
    );
  }
}
