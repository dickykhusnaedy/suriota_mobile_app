import 'package:flutter/material.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/constants/app_gap.dart';
import 'package:gateway_config/core/controllers/ble_controller.dart';
import 'package:gateway_config/core/controllers/devices_controller.dart';
import 'package:gateway_config/core/controllers/modbus_controller.dart';
import 'package:gateway_config/core/utils/app_helpers.dart';
import 'package:gateway_config/core/utils/extensions.dart';
import 'package:gateway_config/core/utils/loading_progress.dart';
import 'package:gateway_config/core/utils/snackbar_custom.dart';
import 'package:gateway_config/models/device_model.dart';
import 'package:gateway_config/models/dropdown_items.dart';
import 'package:gateway_config/presentation/widgets/common/custom_alert_dialog.dart';
import 'package:gateway_config/presentation/widgets/common/dropdown.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

class ModbusScreen extends StatefulWidget {
  const ModbusScreen({super.key, required this.model});
  final DeviceModel model;

  @override
  State<ModbusScreen> createState() => _ModbusScreenState();
}

class _ModbusScreenState extends State<ModbusScreen> {
  final BleController bleController;
  final DevicesController controller;

  final ModbusController modbusController = Get.put(
    ModbusController(),
    permanent: true,
  );

  bool isLoading = false;
  bool isInitialized = false;

  DropdownItems? selectedDevice;

  _ModbusScreenState()
    : bleController = Get.put(BleController(), permanent: true),
      controller = Get.put(DevicesController(), permanent: true) {
    debugPrint('Initialized BleController and DeviceController with Get.put');
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        modbusController.dataModbus.clear();

        controller.fetchDevices(widget.model);
        isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    isInitialized = false;
    super.dispose();
  }

  void _deleteDataModbus(String deviceId, String registerId) async {
    AppHelpers.debugLog(
      'delete data device $deviceId dan register $registerId',
    );
    if (!widget.model.isConnected.value) {
      SnackbarCustom.showSnackbar(
        '',
        'Device not connected',
        AppColor.redColor,
        AppColor.whiteColor,
      );
      return;
    }

    CustomAlertDialog.show(
      title: "Are you sure?",
      message: "Are you sure you want to delete this device?",
      primaryButtonText: 'Yes',
      secondaryButtonText: 'No',
      onPrimaryPressed: () async {
        Get.back();
        modbusController.isFetching.value = true;

        try {
          await modbusController.deleteDevice(
            widget.model,
            deviceId,
            registerId,
          );

          if (Get.context != null) {
            SnackbarCustom.showSnackbar(
              '',
              'Modbus config deleted successfully, refreshing data...',
              Colors.green,
              AppColor.whiteColor,
            );
          }

          await modbusController.fetchDevices(widget.model, deviceId);
        } catch (e) {
          SnackbarCustom.showSnackbar(
            '',
            'Failed to delete modbus config',
            AppColor.redColor,
            AppColor.whiteColor,
          );
        } finally {
          modbusController.isFetching.value = false;
        }
      },
      barrierDismissible: false,
    );
  }

  Widget _emptyView(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.50,
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColor.whiteColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColor.primaryColor.withValues(alpha: 0.1),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.settings_input_component,
              size: 64,
              color: AppColor.grey.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Modbus Configuration',
              textAlign: TextAlign.center,
              style: context.h6.copyWith(
                color: AppColor.blackColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please create or select a device to continue.',
              textAlign: TextAlign.center,
              style: context.bodySmall.copyWith(
                color: AppColor.grey,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<DropdownItems> deviceItem = controller.dataDevices
        .map(
          (data) => DropdownItems(
            text: data['device_name'],
            value: data['device_id'],
          ),
        )
        .toList();

    return Scaffold(
      appBar: _appBar(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppPadding.horizontalMedium,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSpacing.md,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Choose Device',
                    style: context.h5,
                    overflow: TextOverflow.ellipsis,
                  ),
                  TextButton.icon(
                    onPressed: () => controller.fetchDevices(widget.model),
                    label: const Icon(Icons.rotate_left, size: 20),
                    style: TextButton.styleFrom(
                      iconColor: AppColor.primaryColor,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              AppSpacing.sm,
              Obx(() {
                if (controller.isFetching.value) {
                  return LoadingProgress();
                }

                if (controller.dataDevices.isEmpty) {
                  return _emptyView(context);
                }

                return Dropdown(
                  items: deviceItem,
                  selectedValue: selectedDevice?.value,
                  onChanged: (item) {
                    modbusController.fetchDevices(widget.model, item!.value);
                    setState(() {
                      selectedDevice = item;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select an device';
                    }
                    return null;
                  },
                  isRequired: true,
                );
              }),
              AppSpacing.md,
              Obx(() {
                if (modbusController.isFetching.value) {
                  return LoadingProgress();
                }

                if (modbusController.dataModbus.isEmpty) {
                  return _emptyView(context);
                }

                return Column(
                  children: [
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: modbusController.dataModbus.length,
                      separatorBuilder: (context, index) => AppSpacing.sm,
                      itemBuilder: (context, int index) {
                        final item = modbusController.dataModbus[index];

                        return cardDataConfig(item, index);
                      },
                    ),
                    AppSpacing.md,
                    Obx(() {
                      if (modbusController.dataModbus.isNotEmpty &&
                          !bleController.isLoading.value) {
                        return Center(
                          child: Text(
                            'Showing ${modbusController.dataModbus.length} entries',
                            style: context.bodySmall,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                  ],
                );
              }),
              AppSpacing.md,
            ],
          ),
        ),
      ),
    );
  }

  AppBar _appBar(BuildContext context) {
    return AppBar(
      title: Text(
        'Modbus Configuration',
        style: context.h5.copyWith(color: AppColor.whiteColor),
      ),
      backgroundColor: AppColor.primaryColor,
      centerTitle: true,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        IconButton(
          onPressed: () {
            if (controller.dataDevices.isEmpty) {
              CustomAlertDialog.show(
                title: "No Devices Available",
                message:
                    "Please add a device or scan device first before adding Modbus configuration.",
                primaryButtonText: 'OK',
                onPrimaryPressed: () {
                  Get.back();
                },
                barrierDismissible: false,
              );

              return;
            }
            context.push(
              '/devices/modbus-config/add?d=${widget.model.device.remoteId}',
            );
          },
          icon: const Icon(Icons.add_circle, size: 22),
        ),
      ],
    );
  }

  Widget cardDataConfig(Map<String, dynamic> modbus, int index) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.whiteColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColor.primaryColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColor.lightPrimaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.storage,
                color: AppColor.primaryColor,
                size: 28,
              ),
            ),
            AppSpacing.sm,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Register Name
                  Text(
                    modbus['register_name'] ?? 'Unknown Register',
                    style: context.h5.copyWith(
                      color: AppColor.blackColor,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  AppSpacing.xs,
                  // Address
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: AppColor.grey,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          'Address: ${modbus['address']}',
                          style: context.bodySmall.copyWith(
                            color: AppColor.grey,
                            fontSize: 10,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.xs,
                  // Data Type Badge
                  _buildDataTypeBadge(context, modbus['data_type'] ?? 'N/A'),
                ],
              ),
            ),
            AppSpacing.sm,
            // Kolom Kanan: Action Buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildIconButton(
                  icon: Icons.edit,
                  color: AppColor.primaryColor,
                  onPressed: () {
                    context.push(
                      '/devices/modbus-config/edit?d=${widget.model.device.remoteId}&device_id=${selectedDevice!.value}&register_id=${modbus['register_id']}',
                    );
                  },
                ),
                AppSpacing.xs,
                _buildIconButton(
                  icon: Icons.delete,
                  color: AppColor.redColor,
                  onPressed: selectedDevice != null
                      ? () => _deleteDataModbus(
                          selectedDevice!.value,
                          modbus['register_id'],
                        )
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTypeBadge(BuildContext context, String dataType) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColor.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColor.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        dataType,
        style: context.bodySmall.copyWith(
          color: AppColor.primaryColor,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    VoidCallback? onPressed,
  }) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: onPressed != null ? color : AppColor.grey,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: (onPressed != null ? color : AppColor.grey).withValues(
              alpha: 0.25,
            ),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 14, color: AppColor.whiteColor),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );
  }
}
