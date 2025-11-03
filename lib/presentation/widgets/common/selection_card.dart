import 'package:flutter/material.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/utils/extensions.dart';

/// Selection Card Item Model
class SelectionCardItem<T> {
  final T value;
  final String title;
  final String subtitle;
  final IconData icon;

  const SelectionCardItem({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

/// Selection Card Widget
///
/// Example:
/// ```dart
/// SelectionCard<String>(
///   items: [
///     SelectionCardItem(
///       value: 'RTU',
///       title: 'Modbus RTU',
///       subtitle: 'Serial communication',
///       icon: Icons.settings_input_component,
///     ),
///     SelectionCardItem(
///       value: 'TCP',
///       title: 'Modbus TCP',
///       subtitle: 'Ethernet/IP communication',
///       icon: Icons.lan,
///     ),
///   ],
///   selectedValue: selectedModbus,
///   onChanged: (value) => setState(() => selectedModbus = value),
/// )
/// ```
class SelectionCard<T> extends StatelessWidget {
  final List<SelectionCardItem<T>> items;
  final T? selectedValue;
  final ValueChanged<T> onChanged;
  final EdgeInsets? padding;
  final double? spacing;

  const SelectionCard({
    super.key,
    required this.items,
    required this.selectedValue,
    required this.onChanged,
    this.padding,
    this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.whiteColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColor.primaryColor.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      padding: padding ?? const EdgeInsets.all(4),
      child: Column(
        children: List.generate(
          items.length,
          (index) {
            final isLast = index == items.length - 1;
            return Column(
              children: [
                _SelectionCardOption<T>(
                  item: items[index],
                  isSelected: items[index].value == selectedValue,
                  onTap: () => onChanged(items[index].value),
                ),
                if (!isLast) SizedBox(height: spacing ?? 4),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SelectionCardOption<T> extends StatelessWidget {
  final SelectionCardItem<T> item;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectionCardOption({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColor.primaryColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColor.primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // Icon Container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColor.primaryColor
                    : AppColor.grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                item.icon,
                color: isSelected ? AppColor.whiteColor : AppColor.grey,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            // Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: context.h6.copyWith(
                      color: isSelected
                          ? AppColor.primaryColor
                          : AppColor.blackColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: context.bodySmall.copyWith(
                      color: AppColor.grey,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            // Check Icon
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? AppColor.primaryColor : AppColor.grey,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
