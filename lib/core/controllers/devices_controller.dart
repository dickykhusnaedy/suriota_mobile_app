import 'package:flutter/material.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/controllers/ble_controller.dart';
import 'package:gateway_config/core/utils/app_helpers.dart';
import 'package:gateway_config/core/utils/snackbar_custom.dart';
import 'package:gateway_config/models/device_model.dart';
import 'package:get/get.dart';

class DevicesController extends GetxController {
  final RxList<Map<String, dynamic>> dataDevices = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> selectedDevice =
      <Map<String, dynamic>>[].obs;

  final RxBool isFetching = false.obs;

  final BleController bleController = Get.put(BleController());

  Future<void> fetchDevices(DeviceModel model, {int retryCount = 0}) async {
    isFetching.value = true;

    try {
      // Retry logic untuk handle timing issue (max 3 retry dengan 500ms delay)
      if (!model.isConnected.value) {
        if (retryCount < 3) {
          AppHelpers.debugLog(
            'Device not connected yet, retrying... (attempt ${retryCount + 1}/3)',
          );
          isFetching.value = false;
          await Future.delayed(const Duration(milliseconds: 500));
          return fetchDevices(model, retryCount: retryCount + 1);
        }

        // Setelah 3 retry tetap gagal, tampilkan error
        SnackbarCustom.showSnackbar(
          '',
          'Device not connected',
          AppColor.redColor,
          AppColor.whiteColor,
        );
        return;
      }

      AppHelpers.debugLog(
        'Fetching devices for ${model.device.remoteId}, isConnected: ${model.isConnected.value}',
      );

      final response = await bleController.readCommandResponse(
        model,
        type: 'devices_summary',
      );

      if (response.status == 'ok' || response.status == 'success') {
        dataDevices.assignAll(
          (response.config as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
              [],
        );

        AppHelpers.debugLog(
          'Devices fetched successfully: ${dataDevices.length} devices found',
        );
      } else {
        SnackbarCustom.showSnackbar(
          '',
          response.message ?? 'Failed to fecth devices',
          AppColor.redColor,
          AppColor.whiteColor,
        );

        dataDevices.clear();
      }
    } catch (e) {
      AppHelpers.debugLog('Error fetching devices: $e');
      SnackbarCustom.showSnackbar(
        'Error',
        'Failed to fetch devices',
        AppColor.redColor,
        AppColor.whiteColor,
      );
      dataDevices.clear();
    } finally {
      isFetching.value = false;
    }
  }

  Future<void> getDeviceById(
    DeviceModel model,
    String deviceId, {
    int retryCount = 0,
  }) async {
    isFetching.value = true;

    try {
      // Retry logic untuk handle timing issue (max 3 retry dengan 500ms delay)
      if (!model.isConnected.value) {
        if (retryCount < 3) {
          AppHelpers.debugLog(
            'Device not connected yet, retrying getDeviceById... (attempt ${retryCount + 1}/3)',
          );
          isFetching.value = false;
          await Future.delayed(const Duration(milliseconds: 500));
          return getDeviceById(model, deviceId, retryCount: retryCount + 1);
        }

        // Setelah 3 retry tetap gagal, tampilkan error
        SnackbarCustom.showSnackbar(
          '',
          'Device not connected',
          AppColor.redColor,
          AppColor.whiteColor,
        );
        return;
      }

      AppHelpers.debugLog(
        'Getting device by ID: $deviceId, isConnected: ${model.isConnected.value}',
      );

      final response = await bleController.readCommandResponse(
        model,
        type: 'device',
        additionalParams: {'device_id': deviceId},
      );

      if (response.status == 'ok' || response.status == 'success') {
        dynamic config = response.config;

        if (config is List) {
          selectedDevice.assignAll(config.cast<Map<String, dynamic>>());
          AppHelpers.debugLog(
            'Device fetched successfully: $deviceId (${selectedDevice.length} items)',
          );
        } else if (config is Map) {
          selectedDevice.assignAll([config.cast<String, dynamic>()]);
          AppHelpers.debugLog(
            'Device fetched successfully: $deviceId (1 item)',
          );
        } else {
          selectedDevice.clear();
          AppHelpers.debugLog(
            'Invalid config format for device: $deviceId, type: ${config.runtimeType}',
          );
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
          response.message ?? 'Failed to fetch device with ID: $deviceId',
          AppColor.redColor,
          AppColor.whiteColor,
        );

        selectedDevice.clear();
      }
    } catch (e) {
      AppHelpers.debugLog('Error getting device by ID: $e');
      SnackbarCustom.showSnackbar(
        'Error',
        'Failed to fetch device with ID: $deviceId',
        AppColor.redColor,
        AppColor.whiteColor,
      );

      selectedDevice.clear();
    } finally {
      isFetching.value = false;
    }
  }

  Future<void> deleteDevice(DeviceModel model, String deviceId) async {
    isFetching.value = true;

    try {
      final command = {"op": "delete", "type": "device", "device_id": deviceId};

      final response = await bleController.sendCommand(command);

      if (response.status == 'ok' || response.status == 'success') {
        SnackbarCustom.showSnackbar(
          '',
          'Device deleted successfully',
          Colors.green,
          AppColor.whiteColor,
        );
      } else {
        SnackbarCustom.showSnackbar(
          '',
          response.message ?? 'Failed to delete device',
          AppColor.redColor,
          AppColor.whiteColor,
        );
      }
    } catch (e) {
      AppHelpers.debugLog('Error deleting device: $e');
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
