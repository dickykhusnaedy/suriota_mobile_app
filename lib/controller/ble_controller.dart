import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:suriota_mobile_gateway/constant/app_color.dart';
import 'package:suriota_mobile_gateway/constant/app_gap.dart';
import 'package:suriota_mobile_gateway/constant/font_setup.dart';
import 'package:suriota_mobile_gateway/controller/device_data_controller.dart';
import 'package:suriota_mobile_gateway/controller/device_pagination_controller.dart';
import 'package:suriota_mobile_gateway/controller/modbus_pagination_controller.dart';
import 'package:suriota_mobile_gateway/global/utils/helper.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_button.dart';
import 'package:suriota_mobile_gateway/screen/devices/detail_device_screen.dart';
import 'package:suriota_mobile_gateway/screen/home/home_screen.dart';

class BLEController extends GetxController {
  BluetoothService? _selectedService;
  BluetoothCharacteristic? _selectedCharacteristic;
  BluetoothCharacteristic? _writeChar;
  BluetoothCharacteristic? _notifyChar;

  final devices = <BluetoothDevice>[].obs;
  final isLoading = false.obs;

  final Map<int, String> _packetBuffer = {};
  int _expectedPackets = -1;

  final RxString deviceStoredData = ''.obs;

  final RxMap<String, bool> _connectionStatus = <String, bool>{}.obs;
  final RxMap<String, bool> _loadingStatus = <String, bool>{}.obs;
  final RxMap<String, bool> _isConnected = <String, bool>{}.obs;

  final StreamController<String> _statusController =
      StreamController<String>.broadcast();
  Stream<String> get statusStream => _statusController.stream;

  StreamSubscription<BluetoothConnectionState>? _disconnectSub;

  // Antrian untuk memproses notifikasi
  final _packetQueue = <String>[];
  bool _isProcessingQueue = false;

  // Getters
  bool get isDeviceListEmpty => devices.isEmpty;
  RxMap<String, bool> get connectionStatus => _connectionStatus;
  RxMap<String, bool> get loadingStatus => _loadingStatus;
  RxMap<String, bool> get isConnected => _isConnected;
  BluetoothService? get selectedService => _selectedService;
  BluetoothCharacteristic? get selectedCharacteristic =>
      _selectedCharacteristic;
  BluetoothCharacteristic? get writeChar => _writeChar;
  BluetoothCharacteristic? get notifyChar => _notifyChar;

  bool getConnectionStatus(String deviceId) =>
      _connectionStatus[deviceId] ?? false;
  bool getLoadingStatus(String deviceId) => _loadingStatus[deviceId] ?? false;

  void setLoadingStatus(String deviceId, bool isLoading) {
    _loadingStatus[deviceId] = isLoading;
    update();
  }

  bool get isAnyDeviceLoading {
    return _loadingStatus.values.any((isLoading) => isLoading);
  }

  // Variabel untuk timeout dan debugging
  Timer? _packetTimeoutTimer;
  final int _timeoutDuration = 15;
  String? _currentMessageId;
  String? _lastCommandDataType;
  DateTime _lastPacketTime = DateTime.now();
  final bool _verbose = true;

  // Scan device (tidak diubah)
  void scanDevice() async {
    if (isLoading.value) return;
    _startLoading();
    devices.clear();
    await FlutterBluePlus.stopScan();

    final seenDeviceIds = <String>{};
    late final StreamSubscription<List<ScanResult>> subscription;

    subscription = FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        final id = r.device.remoteId.toString();
        if (!seenDeviceIds.contains(id)) {
          seenDeviceIds.add(id);
          devices.add(r.device);
          _connectionStatus[id] = false;
        }
      }
    });

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    } catch (e) {
      _notifyStatus("Scan failed: $e");
    } finally {
      await Future.delayed(const Duration(seconds: 5));
      await subscription.cancel();
      _stopLoading();
    }
  }

  // Connect to device (tidak diubah)
  Future<void> connectToDevice(BluetoothDevice device) async {
    final deviceId = device.remoteId.toString();
    final deviceName =
        device.platformName.isNotEmpty ? device.platformName : deviceId;

    setLoadingStatus(deviceId, true);

    try {
      await FlutterBluePlus.stopScan();
      await device.connect(
          timeout: const Duration(seconds: 10), autoConnect: false);

      _disconnectSub?.cancel();
      _disconnectSub = device.connectionState.listen((state) async {
        if (state == BluetoothConnectionState.disconnected) {
          _notifyStatus("${device.platformName} disconnected unexpectedly");
          resetBleState();
          await resetBleConnectionsOnly();
          await Future.delayed(const Duration(seconds: 3));
          if (Get.currentRoute != '/') {
            await Get.offAll(() => const HomeScreen());
          }
        }
      });

      bool isServiceDiscovered = await _discoverServices(device);
      if (isServiceDiscovered) {
        showConnectedBottomSheet(device);
      } else {
        await disconnectDevice(device);
      }

      _connectionStatus[deviceId] = true;
      _isConnected[deviceId] = true;
    } catch (e) {
      _connectionStatus[deviceId] = false;
      _isConnected[deviceId] = false;
      AppHelpers.debugLog("Failed to connect: $e");
      _notifyStatus("Failed to connect the device: $deviceName");
    } finally {
      setLoadingStatus(deviceId, false);
    }
  }

  // Reset BLE connections (tidak diubah)
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
      _notifyStatus("Failed to reset BLE.");
    }
  }

  // Disconnect device (tidak diubah)
  Future<void> disconnectDevice(BluetoothDevice device) async {
    final deviceId = device.remoteId.toString();
    final deviceName =
        device.platformName.isNotEmpty ? device.platformName : deviceId;
    setLoadingStatus(deviceId, true);

    try {
      await device.disconnect();
      _connectionStatus[deviceId] = false;
      _isConnected[deviceId] = false;
      _notifyStatus("Disconnected from $deviceName.");
    } catch (e) {
      AppHelpers.debugLog("Failed to disconnect: $e");
      _notifyStatus("Failed to disconnect the device: $deviceName");
    } finally {
      setLoadingStatus(deviceId, false);
    }
  }

  // Discover services (tidak diubah)
  Future<bool> _discoverServices(BluetoothDevice device) async {
    try {
      final services = await device.discoverServices().timeout(
            const Duration(seconds: 15),
            onTimeout: () =>
                throw TimeoutException("Service discovery timed out."),
          );

      if (services.isEmpty) {
        _notifyStatus("No services found on ${device.platformName}");
        return false;
      }

      for (final service in services) {
        for (final char in service.characteristics) {
          _assignCharacteristic(char);
          if (_writeChar != null && _notifyChar != null) {
            _selectedService = service;
            return true;
          }
        }
      }

      _notifyStatus("No valid characteristic with notify/write/read found.");
      return false;
    } catch (e) {
      _notifyStatus(
          "Failed to discover service/characteristic on ${device.platformName}");
      AppHelpers.debugLog("Failed to discover service/characteristic: $e");
      return false;
    }
  }

  // Assign characteristic (tidak diubah)
  void _assignCharacteristic(BluetoothCharacteristic char) async {
    final props = char.properties;
    if (props.write && _writeChar == null) {
      _writeChar = char;
    }
    if (props.notify && _notifyChar == null) {
      _notifyChar = char;
      await _notifyChar!.setNotifyValue(true);
      _listenToNotifications();
    }
  }

  // Mendengarkan notifikasi dengan antrian
  void _listenToNotifications() {
    _notifyChar!.onValueReceived.listen((value) async {
      try {
        final data = utf8.decode(value);
        _packetQueue.add(data);
        await _processQueue();
      } catch (e) {
        print("❌ Failed to decode packet: $e");
        _notifyStatus("Failed to decode packet data.");
      }
    });
  }

  // Memproses antrian paket
  Future<void> _processQueue() async {
    if (_isProcessingQueue || _packetQueue.isEmpty) return;
    _isProcessingQueue = true;

    while (_packetQueue.isNotEmpty) {
      final data = _packetQueue.removeAt(0);
      final regex = RegExp(r'P(\d+)/(\d+):(.*)');
      final altRegex = RegExp(r'P(\d+)/(\d+)\s*(.*)'); // Format alternatif
      final match = regex.firstMatch(data) ?? altRegex.firstMatch(data);

      if (_verbose) {
        print("📥 Processing packet: $data");
      }

      if (match != null) {
        _handlePacket(match);
      } else {
        _notifyStatus("Invalid packet format: $data");
        AppHelpers.debugLog("Invalid packet format: $data");
      }
    }

    _isProcessingQueue = false;
  }

  // Menangani paket dengan penanganan duplikasi
  void _handlePacket(RegExpMatch match) async {
    if (_writeChar == null || _notifyChar == null) {
      print("⚠️ No valid characteristics. Ignoring packet.");
      _notifyStatus("Device not fully connected.");
      return;
    }

    final int index = int.parse(match.group(1)!);
    final int totalMinusOne = int.parse(match.group(2)!);
    final String content = match.group(3)!;
    final int actualTotal = totalMinusOne + 1;
    final DateTime timestamp = DateTime.now();

    print(
        "📅 [${timestamp.toIso8601String()}] Packet [$index/$actualTotal]: $content");

    bool isNewMessage = _shouldStartNewMessage(index, actualTotal, timestamp);

    if (isNewMessage) {
      if (_verbose) {
        print("🔄 Starting new message sequence. Total packets: $actualTotal");
      }
      _resetPacketBuffer();
      _currentMessageId = _generateMessageId(actualTotal);
      _startPacketTimeout();
    }

    // Tangani duplikasi paket
    if (_packetBuffer.containsKey(index)) {
      if (_packetBuffer[index] == content) {
        print("⚠️ Duplicate packet ignored: [$index/$actualTotal]");
        return;
      } else {
        print("⚠️ Conflicting packet at index $index. Starting new message.");
        _resetPacketBuffer();
        _currentMessageId = _generateMessageId(actualTotal);
        _startPacketTimeout();
      }
    }

    _lastPacketTime = timestamp;
    _packetBuffer[index] = content;
    _expectedPackets = actualTotal;

    if (_verbose) {
      final sortedKeys = (_packetBuffer.keys.toList()..sort());
      final missingIndices = _getMissingIndices();
      print(
          "🧩 Current buffer: $sortedKeys / $_expectedPackets (Missing: $missingIndices)");
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

      await _processCompleteMessage(message);
    }
  }

  // Memulai timer timeout
  void _startPacketTimeout() {
    _packetTimeoutTimer?.cancel();
    _packetTimeoutTimer = Timer(Duration(seconds: _timeoutDuration), () {
      if (_packetBuffer.isNotEmpty && !_isAllPacketsReceived()) {
        print("⚠️ Timeout: Processing partial data.");
        _processPartialMessage();
      }
    });
  }

  // Memproses pesan lengkap
  Future<void> _processCompleteMessage(String message) async {
    final tempBuffer = Map<int, String>.from(_packetBuffer);
    _processMessage(message);
    _resetPacketBuffer();

    print("📜 Processed message: $message, Previous buffer: $tempBuffer");
  }

  // Memeriksa apakah semua paket diterima
  bool _isAllPacketsReceived() {
    if (_expectedPackets <= 0) return false;
    final List<int> expectedIndices =
        List<int>.generate(_expectedPackets, (i) => i);
    return expectedIndices.every((index) => _packetBuffer.containsKey(index));
  }

  // Menentukan apakah pesan baru harus dimulai
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

  // Membuat ID pesan
  String _generateMessageId(int totalPackets) {
    return "${DateTime.now().millisecondsSinceEpoch}_$totalPackets";
  }

  // Memproses pesan parsial dengan validasi
  void _processPartialMessage() {
    if (_packetBuffer.isEmpty) {
      print("⚠️ No packets to process");
      return;
    }

    final message = _assembleMessage();
    print(
        "⚠️ Processing partial message (${_packetBuffer.length}/$_expectedPackets)");

    if (message.isEmpty || message.length < 10) {
      print("❌ Partial message too short or empty");
      _notifyStatus("Data tidak lengkap, coba lagi");

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
      _notifyStatus("Data tidak lengkap, mencoba ulang...");
    } finally {
      _resetPacketBuffer();
    }
  }

  // Mendapatkan indeks yang hilang
  List<int> _getMissingIndices() {
    if (_expectedPackets <= 0) return [];
    final allIndices = List<int>.generate(_expectedPackets, (i) => i);
    return allIndices.where((i) => !_packetBuffer.containsKey(i)).toList();
  }

  // Merakit pesan dari buffer
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

  // Mengatur ulang buffer
  void _resetPacketBuffer() {
    _packetBuffer.clear();
    _expectedPackets = -1;
    _currentMessageId = null;
    _packetTimeoutTimer?.cancel();
    _packetTimeoutTimer = null;
  }

  // Memeriksa apakah pesan adalah pesan sukses
  bool _isSuccessMessage(String message) {
    final successPattern = RegExp(r'success', caseSensitive: false);
    return successPattern.hasMatch(message);
  }

  // Menangani pesan sukses
  Future<void> _handleSuccessMessage(String message) async {
    showSnackbar("Success", message, Colors.green[500], Colors.white);
  }

  // Memproses pesan
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
        _notifyStatus("ESP32 response missing 'data' field.");
      }
    } catch (e) {
      print("❌ Failed to parse JSON: $e");

      if (_isSuccessMessage(message)) {
        _handleSuccessMessage(message);
      } else {
        _notifyStatus("Invalid response format from ESP32");
      }
    }
  }

  // Update pagination data (tidak diubah)
  void _updatePaginationData(Map<String, dynamic> json, String dataType) {
    if (dataType == 'devices') {
      final paginationController = Get.find<DevicePaginationController>();
      paginationController.setPaginationData(json);
    } else if (dataType == 'modbus') {
      final modbusPagination = Get.find<ModbusPaginationController>();
      modbusPagination.setPaginationData(json);
    }
  }

  // Handle single device data (tidak diubah)
  void _handleSingleDeviceData(dynamic device) {
    print("📌 Read by ID result: $device");
    final deviceData = Get.put(DeviceDataController());
    deviceData.setSingleDevice(device);
    _notifyStatus("Success load data.");
  }

  // Mengirim perintah dengan MTU dinamis
  void sendCommand(String commandString, String dataType) async {
    _startLoading();

    if (_writeChar == null) {
      _notifyStatus("Characteristic Write tidak ditemukan.");
      _stopLoading();
      return;
    }

    try {
      if (!commandString.endsWith('#')) {
        commandString += '#';
      }

// Simpan dataType untuk cek di _processMessage
      _lastCommandDataType = dataType;

      final bytes = utf8.encode(commandString);
      final mtu = await _writeChar!.device.mtu.first ?? 20;

      for (int offset = 0; offset < bytes.length; offset += mtu) {
        final chunk = bytes.sublist(
          offset,
          offset + mtu > bytes.length ? bytes.length : offset + mtu,
        );
        await _writeChar!
            .write(chunk, withoutResponse: false)
            .timeout(const Duration(seconds: 5));

        await Future.delayed(const Duration(milliseconds: 50));
      }

      print("Command sent: $commandString");
    } catch (e) {
      AppHelpers.debugLog("Failed to send a command: $e");
      _notifyStatus("Device disconnected...");
    } finally {
      _stopLoading();
    }
  }

  Future<void> disconnectDeviceWithRedirect(BluetoothDevice device) async {
    final deviceId = device.remoteId.toString();
    final deviceName =
        device.platformName.isNotEmpty ? device.platformName : deviceId;
    _loadingStatus[deviceId] = true;

    try {
      await device.disconnect().timeout(const Duration(seconds: 10));
      _connectionStatus[deviceId] = false;
      _isConnected[deviceId] = false;
      // Reset karakteristik Bluetooth
      _writeChar = null;
      _notifyChar = null;
      _selectedService = null;

      _notifyStatus("Disconnected from $deviceName.");

      // Tutup overlay dan navigasi kembali dengan aman
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
      if (e is TimeoutException) {
        _notifyStatus("Disconnect timed out for $deviceName");
      } else {
        _notifyStatus("Failed to disconnect the device: $deviceName");
      }
    } finally {
      _loadingStatus[deviceId] = false;
    }
  }

  // Fungsi utilitas lainnya (tidak diubah)
  void _startLoading() {
    isLoading.value = true;
  }

  void _stopLoading() {
    isLoading.value = false;
  }

  void resetBleState() {
    _writeChar = null;
    _notifyChar = null;
    _selectedService = null;
    _selectedCharacteristic = null;
    _disconnectSub?.cancel();
    _disconnectSub = null;
    _packetBuffer.clear();
    _expectedPackets = -1;
    _connectionStatus.clear();
    _isConnected.clear();
    _loadingStatus.clear();
    isLoading.value = false;
  }

  void showSnackbar(
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

  void showConnectedBottomSheet(BluetoothDevice device) {
    Get.bottomSheet(
      Container(
        padding: AppPadding.medium,
        decoration: const BoxDecoration(
          color: AppColor.whiteColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Wrap(
          children: [
            Center(
              child: Column(
                children: [
                  Text(
                    "Device Connected",
                    style: FontFamily.headlineLarge,
                  ),
                  AppSpacing.sm,
                  Text(
                      "Do you want to open device (${device.platformName.isNotEmpty ? device.platformName : device.remoteId.toString()}) page detail?",
                      style: FontFamily.normal),
                  AppSpacing.md,
                  Row(
                    children: [
                      Expanded(
                        child: Button(
                            onPressed: () =>
                                Navigator.of(Get.overlayContext!).pop(),
                            text: "No",
                            btnColor: AppColor.grey),
                      ),
                      AppSpacing.md,
                      Expanded(
                        child: Button(
                          onPressed: () {
                            Navigator.of(Get.overlayContext!).pop();
                            Get.to(() => DetailDeviceScreen(device: device));
                          },
                          text: "Yes",
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      isDismissible: false,
      enableDrag: false,
    );
  }

  Future<void> showDisconnectedBottomSheet(BluetoothDevice device) async {
    final deviceName = device.platformName.isNotEmpty
        ? device.platformName
        : device.remoteId.toString();

    Get.bottomSheet(
      Container(
        padding: AppPadding.medium,
        decoration: const BoxDecoration(
          color: AppColor.whiteColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Wrap(
          children: [
            Center(
              child: Column(
                children: [
                  Text(
                    "Disconnect Device",
                    style: FontFamily.headlineLarge,
                  ),
                  AppSpacing.sm,
                  Text("Do you want to disconnect the device ($deviceName)?",
                      style: FontFamily.normal),
                  AppSpacing.md,
                  Row(
                    children: [
                      Expanded(
                        child: Button(
                            onPressed: () =>
                                Navigator.of(Get.overlayContext!).pop(),
                            text: "No",
                            btnColor: AppColor.grey),
                      ),
                      AppSpacing.md,
                      Expanded(
                        child: Button(
                          onPressed: () async {
                            await disconnectDeviceWithRedirect(device);
                          },
                          text: "Yes",
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      isDismissible: false,
      enableDrag: false,
    );
  }

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

  @override
  void onClose() {
    _statusController.close();
    super.onClose();
  }
}
