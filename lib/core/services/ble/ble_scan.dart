import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:suriota_mobile_gateway/core/controllers/ble/ble_controller.dart';
import 'package:suriota_mobile_gateway/core/utils/app_helpers.dart';

class BLEScanner {
  BLEController? controller;

  // Scan for BLE devices
  Future<void> scanDevice() async {
    if (controller!.isLoading.value) return;
    controller!.startLoading();
    controller!.devices.clear();
    await FlutterBluePlus.stopScan();

    final seenDeviceIds = <String>{};
    final subscription = FlutterBluePlus.scanResults.listen((results) {
      for (final result in results) {
        final deviceId = result.device.remoteId.toString();
        if (!seenDeviceIds.contains(deviceId)) {
          seenDeviceIds.add(deviceId);
          controller!.devices.add(result.device);
          controller!.setLoadingStatus(deviceId, false);
          controller!.connectionStatus[deviceId] = false;
          AppHelpers.debugLog('Found device: $deviceId');
        }
      }
    });

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
      await Future.delayed(const Duration(seconds: 5));
    } catch (e) {
      controller!.notifyStatus('Scan failed: $e');
      AppHelpers.debugLog('Scan error: $e');
    } finally {
      await subscription.cancel();
      controller!.stopLoading();
    }
  }
}
