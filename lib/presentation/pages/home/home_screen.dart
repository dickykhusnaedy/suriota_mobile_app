import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/constants/app_gap.dart';
import 'package:gateway_config/core/constants/app_image_assets.dart';
import 'package:gateway_config/core/controllers/ble_controller.dart';
import 'package:gateway_config/core/utils/app_helpers.dart';
import 'package:gateway_config/core/utils/extensions.dart';
import 'package:gateway_config/core/utils/snackbar_custom.dart';
import 'package:gateway_config/models/device_model.dart';
import 'package:gateway_config/presentation/pages/devices/widgets/device_list_widget.dart';
import 'package:gateway_config/presentation/pages/sidebar_menu/sidebar_menu.dart';
import 'package:gateway_config/presentation/widgets/common/custom_alert_dialog.dart';
import 'package:gateway_config/presentation/widgets/common/custom_button.dart';
import 'package:gateway_config/presentation/widgets/common/loading_overlay.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

// ignore: must_be_immutable
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final controller = Get.put(BleController());

  bool isLoading = false;

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

        setState(() {
          isLoading = true;
        });

        try {
          await controller.disconnectFromDevice(deviceModel);
        } catch (e) {
          AppHelpers.debugLog('Error disconnecting from device: $e');
          Get.snackbar(
            'Error',
            'Failed to disconnect from device',
            backgroundColor: AppColor.redColor,
            colorText: AppColor.whiteColor,
          );
        } finally {
          setState(() {
            isLoading = false;
          });
        }
      },
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        Scaffold(
          appBar: _appBar(screenWidth),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: AppPadding.screenPadding,
              child: _homeContent(context),
            ),
          ),
          endDrawer: const SideBarMenu(),
          floatingActionButton:
              controller.errorMessage.value.contains(
                'Bluetooth has been turned off',
              )
              ? null
              : _floatingButtonCustom(context),
        ),
        Obx(() {
          return LoadingOverlay(
            isLoading: controller.isLoadingConnectionGlobal.value,
            message: controller.message.value.isNotEmpty
                ? controller.message.value
                : controller.errorMessage.value,
          );
        }),
      ],
    );
  }

  AppBar _appBar(double screenWidth) {
    return AppBar(
      backgroundColor: Colors.white,
      title: SizedBox(
        width: screenWidth * (screenWidth <= 600 ? 0.4 : 0.2),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.asset(ImageAsset.logoSuriota, fit: BoxFit.contain),
        ),
      ),
    );
  }

  Column _homeContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hallo, Fulan👋',
          style: context.h1.copyWith(color: AppColor.blackColor),
        ),
        AppSpacing.xs,
        Text(
          'Connecting the device near you',
          style: context.body.copyWith(color: AppColor.grey),
        ),
        AppSpacing.xxl,
        Text(
          'Device List',
          style: context.h4.copyWith(color: AppColor.blackColor),
        ),
        AppSpacing.sm,
        Obx(() {
          if (controller.errorMessage.value.contains(
            'Bluetooth has been turned off',
          )) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.55,
              alignment: Alignment.center,
              child: Center(
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
              ),
            );
          }
          // ignore: prefer_is_empty
          if (controller.scannedDevices.isEmpty) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.55,
              alignment: Alignment.center,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'No device found.\nFind devices near you by clicking the (+) button.',
                      textAlign: TextAlign.center,
                      style: context.body.copyWith(color: AppColor.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            separatorBuilder: (context, index) => AppSpacing.sm,
            itemCount: controller.scannedDevices.length,
            itemBuilder: (context, index) {
              final deviceModel = controller.scannedDevices[index];

              return Obx(() {
                return DeviceListWidget(
                  device: deviceModel.device,
                  isConnected: deviceModel.isConnected.value,
                  isLoadingConnection: deviceModel.isLoadingConnection.value,
                  onConnect: () async {
                    if (!deviceModel.isConnected.value) {
                      await controller.connectToDevice(
                        deviceModel,
                      ); // Call connectToDevice from BleController
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
          );
        }),
      ],
    );
  }

  Container _floatingButtonCustom(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColor.primaryColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: () async {
          context.push('/devices/add');
        },
        child: const Icon(
          Icons.add_circle,
          size: 20,
          color: AppColor.whiteColor,
        ),
      ),
    );
  }
}
