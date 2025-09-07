import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:gateway_config/presentation/widgets/common/custom_alert_dialog.dart';
import 'package:gateway_config/presentation/pages/devices/detail_device_screen.dart';

class BLEUtils {
  // Show dialog when a device is connected
  static void showConnectedBottomSheet(BluetoothDevice device) {
    CustomAlertDialog.show(
      title: 'Device Connected',
      message:
          'Do you want to open device (${device.platformName.isNotEmpty ? device.platformName : device.remoteId}) page detail?',
      primaryButtonText: 'Yes',
      secondaryButtonText: 'No',
      onPrimaryPressed: () => Get.to(() => DetailDeviceScreen(device: device)),
      barrierDismissible: false,
    );
  }

  // Show dialog to confirm device disconnection
  static void showDisconnectedBottomSheet(
    BluetoothDevice device,
    VoidCallback? onDisconnect,
  ) {
    final deviceName = device.platformName.isNotEmpty
        ? device.platformName
        : device.remoteId.toString();
    CustomAlertDialog.show(
      title: 'Disconnect Device?',
      message: 'Do you want to disconnect the device ($deviceName)?',
      primaryButtonText: 'Yes',
      secondaryButtonText: 'No',
      onPrimaryPressed: onDisconnect,
      barrierDismissible: false,
    );
  }
}
