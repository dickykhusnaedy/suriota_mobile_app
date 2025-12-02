import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:gateway_config/core/controllers/devices_controller.dart';
import 'package:gateway_config/core/controllers/modbus_controller.dart';
import 'package:gateway_config/core/utils/app_helpers.dart';
import 'package:get/get.dart';

class DeviceModel {
  final BluetoothDevice device;
  final RxBool isConnected;
  final RxBool isLoadingConnection;
  final Rx<DateTime?> lastConnectionTime;
  final Rx<DateTime?> updatedAt;
  void Function() onConnect;
  void Function() onDisconnect;

  DeviceModel({
    required this.device,
    required this.onConnect,
    required this.onDisconnect,
  }) : isConnected = RxBool(false),
       isLoadingConnection = RxBool(false),
       lastConnectionTime = Rx<DateTime?>(null),
       updatedAt = Rx<DateTime?>(null);

  /// Clear all cached device data and register data from controllers
  /// This should be called after factory reset or when device configuration is cleared
  void clearData() {
    try {
      AppHelpers.debugLog('Clearing device data and register data...');

      // Clear device data from DevicesController
      final devicesController = Get.find<DevicesController>();
      devicesController.dataDevices.clear();
      devicesController.selectedDevice.clear();
      devicesController.filteredDataDevices.clear();
      devicesController.lastFetchTime.value = null;
      devicesController.searchQuery.value = '';
      devicesController.selectedProtocol.value = 'All';

      AppHelpers.debugLog('Device data cleared from DevicesController');

      // Clear register data from ModbusController
      final modbusController = Get.find<ModbusController>();
      modbusController.dataModbus.clear();
      modbusController.selectedModbus.clear();
      modbusController.lastFetchTime.value = null;

      AppHelpers.debugLog('Register data cleared from ModbusController');

      AppHelpers.debugLog('All data cleared successfully');
    } catch (e) {
      AppHelpers.debugLog('Error clearing data: $e');
    }
  }
}
