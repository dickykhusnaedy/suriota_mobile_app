import 'package:get/get.dart';
import 'package:get/get_connect/http/src/utils/utils.dart';
import 'package:suriota_mobile_gateway/view/home/home_page.dart';

class DeviceModel {
  final String deviceTitle;
  final String deviceAddress;
  RxBool deviceStatus = true.obs;
  DeviceModel(
      {required this.deviceAddress,
      required this.deviceTitle,
      required this.deviceStatus });
}

