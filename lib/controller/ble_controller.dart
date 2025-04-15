import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:suriota_mobile_gateway/constant/app_color.dart';
import 'package:suriota_mobile_gateway/constant/app_gap.dart';
import 'package:suriota_mobile_gateway/constant/font_setup.dart';
import 'package:suriota_mobile_gateway/global/utils/helper.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_button.dart';
import 'package:suriota_mobile_gateway/screen/devices/detail_device_screen.dart';

class BLEController extends GetxController {
  final Guid serviceUuid = Guid("12345678-1234-1234-1234-1234567890ab");
  final Guid characteristicUuid = Guid("abcd1234-1234-1234-1234-abcdef123456");

  var isLoading = false.obs;
  final devices = <BluetoothDevice>[].obs;
  BluetoothCharacteristic? _characteristic;
  bool get isDeviceListEmpty => devices.isEmpty;

  final StreamController<String> _statusController =
      StreamController<String>.broadcast();
  Stream<String> get statusStream => _statusController.stream;

  final RxMap<String, bool> _connectionStatus = <String, bool>{}.obs;
  RxMap<String, bool> get connectionStatus => _connectionStatus;

  final RxMap<String, bool> _loadingStatus = <String, bool>{}.obs;
  RxMap<String, bool> get loadingStatus => _loadingStatus;

  final RxMap<String, bool> _isConnected = <String, bool>{}.obs;
  RxMap<String, bool> get isConnected => _isConnected;

  void _notifyStatus(String status) {
    _statusController.add(status);

    Get.snackbar(
      '',
      status,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColor.grey,
      colorText: AppColor.whiteColor,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      titleText: const SizedBox(),
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
    );
  }

  /// Mendapatkan status koneksi perangkat
  bool getConnectionStatus(String deviceId) {
    return _connectionStatus[deviceId] ?? false;
  }

  /// Mendapatkan status loading perangkat
  bool getLoadingStatus(String deviceId) {
    return _loadingStatus[deviceId] ?? false;
  }

  /// Scan device
  void scanDevice() async {
    if (isLoading.value) return;

    _startLoading();
    devices.clear();

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    final subscription = FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult r in results) {
        if (!devices.contains(r.device)) {
          devices.add(r.device);
          _connectionStatus[r.device.remoteId.toString()] = false;
        }

        // Disabled temporary
        // if (r.device.platformName == "ESP32-BLE-LED") {
        //   await _handleDeviceConnection(r.device);
        //   return; // Hentikan proses setelah menemukan perangkat.
        // }
      }
    });

    Future.delayed(const Duration(seconds: 5), () {
      subscription.cancel();
      _stopLoading();
    });
  }

  /// Connect to device
  Future<void> connectToDevice(BluetoothDevice device) async {
    final deviceId = device.remoteId.toString();
    final deviceName =
        device.platformName != '' ? device.platformName : deviceId;

    _loadingStatus[deviceId] = true;

    try {
      await FlutterBluePlus.stopScan();
      await device.connect();

      _connectionStatus[deviceId] = true;
      _isConnected[deviceId] = true;

      bool isServiceDiscovered = await _discoverServices(device);
      if (isServiceDiscovered) {
        showConnectedBottomSheet(device);
      } else {
        await disconnectDevice(device);
      }
    } catch (e) {
      _connectionStatus[deviceId] = false;
      _isConnected[deviceId] = false;

      AppHelpers.debugLog("Failed to connect: $e");
      _notifyStatus("Failed to connect the device: $deviceName");
    } finally {
      _loadingStatus[deviceId] = false;
    }
  }

  /// Disconnect to device
  Future<void> disconnectDevice(BluetoothDevice device) async {
    final deviceId = device.remoteId.toString();
    final deviceName =
        device.platformName != '' ? device.platformName : deviceId;
    _loadingStatus[deviceId] = true;

    try {
      await device.disconnect();

      _connectionStatus[deviceId] = false;
      _isConnected[deviceId] = false;

      _notifyStatus(
          "Disconnected from $deviceName due to service discovery failure.");
    } catch (e) {
      AppHelpers.debugLog("Failed to disconnect: $e");
      _notifyStatus("Failed to connect the device: $deviceName");
    } finally {
      _loadingStatus[deviceId] = false;
    }
  }

  // Disconnect device with redirect page
  Future<void> disconnectDeviceWithRedirect(BluetoothDevice device) async {
    final deviceId = device.remoteId.toString();
    final deviceName =
        device.platformName != '' ? device.platformName : deviceId;
    _loadingStatus[deviceId] = true;

    try {
      await device.disconnect();

      _connectionStatus[deviceId] = false;
      _isConnected[deviceId] = false;

      _notifyStatus(
          "Disconnected from $deviceName due to service discovery failure.");

      if (Get.isOverlaysOpen) {
        Get.back(); // ini menutup bottom sheet
        Get.back();
      }
    } catch (e) {
      AppHelpers.debugLog("Failed to disconnect: $e");
      _notifyStatus("Failed to connect the device: $deviceName");
    } finally {
      _loadingStatus[deviceId] = false;
    }
  }

  /// Get characteristic device
  Future<bool> _discoverServices(BluetoothDevice device) async {
    try {
      List<BluetoothService> services = await device.discoverServices().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException("Service discovery timed out.");
        },
      );

      for (var service in services) {
        if (service.serviceUuid == serviceUuid) {
          for (var c in service.characteristics) {
            if (c.characteristicUuid == characteristicUuid) {
              _characteristic = c;
              await c.setNotifyValue(true);

              c.onValueReceived.listen((value) {
                _notifyStatus("Response: ${String.fromCharCodes(value)}");
              });

              return true;
            }
          }
        }
      }
      _notifyStatus(
          "Service UUID: $serviceUuid or Characteristic UUID: $characteristicUuid not found on ${device.platformName != '' ? device.platformName : device.remoteId.toString()}");
      return false;
    } catch (e) {
      _notifyStatus(
          "Failed to discover service/characteristic on ${device.platformName != '' ? device.platformName : device.remoteId.toString()}");
      AppHelpers.debugLog("Failed to discover service/characteristic: $e");
      return false;
    }
  }

  /// Send command to device
  void sendCommand(String command) async {
    if (_characteristic == null) {
      _notifyStatus("Characteristic not found.");
      return;
    }

    try {
      await _characteristic!.write(command.codeUnits, withoutResponse: false);
      _notifyStatus("Send command: $command");
    } catch (e) {
      _notifyStatus("Failed to send command");
      AppHelpers.debugLog("Failed to send command: $e");
    }
  }

  void _startLoading() {
    isLoading.value = true;
  }

  void _stopLoading() {
    isLoading.value = false;
  }

  void showSnackbar(
      String title, String message, Color? bgColor, Color? textColor) {
    if (title == '') {
      Get.snackbar(
        '',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: bgColor ?? AppColor.redColor,
        colorText: textColor ?? AppColor.whiteColor,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        titleText: const SizedBox(),
        padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
      );
    } else {
      Get.snackbar(
        title,
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: bgColor ?? AppColor.redColor,
        colorText: textColor ?? AppColor.whiteColor,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
      );
    }
  }

  void showConnectedBottomSheet(BluetoothDevice device) {
    Get.bottomSheet(
      Container(
        padding: AppPadding.medium,
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
                    "Device Connected",
                    style: FontFamily.headlineLarge,
                  ),
                  AppSpacing.sm,
                  Text(
                      "Do you want to open device (${device.remoteId.toString()}) page detail?",
                      style: FontFamily.normal),
                  AppSpacing.md,
                  Row(
                    children: [
                      Expanded(
                        child: Button(
                            onPressed: () => Navigator.of(Get.overlayContext!)
                                .pop(), // hanya tutup bottom sheet
                            text: "No",
                            btnColor: AppColor.grey),
                      ),
                      AppSpacing.md,
                      Expanded(
                        child: Button(
                          onPressed: () {
                            Navigator.of(Get.overlayContext!).pop();
                            Get.to(() => DetailDeviceScreen(device: device));
                          },
                          text: "Yes",
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

  Future<void> showDisconnectedBottomSheet(BluetoothDevice device) async {
    final deviceName = device.platformName != ''
        ? device.platformName
        : device.remoteId.toString();

    Get.bottomSheet(
      Container(
        padding: AppPadding.medium,
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
                    "Disconnect Device",
                    style: FontFamily.headlineLarge,
                  ),
                  AppSpacing.sm,
                  Text("Do you want to disconnect the device ($deviceName)?",
                      style: FontFamily.normal),
                  AppSpacing.md,
                  Row(
                    children: [
                      Expanded(
                        child: Button(
                            onPressed: () => Navigator.of(Get.overlayContext!)
                                .pop(), // hanya tutup bottom sheet
                            text: "No",
                            btnColor: AppColor.grey),
                      ),
                      AppSpacing.md,
                      Expanded(
                        child: Button(
                          onPressed: () async {
                            await disconnectDeviceWithRedirect(device);
                          },
                          text: "Yes",
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

  @override
  void onClose() {
    _statusController.close();
    super.onClose();
  }
}
