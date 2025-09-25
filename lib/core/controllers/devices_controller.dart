import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/controllers/ble_controller.dart';
import 'package:gateway_config/core/utils/app_helpers.dart';
import 'package:gateway_config/core/utils/snackbar_custom.dart';
import 'package:gateway_config/models/device_model.dart';
import 'package:get/get.dart';

class DevicesController extends GetxController {
  final RxList<Map<String, dynamic>> dataDevices = <Map<String, dynamic>>[].obs;
  final RxBool isFetching = false.obs;

  final BleController bleController = Get.put(BleController());

  Future<void> fetchDevices(DeviceModel model) async {
    try {
      isFetching.value = true;

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
        type: 'devices_summary',
      );

      if (response.status == 'ok' || response.status == 'success') {
        dataDevices.assignAll(
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

  Map<String, dynamic>? getDeviceById(String deviceId) {
    try {
      final device = dataDevices.firstWhere(
        (device) => device['device_id'] == deviceId,
        orElse: () => <String, dynamic>{},
      );

      return device.isNotEmpty ? device : null;
    } catch (e) {
      AppHelpers.debugLog('Error finding device by ID: $e');
      SnackbarCustom.showSnackbar(
        '',
        'Failed to find device with ID: $deviceId',
        AppColor.redColor,
        AppColor.whiteColor,
      );
      return null;
    }
  }
}
