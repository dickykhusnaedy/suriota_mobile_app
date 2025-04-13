import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:suriota_mobile_gateway/constant/app_color.dart';

class BLEController extends GetxController {
  final Guid serviceUuid = Guid("12345678-1234-1234-1234-1234567890ab");
  final Guid characteristicUuid = Guid("abcd1234-1234-1234-1234-abcdef123456");

  // State reaktif untuk BluetoothDevice dan BluetoothCharacteristic
  BluetoothCharacteristic? _characteristic;

  // StreamController untuk status dan daftar perangkat
  final StreamController<String> _statusController =
      StreamController<String>.broadcast();
  Stream<String> get statusStream => _statusController.stream;

  // Daftar perangkat BLE (reaktif)
  final devices = <BluetoothDevice>[].obs;

  // Indikator loading (reaktif)
  var isLoading = false.obs;

  // Map reaktif untuk status koneksi perangkat
  final RxMap<String, bool> _connectionStatus = <String, bool>{}.obs;
  Map<String, bool> get connectionStatus => _connectionStatus;

  // Map reaktif untuk status loading perangkat
  final RxMap<String, bool> _loadingStatus = <String, bool>{}.obs;
  Map<String, bool> get loadingStatus => _loadingStatus;

  // Map reaktif untuk status koneksi (terhubung atau tidak)
  final RxMap<String, bool> _isConnected = <String, bool>{}.obs;
  Map<String, bool> get isConnected => _isConnected;

  // Notifikasi status
  void _notifyStatus(String status) {
    _statusController.add(status);

    Get.snackbar(
      '',
      status, // Pesan status
      snackPosition: SnackPosition.BOTTOM, // Posisi snackbar
      backgroundColor: AppColor.grey, // Warna latar belakang
      colorText: AppColor.whiteColor, // Warna teks
      duration: const Duration(seconds: 3), // Durasi tampilan snackbar
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

  /// Memulai pemindaian BLE
  void scanAndConnect() async {
    if (isLoading.value) return; // Hindari pemindaian ganda

    _startLoading();
    devices.clear();

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    final subscription = FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult r in results) {
        if (!devices.contains(r.device)) {
          devices.add(r.device); // Tambahkan perangkat ke daftar reaktif
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

  /// Menangani koneksi ke perangkat BLE
  Future<void> connectToDevice(BluetoothDevice device) async {
    await _handleDeviceConnection(device);
  }

  /// Memutuskan koneksi dari perangkat BLE
  Future<void> disconnectDevice(BluetoothDevice device) async {
    final deviceId = device.remoteId.toString();
      _loadingStatus[deviceId] = true; // Mulai loading untuk perangkat ini
    try {      
      await device.disconnect();

      _connectionStatus[deviceId] = false; // Update status: disconnected
      _isConnected[deviceId] = false;

      _notifyStatus("Loss connection ${device.platformName}");
    } catch (e) {
      _notifyStatus("Failed to loss connection: $e");
        _isConnected[deviceId] = true;
       _connectionStatus[deviceId] = true;
    } finally {
      _loadingStatus[deviceId] = false; // Hentikan loading untuk perangkat ini
    }
  }

  /// Mengirim perintah ke perangkat BLE
  void sendCommand(String command) async {
    if (_characteristic == null) {
      _notifyStatus("Characteristic not found.");
      return;
    }

    try {
      await _characteristic!.write(command.codeUnits, withoutResponse: false);
      _notifyStatus("Send command: $command");
    } catch (e) {
      _notifyStatus("Failed to send command: $e");
    }
  }

  /// Menangani koneksi ke perangkat BLE
  Future<void> _handleDeviceConnection(BluetoothDevice device) async {
    final deviceId = device.remoteId.toString();
    _loadingStatus[deviceId] = true; 

    try {
      print('start connect');
      await FlutterBluePlus.stopScan();
      await device.connect();

      // _device = device;
      _connectionStatus[deviceId] = true; // Update status: connected
      _isConnected[deviceId] = true;

      await _discoverServices(device);

      _notifyStatus("Connected to ${device.platformName}");
    } catch (e) {
      _connectionStatus[deviceId] = false; // Update status: not connect
      _isConnected[deviceId] = false;

      _notifyStatus("Failed to connect: $e");
    } finally {
      _stopLoading();
      _loadingStatus[deviceId] = false; 
    }
  }

  /// Mencari layanan dan karakteristik BLE
  Future<void> _discoverServices(BluetoothDevice device) async {
    try {
      List<BluetoothService> services = await device.discoverServices();
      for (var service in services) {
        if (service.serviceUuid == serviceUuid) {
          for (var c in service.characteristics) {
            if (c.characteristicUuid == characteristicUuid) {
              _characteristic = c;
              await c.setNotifyValue(true);

              c.onValueReceived.listen((value) {
                _notifyStatus("Response: ${String.fromCharCodes(value)}");
              });

              _notifyStatus("Characteristics discovered.");
              return;
            }
          }
        }
      }
      _notifyStatus("Service or characteristic not found.");
    } catch (e) {
      _notifyStatus("Failed to discover service/characteristic: $e");
    }
  }

  /// Mulai loading
  void _startLoading() {
    isLoading.value = true;
  }

  /// Hentikan loading
  void _stopLoading() {
    isLoading.value = false;
  }

  @override
  void onClose() {
    _statusController.close();
    super.onClose();
  }
}
