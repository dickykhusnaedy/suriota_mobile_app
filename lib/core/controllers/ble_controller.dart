import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/utils/app_helpers.dart';
import 'package:gateway_config/core/utils/ble/ble_utils.dart';
import 'package:gateway_config/core/utils/snackbar_custom.dart';
import 'package:gateway_config/models/command_response.dart';
import 'package:gateway_config/models/device_model.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

class BleController extends GetxController {
  // State variables
  var isScanning = false.obs;
  var isLoading = false.obs;
  var isLoadingConnectionGlobal = false.obs;
  var connectedDevice = Rxn<BluetoothDevice>();
  var response = ''.obs;
  var errorMessage = ''.obs;
  var message = ''.obs;

  var commandLoading = false.obs;
  var commandProgress = 0.0.obs;
  var lastCommand = <String, dynamic>{}.obs;
  var commandCache = <String, CommandResponse>{}.obs;
  var gatewayDeviceResponses = <CommandResponse>[].obs;

  final _deviceCache = <String, DeviceModel>{}.obs;

  // List for scanned devices as DeviceModel
  var scannedDevices = <DeviceModel>[].obs;

  BluetoothCharacteristic? commandChar;
  BluetoothCharacteristic? responseChar;
  StreamSubscription<BluetoothAdapterState>? adapterStateSubscription;

  StreamSubscription? responseSubscription;

  final serviceUUID = Guid('00001830-0000-1000-8000-00805f9b34fb');
  final commandUUID = Guid('11111111-1111-1111-1111-111111111101');
  final responseUUID = Guid('11111111-1111-1111-1111-111111111102');

  @override
  void onInit() {
    super.onInit();

    adapterStateSubscription = FlutterBluePlus.adapterState.listen(
      _handleAdapterStateChange,
    );
    AppHelpers.debugLog('Bluetooth adapter state listener initialized');
  }

  // Function to scan devices
  Future<void> startScan() async {
    if (isScanning.value || isLoading.value) return;

    isLoading.value = true;
    isScanning.value = true;
    errorMessage.value = '';
    scannedDevices.clear(); // Clear old response

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

      // Listen from scan result
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

  // Function to handle scanned device data
  void handleScannedDevice(BluetoothDevice device) {
    // Check for duplicate device
    final deviceId = device.remoteId.toString();
    if (_deviceCache.containsKey(deviceId)) {
      AppHelpers.debugLog('Device $deviceId already in cache');
      return;
    }

    // Create DeviceModel with info from BluetoothDevice
    final deviceModel = DeviceModel(
      device: device,
      onConnect: () {},
      onDisconnect: () {},
    );

    deviceModel.onConnect = () => connectToDevice(deviceModel);
    deviceModel.onDisconnect = () => disconnectFromDevice(deviceModel);

    // Add to scannedDevices list
    scannedDevices.add(deviceModel);
    _deviceCache[deviceId] = deviceModel;

    // Listen to connection state to update isConnected
    // ignore: unused_local_variable
    StreamSubscription<BluetoothConnectionState>? connectionSubscription;
    connectionSubscription = device.connectionState.listen((
      BluetoothConnectionState state,
    ) {
      deviceModel.isConnected.value =
          (state == BluetoothConnectionState.connected);
      update();
      if (!deviceModel.isConnected.value) {
        // Reset characteristics if disconnected
        if (connectedDevice.value?.remoteId == device.remoteId) {
          commandChar = null;
          responseChar = null;
          responseSubscription?.cancel();
          response.value = '';
          connectedDevice.value = null;
        }
      }
    });
  }

  // Function to stop scan
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    isScanning.value = false;
  }

  void _handleAdapterStateChange(BluetoothAdapterState state) {
    AppHelpers.debugLog('Bluetooth adapter state changed: $state');
    if (state == BluetoothAdapterState.off) {
      _handleBluetoothOff();
    } else if (state == BluetoothAdapterState.on) {
      errorMessage.value = '';
      update();
    }
  }

  // Function to connect to device
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

      // Get characteristics
      commandChar = service.characteristics.firstWhere(
        (c) => c.uuid == commandUUID,
      );
      responseChar = service.characteristics.firstWhere(
        (c) => c.uuid == responseUUID,
      );

      // ADDED: Log characteristic properties
      AppHelpers.debugLog(
        'Command characteristic properties: write=${commandChar?.properties.write}, writeWithoutResponse=${commandChar?.properties.writeWithoutResponse}',
      );
      AppHelpers.debugLog(
        'Response characteristic properties: notify=${responseChar?.properties.notify}',
      );

      // Subscribe to response
      await responseChar?.setNotifyValue(true);
      BLEUtils.showConnectedBottomSheet(deviceModel);
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

  // Function to disconnect
  Future<void> disconnectFromDevice(DeviceModel deviceModel) async {
    isLoadingConnectionGlobal.value = true; // Set global loading
    message.value = 'Disconnecting...';

    _deviceCache.remove(deviceModel.device.remoteId.toString());

    try {
      await Future.delayed(const Duration(seconds: 3));

      responseSubscription?.cancel();
      await deviceModel.device.disconnect();
      commandChar = null;
      responseChar = null;
      response.value = '';
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

  Future<void> _handleBluetoothOff() async {
    AppHelpers.debugLog('Handling Bluetooth turned off');

    errorMessage.value =
        'Bluetooth has been turned off. Please turn it back on to connect to devices.';

    // Disconnect all connected devices
    for (var deviceModel in scannedDevices.toList()) {
      if (deviceModel.isConnected.value) {
        await disconnectFromDevice(deviceModel);
        AppHelpers.debugLog(
          'Disconnected device: ${deviceModel.device.remoteId}',
        );
      }
    }

    SnackbarCustom.showSnackbar(
      'Bluetooth Turned Off',
      'Bluetooth has been disabled. Enable it to connect to devices.',
      AppColor.redColor,
      AppColor.whiteColor,
    );

    // Redirect to home
    if (Get.context != null) {
      GoRouter.of(Get.context!).go('/');
    } else {
      AppHelpers.debugLog('Warning: Get.context is null, cannot redirect');
    }
  }

  // Method to save response
  void _cacheResponse(String commandId, CommandResponse response) {
    commandCache[commandId] = response;
    AppHelpers.debugLog('Cached response for $commandId: ${response.status}');
  }

  // Method to get data
  CommandResponse? getCachedResponse(String commandId) {
    return commandCache[commandId];
  }

  DeviceModel? findDeviceByRemoteId(String remoteId) {
    return _deviceCache[remoteId]; // O(1)
  }

  // Method to clear cache (ex. when disconnect or manual)
  void clearCommandCache() {
    commandCache.clear();
    AppHelpers.debugLog('Command cache cleared');
  }

  // Function to send command
  Future<CommandResponse> sendCommand(Map<String, dynamic> command) async {
    if (commandChar == null || responseChar == null) {
      errorMessage.value = 'Not connected';
      return CommandResponse(status: 'error', message: 'Not connected');
    }

    // Validate command
    if (!command.containsKey('op') ||
        !command.containsKey('type') ||
        !command.containsKey('config')) {
      errorMessage.value = 'Invalid command format';
      return CommandResponse(
        status: 'error',
        message: 'Invalid command format',
      );
    }

    commandLoading.value = true;
    commandProgress.value = 0.0;
    lastCommand.value = command; // Cache last command
    String jsonStr = jsonEncode(command);

    const chunkSize = 18;
    int totalChunks = (jsonStr.length / chunkSize).ceil() + 1; // +1 for <END>
    int currentChunk = 0;

    try {
      // Ensure subscription is active before sending command
      await responseChar!.setNotifyValue(true);
      await Future.delayed(
        const Duration(milliseconds: 100),
      ); // Wait for subscription

      // CHANGED: Check if writeWithoutResponse is supported
      final bool useWriteWithResponse =
          !(commandChar?.properties.writeWithoutResponse ?? false);
      AppHelpers.debugLog('Using write with response: $useWriteWithResponse');

      // Send command in chunks
      for (int i = 0; i < jsonStr.length; i += chunkSize) {
        String chunk = jsonStr.substring(
          i,
          (i + chunkSize > jsonStr.length) ? jsonStr.length : i + chunkSize,
        );
        await commandChar!.write(
          utf8.encode(chunk),
          withoutResponse: !useWriteWithResponse,
        );
        AppHelpers.debugLog('Sent chunk: $chunk'); // ADDED: Log sent chunk
        currentChunk++;
        commandProgress.value = currentChunk / totalChunks; // Update progress
        await Future.delayed(
          const Duration(milliseconds: 50),
        ); // Optimized delay
      }
      await commandChar!.write(
        utf8.encode('<END>'),
        withoutResponse: !useWriteWithResponse,
      );
      AppHelpers.debugLog('Sent chunk: <END>'); // ADDED: Log sent chunk
      currentChunk++;
      commandProgress.value = 1.0;

      // Wait for response via notification
      final response = await _waitForNotification();
      if (response == null) {
        throw Exception('No response received');
      }

      // Save response if success
      if (response.status == 'success' || response.status == 'ok') {
        gatewayDeviceResponses.add(response);
        AppHelpers.debugLog(
          'Saved response for command ${command['type']}: ${response.toJson()}',
        );
      } else {
        errorMessage.value = response.message ?? 'Failed to save configuration';
      }

      // Show feedback
      SnackbarCustom.showSnackbar(
        '',
        response.status == 'success' || response.status == 'ok'
            ? 'Success save data'
            : errorMessage.value,
        response.status == 'success' || response.status == 'ok'
            ? Colors.green
            : Colors.red,
        AppColor.whiteColor,
      );

      return response;
    } catch (e) {
      errorMessage.value = 'Error sending command: $e';
      commandProgress.value = 0.0;
      AppHelpers.debugLog('Error sending command: $e');
      SnackbarCustom.showSnackbar(
        '',
        errorMessage.value,
        Colors.red,
        AppColor.whiteColor,
      );
      return CommandResponse(status: 'error', message: errorMessage.value);
    } finally {
      commandLoading.value = false;
    }
  }

  // Function to read command response using notification
  Future<CommandResponse> readCommandResponse(
    DeviceModel gatewayModel, {
    required String type,
  }) async {
    if (commandChar == null || responseChar == null) {
      errorMessage.value = 'Not connected';
      return CommandResponse(status: 'error', message: 'Not connected');
    }

    // Set command data
    final readCommand = {
      'op': 'read',
      'type': type, // Dynamic: 'device', 'modbus', 'server', 'logging'
    };
    String jsonStr = jsonEncode(readCommand);

    const chunkSize = 18;
    int totalChunks = (jsonStr.length / chunkSize).ceil() + 1;
    int currentChunk = 0;

    commandLoading.value = true;
    commandProgress.value = 0.0;

    try {
      // Ensure subscription is active before sending command
      await responseChar!.setNotifyValue(true);
      await Future.delayed(
        const Duration(milliseconds: 100),
      ); // Wait for subscription

      // CHANGED: Check if writeWithoutResponse is supported
      final bool useWriteWithResponse =
          !(commandChar?.properties.writeWithoutResponse ?? false);
      AppHelpers.debugLog('Using write with response: $useWriteWithResponse');

      // Send read command in chunks
      for (int i = 0; i < jsonStr.length; i += chunkSize) {
        String chunk = jsonStr.substring(
          i,
          (i + chunkSize > jsonStr.length) ? jsonStr.length : i + chunkSize,
        );
        await commandChar!.write(
          utf8.encode(chunk),
          withoutResponse: !useWriteWithResponse,
        );
        AppHelpers.debugLog('Sent chunk: $chunk'); // ADDED: Log sent chunk
        currentChunk++;
        commandProgress.value = currentChunk / totalChunks;
        await Future.delayed(
          const Duration(milliseconds: 50),
        ); // Optimized delay
      }
      await commandChar!.write(
        utf8.encode('<END>'),
        withoutResponse: !useWriteWithResponse,
      );
      AppHelpers.debugLog('Sent chunk: <END>'); // ADDED: Log sent chunk
      currentChunk++;
      commandProgress.value = 1.0;

      // Wait for response via notification
      final response = await _waitForNotification();
      if (response == null) {
        throw Exception('No response received');
      }

      // Save response if success
      if (response.status == 'success' || response.status == 'ok') {
        gatewayDeviceResponses.add(response);
        AppHelpers.debugLog(
          'Saved read response for type "$type" in Gateway ${gatewayModel.device.remoteId}: ${response.toJson()}',
        );
      } else {
        errorMessage.value = response.message ?? 'Failed to read data';
      }

      return response;
    } catch (e) {
      errorMessage.value = 'Error reading command: $e';
      AppHelpers.debugLog('Error reading command for type "$type": $e');
      return CommandResponse(status: 'error', message: errorMessage.value);
    } finally {
      commandLoading.value = false;
      commandProgress.value = 0.0;
    }
  }

  // Helper to wait for notification response
  Future<CommandResponse?> _waitForNotification() async {
    final completer = Completer<CommandResponse?>();
    StringBuffer buffer = StringBuffer();

    // Cancel previous subscription to avoid conflicts
    responseSubscription?.cancel();

    // Log subscription status
    AppHelpers.debugLog(
      'Starting new response subscription in _waitForNotification',
    );

    // Subscribe to notification
    responseSubscription = responseChar!.lastValueStream.listen(
      (data) {
        final chunk = utf8.decode(
          data,
          allowMalformed: true,
        ); // Allow malformed UTF-8
        AppHelpers.debugLog(
          'Notify chunk received in _waitForNotification: $chunk',
        );
        buffer.write(chunk); // Append all chunks, including <END>
        if (chunk == '<END>') {
          AppHelpers.debugLog(
            'Buffer before parsing in _waitForNotification: ${buffer.toString()}',
          );
          try {
            // Remove <END> from buffer
            final cleanedBuffer = buffer
                .toString()
                .replaceAll('<END>', '')
                .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');
            // Validate JSON before parsing
            if (cleanedBuffer.isEmpty) {
              errorMessage.value = 'Invalid response JSON: Empty buffer';
              AppHelpers.debugLog('Empty buffer in _waitForNotification');
              completer.complete(
                CommandResponse(status: 'error', message: 'Empty buffer'),
              );
              return;
            }
            // Validate JSON structure
            if (!cleanedBuffer.startsWith('{') &&
                !cleanedBuffer.startsWith('[')) {
              errorMessage.value = 'Invalid response JSON: Malformed structure';
              AppHelpers.debugLog('Malformed JSON structure: $cleanedBuffer');
              completer.complete(
                CommandResponse(
                  status: 'error',
                  message: 'Malformed JSON structure',
                ),
              );
              return;
            }
            // Validate JSON end
            if (!cleanedBuffer.endsWith('}') && !cleanedBuffer.endsWith(']')) {
              errorMessage.value =
                  'Invalid response JSON: Incomplete structure';
              AppHelpers.debugLog('Incomplete JSON structure: $cleanedBuffer');
              completer.complete(
                CommandResponse(
                  status: 'error',
                  message: 'Incomplete JSON structure',
                ),
              );
              return;
            }
            final responseJson =
                jsonDecode(cleanedBuffer) as Map<String, dynamic>;
            final cmdResponse = CommandResponse.fromJson(responseJson);

            // Cache with ID (ex. from lastCommand)
            if (lastCommand.isNotEmpty) {
              final commandId =
                  '${lastCommand['op']}_${lastCommand['type'] ?? 'general'}_${DateTime.now().toIso8601String().split('T')[0]}';
              _cacheResponse(commandId, cmdResponse);
            }

            AppHelpers.debugLog(
              'Parsed response in _waitForNotification: ${cmdResponse.toJson()}',
            );
            completer.complete(cmdResponse);
          } catch (e) {
            errorMessage.value = 'Invalid response JSON: $e';
            AppHelpers.debugLog(
              'JSON parsing error in _waitForNotification: $e',
            );
            completer.complete(
              CommandResponse(
                status: 'error',
                message: 'Invalid response JSON: $e',
              ),
            );
          }
          buffer.clear();
        }
      },
      onError: (e) {
        errorMessage.value = 'Notification error: $e';
        AppHelpers.debugLog('Notification error in _waitForNotification: $e');
        completer.complete(
          CommandResponse(status: 'error', message: 'Notification error: $e'),
        );
      },
    );

    // Timeout after 10 seconds
    Future.delayed(Duration(seconds: 10), () {
      if (!completer.isCompleted) {
        errorMessage.value = 'Response timeout';
        AppHelpers.debugLog('Response timeout in _waitForNotification');
        completer.complete(
          CommandResponse(status: 'error', message: 'Response timeout'),
        );
        responseSubscription?.cancel();
      }
    });

    return completer.future;
  }

  // Function to get responses by type
  List<CommandResponse> getResponsesByType(String type) {
    return gatewayDeviceResponses.where((resp) => resp.type == type).toList();
  }

  @override
  void onClose() {
    _deviceCache.clear();
    adapterStateSubscription?.cancel();
    gatewayDeviceResponses.clear();
    clearCommandCache();
    responseSubscription?.cancel();
    super.onClose();
  }
}
