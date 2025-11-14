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
  final _connectionSubscriptions =
      <String, StreamSubscription<BluetoothConnectionState>>{};

  // Optimization: Batch processing untuk scan results
  final _scanBatchQueue = <BluetoothDevice>[];
  Timer? _batchProcessTimer;
  Timer? _uiUpdateDebounceTimer;

  // List for scanned devices as DeviceModel
  var scannedDevices = <DeviceModel>[].obs;

  // List for connection history (devices that have been connected before)
  var connectedHistory = <DeviceModel>[].obs;

  // Search functionality
  var searchQuery = ''.obs;
  var filteredDevices = <DeviceModel>[].obs;

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
      if (device == null && isNavigatingHome.value) {
        // Snackbar dan delay sudah ditangani di auto disconnect listener
        // Di sini langsung navigate saja
        AppHelpers.debugLog('connectedDevice null → executing navigation');

        try {
          // Try GoRouter first
          if (Get.context != null) {
            AppHelpers.debugLog('Attempting navigation with GoRouter');
            GoRouter.of(Get.context!).go('/');
            AppHelpers.debugLog('GoRouter navigation successful');
          } else {
            // Fallback to GetX navigation
            AppHelpers.debugLog('Get.context is null, using GetX navigation');
            Get.offAllNamed('/');
            AppHelpers.debugLog('GetX navigation executed');
          }
        } catch (e) {
          // If GoRouter fails, fallback to GetX
          AppHelpers.debugLog('GoRouter navigation failed: $e');
          AppHelpers.debugLog('Falling back to GetX navigation');
          try {
            Get.offAllNamed('/');
            AppHelpers.debugLog('GetX fallback navigation successful');
          } catch (e2) {
            AppHelpers.debugLog('GetX fallback also failed: $e2');
          }
        } finally {
          // Reset flag immediately after navigation attempt
          // Fallback in disconnectFromDevice will handle reset if this fails
          isNavigatingHome.value = false;
          AppHelpers.debugLog('isNavigatingHome flag reset to false by ever()');
        }
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
    _deviceCache.clear(); // Clear device cache for consistency
    _scanBatchQueue.clear(); // Clear batch queue
    clearSearch(); // Clear search state

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

      // OPTIMIZATION: Batch processing - kumpulkan devices dulu, process nanti
      FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult r in results) {
          _addDeviceToBatch(r.device);
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

  // OPTIMIZATION: Batch processing methods untuk mengurangi UI stuttering
  void _addDeviceToBatch(BluetoothDevice device) {
    final deviceId = device.remoteId.toString();

    // Skip jika sudah ada di cache (menghindari duplicate processing)
    if (_deviceCache.containsKey(deviceId)) {
      return;
    }

    // Skip jika sudah ada di batch queue
    if (_scanBatchQueue.any((d) => d.remoteId.toString() == deviceId)) {
      return;
    }

    _scanBatchQueue.add(device);

    // Cancel existing timer
    _batchProcessTimer?.cancel();

    // Process batch setelah 300ms (debounce)
    // Ini membuat multiple devices diproses sekaligus, bukan satu-satu
    _batchProcessTimer = Timer(const Duration(milliseconds: 300), () {
      _processBatch();
    });
  }

  void _processBatch() {
    if (_scanBatchQueue.isEmpty) return;

    AppHelpers.debugLog(
      'Processing batch of ${_scanBatchQueue.length} devices',
    );

    // Process semua devices dalam batch
    for (final device in _scanBatchQueue) {
      _processScannedDevice(device);
    }

    // Clear batch setelah diproses
    _scanBatchQueue.clear();

    // Update filtered devices setelah batch processing
    // Ini akan mempertahankan search query jika ada
    filterDevices(searchQuery.value);

    // Debounced UI update - hanya update sekali untuk semua devices
    _scheduleUIUpdate();
  }

  void _scheduleUIUpdate() {
    _uiUpdateDebounceTimer?.cancel();
    _uiUpdateDebounceTimer = Timer(const Duration(milliseconds: 100), () {
      update(); // Single update call untuk semua devices
    });
  }

  // Internal processing method (dipanggil dari batch processor)
  void _processScannedDevice(BluetoothDevice device) {
    final deviceId = device.remoteId.toString();

    // Double-check duplicate (safety)
    if (_deviceCache.containsKey(deviceId)) {
      return;
    }

    // Create DeviceModel
    final deviceModel = DeviceModel(
      device: device,
      onConnect: () {},
      onDisconnect: () {},
    );

    deviceModel.onConnect = () => connectToDevice(deviceModel);
    deviceModel.onDisconnect = () => disconnectFromDevice(deviceModel);

    // Add to list dan cache
    scannedDevices.add(deviceModel);
    _deviceCache[deviceId] = deviceModel;

    // OPTIMIZATION: Lazy initialization - hanya setup subscription saat connect
    // Tidak perlu setup connection listener untuk semua devices saat scan
    // Ini akan dipindahkan ke connectToDevice() method
  }

  // OPTIMIZATION: Setup connection state listener (dipanggil saat connect)
  void _setupConnectionStateListener(DeviceModel deviceModel) {
    final deviceId = deviceModel.device.remoteId.toString();

    // Cancel existing subscription if any
    _connectionSubscriptions[deviceId]?.cancel();

    // Listen to connection state to update isConnected
    _connectionSubscriptions[deviceId] = deviceModel.device.connectionState
        .listen((BluetoothConnectionState state) {
          deviceModel.isConnected.value =
              (state == BluetoothConnectionState.connected);
          update();

          if (state == BluetoothConnectionState.disconnected) {
            AppHelpers.debugLog('Device auto disconnected');

            // Reset state BLE hanya untuk device yang sedang terhubung
            if (connectedDevice.value?.remoteId ==
                deviceModel.device.remoteId) {
              // Don't nullify characteristics if streaming is active
              // This prevents killing active streaming sessions
              if (streamedData.isEmpty) {
                commandChar = null;
                responseChar = null;
                responseSubscription?.cancel();
                AppHelpers.debugLog(
                  'Cleared BLE characteristics (no active streaming)',
                );
              } else {
                // Keep characteristics alive for streaming
                AppHelpers.debugLog(
                  'Keeping BLE characteristics alive (streaming active)',
                );
              }

              response.value = '';

              // Clear gateway device responses to avoid stale data
              gatewayDeviceResponses.clear();

              // Show snackbar SEBELUM trigger navigation
              if (!isNavigatingHome.value) {
                isNavigatingHome.value = true;
                SnackbarCustom.showSnackbar(
                  '',
                  'Device disconnect, will be redirect to home in 3 seconds.',
                  AppColor.labelColor,
                  AppColor.whiteColor,
                );

                // Delay SEBELUM set connectedDevice = null (yang trigger ever)
                Future.delayed(const Duration(seconds: 3), () {
                  connectedDevice.value =
                      null; // Ini akan trigger ever() untuk navigate
                });
              }
            }
          }
        });
  }

  // Function to handle scanned device data (backward compatibility)
  // DEPRECATED: Gunakan _addDeviceToBatch untuk scanning otomatis
  void handleScannedDevice(BluetoothDevice device) {
    // Untuk backward compatibility, langsung process tanpa batching
    _processScannedDevice(device);
    update(); // Manual update karena tidak melalui batch processor
  }

  // Function to stop scan
  Future<void> stopScan() async {
    // Cancel batch timers
    _batchProcessTimer?.cancel();
    _uiUpdateDebounceTimer?.cancel();

    // Process remaining devices in batch before stopping
    if (_scanBatchQueue.isNotEmpty) {
      _processBatch();
    }

    await FlutterBluePlus.stopScan();
    isScanning.value = false;
  }

  // SEARCH FUNCTIONALITY: Filter devices berdasarkan nama
  void filterDevices(String query) {
    searchQuery.value = query.toLowerCase().trim();

    if (searchQuery.value.isEmpty) {
      // Jika search kosong, tampilkan semua devices
      filteredDevices.value = scannedDevices.toList();
    } else {
      // Filter berdasarkan device name (platformName atau remoteId)
      filteredDevices.value = scannedDevices.where((deviceModel) {
        final deviceName = deviceModel.device.platformName.toLowerCase();
        final deviceId = deviceModel.device.remoteId.toString().toLowerCase();

        return deviceName.contains(searchQuery.value) ||
            deviceId.contains(searchQuery.value);
      }).toList();
    }

    AppHelpers.debugLog(
      'Search query: "${searchQuery.value}", Found: ${filteredDevices.length} devices',
    );
  }

  // Clear search and reset to show all devices
  void clearSearch() {
    searchQuery.value = '';
    filteredDevices.value = scannedDevices.toList();
  }

  // Add or update device in connection history
  void addOrUpdateHistory(DeviceModel deviceModel) {
    // Update timestamp
    deviceModel.lastConnectionTime.value = DateTime.now();

    // Find if device already exists in history (by remoteId)
    final index = connectedHistory.indexWhere(
      (d) => d.device.remoteId == deviceModel.device.remoteId,
    );

    if (index >= 0) {
      // Device exists: remove from old position and add to front (most recent)
      connectedHistory.removeAt(index);
      connectedHistory.insert(0, deviceModel);
      AppHelpers.debugLog(
        'Updated device in history: ${deviceModel.device.remoteId}',
      );
    } else {
      // New device: add to front
      connectedHistory.insert(0, deviceModel);
      AppHelpers.debugLog(
        'Added new device to history: ${deviceModel.device.remoteId}',
      );
    }
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

    // OPTIMIZATION: Lazy initialization - setup connection listener saat connect
    // Bukan saat scan, ini mengurangi overhead saat scanning banyak devices
    _setupConnectionStateListener(deviceModel);

    try {
      await deviceModel.device.connect();
      connectedDevice.value = deviceModel.device;
      deviceModel.isConnected.value = true;

      // Add to connection history
      addOrUpdateHistory(deviceModel);

      // FIX: Re-add device to cache after successful connection
      // Ini mencegah device null setelah disconnect-reconnect
      final deviceId = deviceModel.device.remoteId.toString();
      _deviceCache[deviceId] = deviceModel;
      AppHelpers.debugLog('Device re-added to cache: $deviceId');

      AppHelpers.debugLog(
        'Device connected successfully: ${deviceModel.device.remoteId}, isConnected: ${deviceModel.isConnected.value}',
      );

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

      AppHelpers.debugLog(
        'Connection setup completed for ${deviceModel.device.remoteId}, final isConnected: ${deviceModel.isConnected.value}',
      );

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
    // LOG PALING AWAL untuk memastikan method dipanggil
    AppHelpers.debugLog(
      '=== disconnectFromDevice() CALLED ===',
    );

    try {
      isLoadingConnectionGlobal.value = true; // Set global loading
      message.value = 'Disconnecting...';

      AppHelpers.debugLog(
        'Getting device ID from deviceModel...',
      );

      final deviceId = deviceModel.device.remoteId.toString();

      AppHelpers.debugLog(
        'Disconnecting device: $deviceId',
      );

      // Remove from cache (device tetap di scannedDevices untuk reconnection)
      // Device akan di-add kembali ke cache saat reconnect (di connectToDevice)
      _deviceCache.remove(deviceId);
      AppHelpers.debugLog('Device removed from cache: $deviceId');

      // Cancel connection subscription
      _connectionSubscriptions[deviceId]?.cancel();
      _connectionSubscriptions.remove(deviceId);

      AppHelpers.debugLog('Connection subscriptions cancelled for: $deviceId');
      // Manual disconnect: show snackbar and delay before triggering navigation
      // Don't clear BLE resources if streaming is active
      if (streamedData.isEmpty) {
        responseSubscription?.cancel();
        AppHelpers.debugLog(
          'Manual disconnect: Cleared responseSubscription (no active streaming)',
        );
      } else {
        AppHelpers.debugLog(
          'Manual disconnect: Keeping responseSubscription alive (streaming active)',
        );
      }

      await deviceModel.device.disconnect();

      // Don't nullify characteristics if streaming is active
      if (streamedData.isEmpty) {
        commandChar = null;
        responseChar = null;
        AppHelpers.debugLog(
          'Manual disconnect: Cleared BLE characteristics (no active streaming)',
        );
      } else {
        AppHelpers.debugLog(
          'Manual disconnect: Keeping BLE characteristics alive (streaming active)',
        );
      }
      response.value = '';
      deviceModel.isConnected.value = false;

      // Update connection history with disconnect timestamp
      addOrUpdateHistory(deviceModel);

      AppHelpers.debugLog('Device state set to disconnected');

      // Show snackbar for manual disconnect
      if (!isNavigatingHome.value) {
        AppHelpers.debugLog(
          'isNavigatingHome = false, setting to true and showing snackbar',
        );
        isNavigatingHome.value = true;
        SnackbarCustom.showSnackbar(
          '',
          'Device disconnect, will be redirect to home in 3 seconds.',
          AppColor.labelColor,
          AppColor.whiteColor,
        );

        AppHelpers.debugLog('Starting 3 second delay before navigation...');
        // Delay before triggering navigation
        await Future.delayed(const Duration(seconds: 3));
        AppHelpers.debugLog('3 second delay completed');
      } else {
        AppHelpers.debugLog(
          'isNavigatingHome already true, skipping snackbar and delay',
        );
      }

      // Capture flag state BEFORE triggering ever()
      // This prevents race condition with ever() callback
      final shouldNavigate = isNavigatingHome.value;

      AppHelpers.debugLog(
        'Captured shouldNavigate = $shouldNavigate, setting connectedDevice to null',
      );

      connectedDevice.value = null; // Trigger ever() untuk navigate

      AppHelpers.debugLog('connectedDevice set to null, ever() should trigger now');

      // Clear gateway device responses to avoid stale data
      gatewayDeviceResponses.clear();

      // Fallback navigation if ever() doesn't trigger (e.g., context issues)
      // Wait for ever() to potentially execute first
      AppHelpers.debugLog('Waiting 500ms for ever() callback...');
      await Future.delayed(const Duration(milliseconds: 500));
      AppHelpers.debugLog('500ms delay completed, checking fallback...');

      // Fallback navigation: if shouldNavigate is true, ALWAYS navigate
      // Don't check isNavigatingHome.value because ever() might reset it
      // but fail to navigate (silent failure due to context issues)
      AppHelpers.debugLog(
        'Fallback check: shouldNavigate=$shouldNavigate, isNavigatingHome.value=${isNavigatingHome.value}',
      );

      if (shouldNavigate) {
        AppHelpers.debugLog(
          'shouldNavigate=true, executing fallback navigation (regardless of flag state)',
        );
        try {
          if (Get.context != null) {
            AppHelpers.debugLog('Navigating with GoRouter.go("/")');
            GoRouter.of(Get.context!).go('/');
            AppHelpers.debugLog('Fallback GoRouter navigation successful');
          } else {
            AppHelpers.debugLog('Get.context is null, using Get.offAllNamed("/")');
            Get.offAllNamed('/');
            AppHelpers.debugLog('Fallback GetX navigation successful');
          }
        } catch (e) {
          AppHelpers.debugLog('Fallback navigation error: $e');
          try {
            AppHelpers.debugLog('Retrying with Get.offAllNamed("/")');
            Get.offAllNamed('/');
            AppHelpers.debugLog(
              'Fallback GetX navigation successful (2nd try)',
            );
          } catch (e2) {
            AppHelpers.debugLog('All fallback navigation failed: $e2');
          }
        } finally {
          // Ensure flag is reset even if ever() already did it
          isNavigatingHome.value = false;
          AppHelpers.debugLog('isNavigatingHome flag ensured reset to false');
        }
      } else {
        AppHelpers.debugLog(
          'shouldNavigate = false, no navigation needed',
        );
      }

      AppHelpers.debugLog(
        'Device disconnected: ${deviceModel.device.remoteId}, isConnected: ${deviceModel.isConnected.value}',
      );

      AppHelpers.debugLog('Checking final connection state...');
      final currentState = await deviceModel.device.connectionState.first;
      if (currentState == BluetoothConnectionState.connected) {
        deviceModel.isConnected.value = true;
        AppHelpers.debugLog('Device still connected (unexpected)');
      } else {
        deviceModel.isConnected.value = false;
        AppHelpers.debugLog('Device confirmed disconnected');
      }
      update();

      AppHelpers.debugLog(
        '=== disconnectFromDevice() COMPLETED SUCCESSFULLY ===',
      );
    } catch (e, stackTrace) {
      errorMessage.value = 'Error disconnecting';
      AppHelpers.debugLog('=== DISCONNECTING ERROR ===');
      AppHelpers.debugLog('Error: $e');
      AppHelpers.debugLog('StackTrace: $stackTrace');

      // Show error to user
      SnackbarCustom.showSnackbar(
        'Error',
        'Failed to disconnect: $e',
        AppColor.redColor,
        AppColor.whiteColor,
      );
    } finally {
      isLoadingConnectionGlobal.value = false; // Reset global loading
      message.value = 'Success disconnected...';
      AppHelpers.debugLog('disconnectFromDevice() finally block executed');
    }
  }

  Future<void> _handleBluetoothOff() async {
    AppHelpers.debugLog('Handling Bluetooth turned off');

    errorMessage.value =
        'Bluetooth has been turned off. Please turn it back on to connect to devices.';

    // Cancel all connection subscriptions
    for (var subscription in _connectionSubscriptions.values) {
      subscription.cancel();
    }
    _connectionSubscriptions.clear();

    // Disconnect all connected devices
    for (var deviceModel in scannedDevices.toList()) {
      if (deviceModel.isConnected.value) {
        await disconnectFromDevice(deviceModel);
        AppHelpers.debugLog(
          'Disconnected device: ${deviceModel.device.remoteId}',
        );
      }
    }

    // Clear all caches
    gatewayDeviceResponses.clear();

    SnackbarCustom.showSnackbar(
      'Bluetooth Turned Off',
      'Bluetooth has been disabled. Enable it to connect to devices.',
      AppColor.redColor,
      AppColor.whiteColor,
    );

    // Redirect to home
    try {
      if (Get.context != null) {
        AppHelpers.debugLog(
          'Attempting navigation with GoRouter (Bluetooth OFF)',
        );
        GoRouter.of(Get.context!).go('/');
        AppHelpers.debugLog('GoRouter navigation successful (Bluetooth OFF)');
      } else {
        AppHelpers.debugLog('Get.context is null, using GetX navigation');
        Get.offAllNamed('/');
        AppHelpers.debugLog('GetX navigation executed (Bluetooth OFF)');
      }
    } catch (e) {
      AppHelpers.debugLog('GoRouter navigation failed: $e');
      AppHelpers.debugLog('Falling back to GetX navigation');
      try {
        Get.offAllNamed('/');
        AppHelpers.debugLog(
          'GetX fallback navigation successful (Bluetooth OFF)',
        );
      } catch (e2) {
        AppHelpers.debugLog('GetX fallback also failed: $e2');
      }
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

    // Detect stop command untuk special handling
    final isStopCommand = command['device_id'] == 'stop';

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
          // Skip jika completer sudah completed
          if (responseCompleter.isCompleted) {
            AppHelpers.debugLog('Completer already completed, ignoring chunk');
            return;
          }

          final chunk = utf8.decode(data, allowMalformed: true);
          AppHelpers.debugLog('Notify chunk received: $chunk');
          responseBuffer.write(chunk);

          if (chunk.contains('<END>')) {
            // Deteksi <END> di chunk apapun
            AppHelpers.debugLog(
              'Buffer before parsing: ${responseBuffer.toString()}',
            );
            try {
              // Split by <END> to handle multiple messages
              final bufferStr = responseBuffer.toString();
              final parts = bufferStr.split('<END>');

              // Process only FIRST complete segment (before first <END>)
              if (parts.isNotEmpty) {
                final firstSegment = parts[0]
                    .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '')
                    .trim();

                // Special handling untuk stop command - lebih lenient
                if (isStopCommand) {
                  // Untuk stop command, accept empty/simple response
                  if (firstSegment.isEmpty ||
                      !firstSegment.startsWith('{') &&
                          !firstSegment.startsWith('[')) {
                    AppHelpers.debugLog(
                      'Stop command: accepting simple/empty response',
                    );
                    if (!responseCompleter.isCompleted) {
                      responseCompleter.complete(
                        CommandResponse(
                          status: 'ok',
                          message: 'Stream stopped successfully',
                          type: command['type'] ?? 'device',
                        ),
                      );
                    }
                    responseBuffer.clear();
                    return;
                  }
                }

                // Normal validation untuk non-stop command
                if (firstSegment.isEmpty) {
                  throw Exception('Empty buffer');
                }
                if (!firstSegment.startsWith('{') &&
                    !firstSegment.startsWith('[')) {
                  throw Exception('Malformed JSON structure');
                }
                if (!firstSegment.endsWith('}') &&
                    !firstSegment.endsWith(']')) {
                  throw Exception('Incomplete JSON structure');
                }

                final responseJson =
                    jsonDecode(firstSegment) as Map<String, dynamic>;

                // Inject type from command if not present in response
                // Device BLE might not send 'type' field, so we inject it manually
                responseJson['type'] = responseJson['type'] ?? command['type'] ?? 'device';

                // Map alternate field names to 'config' (mirrors logic in readCommandResponse)
                // Firmware may send "devices", "data", or type-based field names instead of "config"
                if (!responseJson.containsKey('config')) {
                  dynamic configData =
                      responseJson[command['type']] ??  // Try type as field name (e.g., "devices")
                      responseJson['data'] ??           // Try 'data'
                      responseJson['devices'] ??        // Try 'devices'
                      {};
                  responseJson['config'] = configData;
                }

                final cmdResponse = CommandResponse.fromJson(responseJson);

                // Cache dengan ID (ex. from lastCommand)
                if (lastCommand.isNotEmpty) {
                  final commandId =
                      '${lastCommand['op']}_${lastCommand['type'] ?? 'general'}_${DateTime.now().toIso8601String().split('T')[0]}';
                  _cacheResponse(commandId, cmdResponse);
                }

                AppHelpers.debugLog('Parsed response: ${cmdResponse.toJson()}');

                // Complete hanya jika belum completed
                if (!responseCompleter.isCompleted) {
                  responseCompleter.complete(cmdResponse);
                }
              }
            } catch (e) {
              errorMessage.value = 'Invalid response JSON: $e';
              AppHelpers.debugLog('JSON parsing error: $e');

              // Complete dengan error hanya jika belum completed
              if (!responseCompleter.isCompleted) {
                responseCompleter.complete(
                  CommandResponse(
                    status: 'error',
                    message: 'Invalid response JSON: $e',
                    type: command['type'] ?? 'device',
                  ),
                );
              }
            }
            responseBuffer.clear();
          }
        },
        onError: (e) {
          errorMessage.value = 'Notification error: $e';
          AppHelpers.debugLog('Notification error: $e');

          // Complete dengan error hanya jika belum completed
          if (!responseCompleter.isCompleted) {
            responseCompleter.complete(
              CommandResponse(
                status: 'error',
                message: 'Notification error: $e',
                type: command['type'] ?? 'device',
              ),
            );
          }
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

      // Tunggu response via completer dengan timeout berbeda untuk stop command
      final timeoutDuration = isStopCommand
          ? const Duration(seconds: 5)
          : const Duration(seconds: 15);

      final response = await responseCompleter.future.timeout(
        timeoutDuration,
        onTimeout: () {
          AppHelpers.debugLog(
            'Response timeout${isStopCommand ? ' (stop command)' : ''}',
          );
          // Untuk stop command, timeout tidak dianggap error
          if (isStopCommand) {
            return CommandResponse(
              status: 'ok',
              message: 'Stream stopped successfully',
              type: command['type'] ?? 'device',
            );
          }
          return CommandResponse(
            status: 'error',
            message: 'Response timeout',
            type: command['type'] ?? 'device',
          );
        },
      );

      if (response == null) {
        // Untuk stop command, null response dianggap success
        if (isStopCommand) {
          AppHelpers.debugLog('Stop command: null response treated as success');
          return CommandResponse(
            status: 'ok',
            message: 'Stream stopped successfully',
            type: command['type'] ?? 'device',
          );
        }
        throw Exception('No response received');
      }

      // Warn if devices_summary is empty
      if (response.status == 'ok' &&
          response.config is List &&
          (response.config as List).isEmpty) {
        errorMessage.value = 'Warning: No devices found in response';
        AppHelpers.debugLog('Empty devices_summary in response');
      }

      AppHelpers.debugLog('Error message.value all: ${response.message}');
      // Save response if success
      if (response.status == 'success' || response.status == 'ok') {
        gatewayDeviceResponses.add(response);
        AppHelpers.debugLog(
          'Saved response for command ${command['type']}: ${response.toJson()}',
        );
      } else {
        errorMessage.value = response.message ?? 'Failed to save configuration';
        AppHelpers.debugLog('Error message.value: ${response.message}');
      }

      // Show feedback (skip untuk delete dan stop command)
      if (command['op'] != 'delete' && !isStopCommand) {
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

      // Skip snackbar error untuk stop command
      if (!isStopCommand) {
        SnackbarCustom.showSnackbar(
          '',
          errorMessage.value,
          Colors.red,
          AppColor.whiteColor,
        );
      }

      // Untuk stop command, return success meskipun ada error
      if (isStopCommand) {
        AppHelpers.debugLog('Stop command: error ignored, returning success');
        return CommandResponse(
          status: 'ok',
          message: 'Stream stopped successfully',
          type: command['type'] ?? 'device',
        );
      }

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
          // Skip jika completer sudah completed
          if (responseCompleter.isCompleted) {
            AppHelpers.debugLog('Completer already completed, ignoring chunk');
            return;
          }

          final chunk = utf8.decode(data, allowMalformed: true);
          AppHelpers.debugLog('Notify chunk received: $chunk');
          responseBuffer.write(chunk);

          if (chunk.contains('<END>')) {
            AppHelpers.debugLog(
              'Buffer before parsing: ${responseBuffer.toString()}',
            );
            try {
              // Split by <END> to handle multiple messages
              final bufferStr = responseBuffer.toString();
              final parts = bufferStr.split('<END>');

              // Process only FIRST complete segment (before first <END>)
              if (parts.isNotEmpty && parts[0].trim().isNotEmpty) {
                final firstSegment = parts[0]
                    .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '')
                    .trim();

                AppHelpers.debugLog('Raw cleaned buffer: $firstSegment');

                if (firstSegment.isEmpty) {
                  throw Exception('Empty buffer');
                }
                if (!firstSegment.startsWith('{') &&
                    !firstSegment.startsWith('[')) {
                  throw Exception('Malformed JSON structure');
                }
                if (!firstSegment.endsWith('}') &&
                    !firstSegment.endsWith(']')) {
                  throw Exception('Incomplete JSON structure');
                }

                final decoded = jsonDecode(firstSegment);
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

                // Complete hanya jika belum completed
                if (!responseCompleter.isCompleted) {
                  responseCompleter.complete(cmdResponse);
                }
              }
            } catch (e) {
              errorMessage.value = 'Invalid response JSON: $e';
              AppHelpers.debugLog('JSON parsing error: $e');

              // Complete dengan error hanya jika belum completed
              if (!responseCompleter.isCompleted) {
                responseCompleter.complete(
                  CommandResponse(
                    status: 'error',
                    message: 'Invalid response JSON: $e',
                    type: type,
                    config: [],
                  ),
                );
              }
            }
            responseBuffer.clear();
          }
        },
        onError: (e) {
          AppHelpers.debugLog('Notification error: $e');

          // Complete dengan error hanya jika belum completed
          if (!responseCompleter.isCompleted) {
            responseCompleter.complete(
              CommandResponse(
                status: 'error',
                message: 'Notification error: $e',
                type: type,
                config: [],
              ),
            );
          }
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
      // Setup continuous listener BEFORE sending command
      responseSubscription?.cancel(); // Cancel jika ada sebelumnya
      StringBuffer streamBuffer = StringBuffer();

      responseSubscription = responseChar!.lastValueStream.listen((data) {
        final chunk = utf8.decode(data, allowMalformed: true);
        AppHelpers.debugLog('Realtime chunk received: $chunk');
        streamBuffer.write(chunk);

        if (chunk.contains('<END>')) {
          try {
            final bufferStr = streamBuffer.toString();
            final parts = bufferStr.split('<END>');

            // Check if buffer ends with <END> delimiter
            final endsWithDelimiter = bufferStr.endsWith('<END>');

            // Process only complete segments (those followed by <END>)
            final completeCount = endsWithDelimiter
                ? parts.length
                : parts.length - 1;

            for (int i = 0; i < completeCount; i++) {
              final segment = parts[i].trim();
              if (segment.isEmpty) continue;

              try {
                final cleanedSegment = segment
                    .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '')
                    .trim();

                // Skip if not valid JSON structure
                if (cleanedSegment.isEmpty ||
                    (!cleanedSegment.startsWith('{') &&
                        !cleanedSegment.startsWith('['))) {
                  AppHelpers.debugLog(
                    'Skipping invalid segment: ${cleanedSegment.substring(0, cleanedSegment.length > 50 ? 50 : cleanedSegment.length)}...',
                  );
                  continue;
                }

                final decoded = jsonDecode(cleanedSegment);

                // Handle nested data structure
                Map<String, dynamic>? dataMap;
                if (decoded is Map<String, dynamic>) {
                  // Check if data is nested in 'data' field
                  dataMap = decoded['data'] as Map<String, dynamic>? ?? decoded;
                }

                if (dataMap != null) {
                  final address = dataMap['address']?.toString();
                  final value = dataMap['value']?.toString();
                  if (address != null && value != null) {
                    streamedData[address] = value;
                    streamedData.refresh(); // Trigger reactive update
                    AppHelpers.debugLog(
                      'Updated streamedData: $address -> $value',
                    );
                  }
                } else if (decoded is List) {
                  bool updated = false;
                  for (var item in decoded) {
                    if (item is Map<String, dynamic>) {
                      final itemData =
                          item['data'] as Map<String, dynamic>? ?? item;
                      final address = itemData['address']?.toString();
                      final value = itemData['value']?.toString();
                      if (address != null && value != null) {
                        streamedData[address] = value;
                        updated = true;
                      }
                    }
                  }
                  if (updated) {
                    streamedData.refresh(); // Trigger reactive update
                  }
                }
              } catch (e) {
                AppHelpers.debugLog('Realtime parsing error for segment: $e');
              }
            }

            // Keep partial segment in buffer if exists
            streamBuffer.clear();
            if (!endsWithDelimiter && parts.isNotEmpty) {
              streamBuffer.write(parts.last);
              AppHelpers.debugLog(
                'Keeping partial data for next chunk: ${parts.last.substring(0, parts.last.length > 30 ? 30 : parts.last.length)}...',
              );
            }
          } catch (e) {
            AppHelpers.debugLog('Realtime parsing error: $e');
            streamBuffer.clear();
          }
        }
      });

      await responseChar!.setNotifyValue(true);
      await Future.delayed(const Duration(milliseconds: 300));

      // Send start command manually (without sendCommand to avoid subscription conflict)
      String jsonStr = jsonEncode(startCommand);
      AppHelpers.debugLog('Sending stream start command: $jsonStr');

      const chunkSize = 18;
      final bool useWriteWithResponse =
          !(commandChar?.properties.writeWithoutResponse ?? false);

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
        AppHelpers.debugLog('Sent chunk: $chunk');
        await Future.delayed(const Duration(milliseconds: 50));
      }

      // Send END delimiter
      await Future.delayed(const Duration(milliseconds: 100));
      await commandChar!.write(
        utf8.encode('<END>'),
        withoutResponse: !useWriteWithResponse,
      );
      AppHelpers.debugLog('Sent chunk: <END>');
      AppHelpers.debugLog('Stream started successfully');
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
    try {
      responseSubscription?.cancel();
      streamedData.clear();

      if (commandChar != null) {
        final stopCommand = {"op": "read", "type": type, "device_id": "stop"};
        String jsonStr = jsonEncode(stopCommand);
        AppHelpers.debugLog('Sending stream stop command: $jsonStr');

        const chunkSize = 18;
        final bool useWriteWithResponse =
            !(commandChar?.properties.writeWithoutResponse ?? false);

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
          await Future.delayed(const Duration(milliseconds: 50));
        }

        // Send END delimiter
        await Future.delayed(const Duration(milliseconds: 100));
        await commandChar!.write(
          utf8.encode('<END>'),
          withoutResponse: !useWriteWithResponse,
        );
      }

      AppHelpers.debugLog('Stream stopped');
    } catch (e) {
      AppHelpers.debugLog('Error stopping stream: $e');
    }
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
            final bufferStr = streamBuffer.toString();
            final parts = bufferStr.split('<END>');

            // Check if buffer ends with <END> delimiter
            final endsWithDelimiter = bufferStr.endsWith('<END>');

            // Process only complete segments (those followed by <END>)
            final completeCount = endsWithDelimiter
                ? parts.length
                : parts.length - 1;

            for (int i = 0; i < completeCount; i++) {
              final segment = parts[i].trim();
              if (segment.isEmpty) continue;

              try {
                final cleanedSegment = segment
                    .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '')
                    .trim();

                // Skip if not valid JSON structure
                if (cleanedSegment.isEmpty ||
                    (!cleanedSegment.startsWith('{') &&
                        !cleanedSegment.startsWith('['))) {
                  AppHelpers.debugLog(
                    'Skipping invalid segment: ${cleanedSegment.substring(0, cleanedSegment.length > 50 ? 50 : cleanedSegment.length)}...',
                  );
                  continue;
                }

                final decoded = jsonDecode(cleanedSegment);

                // Handle nested data structure
                Map<String, dynamic>? dataMap;
                if (decoded is Map<String, dynamic>) {
                  // Check if data is nested in 'data' field
                  dataMap = decoded['data'] as Map<String, dynamic>? ?? decoded;
                }

                if (dataMap != null) {
                  final address = dataMap['address']?.toString();
                  final value = dataMap['value']?.toString();
                  final name = dataMap['name']?.toString();
                  final unit = dataMap['unit']?.toString();

                  if (address != null && value != null) {
                    // Store as JSON string to include name and value
                    final dataJson = jsonEncode({
                      'name': name ?? 'Unknown Sensor',
                      'value': value,
                      'address': address,
                      'unit': unit,
                    });
                    streamedData[address] = dataJson;
                    streamedData.refresh(); // Trigger reactive update
                    AppHelpers.debugLog(
                      'Enhanced stream update: $address -> name: $name, value: $value',
                    );
                  }
                } else if (decoded is List) {
                  bool updated = false;
                  for (var item in decoded) {
                    if (item is Map<String, dynamic>) {
                      final itemData =
                          item['data'] as Map<String, dynamic>? ?? item;
                      final address = itemData['address']?.toString();
                      final value = itemData['value']?.toString();
                      final name = itemData['name']?.toString();
                      final unit = itemData['unit']?.toString();

                      if (address != null && value != null) {
                        // Store as JSON string to include name and value
                        final dataJson = jsonEncode({
                          'name': name ?? 'Unknown Sensor',
                          'value': value,
                          'address': address,
                          'unit': unit,
                        });
                        streamedData[address] = dataJson;
                        updated = true;
                        AppHelpers.debugLog(
                          'Enhanced stream batch update: $address -> name: $name, value: $value',
                        );
                      }
                    }
                  }
                  if (updated) {
                    streamedData.refresh(); // Trigger reactive update
                  }
                }
              } catch (e) {
                AppHelpers.debugLog(
                  'Enhanced stream parsing error for segment: $e',
                );
              }
            }

            // Keep partial segment in buffer if exists
            streamBuffer.clear();
            if (!endsWithDelimiter && parts.isNotEmpty) {
              streamBuffer.write(parts.last);
              AppHelpers.debugLog(
                'Keeping partial data for next chunk: ${parts.last.substring(0, parts.last.length > 30 ? 30 : parts.last.length)}...',
              );
            }
          } catch (e) {
            AppHelpers.debugLog('Enhanced stream parsing error: $e');
            streamBuffer.clear();
          }
        }
      });

      await responseChar!.setNotifyValue(true);
      await Future.delayed(const Duration(milliseconds: 300));

      // Send start command manually (without sendCommand to avoid subscription conflict)
      String jsonStr = jsonEncode(startCommand);
      AppHelpers.debugLog('Sending enhanced stream start command: $jsonStr');

      const chunkSize = 18;
      final bool useWriteWithResponse =
          !(commandChar?.properties.writeWithoutResponse ?? false);

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
        AppHelpers.debugLog('Sent chunk: $chunk');
        await Future.delayed(const Duration(milliseconds: 50));
      }

      // Send END delimiter
      await Future.delayed(const Duration(milliseconds: 100));
      await commandChar!.write(
        utf8.encode('<END>'),
        withoutResponse: !useWriteWithResponse,
      );
      AppHelpers.debugLog('Sent chunk: <END>');
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

      // Delay sebelum cancel subscription untuk memastikan device process stop command
      await Future.delayed(const Duration(milliseconds: 500));

      responseSubscription?.cancel();
      streamedData.clear();
      AppHelpers.debugLog('Enhanced streaming stopped');
    } catch (e) {
      AppHelpers.debugLog('Error stopping enhanced stream: $e');
      // Tetap cancel subscription dan clear data meskipun ada error
      responseSubscription?.cancel();
      streamedData.clear();
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
    // OPTIMIZATION: Cancel batch processing timers
    _batchProcessTimer?.cancel();
    _uiUpdateDebounceTimer?.cancel();
    _scanBatchQueue.clear();

    _deviceCache.clear();
    streamedData.clear();
    gatewayDeviceResponses.clear();

    // Cancel all connection subscriptions
    for (var subscription in _connectionSubscriptions.values) {
      subscription.cancel();
    }
    _connectionSubscriptions.clear();

    adapterStateSubscription?.cancel();
    clearCommandCache();
    responseSubscription?.cancel();

    super.onClose();
  }
}
