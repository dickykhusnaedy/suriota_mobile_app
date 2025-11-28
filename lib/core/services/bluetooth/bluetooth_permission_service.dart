import 'package:flutter/material.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/constants/app_gap.dart';
import 'package:gateway_config/core/utils/extensions.dart';
import 'package:gateway_config/presentation/widgets/common/custom_button.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothPermissionService extends GetxController {
  static Future<bool> checkAndRequestPermissions(BuildContext context) async {
    // First check current status before requesting
    print('=== Checking Initial Permission Status ===');
    var bluetoothScanStatus = await Permission.bluetoothScan.status;
    var bluetoothConnectStatus = await Permission.bluetoothConnect.status;
    var locationStatus = await Permission.locationWhenInUse.status;

    print('BluetoothScan: $bluetoothScanStatus');
    print('BluetoothConnect: $bluetoothConnectStatus');
    print('LocationWhenInUse: $locationStatus');

    // Define required permissions based on platform and Android version
    List<Permission> requiredPermissions = [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ];

    // NOTE: Storage permission is NOT requested at startup
    // It will be requested later when user actually needs it (backup/restore)
    // See settings_device_screen.dart for storage permission handling

    // Request permissions
    print('=== Requesting Permissions ===');
    final statuses = await requiredPermissions.request();

    // Debug: Print permission statuses
    print('=== Permission Statuses ===');
    statuses.forEach((permission, status) {
      print(
        '$permission: $status (isGranted: ${status.isGranted}, isPermanentlyDenied: ${status.isPermanentlyDenied})',
      );
    });

    // Check critical permissions (Bluetooth and Location)
    // Storage permission is optional and shouldn't block app startup
    bool criticalPermissionsGranted =
        (statuses[Permission.bluetoothScan]?.isGranted ?? false) &&
        (statuses[Permission.bluetoothConnect]?.isGranted ?? false) &&
        (statuses[Permission.locationWhenInUse]?.isGranted ?? false);

    print('Critical Permissions Granted: $criticalPermissionsGranted');

    // If critical permissions not granted, check if any are permanently denied
    if (!criticalPermissionsGranted) {
      // Check if any CRITICAL permission is permanently denied
      bool criticalPermanentlyDenied =
          (statuses[Permission.bluetoothScan]?.isPermanentlyDenied ?? false) ||
          (statuses[Permission.bluetoothConnect]?.isPermanentlyDenied ??
              false) ||
          (statuses[Permission.locationWhenInUse]?.isPermanentlyDenied ??
              false);

      print('Critical Permanently Denied: $criticalPermanentlyDenied');

      if (criticalPermanentlyDenied) {
        // Show bottom sheet to guide user to settings
        // ignore: use_build_context_synchronously
        await _showPermissionBottomSheet(context, isDenied: false);

        // Re-check permissions after user returns from settings
        print('=== Re-checking Permissions After Settings ===');
        final recheckStatuses = await requiredPermissions.request();

        recheckStatuses.forEach((permission, status) {
          print('$permission: $status (isGranted: ${status.isGranted})');
        });

        criticalPermissionsGranted =
            (recheckStatuses[Permission.bluetoothScan]?.isGranted ?? false) &&
            (recheckStatuses[Permission.bluetoothConnect]?.isGranted ??
                false) &&
            (recheckStatuses[Permission.locationWhenInUse]?.isGranted ?? false);

        print(
          'Critical Permissions After Recheck: $criticalPermissionsGranted',
        );
      } else {
        // Critical permissions just denied (not permanently), show request dialog
        // ignore: use_build_context_synchronously
        await _showPermissionBottomSheet(context, isDenied: true);

        // Re-request after user sees the explanation
        print('=== Re-requesting Permissions ===');
        final recheckStatuses = await requiredPermissions.request();

        criticalPermissionsGranted =
            (recheckStatuses[Permission.bluetoothScan]?.isGranted ?? false) &&
            (recheckStatuses[Permission.bluetoothConnect]?.isGranted ??
                false) &&
            (recheckStatuses[Permission.locationWhenInUse]?.isGranted ?? false);

        print(
          'Critical Permissions After Re-request: $criticalPermissionsGranted',
        );
      }
    }

    print('Final Result: $criticalPermissionsGranted');
    return criticalPermissionsGranted;
  }

  static Future<void> _showPermissionBottomSheet(
    BuildContext context, {
    required bool isDenied,
  }) async {
    await showModalBottomSheet(
      context: context,
      isDismissible:
          !isDenied, // Can dismiss if just denied, not if permanently denied
      enableDrag: !isDenied,
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
                    Text(
                      isDenied ? "Permissions Required" : "Need Permissions",
                      style: sheetContext.h4,
                    ),
                    AppSpacing.sm,
                    Text(
                      isDenied
                          ? "This app requires Bluetooth and Location permissions to scan and connect to BLE devices. Please grant the permissions to continue."
                          : "Some permissions were permanently denied. To continue, please enable them in your settings.",
                      style: sheetContext.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    AppSpacing.md,
                    Row(
                      children: [
                        if (!isDenied) ...[
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
                        ],
                        Expanded(
                          child: Button(
                            onPressed: () {
                              if (!isDenied) {
                                openAppSettings();
                              }
                              Navigator.of(sheetContext).pop();
                            },
                            text: isDenied
                                ? "OK, Request Again"
                                : "Open Settings",
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
