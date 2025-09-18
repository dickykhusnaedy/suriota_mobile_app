import 'package:flutter/material.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/constants/app_gap.dart';
import 'package:gateway_config/core/constants/app_image_assets.dart';
import 'package:gateway_config/core/controllers/ble_controller.dart';
import 'package:gateway_config/core/controllers/devices/device_pagination_controller.dart';
import 'package:gateway_config/core/utils/extensions.dart';
import 'package:gateway_config/core/utils/loading_progress.dart';
import 'package:gateway_config/core/utils/snackbar_custom.dart';
import 'package:gateway_config/models/device_model.dart';
import 'package:gateway_config/presentation/pages/devices/device_communication/data_display_screen.dart';
import 'package:gateway_config/presentation/widgets/common/custom_alert_dialog.dart';
import 'package:gateway_config/presentation/widgets/common/custom_button.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

class DeviceCommunicationsScreen extends StatefulWidget {
  const DeviceCommunicationsScreen({super.key, required this.model});
  final DeviceModel model;

  @override
  State<DeviceCommunicationsScreen> createState() =>
      _DeviceCommunicationsScreenState();
}

class _DeviceCommunicationsScreenState
    extends State<DeviceCommunicationsScreen> {
  final BleController bleController;
  final DevicePaginationController controller;

  Map<String, dynamic>? dataDevice = {};

  bool isLoading = false;
  bool isInitialized = false;

  _DeviceCommunicationsScreenState()
    : bleController = Get.put(BleController(), permanent: true),
      controller = Get.put(DevicePaginationController(), permanent: true) {
    debugPrint(
      'Initialized BLEController and DevicePaginationController with Get.put',
    );
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
        _fetchDevices();
        isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    isInitialized = false;
    super.dispose();
  }

  void _fetchDevices() async {
    try {
      // Periksa koneksi BLE
      if (!widget.model.isConnected.value) {
        SnackbarCustom.showSnackbar(
          '',
          'Device not connected',
          AppColor.redColor,
          AppColor.whiteColor,
        );
        return;
      }

      final response = await bleController.readCommandResponse(
        widget.model,
        type: 'devices_summary',
      );

      if (response.status == 'success') {
        dataDevice = response.config as Map<String, dynamic>? ?? {};
      } else {
        SnackbarCustom.showSnackbar(
          '',
          response.message ?? 'Failed to fetch devices',
          AppColor.redColor,
          AppColor.whiteColor,
        );
      }
    } catch (e) {
      debugPrint('Error fetching devices: $e');
      SnackbarCustom.showSnackbar(
        'Error',
        'Failed to fetch devices: $e',
        AppColor.redColor,
        AppColor.whiteColor,
      );
    }
  }

  void _deleteDevice(int deviceId) async {
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
        setState(() => isLoading = true);

        Get.back();
        await Future.delayed(const Duration(seconds: 1));

        try {
          // bleController.sendCommand('DELETE|devices|id:$deviceId', 'devices');
        } catch (e) {
          debugPrint('Error deleting device: $e');
          Get.snackbar('Error', 'Failed to delete device: $e');
        } finally {
          setState(() => isLoading = false);
        }
      },
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppPadding.horizontalMedium,
          child: _bodyContent(context),
        ),
      ),
    );
  }

  AppBar _appBar(BuildContext context) {
    return AppBar(
      centerTitle: true,
      title: Text(
        'Device Communications',
        style: context.h5.copyWith(color: AppColor.whiteColor),
      ),
      iconTheme: const IconThemeData(color: AppColor.whiteColor),
      backgroundColor: AppColor.primaryColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          Get.back();
        },
      ),
      actions: [
        IconButton(
          onPressed: () {
            context.push(
              '/devices/device-communication/add?id=${widget.model.device.remoteId}',
            );
          },
          icon: const Icon(Icons.add_circle, size: 22),
        ),
      ],
    );
  }

  Column _bodyContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSpacing.md,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Data Devices',
              style: context.h5,
              overflow: TextOverflow.ellipsis,
            ),
            TextButton.icon(
              onPressed: _fetchDevices,
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
          if (bleController.commandLoading.value) {
            return LoadingProgress();
          }

          if (bleController.gatewayDeviceResponses.isEmpty) {
            return _emptyView(context);
          }

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.devices.length,
            separatorBuilder: (context, index) => AppSpacing.sm,
            itemBuilder: (context, index) {
              final item = controller.devices[index];
              final deviceId = item['id'] as int? ?? 0;
              final name = item['name'] as String? ?? 'Unknown';
              final modbusType = item['modbus_type'] as String? ?? 'Unknown';

              return InkWell(
                onTap: () {
                  Get.to(
                    () => DisplayDataPage(title: name, modbusType: modbusType),
                  );
                },
                child: _cardDeviceConnection(
                  context,
                  deviceId,
                  name,
                  modbusType,
                ),
              );
            },
          );
        }),
        AppSpacing.md,
        Obx(() {
          if (bleController.gatewayDeviceResponses.isNotEmpty &&
              !bleController.isLoading.value) {
            return Center(
              child: Text(
                'Showing ${controller.totalRecords.value} entries',
                style: context.bodySmall,
              ),
            );
          }
          return const SizedBox.shrink();
        }),
        AppSpacing.md,
      ],
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
              'You don`t have any devices yet.',
              textAlign: TextAlign.center,
              style: context.body.copyWith(color: AppColor.grey),
            ),
          ],
        ),
      ),
    );
  }

  Card _cardDeviceConnection(
    BuildContext context,
    int deviceId,
    String title,
    String modbusType,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Card(
      color: AppColor.cardColor,
      margin: EdgeInsets.zero,
      elevation: 0.0,
      child: Padding(
        padding: AppPadding.small,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              flex: screenWidth <= 600 ? 2 : 3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Image.asset(
                    ImageAsset.iconModbus,
                    width: 50,
                    height: 50,
                    fit: BoxFit.contain,
                  ),
                  AppSpacing.sm,
                  Flexible(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: context.h6,
                          overflow: TextOverflow.ellipsis,
                        ),
                        AppSpacing.xs,
                        Text(
                          'Device $modbusType',
                          style: context.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.sm,
            Button(
              width: 50,
              height: 32,
              onPressed: () {
                // Get.to(() => FormSetupDeviceScreen(id: deviceId));
              },
              icons: const Icon(Icons.edit, color: AppColor.whiteColor),
              btnColor: AppColor.primaryColor,
              customStyle: context.buttonTextSmallest,
            ),
            AppSpacing.sm,
            Button(
              width: 50,
              height: 32,
              onPressed: () => _deleteDevice(deviceId),
              icons: const Icon(Icons.delete, color: AppColor.whiteColor),
              btnColor: AppColor.redColor,
              customStyle: context.buttonTextSmallest,
            ),
          ],
        ),
      ),
    );
  }
}
