import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:suriota_mobile_gateway/constant/app_color.dart';
import 'package:suriota_mobile_gateway/constant/font_setup.dart';
import 'package:suriota_mobile_gateway/controller/device_data_controller.dart';
import 'package:suriota_mobile_gateway/controller/device_pagination_controller.dart';
import 'package:suriota_mobile_gateway/controller/modbus_pagination_controller.dart';
import 'package:suriota_mobile_gateway/global/utils/helper.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_alert_dialog.dart';
import 'package:suriota_mobile_gateway/screen/devices/detail_device_screen.dart';
import 'package:suriota_mobile_gateway/screen/home/home_screen.dart';

// Main BLE Controller
class BLEController extends GetxController {
  // State variables
  final devices = <BluetoothDevice>[].obs;
  final isLoading = false.obs;
  final deviceStoredData = ''.obs;
  final RxMap<String, bool> _connectionStatus = <String, bool>{}.obs;
  final RxMap<String, bool> _loadingStatus = <String, bool>{}.obs;
  final RxMap<String, bool> _isConnected = <String, bool>{}.obs;
  BluetoothService? _selectedService;
  BluetoothCharacteristic? _selectedCharacteristic;
  BluetoothCharacteristic? _writeChar;
  BluetoothCharacteristic? _notifyChar;
  StreamSubscription<BluetoothConnectionState>? _disconnectSub;

  // Stream for status updates
  final StreamController<String> _statusController =
      StreamController<String>.broadcast();
  Stream<String> get statusStream => _statusController.stream;

  // Modular components
  final BLEScanner scanner;
  final BLEConnectionManager connectionManager;
  final BLEDataProcessor dataProcessor;

  // Constructor
  BLEController()
      : scanner = BLEScanner(),
        connectionManager = BLEConnectionManager(),
        dataProcessor = BLEDataProcessor() {
    // Set controller reference for modular components
    scanner.controller = this;
    connectionManager.controller = this;
    dataProcessor.controller = this;
    AppHelpers.debugLog("BLEController initialized");
  }

  // Getters for public access
  bool get isDeviceListEmpty => devices.isEmpty;
  RxMap<String, bool> get connectionStatus => _connectionStatus;
  RxMap<String, bool> get loadingStatus => _loadingStatus;
  RxMap<String, bool> get isConnected => _isConnected;
  BluetoothService? get selectedService => _selectedService;
  BluetoothCharacteristic? get selectedCharacteristic =>
      _selectedCharacteristic;
  BluetoothCharacteristic? get writeChar => _writeChar;
  BluetoothCharacteristic? get notifyChar => _notifyChar;
  bool get isAnyDeviceLoading =>
      _loadingStatus.values.any((isLoading) => isLoading);

  // Get connection status for a specific device
  bool getConnectionStatus(String deviceId) =>
      _connectionStatus[deviceId] ?? false;

  // Get loading status for a specific device
  bool getLoadingStatus(String deviceId) => _loadingStatus[deviceId] ?? false;

  // Set loading status for a specific device
  void setLoadingStatus(String deviceId, bool isLoading) {
    _loadingStatus[deviceId] = isLoading;
    update();
  }

  // Public methods
  void scanDevice() => scanner.scanDevice();
  Future<void> connectToDevice(BluetoothDevice device) =>
      connectionManager.connectToDevice(device);
  Future<void> disconnectDevice(BluetoothDevice device) =>
      connectionManager.disconnectDevice(device);
  Future<void> disconnectDeviceWithRedirect(BluetoothDevice device) =>
      connectionManager.disconnectDeviceWithRedirect(device);
  Future<void> resetBleConnectionsOnly() =>
      connectionManager.resetBleConnectionsOnly();

  // Send command with null check
  void sendCommand(String command, String dataType) {
    if (dataProcessor == null) {
      _notifyStatus("Data processor not initialized.");
      AppHelpers.debugLog("Error: dataProcessor is null in sendCommand");
      return;
    }
    dataProcessor.sendCommand(command, dataType);
  }

  // Reset BLE state
  void resetBleState() {
    _writeChar = null;
    _notifyChar = null;
    _selectedService = null;
    _selectedCharacteristic = null;
    _disconnectSub?.cancel();
    _disconnectSub = null;
    dataProcessor.resetState();
    _connectionStatus.clear();
    _isConnected.clear();
    _loadingStatus.clear();
    isLoading.value = false;
  }

  // Show disconnected dialog
  void showDisconnectedBottomSheet(BluetoothDevice device) {
    BLEUtils.showDisconnectedBottomSheet(
        device, () => disconnectDevice(device));
  }

  // Internal utility methods
  void _startLoading() {
    isLoading.value = true;
  }

  void _stopLoading() {
    isLoading.value = false;
  }

  // Notify status updates
  void _notifyStatus(String status) {
    _statusController.add(status);
    Get.snackbar(
      '',
      status,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColor.grey,
      colorText: AppColor.whiteColor,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      titleText: const SizedBox(),
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
    );
  }

  // Clean up on controller close
  @override
  void onClose() {
    _statusController.close();
    super.onClose();
  }
}

// Scanner for BLE devices
class BLEScanner {
  // Reference to BLEController, non-final to allow setting after initialization
  BLEController? controller;

  BLEScanner();

  // Scan for BLE devices
  void scanDevice() async {
    if (controller!.isLoading.value) return;
    controller!._startLoading();
    controller!.devices.clear();
    await FlutterBluePlus.stopScan();

    final seenDeviceIds = <String>{};
    late final StreamSubscription<List<ScanResult>> subscription;

    subscription = FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        final id = r.device.remoteId.toString();
        if (!seenDeviceIds.contains(id)) {
          seenDeviceIds.add(id);
          controller!.devices.add(r.device);
          controller!._connectionStatus[id] = false;
        }
      }
    });

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    } catch (e) {
      controller!._notifyStatus("Scan failed: $e");
    } finally {
      await Future.delayed(const Duration(seconds: 5));
      await subscription.cancel();
      controller!._stopLoading();
    }
  }
}

// Connection manager for BLE devices
class BLEConnectionManager {
  // Reference to BLEController, non-final to allow setting after initialization
  BLEController? controller;

  BLEConnectionManager();

  // Connect to a BLE device
  Future<void> connectToDevice(BluetoothDevice device) async {
    final deviceId = device.remoteId.toString();
    final deviceName =
        device.platformName.isNotEmpty ? device.platformName : deviceId;
    controller!.setLoadingStatus(deviceId, true);

    try {
      await FlutterBluePlus.stopScan();
      // Request higher MTU at connection
      AppHelpers.debugLog("Requested MTU 512 for device: $deviceName");
      await device.connect(
          timeout: const Duration(seconds: 10), autoConnect: false);

      controller!._disconnectSub?.cancel();
      controller!._disconnectSub = device.connectionState.listen((state) async {
        if (state == BluetoothConnectionState.disconnected) {
          controller!._notifyStatus(
              "${device.platformName} disconnected unexpectedly");
          controller!.resetBleState();
          await resetBleConnectionsOnly();
          await Future.delayed(const Duration(seconds: 3));
          if (Get.currentRoute != '/') {
            await Get.offAll(() => const HomeScreen());
          }
        }
      });

      bool isServiceDiscovered = await _discoverServices(device);
      if (isServiceDiscovered) {
        BLEUtils.showConnectedBottomSheet(device);
      } else {
        await disconnectDevice(device);
      }

      controller!._connectionStatus[deviceId] = true;
      controller!._isConnected[deviceId] = true;
    } catch (e) {
      controller!._connectionStatus[deviceId] = false;
      controller!._isConnected[deviceId] = false;
      AppHelpers.debugLog("Failed to connect: $e");
      controller!._notifyStatus("Failed to connect the device: $deviceName");
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
      await device.disconnect().timeout(const Duration(seconds: 5),
          onTimeout: () {
        throw TimeoutException("Disconnect took too long");
      });

      controller!._connectionStatus[deviceId] = false;
      controller!._isConnected[deviceId] = false;
      controller!._notifyStatus("Disconnected from $deviceName.");
    } catch (e) {
      AppHelpers.debugLog("Failed to disconnect: $e");
      controller!._connectionStatus[deviceId] = false;
      controller!._isConnected[deviceId] = false;
      controller!
          ._notifyStatus("Failed to disconnect the device $deviceName: $e");
    } finally {
      await Future.microtask(
          () => controller!.setLoadingStatus(deviceId, false));
    }
  }

  // Disconnect with navigation
  Future<void> disconnectDeviceWithRedirect(BluetoothDevice device) async {
    final deviceId = device.remoteId.toString();
    final deviceName =
        device.platformName.isNotEmpty ? device.platformName : deviceId;
    controller!.setLoadingStatus(deviceId, true);

    try {
      await device.disconnect().timeout(const Duration(seconds: 10));
      controller!._connectionStatus[deviceId] = false;
      controller!._isConnected[deviceId] = false;
      controller!._writeChar = null;
      controller!._notifyChar = null;
      controller!._selectedService = null;

      controller!._notifyStatus("Disconnected from $deviceName.");

      if (Get.isRegistered<GetNavigator>()) {
        if (Get.isOverlaysOpen) {
          Get.back(closeOverlays: true);
        }
        if (Get.currentRoute != '/' && Get.previousRoute.isNotEmpty) {
          Get.back();
        }
      }
    } catch (e) {
      AppHelpers.debugLog("Failed to disconnect: $e");
      controller!._notifyStatus(e is TimeoutException
          ? "Disconnect timed out for $deviceName"
          : "Failed to disconnect the device: $deviceName");
    } finally {
      controller!.setLoadingStatus(deviceId, false);
    }
  }

  // Reset all BLE connections
  Future<void> resetBleConnectionsOnly() async {
    try {
      AppHelpers.debugLog("🔄 Resetting BLE connection state...");
      await FlutterBluePlus.stopScan();
      final connectedDevices = await FlutterBluePlus.connectedSystemDevices;
      for (final device in connectedDevices) {
        try {
          await device.disconnect();
          AppHelpers.debugLog("⛔ Disconnecting ${device.platformName}...");
        } catch (e) {
          AppHelpers.debugLog(
              "❌ Failed to disconnect ${device.platformName}: $e");
        }
      }
    } catch (e) {
      AppHelpers.debugLog("❌ Error resetting BLE: $e");
      controller!._notifyStatus("Failed to reset BLE.");
    }
  }

  // Discover services on a connected device
  Future<bool> _discoverServices(BluetoothDevice device) async {
    try {
      final services = await device.discoverServices().timeout(
            const Duration(seconds: 15),
            onTimeout: () =>
                throw TimeoutException("Service discovery timed out."),
          );

      if (services.isEmpty) {
        controller!
            ._notifyStatus("No services found on ${device.platformName}");
        return false;
      }

      for (final service in services) {
        for (final char in service.characteristics) {
          _assignCharacteristic(char);
          if (controller!._writeChar != null &&
              controller!._notifyChar != null) {
            controller!._selectedService = service;
            return true;
          }
        }
      }

      controller!._notifyStatus(
          "No valid characteristic with notify/write/read found.");
      return false;
    } catch (e) {
      controller!._notifyStatus(
          "Failed to discover service/characteristic on ${device.platformName}");
      AppHelpers.debugLog("Failed to discover service/characteristic: $e");
      return false;
    }
  }

  // Assign characteristics for write and notify
  void _assignCharacteristic(BluetoothCharacteristic char) async {
    final props = char.properties;
    if (props.write && controller!._writeChar == null) {
      controller!._writeChar = char;
      AppHelpers.debugLog("Assigned write characteristic: ${char.uuid}");
    }
    if (props.notify && controller!._notifyChar == null) {
      controller!._notifyChar = char;
      try {
        await controller!._notifyChar!.setNotifyValue(true);
        await Future.delayed(
            const Duration(milliseconds: 500)); // Ensure subscription is active
        controller!.dataProcessor._listenToNotifications();
        AppHelpers.debugLog(
            "Notification enabled for characteristic: ${char.uuid}");
      } catch (e) {
        AppHelpers.debugLog("Failed to enable notification: $e");
        controller!._notifyStatus("Gagal mengaktifkan notifikasi BLE");
      }
    }
  }
}

// Data processor for handling BLE packets and commands
class BLEDataProcessor {
  // Reference to BLEController, non-final to allow setting after initialization
  BLEController? controller;
  final Map<int, String> _packetBuffer = {};
  final _packetQueue = <String>[];
  bool _isProcessingQueue = false;
  int _expectedPackets = -1;
  String? _currentMessageId;
  String? _lastCommandDataType;
  String? _lastCommand; // Store last command for retry
  DateTime _lastPacketTime = DateTime.now();
  Timer? _packetTimeoutTimer;
  int _timeoutDuration = 30; // Base timeout
  final bool _verbose = true;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  static const int _secondsPerPacketBatch = 1;

  BLEDataProcessor();

  // Reset internal state for packet processing
  void resetState() {
    _packetBuffer.clear();
    _expectedPackets = -1;
    _currentMessageId = null;
    _packetTimeoutTimer?.cancel();
    _packetTimeoutTimer = null;
    _packetQueue.clear();
    _isProcessingQueue = false;
    _lastCommand = null;
    _retryCount = 0;
    _timeoutDuration = 30;
    AppHelpers.debugLog("BLEDataProcessor state reset");
  }

  // Listen to notifications from the notify characteristic
  void _listenToNotifications() {
    if (controller!._notifyChar == null) {
      AppHelpers.debugLog(
          "Error: _notifyChar is null in _listenToNotifications");
      controller!._notifyStatus("Karakteristik notifikasi tidak ditemukan");
      return;
    }

    controller!._notifyChar!.onValueReceived.listen((value) async {
      try {
        final data = utf8.decode(value);
        print("📬 Received packet: $data");
        AppHelpers.debugLog("Received packet: $data");
        if (data.isNotEmpty) {
          _packetQueue.add(data);
          await _processQueue();
        } else {
          AppHelpers.debugLog("Empty packet received");
        }
      } catch (e) {
        print("❌ Failed to decode packet: $e");
        AppHelpers.debugLog("Failed to decode packet: $e");
        controller!._notifyStatus("Gagal mendekode data paket");
      }
    }, onError: (e) {
      AppHelpers.debugLog("Notification stream error: $e");
      controller!._notifyStatus("Kesalahan menerima notifikasi BLE");
    });
  }

  // Process the packet queue
  Future<void> _processQueue() async {
    if (_isProcessingQueue || _packetQueue.isEmpty) return;
    _isProcessingQueue = true;

    while (_packetQueue.isNotEmpty) {
      // Check if timeout has occurred
      if (_packetTimeoutTimer != null && !_packetTimeoutTimer!.isActive) {
        print("⚠️ Queue processing stopped due to timeout");
        _isProcessingQueue = false;
        return;
      }

      final data = _packetQueue.removeAt(0);
      final regex = RegExp(r'P(\d+)/(\d+):(.*)');
      final altRegex = RegExp(r'P(\d+)/(\d+)\s*(.*)');
      final match = regex.firstMatch(data) ?? altRegex.firstMatch(data);

      if (_verbose) {
        print("📥 Processing packet: $data");
      }

      if (match != null) {
        _handlePacket(match);
      } else {
        controller!._notifyStatus("Format paket tidak valid: $data");
        AppHelpers.debugLog("Invalid packet format: $data");
      }
    }

    _isProcessingQueue = false;
  }

  // Handle individual packets
  void _handlePacket(RegExpMatch match) async {
    if (controller!._writeChar == null || controller!._notifyChar == null) {
      print("⚠️ No valid characteristics. Ignoring packet.");
      AppHelpers.debugLog("No valid characteristics in _handlePacket");
      controller!._notifyStatus("Perangkat tidak terhubung sepenuhnya");
      return;
    }

    final int index = int.parse(match.group(1)!);
    final int totalMinusOne = int.parse(match.group(2)!);
    final String content = match.group(3)!;
    final int actualTotal = totalMinusOne + 1;
    final DateTime timestamp = DateTime.now();

    print(
        "📅 [${timestamp.toIso8601String()}] Packet [$index/$actualTotal]: $content");
    AppHelpers.debugLog("Processing packet [$index/$actualTotal]: $content");

    bool isNewMessage = _shouldStartNewMessage(index, actualTotal, timestamp);

    if (isNewMessage) {
      if (_verbose) {
        print("🔄 Starting new message sequence. Total packets: $actualTotal");
      }
      _resetPacketBuffer();
      _currentMessageId = _generateMessageId(actualTotal);
      _expectedPackets = actualTotal; // Set expected packets early
      _startPacketTimeout();
    }

    if (_packetBuffer.containsKey(index)) {
      if (_packetBuffer[index] == content) {
        print("⚠️ Duplicate packet ignored: [$index/$actualTotal]");
        return;
      } else {
        print("⚠️ Conflicting packet at index $index. Starting new message.");
        _resetPacketBuffer();
        _currentMessageId = _generateMessageId(actualTotal);
        _expectedPackets = actualTotal;
        _startPacketTimeout();
      }
    }

    _lastPacketTime = timestamp;
    _packetBuffer[index] = content;
    _expectedPackets = actualTotal; // Ensure expected packets is updated

    if (_verbose) {
      final sortedKeys = (_packetBuffer.keys.toList()..sort());
      final missingIndices = _getMissingIndices();
      print(
          "🧩 Current buffer: $sortedKeys / $_expectedPackets (Missing: $missingIndices)");
      AppHelpers.debugLog(
          "Buffer: $sortedKeys / $_expectedPackets, Missing: $missingIndices");
    }

    if (_packetBuffer.length % 10 == 0) {
      double completionPercentage =
          (_packetBuffer.length / _expectedPackets) * 100;
      print(
          "📊 Received ${_packetBuffer.length}/$_expectedPackets packets (${completionPercentage.toStringAsFixed(1)}%)");
    }

    if (_isAllPacketsReceived()) {
      _packetTimeoutTimer?.cancel();
      _packetTimeoutTimer = null;

      final message = _assembleMessage();
      print("✅ Full message received (${_packetBuffer.length} packets)");
      if (_verbose) {
        print("📃 Message content: $message");
      }
      AppHelpers.debugLog("Full message: $message");

      await _processCompleteMessage(message);
    }
  }

  // Start packet timeout timer
  void _startPacketTimeout() {
    _packetTimeoutTimer?.cancel();
    // Dynamic timeout: 30s base + 1s per 5 packets
    _timeoutDuration = 30 + (_expectedPackets ~/ 5) * _secondsPerPacketBatch;
    _packetTimeoutTimer = Timer(Duration(seconds: _timeoutDuration), () {
      if (_packetBuffer.isNotEmpty && !_isAllPacketsReceived()) {
        print(
            "⚠️ Timeout: Processing partial data after $_timeoutDuration seconds.");
        AppHelpers.debugLog(
            "Timeout, received ${_packetBuffer.length}/$_expectedPackets packets");
        _processPartialMessage();
      }
    });
    AppHelpers.debugLog(
        "Started timeout timer for $_timeoutDuration seconds, expected: $_expectedPackets packets");
  }

  // Process complete message
  Future<void> _processCompleteMessage(String message) async {
    final tempBuffer = Map<int, String>.from(_packetBuffer);
    _processMessage(message);
    _resetPacketBuffer();
    print("📜 Processed message: $message, Previous buffer: $tempBuffer");
  }

  // Check if all packets are received
  bool _isAllPacketsReceived() {
    if (_expectedPackets <= 0) return false;
    final List<int> expectedIndices =
        List<int>.generate(_expectedPackets, (i) => i);
    return expectedIndices.every((index) => _packetBuffer.containsKey(index));
  }

  // Determine if a new message should start
  bool _shouldStartNewMessage(int index, int total, DateTime timestamp) {
    if (_packetBuffer.isEmpty) return true;
    if (_expectedPackets != total) return true;
    if (_packetBuffer.containsKey(index)) return true;
    if (index == 0 && _packetBuffer.isNotEmpty) return true;
    if (timestamp.difference(_lastPacketTime).inSeconds > _timeoutDuration) {
      return true;
    }
    return false;
  }

  // Generate a unique message ID
  String _generateMessageId(int totalPackets) {
    return "${DateTime.now().millisecondsSinceEpoch}_$totalPackets";
  }

  // Process partial message
  void _processPartialMessage() {
    if (_packetBuffer.isEmpty) {
      print("⚠️ No packets to process");
      controller!._notifyStatus("Tidak ada data diterima, coba lagi");
      return;
    }

    final missingIndices = _getMissingIndices();
    print(
        "🧩 Current buffer: ${(_packetBuffer.keys.toList()..sort())} / $_expectedPackets (Missing: $missingIndices)");
    AppHelpers.debugLog("Missing packets: $missingIndices");

    if (_retryCount < _maxRetries && _lastCommand != null) {
      _retryCount++;
      print("🔄 Retrying command ($_retryCount/$_maxRetries): $_lastCommand");
      AppHelpers.debugLog(
          "Retrying command: $_lastCommand, attempt $_retryCount");
      _resetPacketBuffer();
      controller!._notifyStatus(
          "Data tidak lengkap, mencoba ulang ($_retryCount/$_maxRetries)...");
      sendCommand(_lastCommand!, _lastCommandDataType ?? 'device');
      return;
    }

    final message = _assembleMessage();
    print(
        "⚠️ Processing partial message (${_packetBuffer.length}/$_expectedPackets)");

    if (message.isEmpty || message.length < 50) {
      print("❌ Partial message too short or empty");
      controller!._notifyStatus("Data tidak lengkap, gagal memuat");
      _resetPacketBuffer();
      return;
    }

    try {
      if (_isSuccessMessage(message)) {
        _handleSuccessMessage(message);
      } else {
        _processMessage(message);
      }
    } catch (e) {
      print("❌ Failed to process partial message: $e");
      controller!._notifyStatus("Gagal memproses data, coba lagi");
      AppHelpers.debugLog("Failed to process partial message: $e");
    } finally {
      _resetPacketBuffer();
    }
  }

  // Get missing packet indices
  List<int> _getMissingIndices() {
    if (_expectedPackets <= 0) return [];
    final allIndices = List<int>.generate(_expectedPackets, (i) => i);
    return allIndices.where((i) => !_packetBuffer.containsKey(i)).toList();
  }

  // Assemble message from buffer
  String _assembleMessage() {
    final sortedKeys = (_packetBuffer.keys.toList()..sort());
    final stringBuilder = StringBuffer();
    print(
        "🧩 Current buffer: $sortedKeys / $_expectedPackets (Missing: ${_getMissingIndices()})");
    for (int key in sortedKeys) {
      stringBuilder.write(_packetBuffer[key]);
    }
    return stringBuilder.toString();
  }

  // Reset packet buffer
  void _resetPacketBuffer() {
    _packetBuffer.clear();
    _expectedPackets = -1;
    _currentMessageId = null;
    _packetTimeoutTimer?.cancel();
    _packetTimeoutTimer = null;
  }

  // Check if message is a success message
  bool _isSuccessMessage(String message) {
    final successPattern = RegExp(r'success', caseSensitive: false);
    return successPattern.hasMatch(message);
  }

  // Handle success message
  Future<void> _handleSuccessMessage(String message) async {
    BLEUtils.showSnackbar("Success", message, Colors.green[500], Colors.white);
  }

  // Process received message
  void _processMessage(String message) {
    try {
      if (_isSuccessMessage(message)) {
        _handleSuccessMessage(message);
        return;
      }

      String dataType = _lastCommandDataType ?? 'device';
      final json = jsonDecode(message);

      if (json is List && json.isNotEmpty) {
        _handleSingleDeviceData(json.first);
      } else if (json is Map<String, dynamic> && json.containsKey("data")) {
        _updatePaginationData(json, dataType);
      } else {
        controller!._notifyStatus("ESP32 response missing 'data' field.");
      }
    } catch (e) {
      print("❌ Failed to parse JSON: $e");
      if (_isSuccessMessage(message)) {
        _handleSuccessMessage(message);
      } else {
        controller!._notifyStatus("Invalid response format from ESP32");
      }
    }
  }

  // Update pagination data
  void _updatePaginationData(Map<String, dynamic> json, String dataType) {
    if (dataType == 'devices') {
      final paginationController = Get.find<DevicePaginationController>();
      paginationController.setPaginationData(json);
    } else if (dataType == 'modbus') {
      final modbusPagination = Get.find<ModbusPaginationController>();
      modbusPagination.setPaginationData(json);
    }
  }

  // Handle single device data
  void _handleSingleDeviceData(dynamic device) {
    print("📌 Read by ID result: $device");
    final deviceData = Get.put(DeviceDataController());
    deviceData.setSingleDevice(device);
    controller!._notifyStatus("Success load data.");
  }

  // Send command to the device
  void sendCommand(String commandString, String dataType) async {
    controller!._startLoading();
    if (controller!._writeChar == null) {
      controller!._notifyStatus("Characteristic Write tidak ditemukan.");
      controller!._stopLoading();
      return;
    }

    try {
      if (!commandString.endsWith('#')) {
        commandString += '#';
      }
      _lastCommandDataType = dataType;
      _lastCommand = commandString; // Store command for retry
      _retryCount = 0; // Reset retry count
      final bytes = utf8.encode(commandString);
      final mtu = await controller!._writeChar!.device.mtu.first ?? 512;

      // Request higher MTU if possible
      try {
        await controller!._writeChar!.device.requestMtu(512);
        AppHelpers.debugLog("Requested MTU: 512, actual MTU: $mtu");
      } catch (e) {
        AppHelpers.debugLog("Failed to request MTU: $e");
      }

      for (int offset = 0; offset < bytes.length; offset += mtu) {
        final chunk = bytes.sublist(
          offset,
          offset + mtu > bytes.length ? bytes.length : offset + mtu,
        );
        await controller!._writeChar!
            .write(chunk, withoutResponse: false)
            .timeout(const Duration(seconds: 10));
        await Future.delayed(const Duration(milliseconds: 100));
      }
      print("Command sent: $commandString");
      AppHelpers.debugLog("Sent command: $commandString, MTU: $mtu");
    } catch (e) {
      AppHelpers.debugLog("Failed to send a command: $e");
      controller!._notifyStatus("Device disconnected...");
    } finally {
      controller!._stopLoading();
    }
  }
}

// Utility class for UI-related functions
class BLEUtils {
  // Show a snackbar with the given title, message, and colors
  static void showSnackbar(
      String title, String message, Color? bgColor, Color? textColor) {
    final snackbar = GetSnackBar(
      title: title.isEmpty ? null : title,
      message: message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: bgColor ?? AppColor.redColor,
      messageText: Text(
        message,
        style:
            FontFamily.normal.copyWith(color: textColor ?? AppColor.whiteColor),
      ),
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      padding: title.isEmpty
          ? const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 12.0)
          : const EdgeInsets.all(12.0),
      titleText: title.isEmpty ? const SizedBox() : null,
      borderRadius: 8,
    );
    Get.showSnackbar(snackbar);
  }

  // Show a dialog when a device is connected
  static void showConnectedBottomSheet(BluetoothDevice device) {
    CustomAlertDialog.show(
      title: "Device Connected",
      message:
          "Do you want to open device (${device.platformName.isNotEmpty ? device.platformName : device.remoteId.toString()}) page detail?",
      primaryButtonText: 'Yes',
      secondaryButtonText: 'No',
      onPrimaryPressed: () => Get.to(() => DetailDeviceScreen(device: device)),
      barrierDismissible: false,
    );
  }

  // Show a dialog to confirm device disconnection
  static void showDisconnectedBottomSheet(
      BluetoothDevice device, VoidCallback? onDisconnect) {
    final deviceName = device.platformName.isNotEmpty
        ? device.platformName
        : device.remoteId.toString();
    CustomAlertDialog.show(
      title: "Disconnect Device?",
      message: "Do you want to disconnect the device ($deviceName)?",
      primaryButtonText: 'Yes',
      secondaryButtonText: 'No',
      onPrimaryPressed: onDisconnect,
      barrierDismissible: false,
    );
  }
}
