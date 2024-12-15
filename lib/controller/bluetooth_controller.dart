import 'dart:convert';

import 'package:flutter_blue/flutter_blue.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:suriota_mobile_gateway/constant/app_color.dart';
import 'package:suriota_mobile_gateway/models/device_model.dart';

class BluetoothController extends GetxController {
  // Observables
  var isScanning = false.obs;
  var devices = <BluetoothDevice>[].obs;
  var pairedDevices = <DeviceModel>[].obs; // Perangkat tersimpan
  var connectedDevice = Rxn<BluetoothDevice>();

  // Instances
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  final GetStorage storage = GetStorage();

  @override
  void onInit() {
    super.onInit();
    loadPairedDevices(); // Muat perangkat tersimpan saat controller diinisialisasi
  }

  // Fungsi untuk memulai scanning perangkat BLE
  void scanDevices() {
    isScanning.value = true;
    devices.clear(); // Hapus daftar perangkat saat scan ulang

    flutterBlue.startScan(timeout: Duration(seconds: 10)).then((_) {
      isScanning.value = false;
    });

    flutterBlue.scanResults.listen((results) {
      for (var result in results) {
        if (!devices.contains(result.device)) {
          devices.add(result.device);
        }
      }
    });
  }

  // Fungsi untuk menghubungkan perangkat
  void connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      connectedDevice.value = device;
      print('Connected to ${device.name}');
    } catch (e) {
      print('Failed to connect: $e');
    }
  }

  void disconnectDevice() async {
    if (connectedDevice.value != null) {
      try {
        await connectedDevice.value!.disconnect();
        print('Device disconnected: ${connectedDevice.value!.name}');

        // Cari perangkat di pairedDevices dan ubah isConnected menjadi false
        final deviceIndex = pairedDevices.indexWhere((device) =>
            device.deviceAddress == connectedDevice.value!.id.toString());
        if (deviceIndex != -1) {
          pairedDevices[deviceIndex].isConnected.value = false;
          Get.snackbar(
            "Disconnected",
            "${pairedDevices[deviceIndex].deviceTitle} has been disconnected",
            snackPosition: SnackPosition.BOTTOM,
          );
        }

        // Reset connectedDevice
        connectedDevice.value = null;
      } catch (e) {
        print('Error disconnecting device: $e');
        Get.snackbar(
          "Disconnection Failed",
          "Failed to disconnect. Please try again.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColor.redColor,
          colorText: Get.theme.colorScheme.onError,
        );
      }
    }
  }

  void savePairedDevice(DeviceModel deviceModel) {
    // Periksa apakah perangkat dengan deviceAddress yang sama sudah ada
    final isDuplicate = pairedDevices
        .any((device) => device.deviceAddress == deviceModel.deviceAddress);

    if (!isDuplicate) {
      pairedDevices.add(deviceModel);

      // Konversi ke List<Map<String, dynamic>>
      final devicesToSave =
          pairedDevices.map((device) => device.toJson()).toList();

      // Simpan ke GetStorage
      storage.write('pairedDevices', devicesToSave);

      print('Device saved: ${deviceModel.deviceTitle}');
      print('Devices stored: $devicesToSave');
    } else {
      print(
          'Device with address ${deviceModel.deviceAddress} is already saved.');
    }
  }

  void loadPairedDevices() {
    // Baca data mentah dari GetStorage
    final rawDevices = storage.read('pairedDevices');

    // Jika data adalah String (hasil jsonEncode), decode JSON menjadi List
    final savedDevices = rawDevices is String
        ? (jsonDecode(rawDevices) as List<dynamic>)
        : (rawDevices as List<dynamic>? ?? []);

    // Konversi dari List<dynamic> ke List<DeviceModel>
    pairedDevices.value = savedDevices
        .map((device) =>
            DeviceModel.fromJson(device as Map<String, dynamic>, flutterBlue))
        .toList();

    print('Paired devices loaded: ${pairedDevices.map((d) => d.deviceTitle)}');
  }

  // Fungsi untuk menghapus perangkat tersimpan
  void removeDevice({required int index}) {
    pairedDevices.removeAt(index);

    // Update GetStorage
    final devicesToSave =
        pairedDevices.map((device) => device.toJson()).toList();
    storage.write('pairedDevices', devicesToSave);
    print('Device removed');
  }

  // Fungsi untuk scan dan koneksi perangkat berdasarkan MAC address
  void scanSavedDevices() async {
    for (var savedDevice in pairedDevices) {
      flutterBlue.startScan(timeout: Duration(seconds: 5));
      flutterBlue.scanResults.listen((results) {
        for (var result in results) {
          if (result.device.id.toString() == savedDevice.deviceAddress) {
            connectToDevice(result.device);
            savedDevice.isConnected.value = true;
            print('Connected to saved device: ${savedDevice.deviceTitle}');
            flutterBlue.stopScan();
            break;
          }
        }
      });
    }
  }

  void connectToPairedDevice(DeviceModel deviceModel) async {
    try {
      isScanning.value = true;

      // Mulai scan untuk menemukan perangkat dengan MAC address yang cocok
      flutterBlue.startScan(timeout: Duration(seconds: 5));
      flutterBlue.scanResults.listen((results) async {
        for (var result in results) {
          if (result.device.id.toString() == deviceModel.deviceAddress) {
            // Hentikan proses scan
            flutterBlue.stopScan();
            isScanning.value = false;

            // Hubungkan perangkat
            connectToDevice(result.device);
            return; // Keluar setelah berhasil terhubung
          }
        }
      });
    } catch (e) {
      isScanning.value = false;
      print('Failed to connect to paired device: $e');
      Get.snackbar(
        "Connection Failed",
        "Failed to connect to ${deviceModel.deviceTitle}. Please try again.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColor.redColor,
        colorText: Get.theme.colorScheme.onError,
      );
    }
  }
}
