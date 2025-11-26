import 'package:flutter/material.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/constants/app_gap.dart';
import 'package:gateway_config/core/utils/extensions.dart';
import 'package:gateway_config/models/dropdown_items.dart';
import 'package:gateway_config/presentation/widgets/common/custom_textfield.dart';
import 'package:gateway_config/presentation/widgets/common/dropdown.dart';
import 'package:gateway_config/presentation/widgets/server_config/device_accordion_card.dart';

class CustomTopicCard extends StatefulWidget {
  final int index;
  final String topicName;
  final int intervalValue;
  final String intervalUnit;
  final Map<String, Set<String>> selectedRegisters;
  final List<Map<String, dynamic>> devicesWithRegisters;
  final ValueChanged<Map<String, dynamic>> onTopicChanged;
  final VoidCallback onRemove;
  final bool canRemove;

  const CustomTopicCard({
    super.key,
    required this.index,
    required this.topicName,
    required this.intervalValue,
    required this.intervalUnit,
    required this.selectedRegisters,
    required this.devicesWithRegisters,
    required this.onTopicChanged,
    required this.onRemove,
    this.canRemove = true,
  });

  @override
  State<CustomTopicCard> createState() => _CustomTopicCardState();
}

class _CustomTopicCardState extends State<CustomTopicCard> {
  late TextEditingController _topicNameController;
  late TextEditingController _intervalValueController;
  late String _selectedIntervalUnit;

  // Available interval units
  final List<DropdownItems> _intervalUnits = [
    DropdownItems(text: 'Seconds', value: 's'),
    DropdownItems(text: 'Minutes', value: 'm'),
    DropdownItems(text: 'Hours', value: 'h'),
  ];

  @override
  void initState() {
    super.initState();
    _topicNameController = TextEditingController(text: widget.topicName);
    _intervalValueController = TextEditingController(
      text: widget.intervalValue.toString(),
    );
    _selectedIntervalUnit = widget.intervalUnit;

    // Add listeners for text changes
    _topicNameController.addListener(_notifyChanges);
    _intervalValueController.addListener(_notifyChanges);
  }

  @override
  void dispose() {
    _topicNameController.dispose();
    _intervalValueController.dispose();
    super.dispose();
  }

  void _notifyChanges() {
    widget.onTopicChanged({
      'topicName': _topicNameController.text,
      'intervalValue': _intervalValueController.intValue ?? 0,
      'intervalUnit': _selectedIntervalUnit,
      'selectedRegisters': widget.selectedRegisters,
    });
  }

  void _handleDeviceSelectionChanged(String deviceId, Set<String> registerIds) {
    final updatedSelection = Map<String, Set<String>>.from(
      widget.selectedRegisters,
    );

    if (registerIds.isEmpty) {
      updatedSelection.remove(deviceId);
    } else {
      updatedSelection[deviceId] = registerIds;
    }

    widget.onTopicChanged({
      'topicName': _topicNameController.text,
      'intervalValue': _intervalValueController.intValue ?? 0,
      'intervalUnit': _selectedIntervalUnit,
      'selectedRegisters': updatedSelection,
    });
  }

  int _getTotalSelectedRegisters() {
    return widget.selectedRegisters.values
        .fold(0, (sum, registerSet) => sum + registerSet.length);
  }

  @override
  Widget build(BuildContext context) {
    final totalSelected = _getTotalSelectedRegisters();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.whiteColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColor.primaryColor.withValues(alpha:0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              // Topic Number Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColor.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Topic ${widget.index + 1}',
                  style: context.bodySmall.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColor.whiteColor,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Selected Count Badge
              if (totalSelected > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColor.primaryColor.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColor.primaryColor.withValues(alpha:0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 12,
                        color: AppColor.primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$totalSelected selected',
                        style: context.bodySmall.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColor.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),

              const Spacer(),

              // Remove Button
              if (widget.canRemove)
                IconButton(
                  onPressed: widget.onRemove,
                  icon: Icon(
                    Icons.delete_outline,
                    color: AppColor.redColor,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Remove topic',
                ),
            ],
          ),

          AppSpacing.md,

          // Topic Name Input
          CustomTextFormField(
            controller: _topicNameController,
            labelTxt: 'Topic Name',
            hintTxt: 'e.g., temperature_sensors',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Topic name is required';
              }
              return null;
            },
            isRequired: true,
          ),

          AppSpacing.md,

          // Interval Configuration
          Row(
            children: [
              Expanded(
                flex: 2,
                child: CustomTextFormField(
                  controller: _intervalValueController,
                  labelTxt: 'Interval',
                  hintTxt: '5',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    final num = ThousandsSeparatorInputFormatter.getIntValue(value);
                    if (num == null || num <= 0) {
                      return 'Invalid';
                    }
                    return null;
                  },
                  isRequired: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: Dropdown(
                  items: _intervalUnits,
                  selectedValue: _selectedIntervalUnit,
                  label: 'Unit',
                  onChanged: (item) {
                    setState(() {
                      _selectedIntervalUnit = item!.value;
                      _notifyChanges();
                    });
                  },
                  isRequired: true,
                ),
              ),
            ],
          ),

          AppSpacing.md,

          // Section Divider
          Row(
            children: [
              Icon(
                Icons.devices,
                size: 16,
                color: AppColor.grey,
              ),
              const SizedBox(width: 6),
              Text(
                'Select Devices & Registers',
                style: context.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppColor.grey.withValues(alpha:0.8),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Divider(
                  color: AppColor.grey.withValues(alpha:0.2),
                  thickness: 1,
                ),
              ),
            ],
          ),

          AppSpacing.md,

          // Devices Accordion List
          if (widget.devicesWithRegisters.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColor.grey.withValues(alpha:0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColor.grey.withValues(alpha:0.2),
                  width: 1,
                ),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.devices_other,
                      size: 32,
                      color: AppColor.grey.withValues(alpha:0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No devices available',
                      style: context.bodySmall.copyWith(
                        color: AppColor.grey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...widget.devicesWithRegisters.map((device) {
              final deviceId = device['device_id'] ?? '';
              final deviceName = device['device_name'] ?? '';
              final registers = List<Map<String, dynamic>>.from(
                device['registers'] ?? [],
              );
              final selectedForDevice =
                  widget.selectedRegisters[deviceId] ?? {};

              return DeviceAccordionCard(
                deviceId: deviceId,
                deviceName: deviceName,
                registers: registers,
                selectedRegisterIds: selectedForDevice,
                onSelectionChanged: (newSelection) {
                  _handleDeviceSelectionChanged(deviceId, newSelection);
                },
              );
            }),

          // Info Text
          if (widget.devicesWithRegisters.isNotEmpty) ...[
            AppSpacing.sm,
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColor.primaryColor.withValues(alpha:0.05),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 12,
                    color: AppColor.primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Tap device to expand and select registers',
                      style: context.bodySmall.copyWith(
                        fontSize: 9,
                        color: AppColor.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
