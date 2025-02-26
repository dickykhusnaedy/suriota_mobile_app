import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';

class BluetoothController extends GetxController {
  var devices = <BluetoothDevice>[].obs; //the result after scanning
  var connectedDevice = Rxn<BluetoothDevice>(); //the connected device
  var isScanning = false.obs; //scanning boolean
  var connectingDevices = <String, bool>{}.obs;

  @override
  void onInit() {
    super.onInit();
    FlutterBluePlus.setLogLevel(LogLevel.info, color: true);
  }

  // Fungsi untuk scanning perangkat BLE
  void startScan() {
    if (isScanning.value) return;

    isScanning.value = true;
    devices.clear();

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    FlutterBluePlus.scanResults.listen((results) {
      for (var result in results) {
        if (!devices.contains(result.device)) {
          devices.add(result.device);
        }
      }
    });

    Future.delayed(const Duration(seconds: 5), () {
      FlutterBluePlus.stopScan();
      isScanning.value = false;
    });
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      connectingDevices[device.remoteId.toString()] =
          true; // Aktifkan loading hanya untuk perangkat ini
      connectingDevices.refresh(); // Memperbarui UI

      await device.connect().timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException("Connection timed out");
        },
      );

      connectedDevice.value = device;
      print("Connected to device: $device");
      Get.snackbar("Success", "Connected to device: ${device.remoteId}",
          snackPosition: SnackPosition.TOP);
    } catch (e) {
      print("Connection failed: $e");
      Get.snackbar("Error", "Failed to connect: ${device.remoteId}",
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      connectingDevices[device.remoteId.toString()] = false; // Matikan loading
      connectingDevices.refresh();
    }
  }

  // Fungsi untuk memutuskan koneksi perangkat
  Future<void> disconnectDevice() async {
    if (connectedDevice.value != null) {
      await connectedDevice.value!.disconnect();
      connectedDevice.value = null;
      Get.snackbar("Disconnect", "Disconected from device",
          snackPosition: SnackPosition.TOP);
    }
  }
}
