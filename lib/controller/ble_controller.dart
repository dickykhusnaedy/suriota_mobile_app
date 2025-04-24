import 'dart:async';
import 'dart:convert';

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
  BluetoothService? _selectedService;
  BluetoothCharacteristic? _selectedCharacteristic;
  BluetoothCharacteristic? _writeChar;
  BluetoothCharacteristic? _notifyChar;

  final devices = <BluetoothDevice>[].obs;
  final isLoading = false.obs;

  final RxMap<String, bool> _connectionStatus = <String, bool>{}.obs;
  final RxMap<String, bool> _loadingStatus = <String, bool>{}.obs;
  final RxMap<String, bool> _isConnected = <String, bool>{}.obs;

  final StreamController<String> _statusController =
      StreamController<String>.broadcast();
  Stream<String> get statusStream => _statusController.stream;

  // Getters
  bool get isDeviceListEmpty => devices.isEmpty;
  RxMap<String, bool> get connectionStatus => _connectionStatus;
  RxMap<String, bool> get loadingStatus => _loadingStatus;
  RxMap<String, bool> get isConnected => _isConnected;
  BluetoothService? get selectedService => _selectedService;
  BluetoothCharacteristic? get selectedCharacteristic =>
      _selectedCharacteristic;
  BluetoothCharacteristic? get writeChar => _writeChar;
  BluetoothCharacteristic? get notifyChar => _notifyChar;

  // Utility Getters
  bool getConnectionStatus(String deviceId) =>
      _connectionStatus[deviceId] ?? false;
  bool getLoadingStatus(String deviceId) => _loadingStatus[deviceId] ?? false;

  void setLoadingStatus(String deviceId, bool isLoading) {
    _loadingStatus[deviceId] = isLoading;
    update(); // Beritahu GetX bahwa state telah berubah
  }

  bool get isAnyDeviceLoading {
    return _loadingStatus.values.any((isLoading) => isLoading);
  }

  /// Scan device
  void scanDevice() async {
    if (isLoading.value) return;

    _startLoading();
    devices.clear();

    await FlutterBluePlus.stopScan();

    final seenDeviceIds = <String>{};
    late final StreamSubscription<List<ScanResult>> subscription;

    subscription = FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        final id = r.device.remoteId.toString();

        if (r.device.platformName.isNotEmpty && !seenDeviceIds.contains(id)) {
          seenDeviceIds.add(id);
          devices.add(r.device);
          _connectionStatus[id] = false;
        }
      }
    });

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    } catch (e) {
      _notifyStatus("Scan failed: $e");
    } finally {
      await Future.delayed(const Duration(seconds: 5));
      await subscription.cancel();
      _stopLoading();
    }
  }

  /// Connect to device
  Future<void> connectToDevice(BluetoothDevice device) async {
    final deviceId = device.remoteId.toString();
    final deviceName =
        device.platformName.isNotEmpty ? device.platformName : deviceId;

    setLoadingStatus(deviceId, true);

    try {
      await FlutterBluePlus.stopScan();
      await device.connect(timeout: const Duration(seconds: 10));

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
      setLoadingStatus(deviceId, false);
    }
  }

  /// Disconnect to device
  Future<void> disconnectDevice(BluetoothDevice device) async {
    final deviceId = device.remoteId.toString();
    final deviceName =
        device.platformName.isNotEmpty ? device.platformName : deviceId;
    setLoadingStatus(deviceId, true);

    try {
      await device.disconnect();

      _connectionStatus[deviceId] = false;
      _isConnected[deviceId] = false;

      _notifyStatus("Disconnected from $deviceName.");
    } catch (e) {
      AppHelpers.debugLog("Failed to disconnect: $e");
      _notifyStatus("Failed to connect the device: $deviceName");
    } finally {
      setLoadingStatus(deviceId, false);
    }
  }

  // Disconnect device with redirect page
  Future<void> disconnectDeviceWithRedirect(BluetoothDevice device) async {
    final deviceId = device.remoteId.toString();
    final deviceName =
        device.platformName.isNotEmpty ? device.platformName : deviceId;
    _loadingStatus[deviceId] = true;

    try {
      await device.disconnect();

      _connectionStatus[deviceId] = false;
      _isConnected[deviceId] = false;

      _notifyStatus("Disconnected from $deviceName.");

      if (Get.isOverlaysOpen) {
        Get.back();
      }
      Future.delayed(const Duration(milliseconds: 300), () {
        if (Get.currentRoute != '/') {
          Get.back(); // Kembali ke halaman sebelumnya
        }
      });
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

      if (services.isEmpty) {
        _notifyStatus("No services found on ${device.platformName}");
        return false;
      }

      for (var service in services) {
        for (var char in service.characteristics) {
          final props = char.properties;

          if (props.write && _writeChar == null) {
            _writeChar = char;
          }

          if (props.notify && _notifyChar == null) {
            _notifyChar = char;

            await _notifyChar!.setNotifyValue(true);
            _notifyChar!.onValueReceived.listen((value) {
              final received = utf8.decode(value);
              _notifyStatus("Notify from ESP32: $received");
            });
          }

          // Jika sudah dapat keduanya, kita lanjut
          if (_writeChar != null && _notifyChar != null) {
            _selectedService = service;
            return true;
          }
        }
      }

      _notifyStatus("No valid characteristic with notify/write/read found.");
      return false;
    } catch (e) {
      _notifyStatus(
          "Failed to discover service/characteristic on ${device.platformName}");
      AppHelpers.debugLog("Failed to discover service/characteristic: $e");
      return false;
    }
  }

  /// Send command to device
  void sendCommand(String value) async {
    if (_writeChar == null) {
      _notifyStatus("Characteristic Write tidak ditemukan.");
      return;
    }

    try {
      final bytes = utf8.encode(value);
      await _writeChar!.write(bytes, withoutResponse: false);
    } catch (e) {
      _notifyStatus("Failde send a command");
      AppHelpers.debugLog("Failde send a command: $e");
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
    final snackbar = GetSnackBar(
      title: title.isEmpty ? null : title,
      message: message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: bgColor ?? AppColor.redColor,
      messageText: Text(
        message,
        style:
            FontFamily.normal.copyWith(color: textColor ?? AppColor.whiteColor),
      ),
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      padding: title.isEmpty
          ? const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 12.0)
          : const EdgeInsets.all(12.0),
      titleText: title.isEmpty ? const SizedBox() : null,
      borderRadius: 8,
    );

    Get.showSnackbar(snackbar);
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
                      "Do you want to open device (${device.platformName.isNotEmpty ? device.platformName : device.remoteId.toString()}) page detail?",
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
    final deviceName = device.platformName.isNotEmpty
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

  @override
  void onClose() {
    _statusController.close();
    super.onClose();
  }
}
