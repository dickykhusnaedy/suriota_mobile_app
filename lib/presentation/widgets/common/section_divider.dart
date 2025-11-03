import 'package:flutter/material.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/constants/app_gap.dart';
import 'package:gateway_config/core/utils/extensions.dart';

class SectionDivider extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? textColor;
  final Color? accentColor;

  const SectionDivider({
    super.key,
    required this.title,
    this.icon,
    this.backgroundColor,
    this.borderColor,
    this.textColor,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColor.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: borderColor ?? AppColor.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Accent bar
          Container(
            width: 2,
            height: 20,
            decoration: BoxDecoration(
              color: accentColor ?? AppColor.primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          AppSpacing.sm,
          // Optional icon
          if (icon != null) ...[
            Icon(icon, color: textColor ?? AppColor.primaryColor, size: 18),
            AppSpacing.sm,
          ],
          // Title
          Expanded(
            child: Text(
              title,
              style: context.h6.copyWith(
                color: textColor ?? AppColor.primaryColor,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
