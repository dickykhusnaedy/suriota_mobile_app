import 'package:gateway_config/core/controllers/ble_controller.dart';
import 'package:get/get.dart';

class ServerConfigController extends GetxController {
  final RxBool isFetching = false.obs;

  final BleController bleController = Get.put(BleController());
}