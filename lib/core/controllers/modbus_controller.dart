import 'package:flutter/material.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/controllers/ble_controller.dart';
import 'package:gateway_config/core/utils/app_helpers.dart';
import 'package:gateway_config/core/utils/snackbar_custom.dart';
import 'package:gateway_config/models/device_model.dart';
import 'package:get/get.dart';

class ModbusController extends GetxController {
  final RxList<Map<String, dynamic>> dataModbus = <Map<String, dynamic>>[].obs;
  final Rx<Map<String, dynamic>?> selectedModbusData =
      Rx<Map<String, dynamic>?>(null);
  final RxBool isFetching = false.obs;

  final BleController bleController = Get.put(BleController());

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
        additionalParams: {'device_id': deviceId},
      );

      if (response.status == 'ok' || response.status == 'success') {
        dataModbus.assignAll(
          (response.config as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
              [],
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
        SnackbarCustom.showSnackbar(
          '',
          'Device deleted successfully',
          Colors.green,
          AppColor.whiteColor,
        );

        await Future.delayed(const Duration(seconds: 3));
        await fetchDevices(model, deviceId);
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
