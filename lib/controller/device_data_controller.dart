import 'package:get/get.dart';

class DeviceDataController extends GetxController {
  final RxMap<String, dynamic> singleDevice = <String, dynamic>{}.obs;

  void setSingleDevice(Map<String, dynamic> data) {
    singleDevice.assignAll(data);
  }

  void clearDevice() {
    singleDevice.clear();
  }
}
