import 'dart:async';
import 'dart:convert';

import 'package:flutter_blue/flutter_blue.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:suriota_mobile_gateway/models/device_model.dart';

class BluetoothController extends GetxController {
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  late StreamSubscription<List<ScanResult>> _scanSubscription;
  final GetStorage storage = GetStorage();

  var devices = <BluetoothDevice>[].obs;
  RxList<DeviceModel> pairedDevices = <DeviceModel>[].obs;

  Rx<BluetoothDevice?> connectedDevice = Rx<BluetoothDevice?>(null);
  Rx<BluetoothDeviceState?> deviceState = Rx<BluetoothDeviceState?>(null);
  var isScanning = false.obs;

  final _seenDevices =
      <String>{}; // Untuk melacak perangkat yang sudah ditemukan

  @override
  void onInit() {
    super.onInit();
    scanDevices();
    loadPairedDevices(); // Memuat perangkat yang telah dipair dari penyimpanan
  }

  @override
  void onClose() {
    super.onClose();
    _scanSubscription.cancel(); // Menghentikan subscription hasil scan
    flutterBlue.stopScan();
    devices.clear();
    if (connectedDevice.value != null) {
      connectedDevice.value!.disconnect();
    }
  }

  // Scan perangkat Bluetooth
  void scanDevices() {
    isScanning.value = true;
    devices.clear();
    _seenDevices.clear();

    flutterBlue.startScan(timeout: const Duration(seconds: 3)).then((_) {
      isScanning.value = false; // Scanning selesai
    });

    _scanSubscription = flutterBlue.scanResults.listen((results) {
      for (ScanResult result in results) {
        if (result.device.name.isNotEmpty &&
            !_seenDevices.contains(result.device.id.id)) {
          _seenDevices.add(result
              .device.id.id); // Tambahkan ke set untuk menghindari duplikasi
          devices.add(result.device);
        }
      }
    });
  }

  // Menghubungkan ke perangkat Bluetooth
  Future<void> connectToDevice(BluetoothDevice device) async {
    if (connectedDevice.value == device) {
      print('${device.name} is already connected');
      return;
    }

    try {
      await device.connect(timeout: const Duration(seconds: 10));
      connectedDevice.value = device;
      monitorDeviceState(device);
      print('Connected to ${device.name}');
      discoverServices(device);
    } catch (e) {
      print('Connection failed: $e');
    }
  }

  // Monitor status koneksi perangkat
  void monitorDeviceState(BluetoothDevice device) {
    device.state.listen((state) {
      deviceState.value = state;
      if (state == BluetoothDeviceState.disconnected) {
        print('Device disconnected. Attempting to reconnect...');
        reconnectDevice(device);
      } else if (state == BluetoothDeviceState.connected) {
        print('Device is connected');
      }
    });
  }

  // Mencoba reconnect perangkat yang terputus
  Future<void> reconnectDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      print('Reconnected to ${device.name}');
    } catch (e) {
      print('Failed to reconnect: $e');
    }
  }

  // Menemukan layanan pada perangkat yang terhubung
  Future<void> discoverServices(BluetoothDevice device) async {
    var services = await device.discoverServices();
    for (var service in services) {
      print('Service UUID: ${service.uuid}');
      for (var characteristic in service.characteristics) {
        print('Characteristic UUID: ${characteristic.uuid}');
      }
    }
  }

  // Memutuskan koneksi perangkat
  Future<void> disconnectDevice() async {
    if (connectedDevice.value != null) {
      await connectedDevice.value!.disconnect();
      connectedDevice.value = null;
      deviceState.value = null;
      print('Device disconnected manually');
    }
  }

  void savePairedDevice(DeviceModel device) {
    // Cek apakah perangkat sudah ada di pairedDevices
    if (pairedDevices
        .any((paired) => paired.deviceAddress == device.deviceAddress)) {
      print('Device ${device.deviceTitle} is already paired');
      return;
    }

    // Tambahkan perangkat ke pairedDevices
    pairedDevices.add(device);
    savePairedDevicesToStorage();
    print('Device ${device.deviceTitle} added to paired devices');
  }

  // Menyimpan perangkat ke GetStorage
  void savePairedDevicesToStorage() {
    List<Map<String, dynamic>> jsonList =
        pairedDevices.map((dev) => dev.toJson()).toList();
    storage.write('pairedDevices', jsonEncode(jsonList));
  }

  // Memuat perangkat yang telah dipair dari GetStorage
  void loadPairedDevices() {
    String? jsonString = storage.read<String>('pairedDevices');
    if (jsonString != null) {
      List<dynamic> jsonList = jsonDecode(jsonString);
      pairedDevices.value = jsonList
          .map((json) =>
              DeviceModel.fromJson(json as Map<String, dynamic>, flutterBlue))
          .toList();
    }
  }

  // Hapus perangkat dari daftar
  void removeDevice({required int index}) {
    pairedDevices.removeAt(index);
    savePairedDevicesToStorage(); // Simpan perubahan ke penyimpanan
  }
}
