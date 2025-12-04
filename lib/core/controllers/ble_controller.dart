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
  // ========== BLE COMMUNICATION CONSTANTS ==========
  /// BLE chunk size for data transmission
  /// Based on MTU (Maximum Transmission Unit) size minus header overhead
  /// Typical BLE MTU is 23 bytes, minus 3 bytes ATT header = 20 bytes usable
  /// We use 18 bytes to be safe and ensure compatibility across devices
  static const int bleChunkSize = 18;

  /// Delay to ensure old subscription is fully cancelled before creating new one
  static const Duration subscriptionCleanupDelay = Duration(milliseconds: 50);

  /// Delay between BLE characteristic notifications to ensure stable transmission
  static const Duration notificationSetupDelay = Duration(milliseconds: 300);

  /// Delay between chunk transmissions for stable BLE communication
  static const Duration chunkTransmissionDelay = Duration(milliseconds: 100);

  /// Delay before sending END delimiter
  static const Duration endDelimiterDelay = Duration(milliseconds: 100);

  /// Delay for batch processing of scanned devices (debounce)
  static const Duration batchProcessDelay = Duration(milliseconds: 300);

  /// Delay for UI updates (debounce)
  static const Duration uiUpdateDelay = Duration(milliseconds: 100);

  /// Buffer size limits for memory protection
  static const int maxBufferSize = 1024 * 100; // 100KB - Maximum buffer size
  static const int maxPartialSize =
      1024 * 10; // 10KB - Maximum partial data size

  /// Command timeout durations
  static const Duration timeoutStopCommand = Duration(seconds: 5);
  static const Duration timeoutDevicesSummary = Duration(seconds: 60);
  static const Duration timeoutSingleDevice = Duration(seconds: 90);
  static const Duration timeoutPaginatedRequest = Duration(
    seconds: 360,
  ); // 6 min
  static const Duration timeoutWriteOperation = Duration(seconds: 45);
  static const Duration timeoutDefault = Duration(seconds: 90);
  static const Duration timeoutLargeDataMinimal = Duration(
    seconds: 900,
  ); // 15 min (reduced from 25 min)
  static const Duration timeoutLargeDataFull = Duration(
    seconds: 900,
  ); // 15 min (reduced from 80 min)

  // State variables
  var isScanning = false.obs;
  var isLoading = false.obs;
  var isLoadingConnectionGlobal = false.obs;
  var connectedDevice = Rxn<BluetoothDevice>();
  var errorMessage = ''.obs;
  var message = ''.obs;

  var commandLoading = false.obs;
  var commandProgress = 0.0.obs;
  var lastCommand = <String, dynamic>{}.obs;
  var commandCache = <String, CommandResponse>{}.obs;
  var gatewayDeviceResponses = <CommandResponse>[].obs;
  var isNavigatingHome = false.obs;

  // Firmware capability flags
  var firmwareSupportsPagination = false.obs;
  var firmwareVersionChecked = false.obs;

  final RxMap<String, String> streamedData = <String, String>{}.obs;

  // Streaming state management
  var isStreaming = false.obs;
  var currentStreamType = ''.obs;
  var currentStreamDeviceId = ''.obs;
  Timer? _streamTimeout;

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

    // Process batch setelah delay (debounce)
    // Ini membuat multiple devices diproses sekaligus, bukan satu-satu
    _batchProcessTimer = Timer(batchProcessDelay, () {
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
    _uiUpdateDebounceTimer = Timer(uiUpdateDelay, () {
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

      // Clear error message after showing it
      Future.delayed(const Duration(seconds: 3), () {
        errorMessage.value = '';
      });

      await disconnectFromDevice(deviceModel);
    } finally {
      deviceModel.isLoadingConnection.value = false;
      isLoadingConnectionGlobal.value = false;
      message.value = 'Success connected...';

      // Clear message after 2 seconds to prevent it from showing on other pages
      Future.delayed(const Duration(seconds: 2), () {
        message.value = '';
      });
    }
  }

  // Function to disconnect
  Future<void> disconnectFromDevice(DeviceModel deviceModel) async {
    // LOG PALING AWAL untuk memastikan method dipanggil
    AppHelpers.debugLog('=== disconnectFromDevice() CALLED ===');

    try {
      isLoadingConnectionGlobal.value = true; // Set global loading
      message.value = 'Disconnecting...';

      AppHelpers.debugLog('Getting device ID from deviceModel...');

      final deviceId = deviceModel.device.remoteId.toString();

      AppHelpers.debugLog('Disconnecting device: $deviceId');

      // FIX: Don't remove from cache - keep device data for reconnection
      // Device cache should only be cleared on new scan or explicit cleanup
      // Just update the connection state instead
      AppHelpers.debugLog(
        'Keeping device in cache for reconnection: $deviceId',
      );

      // Cancel connection subscription with proper cleanup
      final subscription = _connectionSubscriptions[deviceId];
      if (subscription != null) {
        await subscription.cancel();
        await Future.delayed(subscriptionCleanupDelay); // Ensure cleanup
        _connectionSubscriptions.remove(deviceId);
        AppHelpers.debugLog('Connection subscription cancelled for: $deviceId');
      }
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

      AppHelpers.debugLog(
        'connectedDevice set to null, ever() should trigger now',
      );

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
            AppHelpers.debugLog(
              'Get.context is null, using Get.offAllNamed("/")',
            );
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
        AppHelpers.debugLog('shouldNavigate = false, no navigation needed');
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

      // Clear error message after showing it
      Future.delayed(const Duration(seconds: 3), () {
        errorMessage.value = '';
      });

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

      // Clear message after 2 seconds to prevent it from showing on other pages
      Future.delayed(const Duration(seconds: 2), () {
        message.value = '';
      });
    }
  }

  Future<void> _handleBluetoothOff() async {
    AppHelpers.debugLog('Handling Bluetooth turned off');

    errorMessage.value =
        'Bluetooth has been turned off. Please turn it back on to connect to devices.';

    // FIX: Batch disconnect to avoid multiple navigation attempts
    // Cancel all connection subscriptions first
    for (var subscription in _connectionSubscriptions.values) {
      await subscription.cancel();
    }
    _connectionSubscriptions.clear();
    AppHelpers.debugLog('All connection subscriptions cancelled');

    // Batch disconnect all connected devices WITHOUT individual navigation
    // This is more efficient than calling disconnectFromDevice for each device
    final connectedDevices = scannedDevices
        .where((d) => d.isConnected.value)
        .toList();

    for (var deviceModel in connectedDevices) {
      try {
        // Direct disconnect without triggering navigation logic
        await deviceModel.device.disconnect();
        deviceModel.isConnected.value = false;

        // Don't clear characteristics if streaming is active
        if (streamedData.isEmpty) {
          commandChar = null;
          responseChar = null;
        }

        AppHelpers.debugLog(
          'Disconnected device: ${deviceModel.device.remoteId}',
        );
      } catch (e) {
        AppHelpers.debugLog(
          'Error disconnecting device during Bluetooth off: $e',
        );
      }
    }

    // Clear global connected device
    connectedDevice.value = null;

    // Clear all caches and streaming data
    gatewayDeviceResponses.clear();
    streamedData.clear();
    responseSubscription?.cancel();
    responseSubscription = null;

    SnackbarCustom.showSnackbar(
      'Bluetooth Turned Off',
      'Bluetooth has been disabled. Enable it to connect to devices.',
      AppColor.redColor,
      AppColor.whiteColor,
    );

    // Single navigation at the end (not per device)
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

  // Check if firmware supports pagination
  Future<bool> checkFirmwarePaginationSupport() async {
    if (firmwareVersionChecked.value) {
      return firmwareSupportsPagination.value;
    }

    try {
      AppHelpers.debugLog('Testing firmware pagination support...');

      // Test with small pagination request (2 devices)
      final testResponse = await sendCommand({
        "op": "read",
        "type": "devices_summary", // Use summary for quick test
        "page": 0,
        "limit": 2,
      });

      // Check if response indicates pagination support
      final responseJson = testResponse.toJson();

      // Firmware with pagination should return:
      // - total_count, total_pages, page, limit fields
      // - config array with exactly 'limit' items (or less if last page)
      bool hasPaginationFields =
          responseJson.containsKey('total_count') ||
          responseJson.containsKey('total_pages');

      if (hasPaginationFields) {
        firmwareSupportsPagination.value = true;
        AppHelpers.debugLog('✅ Firmware SUPPORTS pagination!');
        AppHelpers.debugLog('   Response has pagination fields: $responseJson');
      } else {
        firmwareSupportsPagination.value = false;
        AppHelpers.debugLog('❌ Firmware does NOT support pagination');
        AppHelpers.debugLog('   Response missing pagination fields');
        AppHelpers.debugLog(
          '   Will use fallback strategy (on-demand loading)',
        );
      }

      firmwareVersionChecked.value = true;
      return firmwareSupportsPagination.value;
    } catch (e) {
      AppHelpers.debugLog('Error checking pagination support: $e');
      // Assume no pagination support on error
      firmwareSupportsPagination.value = false;
      firmwareVersionChecked.value = true;
      return false;
    }
  }

  // Method to clear cache (ex. when disconnect or manual)
  void clearCommandCache() {
    commandCache.clear();
    AppHelpers.debugLog('Command cache cleared');
  }

  // SMART LOADER: Auto-detect pagination support and choose best strategy
  Future<List<Map<String, dynamic>>> loadDevicesWithRegisters({
    bool minimal = true,
    int devicesPerPage = 5,
    Function(int current, int total)? onProgress,
  }) async {
    AppHelpers.debugLog('=== SMART DEVICE LOADER ===');
    AppHelpers.debugLog('Checking firmware pagination support...');

    // Check if firmware supports pagination
    final supportsPagination = await checkFirmwarePaginationSupport();

    if (supportsPagination) {
      AppHelpers.debugLog('Using PAGINATION strategy (optimal)');
      return await _loadDevicesPaginated(
        minimal: minimal,
        devicesPerPage: devicesPerPage,
        onProgress: onProgress,
      );
    } else {
      AppHelpers.debugLog('Using FALLBACK strategy (on-demand loading)');
      AppHelpers.debugLog('⚠️  Firmware does not support pagination yet');
      AppHelpers.debugLog(
        '⚠️  Will load summary first, then devices on-demand',
      );

      return await _loadDevicesFallback(
        minimal: minimal,
        onProgress: onProgress,
      );
    }
  }

  // Strategy 1: Paginated loading (when firmware supports it)
  Future<List<Map<String, dynamic>>> _loadDevicesPaginated({
    required bool minimal,
    required int devicesPerPage,
    Function(int current, int total)? onProgress,
  }) async {
    List<Map<String, dynamic>> allDevices = [];
    int page = 0;
    int totalPages = 1;

    while (page < totalPages) {
      AppHelpers.debugLog('Loading page ${page + 1}...');

      final response = await sendCommand({
        "op": "read",
        "type": "devices_with_registers",
        "minimal": minimal,
        "page": page,
        "limit": devicesPerPage,
      });

      // Extract pagination info from response
      final responseJson = response.toJson();
      totalPages = responseJson['total_pages'] ?? 1;
      final totalCount = responseJson['total_count'] ?? 0;

      AppHelpers.debugLog(
        'Page ${page + 1}/$totalPages loaded (Total devices: $totalCount)',
      );

      // Add devices from this page
      if (response.config is List) {
        // FIX: Safe type casting - handle Map<dynamic, dynamic>
        final rawList = response.config as List;
        for (var item in rawList) {
          if (item is Map) {
            allDevices.add(Map<String, dynamic>.from(item));
          }
        }
      }

      // Notify progress
      onProgress?.call(page + 1, totalPages);

      page++;
    }

    AppHelpers.debugLog(
      '✅ Pagination complete: ${allDevices.length} devices loaded',
    );
    return allDevices;
  }

  // Strategy 2: Fallback loading (when firmware doesn't support pagination)
  Future<List<Map<String, dynamic>>> _loadDevicesFallback({
    required bool minimal,
    Function(int current, int total)? onProgress,
  }) async {
    AppHelpers.debugLog('Step 1: Loading devices summary...');

    // Step 1: Get summary (fast - 60s)
    final summary = await sendCommand({
      "op": "read",
      "type": "devices_summary",
    });

    List<Map<String, dynamic>> deviceIds = [];
    if (summary.config is List) {
      // FIX: Safe type casting - handle Map<dynamic, dynamic>
      final rawList = summary.config as List;
      for (var item in rawList) {
        if (item is Map) {
          // Convert Map<dynamic, dynamic> to Map<String, dynamic>
          deviceIds.add(Map<String, dynamic>.from(item));
        }
      }
    }

    final totalDevices = deviceIds.length;
    AppHelpers.debugLog('Found $totalDevices devices');

    // Step 2: Show warning for large datasets
    if (totalDevices > 10) {
      AppHelpers.debugLog('⚠️  Large dataset detected ($totalDevices devices)');
      AppHelpers.debugLog(
        '⚠️  Estimated time: ${totalDevices * 90 ~/ 60} minutes',
      );
      AppHelpers.debugLog(
        '⚠️  Consider upgrading firmware to support pagination',
      );
    }

    // Step 3: Load each device individually
    List<Map<String, dynamic>> allDevices = [];

    for (int i = 0; i < totalDevices; i++) {
      final deviceId = deviceIds[i]['device_id'] ?? deviceIds[i]['id'];

      AppHelpers.debugLog('Loading device ${i + 1}/$totalDevices: $deviceId');

      try {
        final deviceDetail = await sendCommand({
          "op": "read",
          "type": "device",
          "device_id": deviceId,
          "minimal": minimal,
        });

        if (deviceDetail.config is Map) {
          allDevices.add(deviceDetail.config as Map<String, dynamic>);
        }

        // Notify progress
        onProgress?.call(i + 1, totalDevices);
      } catch (e) {
        AppHelpers.debugLog('Error loading device $deviceId: $e');
        // Continue with next device
      }
    }

    AppHelpers.debugLog(
      '✅ Fallback loading complete: ${allDevices.length} devices loaded',
    );
    return allDevices;
  }

  // Function to send command
  Future<CommandResponse> sendCommand(
    Map<String, dynamic> command, {
    bool useGlobalLoading = false,
  }) async {
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

    // Only trigger global loading if useGlobalLoading is true
    if (useGlobalLoading) {
      isLoadingConnectionGlobal.value = true;
    }
    commandProgress.value = 0.0;
    lastCommand.value = command; // Cache last command

    // Detect stop command untuk special handling
    final isStopCommand = command['device_id'] == 'stop';

    String jsonStr = jsonEncode(command);
    AppHelpers.debugLog('Full command JSON: $jsonStr');

    int totalChunks =
        (jsonStr.length / bleChunkSize).ceil() + 1; // +1 for <END>
    int currentChunk = 0;

    // FIX: Store characteristic references to prevent null issues during execution
    final cmd = commandChar;
    final resp = responseChar;
    if (cmd == null || resp == null) {
      errorMessage.value = 'Characteristics became null';
      return CommandResponse(
        status: 'error',
        message: 'Characteristics became null',
        type: command['type'] ?? 'device',
      );
    }

    try {
      // FIX: Improved subscription cleanup to prevent memory leaks
      if (responseSubscription != null) {
        await responseSubscription!.cancel();
        await Future.delayed(subscriptionCleanupDelay); // Ensure cleanup
        responseSubscription = null;
        AppHelpers.debugLog('Previous subscription cleaned up');
      }

      // FIX: Implement Python-style response handling
      // Python waits for separate <END> chunk instead of parsing immediately
      final responseCompleter = Completer<CommandResponse?>();
      final List<String> responseChunks = []; // Match Python's response_buffer
      // ignore: unused_local_variable
      bool responseComplete = false; // Match Python's response_complete flag

      // Set subscription SEKALI, sebelum kirim, dan collect di sini
      AppHelpers.debugLog(
        'Setting up new response subscription before sending command',
      );
      responseSubscription = responseChar!.lastValueStream.listen(
        (data) {
          // Skip jika completer sudah completed
          if (responseCompleter.isCompleted) {
            AppHelpers.debugLog('Completer already completed, ignoring chunk');
            return;
          }

          final chunk = utf8.decode(data, allowMalformed: true);
          AppHelpers.debugLog('Notify chunk received: "$chunk"');

          // FIX: Python-style logic - check if chunk IS <END>, not contains
          if (chunk == '<END>') {
            responseComplete = true;
            AppHelpers.debugLog('✓ Response complete marker received');

            // NOW parse the complete buffer (Python line 159)
            final fullResponse = responseChunks.join('');
            AppHelpers.debugLog(
              'Full response (${fullResponse.length} bytes): $fullResponse',
            );

            try {
              // Clean control characters
              final cleanedResponse = fullResponse
                  .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '')
                  .trim();

              // Special handling untuk stop command - lebih lenient
              if (isStopCommand) {
                AppHelpers.debugLog('Stop command: accepting any response');
                if (!responseCompleter.isCompleted) {
                  responseCompleter.complete(
                    CommandResponse(
                      status: 'ok',
                      message: 'Stream stopped successfully',
                      type: command['type'] ?? 'device',
                    ),
                  );
                }
                return;
              }

              // FIX: Less strict validation (match Python's try-except)
              if (cleanedResponse.isEmpty) {
                AppHelpers.debugLog('Warning: Empty response, using default');
                if (!responseCompleter.isCompleted) {
                  responseCompleter.complete(
                    CommandResponse(
                      status: 'ok',
                      message: 'Empty response',
                      type: command['type'] ?? 'device',
                    ),
                  );
                }
                return;
              }

              // Try to parse JSON
              final responseJson =
                  jsonDecode(cleanedResponse) as Map<String, dynamic>;

              // Inject type from command if not present in response
              responseJson['type'] =
                  responseJson['type'] ?? command['type'] ?? 'device';

              // Map alternate field names to 'config'
              if (!responseJson.containsKey('config')) {
                dynamic configData =
                    responseJson[command['type']] ??
                    responseJson['data'] ??
                    responseJson['devices'] ??
                    {};
                responseJson['config'] = configData;
              }

              final cmdResponse = CommandResponse.fromJson(responseJson);

              // Cache dengan ID
              if (lastCommand.isNotEmpty) {
                final commandId =
                    '${lastCommand['op']}_${lastCommand['type'] ?? 'general'}_${DateTime.now().toIso8601String().split('T')[0]}';
                _cacheResponse(commandId, cmdResponse);
              }

              AppHelpers.debugLog('Parsed response: ${cmdResponse.toJson()}');

              if (!responseCompleter.isCompleted) {
                responseCompleter.complete(cmdResponse);
                // FIX: Cancel subscription immediately setelah complete
                responseSubscription?.cancel();
                AppHelpers.debugLog(
                  'Response received, subscription cancelled',
                );
              }
            } catch (e) {
              errorMessage.value = 'Invalid response JSON: $e';
              AppHelpers.debugLog('JSON parsing error: $e');
              AppHelpers.debugLog('Raw response was: $fullResponse');

              if (!responseCompleter.isCompleted) {
                responseCompleter.complete(
                  CommandResponse(
                    status: 'error',
                    message: 'Invalid response JSON: $e',
                    type: command['type'] ?? 'device',
                  ),
                );
                // FIX: Cancel subscription immediately setelah complete
                responseSubscription?.cancel();
                AppHelpers.debugLog('Error occurred, subscription cancelled');
              }
            }
          } else {
            // FIX: Accumulate chunks like Python (line 55-56)
            responseChunks.add(chunk);
            AppHelpers.debugLog(
              'Accumulated chunk ${responseChunks.length} (${chunk.length} bytes)',
            );
          }
        },
        onError: (e) {
          errorMessage.value = 'Notification error: $e';
          AppHelpers.debugLog('Notification error: $e');

          if (!responseCompleter.isCompleted) {
            responseCompleter.complete(
              CommandResponse(
                status: 'error',
                message: 'Notification error: $e',
                type: command['type'] ?? 'device',
              ),
            );
            // FIX: Cancel subscription immediately setelah error
            responseSubscription?.cancel();
            AppHelpers.debugLog('Error in stream, subscription cancelled');
          }
        },
      );

      // Enable notify jika belum
      await resp.setNotifyValue(true);
      // Delay to ensure notification is properly set up
      await Future.delayed(notificationSetupDelay);

      // Check if writeWithoutResponse is supported
      final bool useWriteWithResponse = !(cmd.properties.writeWithoutResponse);
      AppHelpers.debugLog('Using write with response: $useWriteWithResponse');

      // Send command in chunks
      StringBuffer sentCommand = StringBuffer(); // Track sent command
      for (int i = 0; i < jsonStr.length; i += bleChunkSize) {
        String chunk = jsonStr.substring(
          i,
          (i + bleChunkSize > jsonStr.length)
              ? jsonStr.length
              : i + bleChunkSize,
        );
        sentCommand.write(chunk); // Build sent command
        await cmd.write(
          utf8.encode(chunk),
          withoutResponse: !useWriteWithResponse,
        );
        AppHelpers.debugLog('Sent chunk: $chunk');
        currentChunk++;
        commandProgress.value = currentChunk / totalChunks; // Update progress
        // Delay for stable BLE transmission
        await Future.delayed(chunkTransmissionDelay);
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
      await Future.delayed(endDelimiterDelay);
      await cmd.write(
        utf8.encode('<END>'),
        withoutResponse: !useWriteWithResponse,
      );
      AppHelpers.debugLog('Sent chunk: <END>');
      currentChunk++;
      commandProgress.value = 1.0;

      // FIX: Simplified timeout calculation using constants
      // Reduced from extreme 80min to more practical 15min max
      Duration timeoutDuration;

      if (isStopCommand) {
        timeoutDuration = timeoutStopCommand;
        AppHelpers.debugLog(
          'Using timeout: ${timeoutDuration.inSeconds}s (stop command)',
        );
      } else {
        final opType = command['op'] as String?;
        final commandType = command['type'] as String?;
        final isMinimal = command['minimal'] == true;
        final hasLimit = command['limit'] != null;

        // Determine timeout based on command type
        if (opType == 'read' && commandType == 'devices_with_registers') {
          // Large data requests
          if (hasLimit) {
            // Paginated: 5-10 devices per page
            timeoutDuration = timeoutPaginatedRequest;
            AppHelpers.debugLog(
              'Using timeout: ${timeoutDuration.inSeconds}s (paginated ${isMinimal ? 'minimal' : 'full'})',
            );
          } else {
            // All devices at once (not recommended but supported)
            timeoutDuration = isMinimal
                ? timeoutLargeDataMinimal
                : timeoutLargeDataFull;
            AppHelpers.debugLog(
              '⚠️ Using timeout: ${timeoutDuration.inSeconds}s (ALL devices ${isMinimal ? 'minimal' : 'full'} - consider pagination!)',
            );
          }
        } else if (opType == 'read' && commandType == 'devices_summary') {
          timeoutDuration = timeoutDevicesSummary;
          AppHelpers.debugLog(
            'Using timeout: ${timeoutDuration.inSeconds}s (devices summary)',
          );
        } else if (opType == 'read' &&
            (commandType == 'device' || commandType == 'registers')) {
          timeoutDuration = timeoutSingleDevice;
          AppHelpers.debugLog(
            'Using timeout: ${timeoutDuration.inSeconds}s (single device/registers)',
          );
        } else if (opType == 'create' || opType == 'update') {
          timeoutDuration = timeoutWriteOperation;
          AppHelpers.debugLog(
            'Using timeout: ${timeoutDuration.inSeconds}s (write operation)',
          );
        } else {
          timeoutDuration = timeoutDefault;
          AppHelpers.debugLog(
            'Using timeout: ${timeoutDuration.inSeconds}s (default)',
          );
        }
      }

      final response = await responseCompleter.future.timeout(
        timeoutDuration,
        onTimeout: () {
          // FIX: Only log timeout if completer hasn't been completed yet
          // If completer already completed, timeout callback shouldn't log error
          if (!responseCompleter.isCompleted) {
            AppHelpers.debugLog(
              'Response timeout after ${timeoutDuration.inSeconds}s${isStopCommand ? ' (stop command)' : ''}',
            );
          }
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
            message: 'Response timeout after ${timeoutDuration.inSeconds}s',
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

        // Clear warning message after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          errorMessage.value = '';
        });
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

        // Clear error message after showing it
        Future.delayed(const Duration(seconds: 3), () {
          errorMessage.value = '';
        });
      }

      // Show feedback only for data-modifying operations (skip read, delete, stop)
      final shouldShowFeedback =
          command['op'] != 'delete' &&
          command['op'] != 'read' &&
          !isStopCommand;

      if (shouldShowFeedback) {
        SnackbarCustom.showSnackbar(
          '',
          response.status == 'success' || response.status == 'ok'
              ? command['op'] == 'create'
                    ? 'Data saved successfully'
                    : command['op'] == 'update'
                    ? 'Data updated successfully'
                    : 'Operation completed successfully'
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

      // Clear error message after showing it
      Future.delayed(const Duration(seconds: 3), () {
        errorMessage.value = '';
      });

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

      // Only reset global loading if it was triggered
      if (useGlobalLoading) {
        isLoadingConnectionGlobal.value = false;
      }
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

    const chunkSize = bleChunkSize;
    int totalChunks = (jsonStr.length / chunkSize).ceil() + 1;
    int currentChunk = 0;

    commandLoading.value = true;
    commandProgress.value = 0.0;

    // FIX: Store characteristic references to prevent null issues
    final cmd = commandChar;
    final resp = responseChar;
    if (cmd == null || resp == null) {
      errorMessage.value = 'Characteristics became null';
      return CommandResponse(
        status: 'error',
        message: 'Characteristics became null',
        type: type,
        config: [],
      );
    }

    try {
      // FIX: Improved subscription cleanup
      if (responseSubscription != null) {
        await responseSubscription!.cancel();
        await Future.delayed(subscriptionCleanupDelay);
        responseSubscription = null;
        AppHelpers.debugLog('Previous read subscription cleaned up');
      }

      // FIX: Apply same Python-style response handling for read commands
      final responseCompleter = Completer<CommandResponse?>();
      final List<String> responseChunks = [];
      // ignore: unused_local_variable
      bool responseComplete = false;

      AppHelpers.debugLog(
        'Starting new response subscription before sending read command',
      );
      responseSubscription = resp.lastValueStream.listen(
        (data) {
          // Skip jika completer sudah completed
          if (responseCompleter.isCompleted) {
            AppHelpers.debugLog('Completer already completed, ignoring chunk');
            return;
          }

          final chunk = utf8.decode(data, allowMalformed: true);
          AppHelpers.debugLog('Notify chunk received: "$chunk"');

          // FIX: Same Python-style logic
          if (chunk == '<END>') {
            responseComplete = true;
            AppHelpers.debugLog('✓ Read response complete marker received');

            final fullResponse = responseChunks.join('');
            AppHelpers.debugLog(
              'Full read response (${fullResponse.length} bytes): $fullResponse',
            );

            try {
              final cleanedResponse = fullResponse
                  .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '')
                  .trim();

              if (cleanedResponse.isEmpty) {
                AppHelpers.debugLog('Warning: Empty read response');
                if (!responseCompleter.isCompleted) {
                  responseCompleter.complete(
                    CommandResponse(
                      status: 'ok',
                      message: 'Empty response',
                      type: type,
                      config: [],
                    ),
                  );
                }
                return;
              }

              final decoded = jsonDecode(cleanedResponse);
              Map<String, dynamic> responseJson;

              if (decoded is Map) {
                responseJson = Map<String, dynamic>.from(decoded);
                responseJson = _sanitizeMap(responseJson);
              } else if (decoded is List &&
                  decoded.isNotEmpty &&
                  decoded.first is Map) {
                responseJson = Map<String, dynamic>.from(decoded.first);
                responseJson = _sanitizeMap(responseJson);
              } else {
                throw Exception('Invalid JSON root: ${decoded.runtimeType}');
              }

              dynamic configData;

              // Special handling untuk type "device" dengan tcp_devices/rtu_devices
              if (type == 'device') {
                // Check if response has tcp_devices or rtu_devices structure
                if (responseJson.containsKey('tcp_devices') ||
                    responseJson.containsKey('rtu_devices')) {
                  AppHelpers.debugLog(
                    'Device response has tcp_devices/rtu_devices structure',
                  );

                  // Try to extract from tcp_devices first
                  final tcpDevices = responseJson['tcp_devices'];
                  final rtuDevices = responseJson['rtu_devices'];

                  if (tcpDevices is Map && tcpDevices['devices'] is List) {
                    final devices = tcpDevices['devices'] as List;
                    if (devices.isNotEmpty) {
                      configData = devices;
                      AppHelpers.debugLog(
                        'Extracted ${devices.length} device(s) from tcp_devices',
                      );
                    } else {
                      configData = {};
                      AppHelpers.debugLog('tcp_devices.devices is empty');
                    }
                  } else if (rtuDevices is Map &&
                      rtuDevices['devices'] is List) {
                    final devices = rtuDevices['devices'] as List;
                    if (devices.isNotEmpty) {
                      configData = devices;
                      AppHelpers.debugLog(
                        'Extracted ${devices.length} device(s) from rtu_devices',
                      );
                    } else {
                      configData = {};
                      AppHelpers.debugLog('rtu_devices.devices is empty');
                    }
                  } else {
                    // No devices found in either tcp or rtu
                    configData = {};
                    AppHelpers.debugLog(
                      'No devices found in tcp_devices or rtu_devices',
                    );
                  }
                } else {
                  // Fallback to original logic for device type without tcp/rtu structure
                  configData =
                      responseJson['config'] ??
                      responseJson[type] ??
                      responseJson['data'] ??
                      {};
                  AppHelpers.debugLog(
                    'Using fallback config extraction for device type',
                  );
                }
              } else {
                // Original logic untuk type lain (devices_summary, registers, etc.)
                configData =
                    responseJson['config'] ??
                    responseJson[type] ??
                    responseJson['data'] ??
                    {};
              }

              if (configData is Map) {
                configData = [configData];
              } else if (configData is! List) {
                configData = [];
              }

              responseJson['config'] = configData;
              responseJson['message'] = "Get data successfully";
              responseJson['type'] = responseJson['type'] ?? type;

              final cmdResponse = CommandResponse.fromJson(responseJson);

              AppHelpers.debugLog(
                'Parsed response status: ${cmdResponse.status}, full: ${cmdResponse.toJson()}',
              );

              if (lastCommand.isNotEmpty) {
                final commandId =
                    '${lastCommand['op']}_${lastCommand['type'] ?? 'general'}_${DateTime.now().toIso8601String().split('T')[0]}';
                _cacheResponse(commandId, cmdResponse);
              }

              if (!responseCompleter.isCompleted) {
                responseCompleter.complete(cmdResponse);
                // FIX: Cancel subscription immediately setelah complete
                responseSubscription?.cancel();
                AppHelpers.debugLog(
                  'Read response received, subscription cancelled',
                );
              }
            } catch (e) {
              errorMessage.value = 'Invalid response JSON: $e';
              AppHelpers.debugLog('JSON parsing error: $e');
              AppHelpers.debugLog('Raw response was: $fullResponse');

              if (!responseCompleter.isCompleted) {
                responseCompleter.complete(
                  CommandResponse(
                    status: 'error',
                    message: 'Invalid response JSON: $e',
                    type: type,
                    config: [],
                  ),
                );
                // FIX: Cancel subscription immediately setelah error
                responseSubscription?.cancel();
                AppHelpers.debugLog(
                  'Read error occurred, subscription cancelled',
                );
              }
            }
          } else {
            responseChunks.add(chunk);
            AppHelpers.debugLog(
              'Accumulated read chunk ${responseChunks.length} (${chunk.length} bytes)',
            );
          }
        },
        onError: (e) {
          AppHelpers.debugLog('Notification error: $e');

          if (!responseCompleter.isCompleted) {
            responseCompleter.complete(
              CommandResponse(
                status: 'error',
                message: 'Notification error: $e',
                type: type,
                config: [],
              ),
            );
            // FIX: Cancel subscription immediately setelah error
            responseSubscription?.cancel();
            AppHelpers.debugLog('Read error in stream, subscription cancelled');
          }
        },
      );

      await responseChar!.setNotifyValue(true);
      await Future.delayed(const Duration(milliseconds: 300));

      // FIX: Clear any stale data received during setup/delay
      responseChunks.clear();
      AppHelpers.debugLog('Cleared response buffer before sending command');

      final bool useWriteWithResponse = !(cmd.properties.writeWithoutResponse);
      AppHelpers.debugLog('Using write with response: $useWriteWithResponse');

      StringBuffer sentCommand = StringBuffer();
      for (int i = 0; i < jsonStr.length; i += chunkSize) {
        String chunk = jsonStr.substring(
          i,
          (i + chunkSize > jsonStr.length) ? jsonStr.length : i + chunkSize,
        );
        sentCommand.write(chunk);
        await cmd.write(
          utf8.encode(chunk),
          withoutResponse: !useWriteWithResponse,
        );
        AppHelpers.debugLog('Sent chunk: $chunk');
        currentChunk++;
        commandProgress.value = currentChunk / totalChunks;
        // Delay for stable BLE transmission
        await Future.delayed(chunkTransmissionDelay);
      }

      AppHelpers.debugLog('Full sent read command: ${sentCommand.toString()}');
      try {
        jsonDecode(sentCommand.toString());
        AppHelpers.debugLog('Sent read command is valid JSON');
      } catch (e) {
        AppHelpers.debugLog('Sent read command is not valid JSON: $e');
      }

      await Future.delayed(endDelimiterDelay);
      await cmd.write(
        utf8.encode('<END>'),
        withoutResponse: !useWriteWithResponse,
      );
      AppHelpers.debugLog('Sent chunk: <END>');
      currentChunk++;
      commandProgress.value = 1.0;

      // FIX: Dynamic timeout for read commands - handle EXTREME 70×70 scenario
      Duration timeoutDuration;
      final isMinimal = additionalParams?['minimal'] == true;
      final hasLimit = additionalParams?['limit'] != null;

      // Large data types need VERY extended timeout (70 devices × 70 registers)
      if (type == 'devices_with_registers') {
        if (isMinimal) {
          if (hasLimit) {
            // Paginated minimal (5-10 devices)
            timeoutDuration = const Duration(seconds: 360); // 6 min
            AppHelpers.debugLog(
              'Using timeout (360s/6min) for paginated minimal',
            );
          } else {
            // ALL devices minimal (70 devices): ~22 min theoretical
            timeoutDuration = const Duration(seconds: 1500); // 25 min
            AppHelpers.debugLog(
              '⚠️⚠️⚠️  EXTREME timeout (1500s/25min) for ALL devices minimal',
            );
          }
        } else {
          if (hasLimit) {
            // Paginated full (5 devices max)
            timeoutDuration = const Duration(seconds: 360); // 6 min
            AppHelpers.debugLog('Using timeout (360s/6min) for paginated FULL');
          } else {
            // ULTRA EXTREME: 70 devices × 70 reg full = ~68 min theoretical
            timeoutDuration = const Duration(seconds: 4800); // 80 min MAX
            AppHelpers.debugLog(
              '🚨🚨🚨  ULTRA EXTREME timeout (4800s/80min) for FULL ALL',
            );
          }
        }
      } else if (type == 'devices_summary') {
        // Summary: just device list without registers (much smaller)
        timeoutDuration = const Duration(seconds: 60);
        AppHelpers.debugLog('Using timeout (60s) for devices_summary');
      } else if (type == 'device' || type == 'registers') {
        // Single device with 70 registers: ~10KB = ~56s theoretical
        timeoutDuration = const Duration(seconds: 90);
        AppHelpers.debugLog(
          'Using timeout (90s) for single device/registers (may have 70 registers)',
        );
      } else {
        timeoutDuration = const Duration(seconds: 90);
        AppHelpers.debugLog('Using default timeout (90s) for read: $type');
      }

      final response = await responseCompleter.future.timeout(
        timeoutDuration,
        onTimeout: () {
          // FIX: Only log timeout if completer hasn't been completed yet
          // If completer already completed, timeout callback shouldn't log error
          if (!responseCompleter.isCompleted) {
            AppHelpers.debugLog(
              'Read command timeout after ${timeoutDuration.inSeconds}s',
            );
          }
          return CommandResponse(
            status: 'error',
            message: 'Response timeout after ${timeoutDuration.inSeconds}s',
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

        // Clear warning message after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          errorMessage.value = '';
        });
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

  Future<void> startDataStream(
    String type,
    String deviceId, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (commandChar == null || responseChar == null) {
      errorMessage.value = 'Not connected';
      return;
    }

    // Prevent multiple streams - stop previous stream if active
    if (isStreaming.value) {
      AppHelpers.debugLog(
        'Stream already active, stopping previous stream first',
      );
      await stopDataStream(currentStreamType.value);
    }

    final startCommand = {"op": "read", "type": type, "device_id": deviceId};
    commandLoading.value = true;
    isStreaming.value = true;
    currentStreamType.value = type;
    currentStreamDeviceId.value = deviceId;

    try {
      // Setup continuous listener BEFORE sending command
      responseSubscription?.cancel(); // Cancel jika ada sebelumnya
      StringBuffer streamBuffer = StringBuffer();
      bool streamActive = true;

      // Setup timeout - will be reset on each data received
      _streamTimeout = Timer(timeout, () {
        if (streamActive) {
          AppHelpers.debugLog(
            '⚠️ Stream timeout after ${timeout.inSeconds}s - no data received',
          );
          responseSubscription?.cancel();
          streamedData.clear();
          errorMessage.value = 'Stream timeout after ${timeout.inSeconds}s';
          streamActive = false;
          isStreaming.value = false;
        }
      });

      responseSubscription = responseChar!.lastValueStream.listen((data) {
        // Reset timeout on each data received
        _streamTimeout?.cancel();
        if (streamActive) {
          _streamTimeout = Timer(timeout, () {
            if (streamActive) {
              AppHelpers.debugLog('⚠️ Stream inactive timeout - no new data');
              responseSubscription?.cancel();
              errorMessage.value = 'Stream inactive - no new data';
              streamActive = false;
              isStreaming.value = false;
            }
          });
        }

        final chunk = utf8.decode(data, allowMalformed: true);
        AppHelpers.debugLog('Realtime chunk received: $chunk');

        // FIX: Check buffer size BEFORE writing to prevent overflow
        if (streamBuffer.length + chunk.length > maxBufferSize) {
          AppHelpers.debugLog(
            '⚠️ Buffer would overflow (current: ${streamBuffer.length}, chunk: ${chunk.length}), clearing buffer',
          );
          streamBuffer.clear();
          errorMessage.value = 'Buffer overflow - data stream too large';
          return;
        }

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
              // Validate partial data size before keeping
              if (parts.last.length > maxPartialSize) {
                AppHelpers.debugLog(
                  '⚠️ Partial data too large (${parts.last.length} bytes), discarding',
                );
              } else {
                streamBuffer.write(parts.last);
                AppHelpers.debugLog(
                  'Keeping partial data for next chunk: ${parts.last.substring(0, parts.last.length > 30 ? 30 : parts.last.length)}...',
                );
              }
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
      AppHelpers.debugLog('Error starting stream: $e');

      // Cleanup on error
      _streamTimeout?.cancel();
      responseSubscription?.cancel();
      responseSubscription = null;
      streamedData.clear();
      isStreaming.value = false;
      currentStreamType.value = '';
      currentStreamDeviceId.value = '';

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

  /// Helper method to send BLE command manually without subscription management
  /// Used by streaming methods to avoid subscription conflicts
  Future<void> _sendCommandManually(Map<String, dynamic> command) async {
    if (commandChar == null) {
      throw Exception('Command characteristic is null');
    }

    final jsonStr = jsonEncode(command);
    AppHelpers.debugLog('Sending manual command: $jsonStr');

    final bool useWriteWithResponse =
        !(commandChar?.properties.writeWithoutResponse ?? false);

    // Send command in chunks
    for (int i = 0; i < jsonStr.length; i += bleChunkSize) {
      String chunk = jsonStr.substring(
        i,
        (i + bleChunkSize > jsonStr.length) ? jsonStr.length : i + bleChunkSize,
      );
      await commandChar!.write(
        utf8.encode(chunk),
        withoutResponse: !useWriteWithResponse,
      );
      AppHelpers.debugLog('Sent chunk: $chunk');
      await Future.delayed(const Duration(milliseconds: 50));
    }

    // Send END delimiter
    await Future.delayed(endDelimiterDelay);
    await commandChar!.write(
      utf8.encode('<END>'),
      withoutResponse: !useWriteWithResponse,
    );
    AppHelpers.debugLog('Sent chunk: <END>');
  }

  Future<void> stopDataStream(String type) async {
    try {
      // Cancel timeout first
      _streamTimeout?.cancel();

      // Send stop command FIRST before canceling subscription
      if (commandChar != null) {
        final stopCommand = {"op": "read", "type": type, "device_id": "stop"};
        await _sendCommandManually(stopCommand);

        // Wait for device to process stop command
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // THEN cancel subscription and clear data
      responseSubscription?.cancel();
      responseSubscription = null;
      streamedData.clear();

      // Reset streaming state
      isStreaming.value = false;
      currentStreamType.value = '';
      currentStreamDeviceId.value = '';

      AppHelpers.debugLog('Stream stopped successfully');
    } catch (e) {
      AppHelpers.debugLog('Error stopping stream: $e');

      // Ensure cleanup even on error
      _streamTimeout?.cancel();
      responseSubscription?.cancel();
      responseSubscription = null;
      streamedData.clear();
      isStreaming.value = false;
      currentStreamType.value = '';
      currentStreamDeviceId.value = '';
    }
  }

  // Function baru untuk enhanced streaming dengan device tracking
  Future<void> startStreamDevice(
    String type,
    String deviceId, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (commandChar == null || responseChar == null) {
      errorMessage.value = 'Not connected';
      return;
    }

    // Prevent multiple streams - stop previous stream if active
    if (isStreaming.value) {
      AppHelpers.debugLog(
        'Enhanced stream already active, stopping previous stream first',
      );
      await stopStreamDevice(currentStreamType.value);
    }

    final startCommand = {"op": "read", "type": type, "device_id": deviceId};
    commandLoading.value = true;
    isStreaming.value = true;
    currentStreamType.value = type;
    currentStreamDeviceId.value = deviceId;

    try {
      // Setup streaming listener yang lebih advanced
      responseSubscription?.cancel();
      StringBuffer streamBuffer = StringBuffer();
      bool streamActive = true;

      // Setup timeout - will be reset on each data received
      _streamTimeout = Timer(timeout, () {
        if (streamActive) {
          AppHelpers.debugLog(
            '⚠️ Enhanced stream timeout after ${timeout.inSeconds}s - no data received',
          );
          responseSubscription?.cancel();
          streamedData.clear();
          errorMessage.value =
              'Enhanced stream timeout after ${timeout.inSeconds}s';
          streamActive = false;
          isStreaming.value = false;
        }
      });

      responseSubscription = responseChar!.lastValueStream.listen((data) {
        // Reset timeout on each data received
        _streamTimeout?.cancel();
        if (streamActive) {
          _streamTimeout = Timer(timeout, () {
            if (streamActive) {
              AppHelpers.debugLog(
                '⚠️ Enhanced stream inactive timeout - no new data',
              );
              responseSubscription?.cancel();
              errorMessage.value = 'Enhanced stream inactive - no new data';
              streamActive = false;
              isStreaming.value = false;
            }
          });
        }

        final chunk = utf8.decode(data, allowMalformed: true);
        AppHelpers.debugLog(
          'Stream chunk received for device $deviceId: $chunk',
        );

        // FIX: Check buffer size BEFORE writing to prevent overflow
        if (streamBuffer.length + chunk.length > maxBufferSize) {
          AppHelpers.debugLog(
            '⚠️ Enhanced stream buffer would overflow (current: ${streamBuffer.length}, chunk: ${chunk.length}), clearing buffer',
          );
          streamBuffer.clear();
          errorMessage.value =
              'Enhanced stream buffer overflow - data stream too large';
          return;
        }

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
              // Validate partial data size before keeping
              if (parts.last.length > maxPartialSize) {
                AppHelpers.debugLog(
                  '⚠️ Enhanced stream partial data too large (${parts.last.length} bytes), discarding',
                );
              } else {
                streamBuffer.write(parts.last);
                AppHelpers.debugLog(
                  'Keeping partial data for next chunk: ${parts.last.substring(0, parts.last.length > 30 ? 30 : parts.last.length)}...',
                );
              }
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
      AppHelpers.debugLog('Error starting enhanced stream: $e');

      // Cleanup on error
      _streamTimeout?.cancel();
      responseSubscription?.cancel();
      responseSubscription = null;
      streamedData.clear();
      isStreaming.value = false;
      currentStreamType.value = '';
      currentStreamDeviceId.value = '';

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
    try {
      // Cancel timeout first
      _streamTimeout?.cancel();

      // Send stop command manually FIRST (avoid sendCommand subscription conflict)
      if (commandChar != null) {
        final stopCommand = {"op": "read", "type": type, "device_id": "stop"};
        await _sendCommandManually(stopCommand);

        // Wait for device to process stop command
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // THEN cancel subscription and clear data
      responseSubscription?.cancel();
      responseSubscription = null;
      streamedData.clear();

      // Reset streaming state
      isStreaming.value = false;
      currentStreamType.value = '';
      currentStreamDeviceId.value = '';

      AppHelpers.debugLog('Enhanced streaming stopped successfully');
    } catch (e) {
      AppHelpers.debugLog('Error stopping enhanced stream: $e');

      // Ensure cleanup even on error
      _streamTimeout?.cancel();
      responseSubscription?.cancel();
      responseSubscription = null;
      streamedData.clear();
      isStreaming.value = false;
      currentStreamType.value = '';
      currentStreamDeviceId.value = '';
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
    _streamTimeout?.cancel(); // Cancel streaming timeout
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
