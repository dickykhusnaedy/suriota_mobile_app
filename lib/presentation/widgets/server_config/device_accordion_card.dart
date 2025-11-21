import 'package:flutter/material.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/utils/extensions.dart';
import 'package:gateway_config/presentation/widgets/server_config/register_selection_chip.dart';

class DeviceAccordionCard extends StatefulWidget {
  final String deviceId;
  final String deviceName;
  final List<Map<String, dynamic>> registers;
  final Set<String> selectedRegisterIds;
  final ValueChanged<Set<String>> onSelectionChanged;
  final bool initiallyExpanded;

  const DeviceAccordionCard({
    super.key,
    required this.deviceId,
    required this.deviceName,
    required this.registers,
    required this.selectedRegisterIds,
    required this.onSelectionChanged,
    this.initiallyExpanded = false,
  });

  @override
  State<DeviceAccordionCard> createState() => _DeviceAccordionCardState();
}

class _DeviceAccordionCardState extends State<DeviceAccordionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _iconRotation;
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _iconRotation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (_isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _handleRegisterToggle(String registerId, bool isSelected) {
    final newSelection = Set<String>.from(widget.selectedRegisterIds);
    if (isSelected) {
      newSelection.add(registerId);
    } else {
      newSelection.remove(registerId);
    }
    widget.onSelectionChanged(newSelection);
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = widget.selectedRegisterIds.length;
    final hasSelection = selectedCount > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColor.whiteColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasSelection
              ? AppColor.primaryColor.withValues(alpha:0.3)
              : AppColor.grey.withValues(alpha:0.2),
          width: hasSelection ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: hasSelection
                ? AppColor.primaryColor.withValues(alpha:0.08)
                : Colors.black.withValues(alpha:0.03),
            blurRadius: hasSelection ? 6 : 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: _toggleExpansion,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Device Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: hasSelection
                          ? AppColor.primaryColor.withValues(alpha:0.1)
                          : AppColor.grey.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.device_hub,
                      size: 18,
                      color: hasSelection ? AppColor.primaryColor : AppColor.grey,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Device Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.deviceName,
                          style: context.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColor.blackColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ID: ${widget.deviceId}',
                          style: context.bodySmall.copyWith(
                            fontSize: 10,
                            color: AppColor.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Selection Badge
                  if (hasSelection) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColor.primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$selectedCount',
                        style: context.bodySmall.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColor.whiteColor,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(width: 8),

                  // Chevron Icon
                  RotationTransition(
                    turns: _iconRotation,
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColor.grey,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Registers List (only render when expanded)
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: widget.registers.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'No registers available',
                          style: context.bodySmall.copyWith(
                            color: AppColor.grey,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.registers.map((register) {
                        final registerId = register['register_id'] ?? '';
                        final registerName = register['register_name'] ?? '';
                        final unit = register['unit'];
                        final isSelected =
                            widget.selectedRegisterIds.contains(registerId);

                        return RegisterSelectionChip(
                          registerId: registerId,
                          registerName: registerName,
                          unit: unit,
                          isSelected: isSelected,
                          onChanged: (selected) =>
                              _handleRegisterToggle(registerId, selected),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}
