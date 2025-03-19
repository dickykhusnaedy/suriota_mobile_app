import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';

class BluetoothController extends GetxController {
  var devices = <BluetoothDevice>[].obs; //the result after scanning
  var connectedDevice = Rxn<BluetoothDevice>(); //the connected device
  var isScanning = false.obs; //scanning boolean
  var connectingDevices = <String, bool>{}.obs;

  // UUID ESP32
  final String serviceUuid = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E";
  final String characteristicUuid = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E";

  BluetoothCharacteristic? targetCharacteristic; // Karakteristik BLE

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

      // Cari karakteristik setelah terhubung
      await discoverServices(device);
      sendData({"device": "iOS", "name": "Cyrillus Rudi Soru"});

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

  // 🔍 Fungsi untuk menemukan layanan & karakteristik BLE
  Future<void> discoverServices(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();
    for (BluetoothService service in services) {
      if (service.uuid.toString().toLowerCase() == serviceUuid.toLowerCase()) {
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          if (characteristic.uuid.toString().toLowerCase() ==
              characteristicUuid.toLowerCase()) {
            targetCharacteristic = characteristic;
            Get.snackbar("Info", "Characteristic found: ${characteristic.uuid}",
                snackPosition: SnackPosition.TOP);
            return;
          }
        }
      }
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
  //   Future<void> sendData(String data) async {
  //   if (targetCharacteristic == null) {
  //     Get.snackbar("Error", "No characteristic found. Please reconnect.",
  //         snackPosition: SnackPosition.BOTTOM);
  //     print("No characteristic found, cannot send data.");
  //     return;
  //   }

  //   List<int> bytes = utf8.encode(data);
  //   await targetCharacteristic!.write(bytes);
  //   print("Data terkirim: $data");
  //   Get.snackbar("Sent", "Data sent: $data", snackPosition: SnackPosition.TOP);
  // }
  
  Future<void> sendData(Map<String, dynamic> jsonData) async {
    if (targetCharacteristic == null) {
      Get.snackbar("Error", "No characteristic found. Please reconnect.",
          snackPosition: SnackPosition.BOTTOM);
      print("No characteristic found, cannot send data.");
      return;
    }

    try {
      // Konversi JSON ke string
      String jsonString = json.encode(jsonData);

      // Konversi string ke bytes
      List<int> bytes = utf8.encode(jsonString);

      // Kirim data ke BLE
      await targetCharacteristic!
          .write(Uint8List.fromList(bytes), withoutResponse: true);

      print("JSON terkirim: $jsonString");
      Get.snackbar("Sent", "JSON sent: $jsonString",
          snackPosition: SnackPosition.TOP);
    } catch (e) {
      print("Error sending JSON: $e");
      Get.snackbar("Error", "Failed to send JSON: $e",
          snackPosition: SnackPosition.BOTTOM);
    }
  }
}
