import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:suriota_mobile_gateway/core/constants/app_color.dart';
import 'package:suriota_mobile_gateway/core/controllers/ble/ble_data_processor.dart';
import 'package:suriota_mobile_gateway/core/services/ble/ble_connection.dart';
import 'package:suriota_mobile_gateway/core/services/ble/ble_scan.dart';
import 'package:suriota_mobile_gateway/core/states/ble/ble_device_status_state.dart';
import 'package:suriota_mobile_gateway/core/utils/ble/ble_components.dart';
import 'package:suriota_mobile_gateway/core/utils/ble/ble_utils.dart';
import 'package:suriota_mobile_gateway/core/utils/snackbar_custom.dart';
import 'package:suriota_mobile_gateway/core/utils/app_helpers.dart';

// Manages BLE operations and state
class BLEController extends GetxController {
  // Observables for device list and loading state
  final RxList<BluetoothDevice> devices = <BluetoothDevice>[].obs;
  final RxBool isLoading = false.obs;
  final RxString storedDeviceData = ''.obs;

  // Device status and BLE components
  final BleDeviceStatusState _status = BleDeviceStatusState();
  final BLEComponents components = BLEComponents();

  // Modular components
  final BLEScanner _scanner;
  final BLEConnection _connectionManager;
  final BLEDataProcessor dataProcessor;

  // Stream for status updates
  final StreamController<String> _statusController =
      StreamController<String>.broadcast();
  Stream<String> get statusStream => _statusController.stream;

  // Constructor with dependency injection for testing
  BLEController({
    BLEScanner? scanner,
    BLEConnection? connectionManager,
    BLEDataProcessor? dataProcessor,
  })  : _scanner = scanner ?? BLEScanner(),
        _connectionManager = connectionManager ?? BLEConnection(),
        dataProcessor = dataProcessor ?? BLEDataProcessor() {
    _initializeDependencies();
    AppHelpers.debugLog('BLEController initialized');
  }

  void _initializeDependencies() {
    _scanner.controller = this;
    _connectionManager.controller = this;
    dataProcessor.controller = this;
  }

  // Getters for public access
  bool get isDeviceListEmpty => devices.isEmpty;
  RxMap<String, bool> get connectionStatus => _status.connectionStatus;
  RxMap<String, bool> get loadingStatus => _status.loadingStatus;
  RxMap<String, bool> get isConnected => _status.isConnected;
  BluetoothService? get selectedService => components.selectedService;
  BluetoothCharacteristic? get selectedCharacteristic =>
      components.selectedCharacteristic;
  BluetoothCharacteristic? get writeCharacteristic =>
      components.writeCharacteristic;
  BluetoothCharacteristic? get notifyCharacteristic =>
      components.notifyCharacteristic;
  bool get isAnyDeviceLoading =>
      _status.loadingStatus.values.any((isLoading) => isLoading);
  RxInt get receivedPackets => dataProcessor.receivedPackets;
  RxInt get expectedPackets => dataProcessor.expectedPackets;

  // Get connection status for a specific device
  bool getConnectionStatus(String deviceId) =>
      _status.connectionStatus[deviceId] ?? false;

  // Get loading status for a specific device
  bool getLoadingStatus(String deviceId) =>
      _status.loadingStatus[deviceId] ?? false;

  // Set loading status for a specific device
  void setLoadingStatus(String deviceId, bool isLoading) {
    _status.loadingStatus[deviceId] = isLoading;
    update();
  }

  // Start scanning for BLE devices
  void scanDevice() => _scanner.scanDevice();

  // Connect to a BLE device
  Future<void> connectToDevice(BluetoothDevice device) =>
      _connectionManager.connectToDevice(device);

  // Disconnect from a BLE device
  Future<void> disconnectDevice(BluetoothDevice device) =>
      _connectionManager.disconnectDevice(device);

  // Reset BLE connections
  Future<void> resetBleConnectionsOnly() =>
      _connectionManager.resetBleConnectionsOnly();

  // Fetch data with a specific command and data type
  Future<Map<String, dynamic>> fetchData(String command, String dataType) =>
      dataProcessor.fetchData(command, dataType);

  // Send command to BLE device
  void sendCommand(String command, String dataType) =>
      dataProcessor.sendCommand(command, dataType);

  // Reset BLE state
  void resetBleState() {
    components.reset();
    dataProcessor.resetState();
    _status.reset();
    _connectionManager.cancelDisconnectSubscription();
    isLoading.value = false;
    AppHelpers.debugLog('BLE state reset');
  }

  // Show disconnected dialog
  void showDisconnectedBottomSheet(BluetoothDevice device) {
    BLEUtils.showDisconnectedBottomSheet(
        device, () => disconnectDevice(device));
  }

  // Notify status updates to UI
  void notifyStatus(String message) {
    _statusController.add(message);
    SnackbarCustom.showSnackbar(
        '', message, AppColor.grey, AppColor.whiteColor);
  }

  // Start loading state
  void startLoading() {
    isLoading.value = true;
  }

  // Stop loading state
  void stopLoading() {
    isLoading.value = false;
  }

  // Clean up resources
  @override
  void onClose() {
    _statusController.close();
    super.onClose();
  }
}
