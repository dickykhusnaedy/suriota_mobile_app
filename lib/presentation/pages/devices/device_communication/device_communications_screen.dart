import 'package:flutter/material.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/constants/app_gap.dart';
import 'package:gateway_config/core/constants/app_image_assets.dart';
import 'package:gateway_config/core/controllers/ble_controller.dart';
import 'package:gateway_config/core/controllers/devices_controller.dart';
import 'package:gateway_config/core/utils/extensions.dart';
import 'package:gateway_config/core/utils/loading_progress.dart';
import 'package:gateway_config/core/utils/snackbar_custom.dart';
import 'package:gateway_config/models/device_model.dart';
import 'package:gateway_config/presentation/widgets/common/custom_alert_dialog.dart';
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
  final DevicesController controller;

  Map<String, dynamic>? dataDevice = {};

  bool isLoading = false;
  bool isInitialized = false;

  _DeviceCommunicationsScreenState()
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

  void _deleteDevice(String deviceId) async {
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
        controller.isFetching.value = true;

        try {
          await controller.deleteDevice(widget.model, deviceId);

          if (Get.context != null) {
            SnackbarCustom.showSnackbar(
              '',
              'Device deleted successfully, refreshing data...',
              Colors.green,
              AppColor.whiteColor,
            );
          }

          await controller.fetchDevices(widget.model);
        } catch (e) {
          SnackbarCustom.showSnackbar(
            '',
            'Failed to delete device',
            AppColor.redColor,
            AppColor.whiteColor,
          );
        } finally {
          controller.isFetching.value = false;
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
              '/devices/device-communication/add?d=${widget.model.device.remoteId}',
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
              onPressed: () async {
                await controller.fetchDevices(widget.model);
              },
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

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.dataDevices.length,
            separatorBuilder: (context, index) => AppSpacing.sm,
            itemBuilder: (context, index) {
              final device = controller.dataDevices[index];

              return InkWell(
                onTap: () {
                  context.push(
                    '/devices/device-communication/stream-data?d=${widget.model.device.remoteId}&stream=${device['device_id']}',
                  );
                },
                child: _cardDeviceConnection(
                  context,
                  device['device_id'] ?? 'No ID',
                  device['device_name'] ?? 'Unknown Device',
                  device['protocol'] ?? 'Unknown',
                ),
              );
            },
          );
        }),
        AppSpacing.md,
        Obx(() {
          if (controller.dataDevices.isNotEmpty &&
              !controller.isFetching.value) {
            return Center(
              child: Text(
                'Showing ${controller.dataDevices.length} entries',
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

  Widget _emptyView(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.60,
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
              Icons.devices_other,
              size: 64,
              color: AppColor.grey.withValues(alpha: 0.5),
            ),
            AppSpacing.md,
            Text(
              'No Devices Yet',
              textAlign: TextAlign.center,
              style: context.h6.copyWith(
                color: AppColor.blackColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpacing.sm,
            Text(
              'You haven\'t added any devices yet.\nTap the + button above to add your first device.',
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

  Widget _cardDeviceConnection(
    BuildContext context,
    String deviceId,
    String title,
    String modbusType,
  ) {
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
            // Kolom Kiri: Icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColor.lightPrimaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(8),
              child: Image.asset(ImageAsset.iconModbus, fit: BoxFit.contain),
            ),
            AppSpacing.sm,
            // Kolom Tengah: Device Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Device Name
                  Text(
                    title,
                    style: context.h6.copyWith(
                      color: AppColor.blackColor,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  AppSpacing.xs,
                  // Protocol Badge
                  _buildProtocolBadge(context, modbusType),
                  AppSpacing.xs,
                  // Device ID
                  Row(
                    children: [
                      Icon(Icons.fingerprint, size: 12, color: AppColor.grey),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          'ID: $deviceId',
                          style: context.bodySmall.copyWith(
                            color: AppColor.grey,
                            fontSize: 10,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
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
                      '/devices/device-communication/edit?d=${widget.model.device.remoteId}&edit=$deviceId',
                    );
                  },
                ),
                AppSpacing.xs,
                _buildIconButton(
                  icon: Icons.delete,
                  color: AppColor.redColor,
                  onPressed: () => _deleteDevice(deviceId),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProtocolBadge(BuildContext context, String protocol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColor.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColor.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.settings_input_component,
            color: AppColor.primaryColor,
            size: 10,
          ),
          AppSpacing.xs,
          Text(
            protocol,
            style: context.bodySmall.copyWith(
              color: AppColor.primaryColor,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
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
