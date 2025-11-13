import 'package:flutter/material.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/controllers/ble_controller.dart';
import 'package:gateway_config/core/utils/app_helpers.dart';
import 'package:gateway_config/core/utils/snackbar_custom.dart';
import 'package:gateway_config/models/device_model.dart';
import 'package:get/get.dart';

class LoggingController extends GetxController {
  final RxList<Map<String, dynamic>> dataLogging = <Map<String, dynamic>>[].obs;
  final RxBool isFetching = false.obs;

  bool _isMounted = true;

  final BleController bleController = Get.find<BleController>();

  Future<void> fetchData(DeviceModel model) async {
    if (!_isMounted) return;
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
        type: 'logging_config',
      );

      if (!_isMounted) return;
      if (response.status == 'ok' || response.status == 'success') {
        dynamic config = response.config;

        if (config is List) {
          dataLogging.assignAll(config.cast<Map<String, dynamic>>());
        } else if (config is Map) {
          dataLogging.assignAll([config.cast<String, dynamic>()]);
        } else {
          dataLogging.clear();
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
          response.message ?? 'Failed to fetch logging data',
          AppColor.redColor,
          AppColor.whiteColor,
        );

        dataLogging.clear();
      }
    } catch (e) {
      if (!_isMounted) return;
      AppHelpers.debugLog('Error fetching logging data: $e');
      SnackbarCustom.showSnackbar(
        'Error',
        'Failed to fetch devices',
        AppColor.redColor,
        AppColor.whiteColor,
      );
      dataLogging.clear();
    } finally {
      if (_isMounted) isFetching.value = false;
    }
  }

  Future<void> updateData(
    DeviceModel model,
    Map<String, dynamic> config,
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

      // Buat command sesuai format
      final command = {
        "op": "update",
        "type": "logging_config",
        "config": config,
      };

      AppHelpers.debugLog('Sending update command: $command');

      final response = await bleController.sendCommand(command);

      if (response.status == 'ok' || response.status == 'success') {
        // Update dataLogging dengan config baru
        dataLogging.assignAll([config]);
        SnackbarCustom.showSnackbar(
          '',
          'Logging data updated successfully',
          Colors.green,
          AppColor.whiteColor,
        );
      } else {
        SnackbarCustom.showSnackbar(
          '',
          response.message ?? 'Failed to update logging data',
          AppColor.redColor,
          AppColor.whiteColor,
        );
      }
    } catch (e) {
      AppHelpers.debugLog('Error updating logging data: $e');
      SnackbarCustom.showSnackbar(
        'Error',
        'Failed to update configuration: $e',
        AppColor.redColor,
        AppColor.whiteColor,
      );
    } finally {
      isFetching.value = false;
    }
  }

  void setMounted(bool value) {
    _isMounted = value;
  }

  @override
  void onClose() {
    _isMounted = false;
    super.onClose();
  }
}
