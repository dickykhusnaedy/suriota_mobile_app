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
        type: 'server_config',
      );

      if (!_isMounted) return;

      if (response.status == 'ok' || response.status == 'success') {
        final config = response.config;

        /// 🔥 Recursive sanitizer tanpa .map() / .cast()
        dynamic sanitize(dynamic data) {
          if (data is Map) {
            final result = <String, dynamic>{};
            for (final entry in data.entries) {
              final key = entry.key?.toString() ?? 'null';
              result[key] = sanitize(entry.value);
            }
            return result;
          } else if (data is List) {
            return data.map((item) => sanitize(item)).toList();
          }
          return data;
        }

        try {
          if (config is List) {
            // Jangan pakai .map().toList(), kita loop manual
            final safeList = <Map<String, dynamic>>[];
            for (final item in config) {
              if (item is Map) {
                safeList.add(sanitize(item));
              }
            }
            dataServer.assignAll(safeList);
            AppHelpers.debugLog(
              '✅ Config parsed safely (list) ${safeList.length}',
            );
          } else if (config is Map) {
            final safeMap = sanitize(config);
            dataServer.assignAll([safeMap]);
            AppHelpers.debugLog('✅ Config parsed safely (map)');
          } else {
            dataServer.clear();
            SnackbarCustom.showSnackbar(
              '',
              'Invalid config type: ${config.runtimeType}',
              AppColor.redColor,
              AppColor.whiteColor,
            );
            AppHelpers.debugLog(
              '⚠️ Invalid config type: ${config.runtimeType}',
            );
          }
        } catch (err) {
          AppHelpers.debugLog('❌ Error parsing config: $err');
          dataServer.clear();
          SnackbarCustom.showSnackbar(
            '',
            'Invalid config format: $err',
            AppColor.redColor,
            AppColor.whiteColor,
          );
        }
      } else {
        SnackbarCustom.showSnackbar(
          '',
          response.message ?? 'Failed to fetch devices',
          AppColor.redColor,
          AppColor.whiteColor,
        );
        dataServer.clear();
      }
    } catch (e) {
      if (!_isMounted) return;
      AppHelpers.debugLog('❌ Error fetching server: $e');
      SnackbarCustom.showSnackbar(
        'Error',
        'Failed to fetch devices: $e',
        AppColor.redColor,
        AppColor.whiteColor,
      );
      dataServer.clear();
    } finally {
      if (_isMounted) isFetching.value = false;
    }
  }

  void setMounted(bool value) {
    _isMounted = value;
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

  @override
  void onClose() {
    _isMounted = false;
    super.onClose();
  }
}
