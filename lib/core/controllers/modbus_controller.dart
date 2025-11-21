import 'package:flutter/material.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/controllers/ble_controller.dart';
import 'package:gateway_config/core/utils/app_helpers.dart';
import 'package:gateway_config/core/utils/snackbar_custom.dart';
import 'package:gateway_config/models/device_model.dart';
import 'package:get/get.dart';

class ModbusController extends GetxController {
  final RxList<Map<String, dynamic>> dataModbus = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> selectedModbus =
      <Map<String, dynamic>>[].obs;
  final RxBool isFetching = false.obs;

  // Smart cache functionality
  var lastFetchTime = Rxn<DateTime>();
  final cacheDuration = const Duration(minutes: 5);

  final BleController bleController = Get.find<BleController>();

  // Smart cache: Check if cached data is still fresh
  bool get isDataFresh {
    if (lastFetchTime.value == null) return false;
    return DateTime.now().difference(lastFetchTime.value!) < cacheDuration;
  }

  // Smart fetch: Only fetch if cache is empty or stale or data updated
  Future<void> fetchDevicesIfNeeded(DeviceModel model, String deviceId) async {
    // Check if device data has been updated
    final hasUpdate = model.updatedAt.value != null;

    if (dataModbus.isEmpty || !isDataFresh || hasUpdate) {
      final reason = dataModbus.isEmpty
          ? "empty"
          : hasUpdate
              ? "data updated"
              : "stale";
      AppHelpers.debugLog(
        'Cache is $reason, fetching fresh modbus data...',
      );
      await fetchDevices(model, deviceId);

      // Reset updatedAt after fetch
      if (hasUpdate) {
        model.updatedAt.value = null;
      }
    } else {
      final cacheAge = DateTime.now().difference(lastFetchTime.value!);
      AppHelpers.debugLog(
        'Using cached modbus data (${dataModbus.length} registers, age: ${cacheAge.inMinutes}m ${cacheAge.inSeconds % 60}s)',
      );
    }
  }

  Future<void> fetchDevices(DeviceModel model, String deviceId) async {
    isFetching.value = true;

    try {
      if (!model.isConnected.value) {
        SnackbarCustom.showSnackbar(
          '',
          'Device not connected',
          AppColor.redColor,
          AppColor.whiteColor,
        );
        return;
      }

      final response = await bleController.readCommandResponse(
        model,
        type: 'registers_summary',
        additionalParams: {'device_id': deviceId, 'minimal': true},
      );

      if (response.status == 'ok' || response.status == 'success') {
        dataModbus.assignAll(
          (response.config as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
              [],
        );

        // Update cache timestamp
        lastFetchTime.value = DateTime.now();

        AppHelpers.debugLog(
          'Modbus registers fetched successfully: ${dataModbus.length} registers found',
        );
      } else {
        SnackbarCustom.showSnackbar(
          '',
          response.message ?? 'Failed to fecth devices',
          AppColor.redColor,
          AppColor.whiteColor,
        );

        dataModbus.clear();
      }
    } catch (e) {
      AppHelpers.debugLog('Error fetching data modbus: $e');
      SnackbarCustom.showSnackbar(
        'Error',
        'Failed to fetch devices',
        AppColor.redColor,
        AppColor.whiteColor,
      );
      dataModbus.clear();
    } finally {
      isFetching.value = false;
    }
  }

  Future<void> getDeviceById(
    DeviceModel model,
    String deviceId,
    String registerId,
  ) async {
    isFetching.value = true;

    try {
      if (!model.isConnected.value) {
        SnackbarCustom.showSnackbar(
          '',
          'Device not connected',
          AppColor.redColor,
          AppColor.whiteColor,
        );
        return;
      }

      final response = await bleController.readCommandResponse(
        model,
        type: 'registers',
        additionalParams: {'device_id': deviceId},
      );

      if (response.status == 'ok' || response.status == 'success') {
        dynamic config = response.config;

        if (config is List) {
          final dataModbus = config.firstWhere((item) {
            final id = item['register_id'];
            return id?.toString() == registerId.toString();
          }, orElse: () => {});

          selectedModbus.assignAll([Map<String, dynamic>.from(dataModbus)]);
        } else if (config is Map) {
          selectedModbus.assignAll([config.cast<String, dynamic>()]);
        } else {
          selectedModbus.clear();
          SnackbarCustom.showSnackbar(
            '',
            'Invalid config format',
            AppColor.redColor,
            AppColor.whiteColor,
          );
        }
      } else {
        SnackbarCustom.showSnackbar(
          '',
          response.message ?? 'Failed to fetch register with ID: $registerId',
          AppColor.redColor,
          AppColor.whiteColor,
        );

        selectedModbus.clear();
      }
    } catch (e) {
      AppHelpers.debugLog('Error getting device by ID: $e');
      SnackbarCustom.showSnackbar(
        'Error',
        'Failed to fetch modbus with ID: $registerId',
        AppColor.redColor,
        AppColor.whiteColor,
      );

      selectedModbus.clear();
    } finally {
      isFetching.value = false;
    }
  }

  Future<void> deleteDevice(
    DeviceModel model,
    String deviceId,
    String registerId,
  ) async {
    isFetching.value = true;

    try {
      final command = {
        "op": "delete",
        "type": "register",
        "device_id": deviceId,
        "register_id": registerId,
      };

      final response = await bleController.sendCommand(command);

      if (response.status == 'ok' || response.status == 'success') {
        // Trigger fetch with updatedAt
        model.updatedAt.value = DateTime.now();

        SnackbarCustom.showSnackbar(
          '',
          'Register deleted successfully',
          Colors.green,
          AppColor.whiteColor,
        );
      } else {
        SnackbarCustom.showSnackbar(
          '',
          response.message ?? 'Failed to delete data modbus',
          AppColor.redColor,
          AppColor.whiteColor,
        );
      }
    } catch (e) {
      AppHelpers.debugLog('Error deleting data modbus: $e');
      SnackbarCustom.showSnackbar(
        'Error',
        'Failed to delete device',
        AppColor.redColor,
        AppColor.whiteColor,
      );
    } finally {
      isFetching.value = false;
    }
  }
}
