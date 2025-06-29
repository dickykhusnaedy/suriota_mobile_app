import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:suriota_mobile_gateway/core/controllers/ble/ble_controller.dart';
import 'package:suriota_mobile_gateway/core/utils/ble/ble_utils.dart';
import 'package:suriota_mobile_gateway/global/utils/helper.dart';
import 'package:suriota_mobile_gateway/screen/home/home_screen.dart';

class BLEConnection {
  BLEController? controller;
  StreamSubscription<BluetoothConnectionState>? _disconnectSubscription;

  // Connect to a BLE device
  Future<void> connectToDevice(BluetoothDevice device) async {
    final deviceId = device.remoteId.toString();
    final deviceName =
        device.platformName.isNotEmpty ? device.platformName : deviceId;
    controller!.setLoadingStatus(deviceId, true);

    try {
      await FlutterBluePlus.stopScan();
      await device.connect(
          timeout: const Duration(seconds: 10), autoConnect: false);
      AppHelpers.debugLog('Requested MTU 512 for device: $deviceName');

      cancelDisconnectSubscription();
      _disconnectSubscription = device.connectionState.listen((state) async {
        if (state == BluetoothConnectionState.disconnected) {
          controller!.resetBleState();
          await resetBleConnectionsOnly();
          if (Get.currentRoute != '/') {
            await Get.offAll(() => const HomeScreen());
          }
        }
      });

      final isServiceDiscovered = await _discoverServices(device);
      if (isServiceDiscovered) {
        BLEUtils.showConnectedBottomSheet(device);
      } else {
        await disconnectDevice(device);
      }

      controller!.connectionStatus[deviceId] = true;
      controller!.isConnected[deviceId] = true;
    } catch (e) {
      controller!.connectionStatus[deviceId] = false;
      controller!.isConnected[deviceId] = false;
      controller!.notifyStatus('Failed to connect to $deviceName');
      AppHelpers.debugLog('Connection error: $e');
    } finally {
      controller!.setLoadingStatus(deviceId, false);
    }
  }

  // Disconnect from a BLE device
  Future<void> disconnectDevice(BluetoothDevice device) async {
    final deviceId = device.remoteId.toString();
    final deviceName =
        device.platformName.isNotEmpty ? device.platformName : deviceId;
    controller!.setLoadingStatus(deviceId, true);

    try {
      if (!controller!.isConnected[deviceId]!) {
        controller!.connectionStatus[deviceId] = false;
        controller!.isConnected[deviceId] = false;
        controller!.notifyStatus('Disconnected from $deviceName');
        return;
      }

      await device.disconnect().timeout(const Duration(seconds: 10));
      controller!.connectionStatus[deviceId] = false;
      controller!.isConnected[deviceId] = false;
      controller!.notifyStatus('Disconnected from $deviceName');
    } catch (e) {
      controller!.connectionStatus[deviceId] = false;
      controller!.isConnected[deviceId] = false;
      controller!.notifyStatus('Failed to disconnect $deviceName: $e');
      AppHelpers.debugLog('Disconnect error: $e');
    } finally {
      controller!.setLoadingStatus(deviceId, false);
    }
  }

  // Reset all BLE connections
  Future<void> resetBleConnectionsOnly() async {
    try {
      await FlutterBluePlus.stopScan();
      final connectedDevices = await FlutterBluePlus.connectedSystemDevices;
      for (final device in connectedDevices) {
        await device.disconnect();
        AppHelpers.debugLog('Disconnected ${device.platformName}');
      }
    } catch (e) {
      controller!.notifyStatus('Failed to reset BLE connections');
      AppHelpers.debugLog('Reset BLE error: $e');
    }
  }

  // Discover services on a connected device
  Future<bool> _discoverServices(BluetoothDevice device) async {
    try {
      final services =
          await device.discoverServices().timeout(const Duration(seconds: 30));
      if (services.isEmpty) {
        controller!.notifyStatus('No services found on ${device.platformName}');
        return false;
      }

      try {
        await device.requestMtu(512);
        final mtu = await device.mtu.first;
        AppHelpers.debugLog('MTU set to: $mtu');
      } catch (e) {
        AppHelpers.debugLog('MTU setup error: $e');
      }

      for (final service in services) {
        for (final char in service.characteristics) {
          _assignCharacteristic(char);
          if (controller!.writeCharacteristic != null &&
              controller!.notifyCharacteristic != null) {
            controller!.components.setSelectedService(service);
            return true;
          }
        }
      }

      controller!.notifyStatus('No valid characteristics found');
      return false;
    } catch (e) {
      controller!.notifyStatus(
          'Failed to discover services on ${device.platformName}');
      AppHelpers.debugLog('Service discovery error: $e');
      return false;
    }
  }

  // Assign characteristics for write and notify operations
  void _assignCharacteristic(BluetoothCharacteristic char) async {
    final props = char.properties;
    if (props.write && controller!.writeCharacteristic == null) {
      controller!.components.setWriteCharacteristic(char);
      AppHelpers.debugLog('Assigned write characteristic: ${char.uuid}');
    }
    if (props.notify && controller!.notifyCharacteristic == null) {
      controller!.components.setNotifyCharacteristic(char);
      try {
        await controller!.notifyCharacteristic!.setNotifyValue(true);
        await Future.delayed(const Duration(milliseconds: 2000));
        controller!.dataProcessor.listenToNotifications();

        AppHelpers.debugLog(
            'Notification enabled for characteristic: ${char.uuid}');
      } catch (e) {
        controller!.notifyStatus('Failed to enable notifications');
        AppHelpers.debugLog('Notification enable error: $e');
      }
    }
  }

  // Cancel disconnect subscription
  void cancelDisconnectSubscription() {
    _disconnectSubscription?.cancel();
    _disconnectSubscription = null;
  }
}
