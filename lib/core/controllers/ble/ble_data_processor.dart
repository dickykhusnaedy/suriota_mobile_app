import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:suriota_mobile_gateway/core/controllers/ble/ble_controller.dart';
import 'package:suriota_mobile_gateway/core/controllers/devices/device_pagination_controller.dart';
import 'package:suriota_mobile_gateway/core/controllers/modbus/modbus_pagination_controller.dart';
import 'package:suriota_mobile_gateway/global/utils/helper.dart';

class BLEDataProcessor {
  BLEController? controller;
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
          controller!.notifyStatus('Timeout waiting for data');
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
    controller!.startLoading();

    try {
      await _validateCharacteristics();
      await _ensureNotificationsEnabled();
      await _sendCommandData(command, dataType);
    } catch (e) {
      _handleSendError(e);
    }
  }

  Future<void> _validateCharacteristics() async {
    if (controller!.writeCharacteristic == null ||
        controller!.notifyCharacteristic == null) {
      throw Exception('Write/Notify characteristics not found');
    }
  }

  Future<void> _ensureNotificationsEnabled() async {
    if (!await controller!.notifyCharacteristic!.isNotifying) {
      await controller!.notifyCharacteristic!.setNotifyValue(true);
      await Future.delayed(const Duration(milliseconds: 3000));
      AppHelpers.debugLog('Re-enabled notifications');
    }
  }

  Future<void> _sendCommandData(String command, String dataType) async {
    final commandWithTerminator = '$command#';
    _resetState(commandWithTerminator, dataType);

    final bytes = utf8.encode(commandWithTerminator);
    final mtu = await controller!.writeCharacteristic!.device.mtu.first;

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
      await controller!.writeCharacteristic!
          .write(chunk, withoutResponse: false);
      await Future.delayed(Duration(milliseconds: mtu < 50 ? 5000 : 3000));
    }
  }

  void _handleSendError(dynamic error) {
    controller!.notifyStatus('Failed to send command: $error');
    AppHelpers.debugLog('Command send error: $error');
  }

  // Listen to BLE notifications
  void listenToNotifications() {
    if (controller!.notifyCharacteristic == null) {
      controller!.notifyStatus('Notify characteristic not found');
      AppHelpers.debugLog('Notify characteristic is null');
      return;
    }

    _packetQueue.clear();
    controller!.notifyCharacteristic!.onValueReceived.listen((value) async {
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
        controller!.notifyStatus('Failed to decode packet: $e');
        AppHelpers.debugLog('Packet decode error: $e');
      }
    }, onError: (e) {
      controller!.notifyStatus('Notification stream error: $e');
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

      controller!.stopLoading();
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
      controller!.notifyStatus('Invalid response format: $e');
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
    controller!.notifyStatus('Retrying command ($_retryCount/$_maxRetries)');
    AppHelpers.debugLog(
        'Retrying command: attempt $_retryCount, command: $_lastCommand');
    sendCommand(_lastCommand!, _lastCommandDataType ?? 'device');
  }

  // Handle timeout failure
  void _handleTimeoutFailure() {
    controller!
        .notifyStatus('Failed to receive data after $_maxRetries retries');
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
        controller!.notifyStatus('$data\nPlease click button fetch data');
      } else if (data == 'No records available') {
        AppHelpers.debugLog('No records response: $data');
        _completer?.complete({'data': [], 'message': data});
        controller!.notifyStatus(data);
        _updatePaginationData({}, _lastCommandDataType ?? 'device');
      } else {
        AppHelpers.debugLog('Empty or invalid response: $data');
        _completer?.complete(
            {'data': [], 'message': 'Empty or invalid message', 'raw': data});
        controller!.notifyStatus('Received empty or invalid response');
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
        controller!.notifyStatus('Error: ${json['error']}');
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
        controller!.notifyStatus('Operation successful (assumed)');
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
        controller!.notifyStatus('Invalid JSON structure received');

        _completer = null;
        _packetTimeoutTimer?.cancel();
        resetState();
        return;
      }
    }

    AppHelpers.debugLog('Invalid JSON structure: $json');
    _completer?.complete(
        {'data': [], 'message': 'Invalid JSON structure', 'raw': json});
    controller!.notifyStatus('Invalid JSON structure received');

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
