import 'package:flutter/material.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/constants/app_gap.dart';
import 'package:gateway_config/core/utils/extensions.dart';

/// Alert Type Enum
enum AlertType {
  success,
  info,
  warning,
  danger,
}

/// Custom Alert Widget
///
/// Reusable alert widget dengan berbagai tipe dan customizable
///
/// Example:
/// ```dart
/// CustomAlertWidget(
///   type: AlertType.info,
///   title: 'Temporary Session',
///   description: 'Device connection history will be cleared...',
/// )
///
/// CustomAlertWidget(
///   type: AlertType.success,
///   icon: Icons.check_circle,
///   title: 'Success',
///   description: 'Operation completed successfully',
/// )
/// ```
class CustomAlertWidget extends StatelessWidget {
  final AlertType type;
  final IconData? icon;
  final String title;
  final String description;
  final bool isResponsive;

  const CustomAlertWidget({
    super.key,
    required this.type,
    this.icon,
    required this.title,
    required this.description,
    this.isResponsive = true,
  });

  /// Get alert configuration based on type
  _AlertConfig _getConfig() {
    switch (type) {
      case AlertType.success:
        return _AlertConfig(
          icon: icon ?? Icons.check_circle_outline,
          primaryColor: Colors.green,
          backgroundColor: Colors.green.withValues(alpha: 0.08),
          borderColor: Colors.green.withValues(alpha: 0.2),
          iconBackgroundColor: Colors.green.withValues(alpha: 0.15),
        );
      case AlertType.info:
        return _AlertConfig(
          icon: icon ?? Icons.info_outline,
          primaryColor: AppColor.primaryColor,
          backgroundColor: AppColor.primaryColor.withValues(alpha: 0.08),
          borderColor: AppColor.primaryColor.withValues(alpha: 0.2),
          iconBackgroundColor: AppColor.primaryColor.withValues(alpha: 0.15),
        );
      case AlertType.warning:
        return _AlertConfig(
          icon: icon ?? Icons.warning_amber_outlined,
          primaryColor: Colors.orange,
          backgroundColor: Colors.orange.withValues(alpha: 0.08),
          borderColor: Colors.orange.withValues(alpha: 0.2),
          iconBackgroundColor: Colors.orange.withValues(alpha: 0.15),
        );
      case AlertType.danger:
        return _AlertConfig(
          icon: icon ?? Icons.error_outline,
          primaryColor: AppColor.redColor,
          backgroundColor: AppColor.redColor.withValues(alpha: 0.08),
          borderColor: AppColor.redColor.withValues(alpha: 0.2),
          iconBackgroundColor: AppColor.redColor.withValues(alpha: 0.15),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = _getConfig();
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = isResponsive && screenWidth <= 600;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            config.backgroundColor,
            config.backgroundColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: config.borderColor,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: config.iconBackgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              config.icon,
              color: config.primaryColor,
              size: isSmallScreen ? 20 : 24,
            ),
          ),
          AppSpacing.sm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: (isSmallScreen ? context.h6 : context.h5).copyWith(
                    color: config.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: context.bodySmall.copyWith(
                    color: AppColor.grey,
                    fontSize: isSmallScreen ? 11 : 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Alert Configuration Class
class _AlertConfig {
  final IconData icon;
  final Color primaryColor;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconBackgroundColor;

  _AlertConfig({
    required this.icon,
    required this.primaryColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.iconBackgroundColor,
  });
}
