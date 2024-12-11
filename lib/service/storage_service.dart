import 'dart:convert'; // Untuk jsonEncode dan jsonDecode
import 'package:flutter_blue/flutter_blue.dart';
import 'package:get_storage/get_storage.dart';
import 'package:suriota_mobile_gateway/models/device_model.dart';

class StorageService {
  final GetStorage storage = GetStorage();

  // Menyimpan List<DeviceModel>
  void saveDeviceList(List<DeviceModel> devices, String key) {
    List<Map<String, dynamic>> jsonList =
        devices.map((device) => device.toJson()).toList();
    storage.write(key, jsonEncode(jsonList));
  }

  // Membaca List<DeviceModel>
  List<DeviceModel> loadDeviceList(String key, FlutterBlue ble) {
    String? jsonString = storage.read<String>(key);
    if (jsonString != null) {
      List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map(
              (json) => DeviceModel.fromJson(json as Map<String, dynamic>, ble))
          .toList();
    }
    return [];
  }
}
