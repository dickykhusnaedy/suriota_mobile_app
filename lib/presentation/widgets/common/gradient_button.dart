import 'package:flutter/material.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/utils/extensions.dart';

/// Gradient Button Widget
///
/// Example:
/// ```dart
/// GradientButton(
///   text: 'Save Data',
///   onPressed: () => print('Saved'),
/// )
/// GradientButton(
///   text: 'Update Configuration',
///   icon: Icons.update,
///   onPressed: () {},
/// )
/// GradientButton(
///   text: 'Delete',
///   icon: Icons.delete,
///   colors: [AppColor.redColor, AppColor.redColor.withOpacity(0.8)],
///   onPressed: () {},
/// )
/// ```
class GradientButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final List<Color>? colors;
  final double? height;
  final double? width;
  final double? borderRadius;
  final EdgeInsets? padding;
  final TextStyle? textStyle;
  final double? iconSize;
  final double? spacing;
  final bool loading;

  const GradientButton({
    super.key,
    required this.text,
    this.icon,
    this.onPressed,
    this.colors,
    this.height,
    this.width,
    this.borderRadius,
    this.padding,
    this.textStyle,
    this.iconSize,
    this.spacing,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || loading;
    final buttonColors =
        colors ??
        [AppColor.primaryColor, AppColor.primaryColor.withValues(alpha: 0.8)];

    return Container(
      width: width ?? double.infinity,
      height: height ?? 54,
      decoration: BoxDecoration(
        gradient: isDisabled ? null : LinearGradient(colors: buttonColors),
        color: isDisabled ? AppColor.grey : null,
        borderRadius: BorderRadius.circular(borderRadius ?? 12),
        boxShadow: isDisabled
            ? null
            : [
                BoxShadow(
                  color: buttonColors.first.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? 12),
          ),
          padding: padding ?? EdgeInsets.zero,
        ),
        child: loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: AppColor.whiteColor,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      color: AppColor.whiteColor,
                      size: iconSize ?? 22,
                    ),
                    SizedBox(width: spacing ?? 10),
                  ],
                  Flexible(
                    child: Text(
                      text,
                      style:
                          textStyle ??
                          context.h6.copyWith(
                            color: AppColor.whiteColor,
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Gradient Button Variants
///
/// Preset button variants untuk use case umum
class GradientButtonVariants {
  /// Primary Button (Blue Gradient)
  static Widget primary({
    required String text,
    IconData? icon,
    VoidCallback? onPressed,
    bool loading = false,
  }) {
    return GradientButton(
      text: text,
      icon: icon,
      onPressed: onPressed,
      loading: loading,
    );
  }

  /// Success Button (Green Gradient)
  static Widget success({
    required String text,
    IconData? icon,
    VoidCallback? onPressed,
    bool loading = false,
  }) {
    return GradientButton(
      text: text,
      icon: icon ?? Icons.check,
      onPressed: onPressed,
      colors: [Colors.green.shade600, Colors.green.shade700],
      loading: loading,
    );
  }

  /// Danger Button (Red Gradient)
  static Widget danger({
    required String text,
    IconData? icon,
    VoidCallback? onPressed,
    bool loading = false,
  }) {
    return GradientButton(
      text: text,
      icon: icon ?? Icons.delete,
      onPressed: onPressed,
      colors: [AppColor.redColor, AppColor.redColor.withValues(alpha: 0.8)],
      loading: loading,
    );
  }

  /// Secondary Button (Grey Gradient)
  static Widget secondary({
    required String text,
    IconData? icon,
    VoidCallback? onPressed,
    bool loading = false,
  }) {
    return GradientButton(
      text: text,
      icon: icon,
      onPressed: onPressed,
      colors: [Colors.grey.shade600, Colors.grey.shade700],
      loading: loading,
    );
  }

  /// Save Button
  static Widget save({
    String text = 'Save',
    VoidCallback? onPressed,
    bool loading = false,
  }) {
    return GradientButton(
      text: text,
      icon: Icons.save,
      onPressed: onPressed,
      loading: loading,
    );
  }

  /// Update Button
  static Widget update({
    String text = 'Update',
    VoidCallback? onPressed,
    bool loading = false,
  }) {
    return GradientButton(
      text: text,
      icon: Icons.update,
      onPressed: onPressed,
      loading: loading,
    );
  }

  /// Submit Button
  static Widget submit({
    String text = 'Submit',
    VoidCallback? onPressed,
    bool loading = false,
  }) {
    return GradientButton(
      text: text,
      icon: Icons.send,
      onPressed: onPressed,
      loading: loading,
    );
  }
}
