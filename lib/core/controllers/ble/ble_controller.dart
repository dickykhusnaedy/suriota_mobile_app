import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:suriota_mobile_gateway/constant/app_color.dart';
import 'package:suriota_mobile_gateway/core/controllers/devices/device_pagination_controller.dart';
import 'package:suriota_mobile_gateway/core/controllers/modbus/modbus_pagination_controller.dart';
import 'package:suriota_mobile_gateway/core/utils/snackbar/snackbar_custom.dart';
import 'package:suriota_mobile_gateway/global/utils/helper.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_alert_dialog.dart';
import 'package:suriota_mobile_gateway/screen/devices/detail_device_screen.dart';
import 'package:suriota_mobile_gateway/screen/home/home_screen.dart';

// Manages BLE operations and state
class BLEController extends GetxController {
  // Observables for device list and loading state
  final RxList<BluetoothDevice> devices = <BluetoothDevice>[].obs;
  final RxBool isLoading = false.obs;
  final RxString storedDeviceData = ''.obs;

  // Device status and BLE components
  final DeviceStatus _status = DeviceStatus();
  final BLEComponents _components = BLEComponents();

  // Modular components
  final BLEScanner _scanner;
  final BLEConnectionManager _connectionManager;
  final BLEDataProcessor _dataProcessor;

  // Stream for status updates
  final StreamController<String> _statusController =
      StreamController<String>.broadcast();
  Stream<String> get statusStream => _statusController.stream;

  // Constructor with dependency injection for testing
  BLEController({
    BLEScanner? scanner,
    BLEConnectionManager? connectionManager,
    BLEDataProcessor? dataProcessor,
  })  : _scanner = scanner ?? BLEScanner(),
        _connectionManager = connectionManager ?? BLEConnectionManager(),
        _dataProcessor = dataProcessor ?? BLEDataProcessor() {
    _scanner._controller = this;
    _connectionManager._controller = this;
    _dataProcessor._controller = this;
    AppHelpers.debugLog('BLEController initialized');
  }

  // Getters for public access
  bool get isDeviceListEmpty => devices.isEmpty;
  RxMap<String, bool> get connectionStatus => _status.connectionStatus;
  RxMap<String, bool> get loadingStatus => _status.loadingStatus;
  RxMap<String, bool> get isConnected => _status.isConnected;
  BluetoothService? get selectedService => _components.selectedService;
  BluetoothCharacteristic? get selectedCharacteristic =>
      _components.selectedCharacteristic;
  BluetoothCharacteristic? get writeCharacteristic =>
      _components.writeCharacteristic;
  BluetoothCharacteristic? get notifyCharacteristic =>
      _components.notifyCharacteristic;
  bool get isAnyDeviceLoading =>
      _status.loadingStatus.values.any((isLoading) => isLoading);
  RxInt get receivedPackets => _dataProcessor.receivedPackets;
  RxInt get expectedPackets => _dataProcessor.expectedPackets;

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
      _dataProcessor.fetchData(command, dataType);

  // Send command to BLE device
  void sendCommand(String command, String dataType) =>
      _dataProcessor.sendCommand(command, dataType);

  // Reset BLE state
  void resetBleState() {
    _components.reset();
    _dataProcessor.resetState();
    _status.reset();
    _connectionManager._cancelDisconnectSubscription();
    isLoading.value = false;
    AppHelpers.debugLog('BLE state reset');
  }

  // Show disconnected dialog
  void showDisconnectedBottomSheet(BluetoothDevice device) {
    BLEUtils.showDisconnectedBottomSheet(
        device, () => disconnectDevice(device));
  }

  // Notify status updates to UI
  void _notifyStatus(String message) {
    _statusController.add(message);
    SnackbarCustom.showSnackbar(
        '', message, AppColor.grey, AppColor.whiteColor);
  }

  // Start loading state
  void _startLoading() {
    isLoading.value = true;
  }

  // Stop loading state
  void _stopLoading() {
    isLoading.value = false;
  }

  // Clean up resources
  @override
  void onClose() {
    _statusController.close();
    super.onClose();
  }
}

// Manages device status states
class DeviceStatus {
  final RxMap<String, bool> connectionStatus = <String, bool>{}.obs;
  final RxMap<String, bool> loadingStatus = <String, bool>{}.obs;
  final RxMap<String, bool> isConnected = <String, bool>{}.obs;

  // Reset all status maps
  void reset() {
    connectionStatus.clear();
    loadingStatus.clear();
    isConnected.clear();
    AppHelpers.debugLog('Device status reset');
  }
}

// Manages BLE component references
class BLEComponents {
  BluetoothService? _selectedService;
  BluetoothCharacteristic? _selectedCharacteristic;
  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _notifyCharacteristic;

  BluetoothService? get selectedService => _selectedService;
  BluetoothCharacteristic? get selectedCharacteristic =>
      _selectedCharacteristic;
  BluetoothCharacteristic? get writeCharacteristic => _writeCharacteristic;
  BluetoothCharacteristic? get notifyCharacteristic => _notifyCharacteristic;

  // Reset all component references
  void reset() {
    _selectedService = null;
    _selectedCharacteristic = null;
    _writeCharacteristic = null;
    _notifyCharacteristic = null;
    AppHelpers.debugLog('BLE components reset');
  }

  // Setters for characteristics
  void setWriteCharacteristic(BluetoothCharacteristic char) =>
      _writeCharacteristic = char;
  void setNotifyCharacteristic(BluetoothCharacteristic char) =>
      _notifyCharacteristic = char;
  void setSelectedService(BluetoothService service) =>
      _selectedService = service;
}

// Scans for BLE devices
class BLEScanner {
  BLEController? _controller;

  // Scan for BLE devices
  Future<void> scanDevice() async {
    if (_controller!.isLoading.value) return;
    _controller!._startLoading();
    _controller!.devices.clear();
    await FlutterBluePlus.stopScan();

    final seenDeviceIds = <String>{};
    final subscription = FlutterBluePlus.scanResults.listen((results) {
      for (final result in results) {
        final deviceId = result.device.remoteId.toString();
        if (!seenDeviceIds.contains(deviceId)) {
          seenDeviceIds.add(deviceId);
          _controller!.devices.add(result.device);
          _controller!.setLoadingStatus(deviceId, false);
          _controller!.connectionStatus[deviceId] = false;
          AppHelpers.debugLog('Found device: $deviceId');
        }
      }
    });

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
      await Future.delayed(const Duration(seconds: 5));
    } catch (e) {
      _controller!._notifyStatus('Scan failed: $e');
      AppHelpers.debugLog('Scan error: $e');
    } finally {
      await subscription.cancel();
      _controller!._stopLoading();
    }
  }
}

// Manages BLE device connections
class BLEConnectionManager {
  BLEController? _controller;
  StreamSubscription<BluetoothConnectionState>? _disconnectSubscription;

  // Connect to a BLE device
  Future<void> connectToDevice(BluetoothDevice device) async {
    final deviceId = device.remoteId.toString();
    final deviceName =
        device.platformName.isNotEmpty ? device.platformName : deviceId;
    _controller!.setLoadingStatus(deviceId, true);

    try {
      await FlutterBluePlus.stopScan();
      await device.connect(
          timeout: const Duration(seconds: 10), autoConnect: false);
      AppHelpers.debugLog('Requested MTU 512 for device: $deviceName');

      _cancelDisconnectSubscription();
      _disconnectSubscription = device.connectionState.listen((state) async {
        if (state == BluetoothConnectionState.disconnected) {
          _controller!.resetBleState();
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

      _controller!.connectionStatus[deviceId] = true;
      _controller!.isConnected[deviceId] = true;
    } catch (e) {
      _controller!.connectionStatus[deviceId] = false;
      _controller!.isConnected[deviceId] = false;
      _controller!._notifyStatus('Failed to connect to $deviceName');
      AppHelpers.debugLog('Connection error: $e');
    } finally {
      _controller!.setLoadingStatus(deviceId, false);
    }
  }

  // Disconnect from a BLE device
  Future<void> disconnectDevice(BluetoothDevice device) async {
    final deviceId = device.remoteId.toString();
    final deviceName =
        device.platformName.isNotEmpty ? device.platformName : deviceId;
    _controller!.setLoadingStatus(deviceId, true);

    try {
      if (!_controller!.isConnected[deviceId]!) {
        _controller!.connectionStatus[deviceId] = false;
        _controller!.isConnected[deviceId] = false;
        _controller!._notifyStatus('Disconnected from $deviceName');
        return;
      }

      await device.disconnect().timeout(const Duration(seconds: 10));
      _controller!.connectionStatus[deviceId] = false;
      _controller!.isConnected[deviceId] = false;
      _controller!._notifyStatus('Disconnected from $deviceName');
    } catch (e) {
      _controller!.connectionStatus[deviceId] = false;
      _controller!.isConnected[deviceId] = false;
      _controller!._notifyStatus('Failed to disconnect $deviceName: $e');
      AppHelpers.debugLog('Disconnect error: $e');
    } finally {
      _controller!.setLoadingStatus(deviceId, false);
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
      _controller!._notifyStatus('Failed to reset BLE connections');
      AppHelpers.debugLog('Reset BLE error: $e');
    }
  }

  // Discover services on a connected device
  Future<bool> _discoverServices(BluetoothDevice device) async {
    try {
      final services =
          await device.discoverServices().timeout(const Duration(seconds: 30));
      if (services.isEmpty) {
        _controller!
            ._notifyStatus('No services found on ${device.platformName}');
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
          if (_controller!.writeCharacteristic != null &&
              _controller!.notifyCharacteristic != null) {
            _controller!._components.setSelectedService(service);
            return true;
          }
        }
      }

      _controller!._notifyStatus('No valid characteristics found');
      return false;
    } catch (e) {
      _controller!._notifyStatus(
          'Failed to discover services on ${device.platformName}');
      AppHelpers.debugLog('Service discovery error: $e');
      return false;
    }
  }

  // Assign characteristics for write and notify operations
  void _assignCharacteristic(BluetoothCharacteristic char) async {
    final props = char.properties;
    if (props.write && _controller!.writeCharacteristic == null) {
      _controller!._components.setWriteCharacteristic(char);
      AppHelpers.debugLog('Assigned write characteristic: ${char.uuid}');
    }
    if (props.notify && _controller!.notifyCharacteristic == null) {
      _controller!._components.setNotifyCharacteristic(char);
      try {
        await _controller!.notifyCharacteristic!.setNotifyValue(true);
        await Future.delayed(const Duration(milliseconds: 2000));
        _controller!._dataProcessor._listenToNotifications();

        AppHelpers.debugLog(
            'Notification enabled for characteristic: ${char.uuid}');
      } catch (e) {
        _controller!._notifyStatus('Failed to enable notifications');
        AppHelpers.debugLog('Notification enable error: $e');
      }
    }
  }

  // Cancel disconnect subscription
  void _cancelDisconnectSubscription() {
    _disconnectSubscription?.cancel();
    _disconnectSubscription = null;
  }
}

// Processes BLE data packets and commands
class BLEDataProcessor {
  BLEController? _controller;
  final RxInt receivedPackets = 0.obs;
  final RxInt expectedPackets = 1.obs;
  Completer<Map<String, dynamic>>? _completer;
  final Map<int, String> _packetBuffer = {};
  final List<String> _packetQueue = [];
  bool _isProcessingQueue = false;
  String? _lastCommand;
  String? _lastCommandDataType;
  int _retryCount = 0;
  Timer? _packetTimeoutTimer;
  DateTime _lastPacketTime = DateTime.now();
  final Set<String> _processedMessageIds = {};

  static const int _maxRetries = 3;
  static const int _packetDelayMs = 50;

  // Set completer for data fetching
  void setCompleter(Completer<Map<String, dynamic>> completer) {
    _completer = completer;
  }

  // Reset processor state
  void resetState() {
    _packetBuffer.clear();
    _packetQueue.clear();
    _processedMessageIds.clear();
    _lastCommand = null;
    _lastCommandDataType = null;
    _retryCount = 0;
    expectedPackets.value = 1;
    receivedPackets.value = 0;
    _packetTimeoutTimer?.cancel();
    AppHelpers.debugLog('BLEDataProcessor state reset');
  }

  // Fetch data with command and data type
  Future<Map<String, dynamic>> fetchData(
      String command, String dataType) async {
    if (_completer != null && !_completer!.isCompleted) {
      AppHelpers.debugLog(
          'Previous fetchData in progress, waiting for completion');
      return _completer!.future;
    }

    _completer = Completer<Map<String, dynamic>>();
    setCompleter(_completer!);
    await sendCommand(command, dataType);
    try {
      final result = await _completer!.future.timeout(
        Duration(seconds: (expectedPackets.value * 5) + 30),
        onTimeout: () {
          _controller!._notifyStatus('Timeout waiting for data');
          AppHelpers.debugLog(
              'Fetch data timeout after ${(expectedPackets.value * 5) + 30} seconds');
          return {
            'success': false,
            'error': 'Timeout',
            'message': 'Data fetch timed out',
            'data': [],
          };
        },
      );
      AppHelpers.debugLog('FetchData result: $result');
      return result;
    } finally {
      _completer = null; // Pembersihan dilakukan di sini setelah hasil diproses
      _packetTimeoutTimer?.cancel();
    }
  }

  // Send command to BLE device
  Future<void> sendCommand(String command, String dataType) async {
    _controller!._startLoading();

    try {
      await _validateCharacteristics();
      await _ensureNotificationsEnabled();
      await _sendCommandData(command, dataType);
    } catch (e) {
      _handleSendError(e);
    }
  }

  Future<void> _validateCharacteristics() async {
    if (_controller!.writeCharacteristic == null ||
        _controller!.notifyCharacteristic == null) {
      throw Exception('Write/Notify characteristics not found');
    }
  }

  Future<void> _ensureNotificationsEnabled() async {
    if (!await _controller!.notifyCharacteristic!.isNotifying) {
      await _controller!.notifyCharacteristic!.setNotifyValue(true);
      await Future.delayed(const Duration(milliseconds: 3000));
      AppHelpers.debugLog('Re-enabled notifications');
    }
  }

  Future<void> _sendCommandData(String command, String dataType) async {
    final commandWithTerminator = '$command#';
    _resetState(commandWithTerminator, dataType);

    final bytes = utf8.encode(commandWithTerminator);
    final mtu = await _controller!.writeCharacteristic!.device.mtu.first;

    await _sendInChunks(bytes, mtu);
    AppHelpers.debugLog('Sent command: $commandWithTerminator, MTU: $mtu');
  }

  void _resetState(String command, String dataType) {
    _lastCommand = command;
    _lastCommandDataType = dataType;
    _retryCount = 0;
    _packetBuffer.clear();
    _packetQueue.clear();
    _processedMessageIds.clear();
    receivedPackets.value = 0;
    expectedPackets.value = 1;
  }

  Future<void> _sendInChunks(List<int> bytes, int mtu) async {
    for (var offset = 0; offset < bytes.length; offset += mtu) {
      final chunk =
          bytes.sublist(offset, (offset + mtu).clamp(0, bytes.length));
      await _controller!.writeCharacteristic!
          .write(chunk, withoutResponse: false);
      await Future.delayed(Duration(milliseconds: mtu < 50 ? 5000 : 3000));
    }
  }

  void _handleSendError(dynamic error) {
    _controller!._notifyStatus('Failed to send command: $error');
    AppHelpers.debugLog('Command send error: $error');
  }

  // Listen to BLE notifications
  void _listenToNotifications() {
    if (_controller!.notifyCharacteristic == null) {
      _controller!._notifyStatus('Notify characteristic not found');
      AppHelpers.debugLog('Notify characteristic is null');
      return;
    }

    _packetQueue.clear();
    _controller!.notifyCharacteristic!.onValueReceived.listen((value) async {
      try {
        final data = utf8.decode(value).trim();
        AppHelpers.debugLog('Received raw data: $data');
        if (data.isNotEmpty) {
          _packetQueue.add(data);
          await Future.delayed(const Duration(milliseconds: _packetDelayMs));
          await _processQueue();
        } else {
          AppHelpers.debugLog('Empty packet received, ignoring');
        }
      } catch (e) {
        _controller!._notifyStatus('Failed to decode packet: $e');
        AppHelpers.debugLog('Packet decode error: $e');
      }
    }, onError: (e) {
      _controller!._notifyStatus('Notification stream error: $e');
      AppHelpers.debugLog('Notification stream error: $e');
    });
  }

  // Process queued packets
  Future<void> _processQueue() async {
    if (_isProcessingQueue || _packetQueue.isEmpty) {
      AppHelpers.debugLog(
          'Queue processing skipped: in progress=$_isProcessingQueue, queue size=${_packetQueue.length}');
      return;
    }
    _isProcessingQueue = true;

    try {
      while (_packetQueue.isNotEmpty) {
        final data = _packetQueue.removeAt(0);
        AppHelpers.debugLog(
            'Processing packet: $data, queue remaining: ${_packetQueue.length}');
        await _processRawPacket(data);
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } finally {
      _isProcessingQueue = false;
      AppHelpers.debugLog('Finished processing queue');
    }
  }

  // Process a raw packet
  Future<void> _processRawPacket(String data) async {
    final match = _parsePacket(data);
    if (match != null) {
      await _storePacket(match);
    } else {
      await _handleDirectResponse(data);
    }
  }

  // Parse packet using regex
  RegExpMatch? _parsePacket(String data) {
    const patterns = [
      r'^P(\d+)/(\d+):(.*)$',
      r'^P(\d+)/(\d+)\s+(.*)$',
      r'^P(\d+)/(\d+)(.*)$',
    ];
    for (final pattern in patterns) {
      final regex = RegExp(pattern);
      final match = regex.firstMatch(data);

      if (match != null) {
        AppHelpers.debugLog(
            'Parsed packet: index=${match.group(1)}, total=${match.group(2)}, content=${match.group(3)}');
        return match;
      }
    }
    AppHelpers.debugLog('Failed to parse packet: $data');
    return null;
  }

  // Store a valid packet
  Future<void> _storePacket(RegExpMatch match) async {
    final index = int.parse(match.group(1)!);
    final totalMinusOne = int.parse(match.group(2)!);
    final content = match.group(3)!;
    final total = totalMinusOne + 1;

    AppHelpers.debugLog(
        'Storing packet: index=$index, total=$total, content length=${content.length}');

    if (_shouldStartNewMessage(index, total)) {
      _initializeNewMessage(total);
    }

    if (_packetBuffer.containsKey(index)) {
      AppHelpers.debugLog('Duplicate packet ignored: index=$index/$total');
      return;
    }

    _packetBuffer[index] = content;
    _lastPacketTime = DateTime.now();
    expectedPackets.value = total;
    receivedPackets.value = _packetBuffer.length;
    AppHelpers.debugLog(
        'Buffer status: ${_packetBuffer.length}/$total packets received');

    if (_isAllPacketsReceived()) {
      AppHelpers.debugLog('All packets received, completing message');
      final message = _assembleMessage();

      try {
        final parsedJson = jsonDecode(message);
        if (parsedJson is Map || parsedJson is List) {
          await _completeMessage(json: parsedJson);
        } else {
          await _completeMessage(data: message);
        }
      } catch (e) {
        await _completeMessage(data: message);
      }

      _controller!._stopLoading();
    }
  }

  // Handle direct response (non-packet format)
  Future<void> _handleDirectResponse(String data) async {
    AppHelpers.debugLog('Handling direct response: $data');
    if (data.toLowerCase().contains('success') ||
        data == 'No records available') {
      await _completeMessage(data: data);
      return;
    }

    try {
      final json = jsonDecode(data);
      AppHelpers.debugLog('Parsed JSON response: ${json.runtimeType}');
      await _completeMessage(json: json);
    } catch (e) {
      _controller!._notifyStatus('Invalid response format: $e');
      AppHelpers.debugLog('Invalid response: $data, error: $e');
      await _completeMessage(data: data);
    }
  }

  // Initialize a new message sequence
  void _initializeNewMessage(int totalPackets) {
    AppHelpers.debugLog(
        'Initializing new message: expected packets=$totalPackets');
    _packetBuffer.clear();
    expectedPackets.value = totalPackets;
    receivedPackets.value = 0;
    _processedMessageIds.add(_generateMessageId(totalPackets));
    _startPacketTimeout();
  }

  // Check if a new message sequence should start
  bool _shouldStartNewMessage(int index, int total) {
    if (_packetBuffer.isEmpty || expectedPackets.value != total || index == 0) {
      AppHelpers.debugLog(
          'Starting new message: index=$index, total=$total, buffer=${_packetBuffer.length}');
      return true;
    }
    final gap = DateTime.now().difference(_lastPacketTime).inSeconds;
    if (gap > 22) {
      AppHelpers.debugLog('Starting new message due to time gap: $gap seconds');
      return true;
    }
    return false;
  }

  // Start packet timeout timer
  void _startPacketTimeout() {
    _packetTimeoutTimer?.cancel();
    final timeoutDuration =
        (expectedPackets.value * 5) + 60; // Increased timeout
    AppHelpers.debugLog(
        'Starting timeout: $timeoutDuration seconds for ${expectedPackets.value} packets');
    _packetTimeoutTimer = Timer(Duration(seconds: timeoutDuration), () {
      AppHelpers.debugLog(
          'Timeout triggered: received=${_packetBuffer.length}/${expectedPackets.value} packets');
      if (_packetBuffer.isNotEmpty &&
          _retryCount < _maxRetries &&
          _lastCommand != null) {
        _retryCommand();
      } else if (_packetBuffer.isNotEmpty) {
        AppHelpers.debugLog(
            'Processing partial data: ${_packetBuffer.length} packets');
        _completeMessage();
      } else {
        _handleTimeoutFailure();
      }
    });
  }

  // Retry a failed command
  void _retryCommand() {
    _retryCount++;
    _packetBuffer.clear();
    receivedPackets.value = 0;
    _controller!._notifyStatus('Retrying command ($_retryCount/$_maxRetries)');
    AppHelpers.debugLog(
        'Retrying command: attempt $_retryCount, command: $_lastCommand');
    sendCommand(_lastCommand!, _lastCommandDataType ?? 'device');
  }

  // Handle timeout failure
  void _handleTimeoutFailure() {
    _controller!
        ._notifyStatus('Failed to receive data after $_maxRetries retries');
    AppHelpers.debugLog('Timeout failure after $_maxRetries retries');
    _completer?.complete({
      'success': false,
      'error': 'Timeout: Incomplete data received',
      'data': [],
      'message': 'Failed to receive complete data',
    });
    _completer = null;
    resetState();
  }

  // Check if all packets are received
  bool _isAllPacketsReceived() {
    if (expectedPackets.value <= 0) return false;
    final received = List.generate(expectedPackets.value, (i) => i)
        .every((i) => _packetBuffer.containsKey(i));
    AppHelpers.debugLog(
        'Checking packets: received=$received, expected=${expectedPackets.value}, buffer=${_packetBuffer.length}');
    return received;
  }

  // Complete message processing
  Future<void> _completeMessage({String? data, dynamic json}) async {
    AppHelpers.debugLog('Completing message: data=$data, json=$json');

    if (data != null) {
      if (data.toLowerCase().contains('successfully')) {
        AppHelpers.debugLog('Success response: $data');
        _completer?.complete({'data': [], 'message': data});
        _controller!._notifyStatus('$data\nPlease click button fetch data');
      } else if (data == 'No records available') {
        AppHelpers.debugLog('No records response: $data');
        _completer?.complete({'data': [], 'message': data});
        _controller!._notifyStatus(data);
        _updatePaginationData({}, _lastCommandDataType ?? 'device');
      } else {
        AppHelpers.debugLog('Empty or invalid response: $data');
        _completer?.complete(
            {'data': [], 'message': 'Empty or invalid message', 'raw': data});
        _controller!._notifyStatus('Received empty or invalid response');
      }

      _completer = null;
      _packetTimeoutTimer?.cancel();
      resetState();
      return;
    }

    if (json is List<dynamic>) {
      AppHelpers.debugLog('Processing list response: ${json.length} items');
      final response = {
        'data': json
            .map((item) =>
                item is Map<String, dynamic> ? item : {'name': item.toString()})
            .toList(),
        'page': 1,
        'pageSize': 5,
        'totalRecords': json.length,
        'totalPages': 1,
        'message': 'Array response converted',
      };
      _completer?.complete(response);

      _packetTimeoutTimer?.cancel();
      resetState();
      return;
    }

    if (json is Map<String, dynamic>) {
      AppHelpers.debugLog('Processing map response: $json');

      if (json['success'] == false && json.containsKey('error')) {
        _completer?.complete({
          'success': false,
          'error': json['error'],
          'message': 'Operation failed'
        });
        _controller!._notifyStatus('Error: ${json['error']}');
        AppHelpers.debugLog('Error response: ${json['error']}');

        _completer = null;
        _packetTimeoutTimer?.cancel();
        resetState();
        return;
      }

      if (json.containsKey('data')) {
        _updatePaginationData(json, _lastCommandDataType ?? 'device');
      } else if (_lastCommandDataType == 'modbus' &&
          _lastCommand != null &&
          (_lastCommand!.contains('"action":"UPDATE"') ||
              _lastCommand!.contains('"action":"CREATE"'))) {
        _completer?.complete({'data': [], 'message': 'Operation successful'});
        _controller!._notifyStatus('Operation successful (assumed)');
      } else {
        _completer?.complete(json);
      }

      _packetTimeoutTimer?.cancel();
      resetState();
      return;
    }

    if (_packetBuffer.isNotEmpty && json == null) {
      final message = _assembleMessage();
      AppHelpers.debugLog('Assembled message from buffer: $message');
      try {
        final parsedJson = jsonDecode(message);
        await _completeMessage(json: parsedJson);
        return;
      } catch (e) {
        AppHelpers.debugLog('Failed to parse assembled message: $e');
        _completer?.complete(
            {'data': [], 'message': 'Invalid JSON structure', 'raw': message});
        _controller!._notifyStatus('Invalid JSON structure received');

        _completer = null;
        _packetTimeoutTimer?.cancel();
        resetState();
        return;
      }
    }

    AppHelpers.debugLog('Invalid JSON structure: $json');
    _completer?.complete(
        {'data': [], 'message': 'Invalid JSON structure', 'raw': json});
    _controller!._notifyStatus('Invalid JSON structure received');

    _completer = null;
    _packetTimeoutTimer?.cancel();
    resetState();
  }

  // Assemble message from buffer
  String _assembleMessage() {
    final sortedKeys = _packetBuffer.keys.toList()..sort();
    final message = sortedKeys.map((key) => _packetBuffer[key]!).join();
    AppHelpers.debugLog('Assembled message: $message');
    return message;
  }

  // Update pagination data based on data type
  void _updatePaginationData(Map<String, dynamic> json, String dataType) {
    AppHelpers.debugLog('Updating pagination data: type=$dataType, json=$json');
    if (dataType == 'devices') {
      Get.find<DevicePaginationController>().setPaginationData(json);
    } else if (dataType == 'modbus') {
      Get.find<ModbusPaginationController>().setPaginationData(json);
    }
  }

  // Generate unique message ID
  String _generateMessageId(int totalPackets) {
    return '${DateTime.now().millisecondsSinceEpoch}_${totalPackets}_$_retryCount';
  }
}

// Utility class for UI-related BLE functions
class BLEUtils {
  // Show dialog when a device is connected
  static void showConnectedBottomSheet(BluetoothDevice device) {
    CustomAlertDialog.show(
      title: 'Device Connected',
      message:
          'Do you want to open device (${device.platformName.isNotEmpty ? device.platformName : device.remoteId}) page detail?',
      primaryButtonText: 'Yes',
      secondaryButtonText: 'No',
      onPrimaryPressed: () => Get.to(() => DetailDeviceScreen(device: device)),
      barrierDismissible: false,
    );
  }

  // Show dialog to confirm device disconnection
  static void showDisconnectedBottomSheet(
      BluetoothDevice device, VoidCallback? onDisconnect) {
    final deviceName = device.platformName.isNotEmpty
        ? device.platformName
        : device.remoteId.toString();
    CustomAlertDialog.show(
      title: 'Disconnect Device?',
      message: 'Do you want to disconnect the device ($deviceName)?',
      primaryButtonText: 'Yes',
      secondaryButtonText: 'No',
      onPrimaryPressed: onDisconnect,
      barrierDismissible: false,
    );
  }
}
