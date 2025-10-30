import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/utils/app_helpers.dart';
import 'package:gateway_config/core/utils/ble_utils.dart';
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
  var isNavigatingHome = false.obs;

  final RxMap<String, String> streamedData = <String, String>{}.obs;

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

    // Listen perubahan koneksi global
    ever(connectedDevice, (device) {
      if (device == null && !isNavigatingHome.value) {
        isNavigatingHome.value = true;
        AppHelpers.debugLog('connectedDevice null → redirect home');

        SnackbarCustom.showSnackbar(
          '',
          'Device disconnect, will be redirect to home in 3 seconds.',
          AppColor.labelColor,
          AppColor.whiteColor,
        );

        Future.delayed(const Duration(seconds: 3), () {
          AppHelpers.debugLog('connectedDevice null → redirect home duration');
          if (Get.context != null) {
            GoRouter.of(Get.context!).go('/');
          } else {
            Get.offAllNamed('/');
          }

          // reset flag setelah navigasi selesai
          Future.delayed(const Duration(seconds: 1), () {
            isNavigatingHome.value = false;
          });
        });
      }
    });

    adapterStateSubscription = FlutterBluePlus.adapterState.listen(
      _handleAdapterStateChange,
    );
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

      if (state == BluetoothConnectionState.disconnected) {
        AppHelpers.debugLog('Device auto disconnected');

        // Reset state BLE hanya untuk device yang sedang terhubung
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
    isNavigatingHome.value = false;

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

      // Log characteristic properties
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
      return CommandResponse(
        status: 'error',
        message: 'Not connected',
        type: command['type'] ?? 'device',
      );
    }

    // Validate command
    if (!command.containsKey('op') || !command.containsKey('type')) {
      errorMessage.value = 'Invalid command format';
      return CommandResponse(
        status: 'error',
        message: 'Invalid command format',
        type: command['type'] ?? 'device',
      );
    }

    commandLoading.value = true;
    commandProgress.value = 0.0;
    lastCommand.value = command; // Cache last command
    String jsonStr = jsonEncode(command);
    AppHelpers.debugLog('Full command JSON: $jsonStr');

    const chunkSize = 18;
    int totalChunks = (jsonStr.length / chunkSize).ceil() + 1; // +1 for <END>
    int currentChunk = 0;

    try {
      // Cancel sub lama jika ada
      responseSubscription?.cancel();

      // Setup buffer dan completer UNTUK RESPONSE (sebelum kirim command)
      final responseCompleter = Completer<CommandResponse?>();
      StringBuffer responseBuffer = StringBuffer();

      // Set subscription SEKALI, sebelum kirim, dan collect di sini
      AppHelpers.debugLog(
        'Starting response subscription before sending command',
      );
      responseSubscription = responseChar!.lastValueStream.listen(
        (data) {
          final chunk = utf8.decode(data, allowMalformed: true);
          AppHelpers.debugLog('Notify chunk received: $chunk');
          responseBuffer.write(chunk);

          if (chunk.contains('<END>')) {
            // Deteksi <END> di chunk apapun
            AppHelpers.debugLog(
              'Buffer before parsing: ${responseBuffer.toString()}',
            );
            try {
              // Clean buffer: hapus <END> dan control chars
              final cleanedBuffer = responseBuffer
                  .toString()
                  .replaceAll('<END>', '')
                  .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '')
                  .trim();

              if (cleanedBuffer.isEmpty) {
                throw Exception('Empty buffer');
              }
              if (!cleanedBuffer.startsWith('{') &&
                  !cleanedBuffer.startsWith('[')) {
                throw Exception('Malformed JSON structure');
              }
              if (!cleanedBuffer.endsWith('}') &&
                  !cleanedBuffer.endsWith(']')) {
                throw Exception('Incomplete JSON structure');
              }

              final responseJson =
                  jsonDecode(cleanedBuffer) as Map<String, dynamic>;
              final cmdResponse = CommandResponse.fromJson(responseJson);

              // Cache dengan ID (ex. from lastCommand)
              if (lastCommand.isNotEmpty) {
                final commandId =
                    '${lastCommand['op']}_${lastCommand['type'] ?? 'general'}_${DateTime.now().toIso8601String().split('T')[0]}';
                _cacheResponse(commandId, cmdResponse);
              }

              AppHelpers.debugLog('Parsed response: ${cmdResponse.toJson()}');
              responseCompleter.complete(cmdResponse);
            } catch (e) {
              errorMessage.value = 'Invalid response JSON: $e';
              AppHelpers.debugLog('JSON parsing error: $e');
              responseCompleter.complete(
                CommandResponse(
                  status: 'error',
                  message: 'Invalid response JSON: $e',
                  type: command['type'] ?? 'device',
                ),
              );
            }
            responseBuffer.clear();
          }
        },
        onError: (e) {
          errorMessage.value = 'Notification error: $e';
          AppHelpers.debugLog('Notification error: $e');
          responseCompleter.complete(
            CommandResponse(
              status: 'error',
              message: 'Notification error: $e',
              type: command['type'] ?? 'device',
            ),
          );
        },
      );

      // Enable notify jika belum
      await responseChar!.setNotifyValue(true);
      await Future.delayed(
        const Duration(milliseconds: 300),
      ); // Tingkatkan delay ke 300ms untuk safety

      // Check if writeWithoutResponse is supported
      final bool useWriteWithResponse =
          !(commandChar?.properties.writeWithoutResponse ?? false);
      AppHelpers.debugLog('Using write with response: $useWriteWithResponse');

      // Send command in chunks
      StringBuffer sentCommand = StringBuffer(); // Track sent command
      for (int i = 0; i < jsonStr.length; i += chunkSize) {
        String chunk = jsonStr.substring(
          i,
          (i + chunkSize > jsonStr.length) ? jsonStr.length : i + chunkSize,
        );
        sentCommand.write(chunk); // Build sent command
        await commandChar!.write(
          utf8.encode(chunk),
          withoutResponse: !useWriteWithResponse,
        );
        AppHelpers.debugLog('Sent chunk: $chunk');
        currentChunk++;
        commandProgress.value = currentChunk / totalChunks; // Update progress
        await Future.delayed(
          const Duration(milliseconds: 50),
        ); // Optimized delay
      }
      // Validate sent command
      AppHelpers.debugLog('Full sent command: ${sentCommand.toString()}');
      try {
        jsonDecode(sentCommand.toString());
        AppHelpers.debugLog('Sent command is valid JSON');
      } catch (e) {
        AppHelpers.debugLog('Sent command is not valid JSON: $e');
      }

      // Add delay before sending <END>
      await Future.delayed(const Duration(milliseconds: 100));
      await commandChar!.write(
        utf8.encode('<END>'),
        withoutResponse: !useWriteWithResponse,
      );
      AppHelpers.debugLog('Sent chunk: <END>');
      currentChunk++;
      commandProgress.value = 1.0;

      // Tunggu response via completer (timeout 15s)
      final response = await responseCompleter.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          AppHelpers.debugLog('Response timeout');
          return CommandResponse(
            status: 'error',
            message: 'Response timeout',
            type: command['type'] ?? 'device',
          );
        },
      );

      if (response == null) {
        throw Exception('No response received');
      }

      // Warn if devices_summary is empty
      if (response.status == 'ok' &&
          response.config is List &&
          (response.config as List).isEmpty) {
        errorMessage.value = 'Warning: No devices found in response';
        AppHelpers.debugLog('Empty devices_summary in response');
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
      if (command['op'] != 'delete') {
        SnackbarCustom.showSnackbar(
          '',
          response.status == 'success' || response.status == 'ok'
              ? command['op'] == 'create'
                    ? 'Data saved successfully'
                    : command['op'] == 'update'
                    ? 'Data updated successfully'
                    : 'Data fetched successfully'
              : errorMessage.value,
          response.status == 'success' || response.status == 'ok'
              ? Colors.green
              : Colors.red,
          AppColor.whiteColor,
        );
      }

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
      return CommandResponse(
        status: 'error',
        message: errorMessage.value,
        type: command['type'] ?? 'device',
      );
    } finally {
      commandLoading.value = false;
    }
  }

  // Function to read command response using notification
  Future<CommandResponse> readCommandResponse(
    DeviceModel gatewayModel, {
    required String type,
    Map<String, dynamic>? additionalParams,
  }) async {
    if (commandChar == null || responseChar == null) {
      errorMessage.value = 'Not connected';
      return CommandResponse(
        status: 'error',
        message: 'Not connected',
        type: type,
      );
    }

    final readCommand = {'op': 'read', 'type': type, ...?additionalParams};
    String jsonStr = jsonEncode(readCommand);
    AppHelpers.debugLog('Full read command JSON: $jsonStr');

    const chunkSize = 18;
    int totalChunks = (jsonStr.length / chunkSize).ceil() + 1;
    int currentChunk = 0;

    commandLoading.value = true;
    commandProgress.value = 0.0;

    try {
      responseSubscription?.cancel();
      final responseCompleter = Completer<CommandResponse?>();
      StringBuffer responseBuffer = StringBuffer();

      AppHelpers.debugLog(
        'Starting new response subscription before sending read command',
      );
      responseSubscription = responseChar!.lastValueStream.listen(
        (data) {
          final chunk = utf8.decode(data, allowMalformed: true);
          AppHelpers.debugLog('Notify chunk received: $chunk');
          responseBuffer.write(chunk);

          if (chunk.contains('<END>')) {
            AppHelpers.debugLog(
              'Buffer before parsing: ${responseBuffer.toString()}',
            );
            try {
              final cleanedBuffer = responseBuffer
                  .toString()
                  .replaceAll('<END>', '')
                  .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '')
                  .trim();

              AppHelpers.debugLog('Raw cleaned buffer: $cleanedBuffer');

              if (cleanedBuffer.isEmpty) {
                throw Exception('Empty buffer');
              }
              if (!cleanedBuffer.startsWith('{') &&
                  !cleanedBuffer.startsWith('[')) {
                throw Exception('Malformed JSON structure');
              }
              if (!cleanedBuffer.endsWith('}') &&
                  !cleanedBuffer.endsWith(']')) {
                throw Exception('Incomplete JSON structure');
              }

              final decoded = jsonDecode(cleanedBuffer);
              Map<String, dynamic> responseJson;

              if (decoded is Map) {
                responseJson = Map<String, dynamic>.from(decoded);
                responseJson = _sanitizeMap(responseJson);
              } else if (decoded is List &&
                  decoded.isNotEmpty &&
                  decoded.first is Map) {
                // fallback jika JSON root array (misal BLE kirim list langsung)
                responseJson = Map<String, dynamic>.from(decoded.first);
                responseJson = _sanitizeMap(responseJson);
              } else {
                throw Exception('Invalid JSON root: ${decoded.runtimeType}');
              }

              dynamic configData =
                  responseJson['config'] ??
                  responseJson[type] ??
                  responseJson['data'] ??
                  {};

              if (configData is Map) {
                configData = [configData]; // Wrap Map jadi List<Map>
              } else if (configData is! List) {
                configData = []; // Fallback jika bukan List/Map
              }

              // Map field lain ke config jika config tidak ada
              responseJson['config'] = configData;
              responseJson['message'] = "Get data successfully";
              responseJson['type'] = responseJson['type'] ?? type;

              final cmdResponse = CommandResponse.fromJson(responseJson);

              AppHelpers.debugLog(
                'Parsed response status: ${cmdResponse.status}, full: ${cmdResponse.toJson()}',
              );

              // Cache jika perlu
              if (lastCommand.isNotEmpty) {
                final commandId =
                    '${lastCommand['op']}_${lastCommand['type'] ?? 'general'}_${DateTime.now().toIso8601String().split('T')[0]}';
                _cacheResponse(commandId, cmdResponse);
              }

              responseCompleter.complete(cmdResponse);
            } catch (e) {
              errorMessage.value = 'Invalid response JSON: $e';
              AppHelpers.debugLog('JSON parsing error: $e');
              responseCompleter.complete(
                CommandResponse(
                  status: 'error',
                  message: 'Invalid response JSON: $e',
                  type: type,
                  config: [],
                ),
              );
            }
            responseBuffer.clear();
          }
        },
        onError: (e) {
          AppHelpers.debugLog('Notification error: $e');
          responseCompleter.complete(
            CommandResponse(
              status: 'error',
              message: 'Notification error: $e',
              type: type,
              config: [],
            ),
          );
        },
      );

      await responseChar!.setNotifyValue(true);
      await Future.delayed(const Duration(milliseconds: 300));

      final bool useWriteWithResponse =
          !(commandChar?.properties.writeWithoutResponse ?? false);
      AppHelpers.debugLog('Using write with response: $useWriteWithResponse');

      StringBuffer sentCommand = StringBuffer();
      for (int i = 0; i < jsonStr.length; i += chunkSize) {
        String chunk = jsonStr.substring(
          i,
          (i + chunkSize > jsonStr.length) ? jsonStr.length : i + chunkSize,
        );
        sentCommand.write(chunk);
        await commandChar!.write(
          utf8.encode(chunk),
          withoutResponse: !useWriteWithResponse,
        );
        AppHelpers.debugLog('Sent chunk: $chunk');
        currentChunk++;
        commandProgress.value = currentChunk / totalChunks;
        await Future.delayed(const Duration(milliseconds: 50));
      }

      AppHelpers.debugLog('Full sent read command: ${sentCommand.toString()}');
      try {
        jsonDecode(sentCommand.toString());
        AppHelpers.debugLog('Sent read command is valid JSON');
      } catch (e) {
        AppHelpers.debugLog('Sent read command is not valid JSON: $e');
      }

      await Future.delayed(const Duration(milliseconds: 100));
      await commandChar!.write(
        utf8.encode('<END>'),
        withoutResponse: !useWriteWithResponse,
      );
      AppHelpers.debugLog('Sent chunk: <END>');
      currentChunk++;
      commandProgress.value = 1.0;

      final response = await responseCompleter.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          AppHelpers.debugLog('Response timeout');
          return CommandResponse(
            status: 'error',
            message: 'Response timeout',
            type: type,
            config: [],
          );
        },
      );

      if (response == null) {
        throw Exception('No response received');
      }

      if (response.status == 'ok' &&
          response.config is List &&
          (response.config as List).isEmpty) {
        errorMessage.value = 'Warning: No devices found in response';
        AppHelpers.debugLog('Empty devices_summary in response');
      }

      // Simpan response bahkan jika status bukan ok/success untuk debugging
      gatewayDeviceResponses.add(response);
      AppHelpers.debugLog(
        'Saved read response for type "$type" in Gateway ${gatewayModel.device.remoteId}: ${response.toJson()}',
      );

      AppHelpers.debugLog(
        'gatewayDeviceResponses: ${gatewayDeviceResponses.map((r) => r.toJson()).toList()}',
      );

      return response;
    } catch (e) {
      errorMessage.value = 'Error reading command: $e';
      AppHelpers.debugLog('Error reading command for type "$type": $e');
      return CommandResponse(
        status: 'error',
        message: errorMessage.value,
        type: type,
        config: {},
      );
    } finally {
      commandLoading.value = false;
      commandProgress.value = 0.0;
    }
  }

  // Function to get responses by type
  List<CommandResponse> getResponsesByType(String type) {
    return gatewayDeviceResponses.where((resp) => resp.type == type).toList();
  }

  Future<void> startDataStream(String type, String deviceId) async {
    if (commandChar == null || responseChar == null) {
      errorMessage.value = 'Not connected';
      return;
    }

    final startCommand = {"op": "read", "type": type, "device_id": deviceId};
    commandLoading.value = true;

    try {
      // Kirim command start (reuse sendCommand logic, tapi tanpa tunggu full response di sini)
      await sendCommand(startCommand); // Ini akan setup subscription internally

      // Setup continuous listener (extend dari existing subscription)
      responseSubscription?.cancel(); // Cancel jika ada sebelumnya
      StringBuffer streamBuffer = StringBuffer();

      responseSubscription = responseChar!.lastValueStream.listen((data) {
        final chunk = utf8.decode(data, allowMalformed: true);
        AppHelpers.debugLog('Realtime chunk received: $chunk');
        streamBuffer.write(chunk);

        if (chunk.contains('<END>')) {
          try {
            final cleanedBuffer = streamBuffer
                .toString()
                .replaceAll('<END>', '')
                .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '')
                .trim();

            if (cleanedBuffer.isNotEmpty) {
              final decoded = jsonDecode(cleanedBuffer);
              // Asumsi format: Map {"address": "0x3042", "value": "142"} atau List<Map>
              if (decoded is Map<String, dynamic>) {
                final address = decoded['address']?.toString();
                final value = decoded['value']?.toString();
                if (address != null && value != null) {
                  streamedData[address] = value; // Update atau tambah
                  AppHelpers.debugLog(
                    'Updated streamedData: $address -> $value',
                  );
                }
              } else if (decoded is List) {
                for (var item in decoded) {
                  if (item is Map<String, dynamic>) {
                    final address = item['address']?.toString();
                    final value = item['value']?.toString();
                    if (address != null && value != null) {
                      streamedData[address] = value;
                    }
                  }
                }
              }
            }
          } catch (e) {
            AppHelpers.debugLog('Realtime parsing error: $e');
          }
          streamBuffer.clear(); // Reset buffer untuk next data
        }
      });

      await responseChar!.setNotifyValue(true);
    } catch (e) {
      errorMessage.value = 'Error starting stream: $e';
      SnackbarCustom.showSnackbar(
        '',
        errorMessage.value,
        Colors.red,
        AppColor.whiteColor,
      );
    } finally {
      commandLoading.value = false;
    }
  }

  Future<void> stopDataStream(String type) async {
    final stopCommand = {"op": "read", "type": type, "device_id": "stop"};
    await sendCommand(stopCommand);
    responseSubscription?.cancel();
    streamedData.clear(); // Optional: clear data setelah stop
    AppHelpers.debugLog('Stream stopped');
  }

  // Function baru untuk enhanced streaming dengan device tracking
  Future<void> startStreamDevice(String type, String deviceId) async {
    if (commandChar == null || responseChar == null) {
      errorMessage.value = 'Not connected';
      return;
    }

    final startCommand = {"op": "read", "type": type, "device_id": deviceId};
    commandLoading.value = true;

    try {
      // Setup streaming listener yang lebih advanced
      responseSubscription?.cancel();
      StringBuffer streamBuffer = StringBuffer();

      responseSubscription = responseChar!.lastValueStream.listen((data) {
        final chunk = utf8.decode(data, allowMalformed: true);
        AppHelpers.debugLog(
          'Stream chunk received for device $deviceId: $chunk',
        );
        streamBuffer.write(chunk);

        if (chunk.contains('<END>')) {
          try {
            final cleanedBuffer = streamBuffer
                .toString()
                .replaceAll('<END>', '')
                .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '')
                .trim();

            if (cleanedBuffer.isNotEmpty) {
              final decoded = jsonDecode(cleanedBuffer);

              // Handle format data streaming yang berbeda
              if (decoded is Map<String, dynamic>) {
                final address = decoded['address']?.toString();
                final value = decoded['value']?.toString();
                final sourceDeviceId =
                    decoded['device_id']?.toString() ?? deviceId;

                if (address != null && value != null) {
                  // Update dengan device_id prefix untuk tracking
                  final key = '$sourceDeviceId:$address';
                  streamedData[address] = value;
                  AppHelpers.debugLog('Enhanced stream update: $key -> $value');
                }
              } else if (decoded is List) {
                for (var item in decoded) {
                  if (item is Map<String, dynamic>) {
                    final address = item['address']?.toString();
                    final value = item['value']?.toString();
                    final sourceDeviceId =
                        item['device_id']?.toString() ?? deviceId;

                    if (address != null && value != null) {
                      streamedData[address] = value;
                      AppHelpers.debugLog(
                        'Enhanced stream batch update: $sourceDeviceId:$address -> $value',
                      );
                    }
                  }
                }
              }
            }
          } catch (e) {
            AppHelpers.debugLog('Enhanced stream parsing error: $e');
          }
          streamBuffer.clear();
        }
      });

      await responseChar!.setNotifyValue(true);

      // Send stream start command
      await sendCommand(startCommand);

      AppHelpers.debugLog('Enhanced streaming started for device: $deviceId');
    } catch (e) {
      errorMessage.value = 'Error starting enhanced stream: $e';
      SnackbarCustom.showSnackbar(
        '',
        errorMessage.value,
        Colors.red,
        AppColor.whiteColor,
      );
    } finally {
      commandLoading.value = false;
    }
  }

  Future<void> stopStreamDevice(String type) async {
    final stopCommand = {"op": "read", "type": type, "device_id": "stop"};

    try {
      await sendCommand(stopCommand);
      responseSubscription?.cancel();
      streamedData.clear();
      AppHelpers.debugLog('Enhanced streaming stopped');
    } catch (e) {
      AppHelpers.debugLog('Error stopping enhanced stream: $e');
    }
  }

  Map<String, dynamic> _sanitizeMap(Map input) {
    final Map<String, dynamic> result = {};
    input.forEach((key, value) {
      final safeKey = key?.toString() ?? 'null';
      if (value is Map) {
        result[safeKey] = _sanitizeMap(value);
      } else if (value is List) {
        result[safeKey] = value
            .map((v) => v is Map ? _sanitizeMap(v) : v)
            .toList();
      } else {
        result[safeKey] = value;
      }
    });
    return result;
  }

  @override
  void onClose() {
    _deviceCache.clear();
    streamedData.clear();
    gatewayDeviceResponses.clear();

    adapterStateSubscription?.cancel();
    clearCommandCache();
    responseSubscription?.cancel();

    super.onClose();
  }
}
