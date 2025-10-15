import 'package:flutter/material.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/constants/app_gap.dart';
import 'package:gateway_config/core/constants/app_image_assets.dart';
import 'package:gateway_config/core/controllers/ble_controller.dart';
import 'package:gateway_config/core/utils/app_helpers.dart';
import 'package:gateway_config/core/utils/extensions.dart';
import 'package:gateway_config/models/device_model.dart';
import 'package:gateway_config/presentation/widgets/common/custom_alert_dialog.dart';
import 'package:gateway_config/presentation/widgets/common/custom_button.dart';
import 'package:gateway_config/presentation/widgets/common/loading_overlay.dart';
import 'package:gateway_config/presentation/widgets/spesific/device_card.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

class DetailDeviceScreen extends StatefulWidget {
  const DetailDeviceScreen({super.key, required this.model});
  final DeviceModel model;

  @override
  State<DetailDeviceScreen> createState() => _DetailDeviceScreenState();
}

class _DetailDeviceScreenState extends State<DetailDeviceScreen> {
  final controller = Get.put(BleController());

  bool isLoading = false;

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

  void disconnect() async {
    CustomAlertDialog.show(
      title: "Disconnect Device",
      message:
          "Are you sure you want to disconnect from ${widget.model.device.platformName}?",
      primaryButtonText: 'Yes',
      secondaryButtonText: 'No',
      onPrimaryPressed: () async {
        Get.back();
        setState(() {
          isLoading = true;
        });

        try {
          await controller.disconnectFromDevice(widget.model);

          AppHelpers.debugLog(
            'Successfully disconnected from ${widget.model.device.platformName}',
          );

          if (Get.context != null) {
            GoRouter.of(Get.context!).go('/');
          } else {
            AppHelpers.debugLog(
              'Warning: Get.context is null, cannot navigate',
            );
          }
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
    return Stack(
      children: [
        Scaffold(
          appBar: _appBar(context, widget.model.device.platformName),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: AppPadding.horizontalMedium,
              child: _bodyContent(context),
            ),
          ),
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

  Column _bodyContent(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    final List<Map<String, dynamic>> menuItems = [
      {
        "text": "Device Communication",
        "imagePath": ImageAsset.iconDevice,
        "page":
            '/devices/device-communication?id=${widget.model.device.remoteId}',
      },
      {
        "text": "Modbus Configurations",
        "imagePath": ImageAsset.iconConfig,
        "page": '/devices/modbus-config?id=${widget.model.device.remoteId}',
      },
      {
        "text": "Server Configurations",
        "imagePath": ImageAsset.iconServer,
        "page": '/devices/server-config?id=${widget.model.device.remoteId}',
      },
      {
        "text": "Logging Configurations",
        "imagePath": ImageAsset.iconLogging,
        "page": '/devices/logging?id=${widget.model.device.remoteId}',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSpacing.md,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              flex: screenWidth <= 600 ? 2 : 3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Image.asset(
                    ImageAsset.iconBluetooth,
                    width: 45,
                    height: 45,
                    fit: BoxFit.contain,
                  ),
                  AppSpacing.md,
                  Flexible(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.model.device.platformName.isNotEmpty
                              ? widget.model.device.platformName
                              : 'N/A',
                          style: context.h4,
                          overflow: TextOverflow.ellipsis,
                        ),
                        AppSpacing.xs,
                        Text(
                          widget.model.device.remoteId.toString(),
                          style: context.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                        AppSpacing.xs,
                        Text(
                          'BONDED',
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
            Obx(() {
              return Flexible(
                flex: 1,
                child: SizedBox(
                  height: 30,
                  child: Button(
                    width: double.infinity,
                    onPressed: disconnect,
                    text: widget.model.isConnected.value
                        ? 'Disconnect'
                        : 'Connect',
                    btnColor: widget.model.isConnected.value
                        ? AppColor.redColor
                        : AppColor.primaryColor,
                    customStyle: context.buttonTextSmallest,
                  ),
                ),
              );
            }),
          ],
        ),
        AppSpacing.xl,
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
                    (item) => CardMenu(
                      width: cardWidth,
                      text: item['text']!,
                      imagePath: item['imagePath']!,
                      page: item['page'],
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

  AppBar _appBar(BuildContext context, String title) {
    return AppBar(
      title: Text(
        'Detail Device',
        style: context.h5.copyWith(color: AppColor.whiteColor),
      ),
      backgroundColor: AppColor.primaryColor,
      iconTheme: const IconThemeData(color: AppColor.whiteColor),
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: () {
            context.push('/devices/info?name=$title');
          },
          icon: const Icon(Icons.info),
        ),
      ],
    );
  }
}
