import 'dart:async';
import 'dart:convert';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:gateway_config/core/utils/app_helpers.dart';
import 'package:gateway_config/core/utils/ble/ble_utils.dart';
import 'package:gateway_config/models/device_model.dart';
import 'package:get/get.dart';

class BleController extends GetxController {
  // Variabel state
  var isScanning = false.obs;
  var isLoading = false.obs;
  var isLoadingConnectionGlobal = false.obs;
  var connectedDevice = Rxn<BluetoothDevice>();
  var response = ''.obs;
  var errorMessage = ''.obs;
  var message = ''.obs;

  // List untuk menyimpan scanned devices sebagai DeviceModel
  var scannedDevices = <DeviceModel>[].obs;

  BluetoothCharacteristic? commandChar;
  BluetoothCharacteristic? responseChar;

  StreamSubscription? responseSubscription;
  String responseBuffer = '';

  final serviceUUID = Guid('00001830-0000-1000-8000-00805f9b34fb');
  final commandUUID = Guid('11111111-1111-1111-1111-111111111101');
  final responseUUID = Guid('11111111-1111-1111-1111-111111111102');

  // Fungsi scan device
  Future<void> startScan() async {
    if (isScanning.value || isLoading.value) return;

    isLoading.value = true;
    isScanning.value = true;
    errorMessage.value = '';
    scannedDevices.clear(); // Kosongkan list sebelum scan baru

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

      // Listen hasil scan
      FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult r in results) {
          handleScannedDevice(r.device);
        }
      });
    } catch (e) {
      errorMessage.value = 'Error scanning: $e';
    } finally {
      await Future.delayed(const Duration(seconds: 10));
      await stopScan();
      isScanning.value = false;
      isLoading.value = false;
    }
  }

  // Fungsi handle data device yang berhasil di-scan
  void handleScannedDevice(BluetoothDevice device) {
    // Cek jika device sudah ada di list (hindari duplikat)
    if (scannedDevices.any(
      (model) => model.device.remoteId == device.remoteId,
    )) {
      return;
    }

    // Buat DeviceModel dengan info dari BluetoothDevice
    final deviceModel = DeviceModel(
      device: device,
      onConnect: () {},
      onDisconnect: () {},
    );

    deviceModel.onConnect = () => connectToDevice(deviceModel);
    deviceModel.onDisconnect = () => disconnectFromDevice(deviceModel);

    // Tambahkan ke list scannedDevices
    scannedDevices.add(deviceModel);

    // Listen connection state untuk update isConnected
    // Pindahkan setelah deviceModel dideklarasikan
    // ignore: unused_local_variable
    StreamSubscription<BluetoothConnectionState>? connectionSubscription;
    connectionSubscription = device.connectionState.listen((
      BluetoothConnectionState state,
    ) {
      deviceModel.isConnected.value =
          (state == BluetoothConnectionState.connected);
      update();
      if (!deviceModel.isConnected.value) {
        // Reset characteristics jika disconnect
        if (connectedDevice.value?.remoteId == device.remoteId) {
          commandChar = null;
          responseChar = null;
          responseSubscription?.cancel();
          responseBuffer = '';
          response.value = '';
          connectedDevice.value = null;
        }
      }
    });
  }

  // Fungsi stop scan
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    isScanning.value = false;
  }

  // Fungsi connect ke device
  Future<void> connectToDevice(DeviceModel deviceModel) async {
    deviceModel.isLoadingConnection.value = true;
    isLoadingConnectionGlobal.value = true;
    errorMessage.value = '';
    message.value = 'Connecting device...';

    try {
      await deviceModel.device.connect();
      connectedDevice.value = deviceModel.device;

      // Discover services
      List<BluetoothService> services = await deviceModel.device
          .discoverServices();
      BluetoothService? service = services.firstWhereOrNull(
        (s) => s.uuid == serviceUUID,
      );

      if (service == null) {
        errorMessage.value = 'Service not found';

        await disconnectFromDevice(deviceModel);
        return;
      }

      // Ambil characteristics
      commandChar = service.characteristics.firstWhere(
        (c) => c.uuid == commandUUID,
      );
      responseChar = service.characteristics.firstWhere(
        (c) => c.uuid == responseUUID,
      );

      // Subscribe ke response
      await responseChar?.setNotifyValue(true);
      responseSubscription = responseChar?.lastValueStream.listen(
        _handleNotification,
      );

      BLEUtils.showConnectedBottomSheet(deviceModel.device);
    } catch (e) {
      errorMessage.value = 'Error connecting';
      AppHelpers.debugLog('Connection error: $e');
      await disconnectFromDevice(deviceModel);
    } finally {
      deviceModel.isLoadingConnection.value = false;
      isLoadingConnectionGlobal.value = false;
      message.value = 'Success connected...';
    }
  }

  // Fungsi disconnect
  Future<void> disconnectFromDevice(DeviceModel deviceModel) async {
    isLoadingConnectionGlobal.value = true; // Set global loading
    message.value = 'Disconnecting...';

    try {
      await Future.delayed(const Duration(seconds: 3));

      responseSubscription?.cancel();
      await deviceModel.device.disconnect();
      commandChar = null;
      responseChar = null;
      response.value = '';
      responseBuffer = '';
      connectedDevice.value = null;
      deviceModel.isConnected.value = false;

      final currentState = await deviceModel.device.connectionState.first;
      if (currentState == BluetoothConnectionState.connected) {
        deviceModel.isConnected.value = true;
      } else {
        deviceModel.isConnected.value = false;
      }
      update();
    } catch (e) {
      errorMessage.value = 'Error disconnecting';
      AppHelpers.debugLog('Disconnecting error: $e');
    } finally {
      isLoadingConnectionGlobal.value = false; // Reset global loading
      message.value = 'Success disconnected...';
    }
  }

  // Fungsi handle notifikasi
  void _handleNotification(List<int> data) {
    String fragment = utf8.decode(data);
    if (fragment == '<END>') {
      try {
        var jsonResponse = jsonDecode(responseBuffer);
        response.value = jsonEncode(jsonResponse);
      } catch (e) {
        errorMessage.value = 'Invalid response JSON: $e';
      }
      responseBuffer = '';
    } else {
      responseBuffer += fragment;
    }
  }

  DeviceModel? findDeviceByRemoteId(String remoteId) {
    final deviceModel = scannedDevices.firstWhereOrNull(
      (deviceModel) => deviceModel.device.remoteId.toString() == remoteId,
    );
    return deviceModel;
  }

  // Fungsi kirim command
  Future<void> sendCommand(Map<String, dynamic> command) async {
    if (commandChar == null) {
      errorMessage.value = 'Not connected';
      return;
    }

    isLoading.value = true;
    String jsonStr = jsonEncode(command);
    const chunkSize = 18;

    try {
      for (int i = 0; i < jsonStr.length; i += chunkSize) {
        String chunk = jsonStr.substring(
          i,
          i + chunkSize > jsonStr.length ? jsonStr.length : i + chunkSize,
        );
        await commandChar!.write(utf8.encode(chunk));
        await Future.delayed(const Duration(milliseconds: 100));
      }
      await commandChar!.write(utf8.encode('<END>'));
    } catch (e) {
      errorMessage.value = 'Error sending command: $e';
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    for (var model in scannedDevices) {
      disconnectFromDevice(model);
    }
    super.onClose();
  }
}
