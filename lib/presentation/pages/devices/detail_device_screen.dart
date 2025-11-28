import 'package:flutter/material.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/constants/app_gap.dart';
import 'package:gateway_config/core/constants/app_image_assets.dart';
import 'package:gateway_config/core/controllers/ble_controller.dart';
import 'package:gateway_config/core/utils/app_helpers.dart';
import 'package:gateway_config/core/utils/extensions.dart';
import 'package:gateway_config/core/utils/snackbar_custom.dart';
import 'package:gateway_config/models/device_model.dart';
import 'package:gateway_config/presentation/widgets/common/custom_alert_dialog.dart';
import 'package:gateway_config/presentation/widgets/common/custom_button.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

class DetailDeviceScreen extends StatefulWidget {
  const DetailDeviceScreen({super.key, required this.model});
  final DeviceModel model;

  @override
  State<DetailDeviceScreen> createState() => _DetailDeviceScreenState();
}

class _DetailDeviceScreenState extends State<DetailDeviceScreen> {
  final controller = Get.find<BleController>();

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!widget.model.isConnected.value && Get.isOverlaysOpen) {
      Get.back();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void disconnect() async {
    CustomAlertDialog.show(
      title: "Disconnect Device",
      message:
          "Are you sure you want to disconnect from ${widget.model.device.platformName}?",
      primaryButtonText: 'Yes',
      secondaryButtonText: 'No',
      onPrimaryPressed: () async {
        Get.back();
        await Future.delayed(Duration.zero);

        try {
          await controller.disconnectFromDevice(widget.model);

          AppHelpers.debugLog(
            'Successfully disconnected from ${widget.model.device.platformName}',
          );

          // Navigation is handled automatically by BLE controller
          // via disconnectFromDevice() fallback navigation after 3 second delay
          // No manual navigation needed here
        } catch (e) {
          AppHelpers.debugLog('Error disconnecting from device: $e');

          SnackbarCustom.showSnackbar(
            'Error',
            'Failed to disconnect from device',
            AppColor.redColor,
            AppColor.whiteColor,
          );
        }
      },
      barrierDismissible: false,
    );
  }

  void handleMenuNavigation(String page) {
    // Check if device is still connected
    if (!widget.model.isConnected.value) {
      // Show snackbar
      SnackbarCustom.showSnackbar(
        '',
        'Device is not connected. Redirecting to home...',
        AppColor.redColor,
        AppColor.whiteColor,
      );

      // Redirect to home after short delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          // Pop until we reach the root route (home)
          // This clears all navigation stack and returns to home
          while (context.canPop()) {
            context.pop();
          }
        }
      });
      return;
    }

    // If device is connected, navigate to the page
    context.push(page);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(widget.model.device.platformName),
      backgroundColor: AppColor.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppPadding.horizontalMedium,
          child: _buildBodyContent(),
        ),
      ),
    );
  }

  Widget _buildBodyContent() {
    double screenWidth = MediaQuery.of(context).size.width;

    final List<Map<String, dynamic>> menuItems = [
      {
        "text": "Device Communications",
        "icon": Icons.devices_outlined,
        "page":
            '/devices/device-communication?id=${widget.model.device.remoteId}',
      },
      {
        "text": "Modbus Configurations",
        "icon": Icons.settings_input_component,
        "page": '/devices/modbus-config?id=${widget.model.device.remoteId}',
      },
      {
        "text": "Server Configurations",
        "icon": Icons.dns_outlined,
        "page": '/devices/server-config?id=${widget.model.device.remoteId}',
      },
      {
        "text": "Logging Configurations",
        "icon": Icons.description_outlined,
        "page": '/devices/logging?id=${widget.model.device.remoteId}',
      },
      {
        "text": "Status",
        "icon": Icons.analytics_outlined,
        "page": '/devices/status?id=${widget.model.device.remoteId}',
      },
      {
        "text": "Settings",
        "icon": Icons.settings_outlined,
        "page": '/devices/settings?id=${widget.model.device.remoteId}',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSpacing.md,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              flex: screenWidth <= 600 ? 2 : 3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColor.primaryColor.withValues(alpha: 0.15),
                          AppColor.lightPrimaryColor.withValues(alpha: 0.25),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColor.primaryColor.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Image.asset(
                      ImageAsset.iconBluetooth,
                      fit: BoxFit.contain,
                    ),
                  ),
                  AppSpacing.md,
                  Flexible(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.model.device.platformName.isNotEmpty
                              ? widget.model.device.platformName
                              : 'N/A',
                          style: context.h4.copyWith(
                            color: AppColor.blackColor,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        AppSpacing.sm,
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 12,
                                    color: Colors.green.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'BONDED',
                                    style: context.bodySmall.copyWith(
                                      color: Colors.green.shade700,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.xs,
                        Row(
                          children: [
                            Icon(
                              Icons.fingerprint,
                              size: 13,
                              color: AppColor.grey.withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.model.device.remoteId.toString(),
                                style: context.bodySmall.copyWith(
                                  color: AppColor.grey,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Obx(() {
              return Flexible(
                flex: 1,
                child: SizedBox(
                  height: 34,
                  child: Button(
                    width: double.infinity,
                    onPressed: disconnect,
                    text: widget.model.isConnected.value
                        ? 'Disconnect'
                        : 'Connect',
                    btnColor: widget.model.isConnected.value
                        ? AppColor.redColor
                        : AppColor.primaryColor,
                    customStyle: context.buttonTextSmallest.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
        AppSpacing.md,
        Divider(
          color: AppColor.grey.withValues(alpha: 0.2),
          thickness: 1,
          height: 1,
        ),
        AppSpacing.md,
        Text('CONFIGURATION MENU', style: context.h4),
        AppSpacing.md,
        LayoutBuilder(
          builder: (context, constraints) {
            double cardWidth = (constraints.maxWidth / 2) - 8;

            return Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.spaceBetween,
              children: menuItems
                  .map(
                    (item) => InkWell(
                      onTap: () => handleMenuNavigation(item['page']),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: cardWidth,
                        height: 160,
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
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColor.primaryColor.withValues(
                                        alpha: 0.15,
                                      ),
                                      AppColor.lightPrimaryColor.withValues(
                                        alpha: 0.25,
                                      ),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColor.primaryColor.withValues(
                                      alpha: 0.2,
                                    ),
                                    width: 1.5,
                                  ),
                                ),
                                child: Icon(
                                  item['icon']!,
                                  size: 32,
                                  color: AppColor.primaryColor,
                                ),
                              ),
                              AppSpacing.sm,
                              Text(
                                item['text']!,
                                style: context.body.copyWith(
                                  color: AppColor.blackColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
        AppSpacing.lg,
      ],
    );
  }

  AppBar _buildAppBar(String title) {
    return AppBar(
      title: Text(
        'Detail Device',
        style: context.h5.copyWith(color: AppColor.whiteColor),
      ),
      backgroundColor: AppColor.primaryColor,
      iconTheme: const IconThemeData(color: AppColor.whiteColor),
      centerTitle: true,
    );
  }
}
