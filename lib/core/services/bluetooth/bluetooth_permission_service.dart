import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/constants/app_gap.dart';
import 'package:gateway_config/core/utils/extensions.dart';
import 'package:gateway_config/presentation/widgets/common/custom_button.dart';

class BluetoothPermissionService extends GetxController {
  static Future<bool> checkAndRequestPermissions(BuildContext context) async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
      Permission.manageExternalStorage
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
    await showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppColor.whiteColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Wrap(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Need Permissions", style: sheetContext.h4),
                    AppSpacing.sm,
                    Text(
                      "Some permissions were permanently denied. To continue, please enable them in your settings.",
                      style: sheetContext.bodySmall,
                    ),
                    AppSpacing.md,
                    Row(
                      children: [
                        Expanded(
                          child: Button(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            text: "Close",
                            btnColor: AppColor.grey,
                            customStyle: sheetContext.bodySmall.copyWith(
                              color: AppColor.whiteColor,
                            ),
                          ),
                        ),
                        AppSpacing.md,
                        Expanded(
                          child: Button(
                            onPressed: () {
                              openAppSettings();
                              Navigator.of(sheetContext).pop();
                            },
                            text: "Open Settings",
                            customStyle: sheetContext.bodySmall.copyWith(
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
        );
      },
    );
  }
}
