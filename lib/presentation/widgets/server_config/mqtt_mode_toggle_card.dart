import 'package:flutter/material.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/utils/extensions.dart';

class MqttModeToggleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isEnabled;
  final ValueChanged<bool> onChanged;
  final Color? accentColor;

  const MqttModeToggleCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.isEnabled,
    required this.onChanged,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveAccentColor = accentColor ?? AppColor.primaryColor;

    return GestureDetector(
      onTap: () => onChanged(!isEnabled),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColor.whiteColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEnabled
                ? effectiveAccentColor.withValues(alpha: 0.4)
                : AppColor.grey.withValues(alpha: 0.2),
            width: isEnabled ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isEnabled
                  ? effectiveAccentColor.withValues(alpha:0.1)
                  : Colors.black.withValues(alpha:0.03),
              blurRadius: isEnabled ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isEnabled
                    ? effectiveAccentColor.withValues(alpha:0.1)
                    : AppColor.grey.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isEnabled ? effectiveAccentColor : AppColor.grey,
              ),
            ),
            const SizedBox(width: 12),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isEnabled
                          ? AppColor.blackColor
                          : AppColor.grey.withValues(alpha:0.8),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: context.bodySmall.copyWith(
                      fontSize: 10,
                      color: AppColor.grey,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Toggle Switch
            GestureDetector(
              onTap: () => onChanged(!isEnabled),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 24,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: isEnabled
                      ? LinearGradient(
                          colors: [
                            effectiveAccentColor,
                            effectiveAccentColor.withValues(alpha:0.8),
                          ],
                        )
                      : null,
                  color: isEnabled ? null : AppColor.grey.withValues(alpha:0.3),
                  boxShadow: [
                    if (isEnabled)
                      BoxShadow(
                        color: effectiveAccentColor.withValues(alpha:0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  alignment:
                      isEnabled ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColor.whiteColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha:0.2),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
