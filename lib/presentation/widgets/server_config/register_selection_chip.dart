import 'package:flutter/material.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/utils/extensions.dart';

class RegisterSelectionChip extends StatelessWidget {
  final String registerId;
  final String registerName;
  final String? unit;
  final bool isSelected;
  final ValueChanged<bool> onChanged;

  const RegisterSelectionChip({
    super.key,
    required this.registerId,
    required this.registerName,
    this.unit,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!isSelected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        constraints: const BoxConstraints(minWidth: 100),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColor.primaryColor
              : AppColor.whiteColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColor.primaryColor
                : AppColor.grey.withValues(alpha:0.3),
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColor.primaryColor.withValues(alpha:0.2)
                  : Colors.black.withValues(alpha:0.03),
              blurRadius: isSelected ? 4 : 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Checkbox + Name
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Checkmark icon (only show when selected)
                if (isSelected) ...[
                  Icon(
                    Icons.check_circle,
                    size: 14,
                    color: AppColor.whiteColor,
                  ),
                  const SizedBox(width: 4),
                ],
                // Register Name
                Flexible(
                  child: Text(
                    registerName,
                    style: context.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      color: isSelected
                          ? AppColor.whiteColor
                          : AppColor.blackColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            // Register ID
            Text(
              registerId,
              style: context.bodySmall.copyWith(
                fontSize: 8,
                color: isSelected
                    ? AppColor.whiteColor.withValues(alpha:0.8)
                    : AppColor.grey,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Unit (if provided)
            if (unit != null && unit!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColor.whiteColor.withValues(alpha:0.2)
                      : AppColor.primaryColor.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  unit!,
                  style: context.bodySmall.copyWith(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? AppColor.whiteColor
                        : AppColor.primaryColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
