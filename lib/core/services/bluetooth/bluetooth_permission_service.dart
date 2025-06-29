import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:suriota_mobile_gateway/core/constants/app_color.dart';
import 'package:suriota_mobile_gateway/core/constants/app_gap.dart';
import 'package:suriota_mobile_gateway/core/utils/extensions.dart';
import 'package:suriota_mobile_gateway/presentation/widgets/common/custom_button.dart';

class BluetoothPermissionService extends GetxController {
  static Future<bool> checkAndRequestPermissions(BuildContext context) async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse
    ].request();

    final allGranted = statuses.values.every((status) => status.isGranted);

    if (!allGranted) {
      if (statuses.values.any((status) => status.isPermanentlyDenied)) {
        // Show a dialog or snackbar to inform the user about the denied permissions
        // ignore: use_build_context_synchronously
        await _showConnectedBottomSheet(context);
      }
    }

    return allGranted;
  }

  static Future<void> _showConnectedBottomSheet(BuildContext context) async {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColor.whiteColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Wrap(
          children: [
            Center(
              child: Column(
                children: [
                  Text(
                    "Need Permissions",
                    style: context.h4,
                  ),
                  AppSpacing.sm,
                  Text(
                      "Some permissions were permanently denied. To continue, please enable them in your settings.",
                      style: context.bodySmall),
                  AppSpacing.md,
                  Row(
                    children: [
                      Expanded(
                        child: Button(
                          onPressed: () => Navigator.of(Get.overlayContext!)
                              .pop(), // hanya tutup bottom sheet
                          text: "Close",
                          btnColor: AppColor.grey,
                          customStyle: context.bodySmall.copyWith(
                            color: AppColor.whiteColor,
                          ),
                        ),
                      ),
                      AppSpacing.md,
                      Expanded(
                        child: Button(
                          onPressed: () {
                            openAppSettings();
                            Navigator.of(Get.overlayContext!).pop();
                          },
                          text: "Open Settings",
                          customStyle: context.bodySmall.copyWith(
                            color: AppColor.whiteColor,
                          ),
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
      isDismissible: false,
      enableDrag: false,
    );
  }
}
