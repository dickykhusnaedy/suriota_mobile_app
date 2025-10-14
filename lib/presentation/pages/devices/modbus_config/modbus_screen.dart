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
import 'package:gateway_config/presentation/widgets/common/custom_button.dart';
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

  Container _emptyView(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.70,
      alignment: Alignment.center,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Oops!... \nNo Modbus configuration found.',
              textAlign: TextAlign.center,
              style: context.buttonText.copyWith(color: AppColor.blackColor),
            ),
            AppSpacing.xs,
            Text(
              'Please create or select one of device to continue.',
              textAlign: TextAlign.center,
              style: context.bodySmall.copyWith(color: AppColor.grey),
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
                // return ListView.separated(
                //   shrinkWrap: true,
                //   physics: const NeverScrollableScrollPhysics(),
                //   itemCount: controller.dataDevices.length,
                //   separatorBuilder: (context, index) => AppSpacing.md,
                //   itemBuilder: (context, int index) {
                //     final item = controller.dataDevices[index];

                //     return cardDataConfig(item, index);
                //   },
                // );
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
                      separatorBuilder: (context, index) => AppSpacing.md,
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
            context.push(
              '/devices/modbus-config/add?d=${widget.model.device.remoteId}',
            );
          },
          icon: const Icon(Icons.add_circle, size: 22),
        ),
      ],
    );
  }

  Card cardDataConfig(Map<String, dynamic> modbus, int index) {
    return Card(
      color: AppColor.cardColor,
      elevation: 0.0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: AppPadding.medium,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(modbus['register_name'], style: context.h5),
            AppSpacing.xs,
            Text('Address : ${modbus['address']}', style: context.bodySmall),
            AppSpacing.xs,
            Text(
              'Data Type : ${modbus['data_type']}',
              style: context.bodySmall,
            ),
            AppSpacing.sm,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  flex: 1,
                  child: Button(
                    width: double.infinity,
                    height: 32,
                    onPressed: selectedDevice != null
                        ? () => _deleteDataModbus(
                            selectedDevice!.value,
                            modbus['register_id'],
                          )
                        : null,
                    icons: const Icon(
                      Icons.delete,
                      size: 18,
                      color: AppColor.whiteColor,
                    ),
                    btnColor: AppColor.redColor,
                  ),
                ),
                AppSpacing.md,
                Flexible(
                  flex: 1,
                  child: Button(
                    width: double.infinity,
                    height: 32,
                    onPressed: () => {
                      CustomAlertDialog.show(
                        title: 'Coming soon',
                        message: "This feature is on progress...",
                      ),
                    },
                    // onPressed: () {
                    //   context.push(
                    //     '/devices/modbus-config/edit?d=${widget.model.device.remoteId}&device_id=${selectedDevice!.value}&register_id=${modbus['register_id']}',
                    //   );
                    // },
                    icons: const Icon(
                      Icons.edit,
                      size: 18,
                      color: AppColor.whiteColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
