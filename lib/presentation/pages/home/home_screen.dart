import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/constants/app_gap.dart';
import 'package:gateway_config/core/constants/app_image_assets.dart';
import 'package:gateway_config/core/controllers/ble_controller.dart';
import 'package:gateway_config/core/controllers/devices_controller.dart';
import 'package:gateway_config/core/utils/app_helpers.dart';
import 'package:gateway_config/core/utils/extensions.dart';
import 'package:gateway_config/core/utils/snackbar_custom.dart';
import 'package:gateway_config/models/device_model.dart';
import 'package:gateway_config/presentation/pages/devices/widgets/device_list_widget.dart';
import 'package:gateway_config/presentation/pages/sidebar_menu/sidebar_menu.dart';
import 'package:gateway_config/presentation/widgets/common/app_bottom_navigation.dart';
import 'package:gateway_config/presentation/widgets/common/custom_alert_dialog.dart';
import 'package:gateway_config/presentation/widgets/common/custom_alert_widget.dart';
import 'package:gateway_config/presentation/widgets/common/custom_button.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatefulWidget {
  final bool showBottomNav;

  const HomeScreen({super.key, this.showBottomNav = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final controller = Get.find<BleController>();
  final devicesController = Get.put(DevicesController());

  @override
  void dispose() {
    super.dispose();
  }

  String _formatLastConnectionTime(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Last seen: Just now';
    } else if (difference.inMinutes < 60) {
      return 'Last seen: ${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return 'Last seen: ${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return 'Last seen: ${difference.inDays}d ago';
    } else {
      final month = dateTime.month.toString().padLeft(2, '0');
      final day = dateTime.day.toString().padLeft(2, '0');
      final year = dateTime.year;
      return 'Last seen: $day/$month/$year';
    }
  }

  void disconnect(DeviceModel deviceModel) async {
    CustomAlertDialog.show(
      title: "Disconnect Device",
      message:
          "Are you sure you want to disconnect from ${deviceModel.device.platformName}?",
      primaryButtonText: 'Yes',
      secondaryButtonText: 'No',
      onPrimaryPressed: () async {
        Get.back();
        await Future.delayed(Duration.zero);

        try {
          await controller.disconnectFromDevice(deviceModel);
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

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: widget.showBottomNav
            ? Colors.transparent
            : AppColor.whiteColor,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: AppColor.whiteColor,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColor.backgroundColor,
        appBar: widget.showBottomNav ? null : _buildAppBar(screenWidth),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: AppPadding.screenPadding,
            child: _buildHomeContent(),
          ),
        ),
        endDrawer: widget.showBottomNav ? null : const SideBarMenu(),
        floatingActionButton: widget.showBottomNav
            ? null
            : Obx(() {
                return Visibility(
                  visible: !controller.errorMessage.value.contains(
                    'Bluetooth has been turned off',
                  ),
                  child: ModernFAB(
                    onPressed: () => context.pushNamed('add-device'),
                  ),
                );
              }),
        floatingActionButtonLocation: widget.showBottomNav
            ? null
            : FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  AppBar _buildAppBar(double screenWidth) {
    return AppBar(
      backgroundColor: AppColor.whiteColor,
      title: SizedBox(
        width: screenWidth * (screenWidth <= 600 ? 0.4 : 0.2),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.asset(ImageAsset.logoSuriota, fit: BoxFit.contain),
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showBottomNav) ...[
          AppSpacing.sm,
          Text(
            'Home',
            style: context.h2.copyWith(
              color: AppColor.blackColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          AppSpacing.sm,
          Text(
            'Manage your connected devices',
            style: context.bodySmall.copyWith(color: AppColor.grey),
          ),
          AppSpacing.lg,
        ],
        Text(
          'Connected Devices',
          style: widget.showBottomNav
              ? context.h5.copyWith(
                  color: AppColor.blackColor,
                  fontWeight: FontWeight.w600,
                )
              : context.h4.copyWith(color: AppColor.blackColor),
        ),
        AppSpacing.md,
        Obx(() {
          if (controller.errorMessage.value.contains(
            'Bluetooth has been turned off',
          )) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.55,
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Bluetooth has been turned off. \nPlease turn it back on to connect to devices.',
                    textAlign: TextAlign.center,
                    style: context.body.copyWith(color: AppColor.grey),
                  ),
                  AppSpacing.md,
                  Button(
                    onPressed: () async {
                      try {
                        await AppSettings.openAppSettings(
                          type: AppSettingsType.bluetooth,
                        );
                      } catch (e) {
                        AppHelpers.debugLog(
                          'Error opening Bluetooth settings: $e',
                        );

                        SnackbarCustom.showSnackbar(
                          '',
                          'Could not open settings Bluetooth',
                          AppColor.redColor,
                          AppColor.whiteColor,
                        );
                      }
                    },
                    text: 'Open Settings',
                    icons: const Icon(
                      Icons.settings,
                      color: AppColor.whiteColor,
                      size: 23,
                    ),
                    height: 42,
                    width: MediaQuery.of(context).size.width * 0.4,
                  ),
                ],
              ),
            );
          }

          if (controller.connectedHistory.isEmpty) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.55,
              alignment: Alignment.center,
              child: Text(
                'No device history.\nConnect a device to see it here.',
                textAlign: TextAlign.center,
                style: context.body.copyWith(color: AppColor.grey),
              ),
            );
          }

          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const CustomAlertWidget(
                type: AlertType.info,
                title: 'Temporary Session',
                description:
                    'Device connection history will be cleared when the app is closed. Make sure to complete your tasks before exiting.',
              ),
              AppSpacing.md,
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.connectedHistory.length,
                itemBuilder: (context, index) {
                  final deviceModel = controller.connectedHistory[index];

                  return Obx(() {
                    return DeviceListWidget(
                      device: deviceModel.device,
                      isConnected: deviceModel.isConnected.value,
                      isLoadingConnection:
                          deviceModel.isLoadingConnection.value,
                      lastConnectionTime: _formatLastConnectionTime(
                        deviceModel.lastConnectionTime.value,
                      ),
                      onConnect: () async {
                        if (!deviceModel.isConnected.value) {
                          await controller.connectToDevice(deviceModel);
                        }
                      },
                      onDisconnect: () async {
                        if (deviceModel.isConnected.value) {
                          disconnect(deviceModel);
                        }
                      },
                    );
                  });
                },
              ),
            ],
          );
        }),
        if (widget.showBottomNav) AppSpacing.xl,
      ],
    );
  }
}
