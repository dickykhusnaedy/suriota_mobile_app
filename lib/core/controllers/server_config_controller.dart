import 'package:flutter/material.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/controllers/ble_controller.dart';
import 'package:gateway_config/core/utils/app_helpers.dart';
import 'package:gateway_config/core/utils/snackbar_custom.dart';
import 'package:gateway_config/models/device_model.dart';
import 'package:get/get.dart';

class ServerConfigController extends GetxController {
  final RxList<Map<String, dynamic>> dataServer = <Map<String, dynamic>>[].obs;
  final RxBool isFetching = false.obs;

  final BleController bleController = Get.put(BleController());

  Future<void> fetchData(DeviceModel model) async {
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
        type: 'server_config',
      );

      if (response.status == 'ok' || response.status == 'success') {
        dynamic config = response.config;

        if (config is List) {
          dataServer.assignAll(config.cast<Map<String, dynamic>>());
        } else if (config is Map) {
          dataServer.assignAll([config.cast<String, dynamic>()]);
        } else {
          dataServer.clear();
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
          response.message ?? 'Failed to fecth devices',
          AppColor.redColor,
          AppColor.whiteColor,
        );

        dataServer.clear();
      }
    } catch (e) {
      AppHelpers.debugLog('Error fetching server: $e');
      SnackbarCustom.showSnackbar(
        'Error',
        'Failed to fetch devices',
        AppColor.redColor,
        AppColor.whiteColor,
      );
      dataServer.clear();
    } finally {
      isFetching.value = false;
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
        "type": "server_config",
        "config": config,
      };

      AppHelpers.debugLog('Sending update command: $command');

      final response = await bleController.sendCommand(command);

      if (response.status == 'ok' || response.status == 'success') {
        // Update dataServer dengan config baru
        dataServer.assignAll([config]);
        SnackbarCustom.showSnackbar(
          '',
          'Configuration updated successfully',
          Colors.green,
          AppColor.whiteColor,
        );
      } else {
        SnackbarCustom.showSnackbar(
          '',
          response.message ?? 'Failed to update configuration',
          AppColor.redColor,
          AppColor.whiteColor,
        );
      }
    } catch (e) {
      AppHelpers.debugLog('Error updating server config: $e');
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

  Map<String, dynamic> getServerConfig() {
    return dataServer.isNotEmpty ? dataServer[0] : <String, dynamic>{};
  }
}
