import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';

class BLEController extends GetxController {
  final Guid serviceUuid = Guid("12345678-1234-1234-1234-1234567890ab");
  final Guid characteristicUuid = Guid("abcd1234-1234-1234-1234-abcdef123456");

  BluetoothDevice? _device;
  BluetoothCharacteristic? _characteristic;
  Function(String status)? onStatusChanged;

  void scanAndConnect() async {
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    final subscription = FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult r in results) {
        if (r.device.platformName == "ESP32-BLE-LED") {
          await FlutterBluePlus.stopScan();
          await r.device.connect();

          _device = r.device;
          _notifyStatus("Connected to ${r.device.platformName}");

          List<BluetoothService> services = await r.device.discoverServices();
          for (var service in services) {
            if (service.serviceUuid == serviceUuid) {
              for (var c in service.characteristics) {
                if (c.characteristicUuid == characteristicUuid) {
                  _characteristic = c;
                  await c.setNotifyValue(true);
                  c.onValueReceived.listen((value) {
                    _notifyStatus("Response: ${String.fromCharCodes(value)}");
                  });
                }
              }
            }
          }
        }
      }
    });

    Future.delayed(const Duration(seconds: 5), () {
      subscription.cancel();
      _notifyStatus("Scan timed out");
    });
  }

  void sendCommand(String command) async {
    if (_characteristic != null) {
      await _characteristic!.write(command.codeUnits, withoutResponse: false);
    }
  }

  void disconnect() async {
    if (_device != null) {
      await _device!.disconnect();
      _notifyStatus("Disconnected");
    }
  }

  void _notifyStatus(String status) {
    if (onStatusChanged != null) {
      onStatusChanged!(status);
      Get.snackbar('Success', status);
    }
  }
}
