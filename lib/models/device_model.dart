import 'package:flutter_blue/flutter_blue.dart';
import 'package:get/get.dart';
import 'package:get/get_connect/http/src/utils/utils.dart';
import 'package:suriota_mobile_gateway/view/home/home_page.dart';

class DeviceModel {
  final String deviceTitle;
  final String deviceAddress;
  final FlutterBlue ble; // Tidak dapat disimpan langsung, perlu solusi khusus
  RxBool isConnected;
  RxBool isAvailable;

  DeviceModel({
    required this.deviceTitle,
    required this.deviceAddress,
    required this.ble,
    required this.isConnected,
    required this.isAvailable,
  });

  // Konversi ke Map (untuk JSON)
  Map<String, dynamic> toJson() {
    return {
      'deviceTitle': deviceTitle,
      'deviceAddress': deviceAddress,
      'isConnected': isConnected.value, // Konversi RxBool ke bool
      'isAvailable': isAvailable.value, // Konversi RxBool ke bool
    };
  }

  // Membuat instance dari Map (JSON)
  factory DeviceModel.fromJson(Map<String, dynamic> json, FlutterBlue ble) {
    return DeviceModel(
      deviceTitle: json['deviceTitle'],
      deviceAddress: json['deviceAddress'],
      ble: ble, // Inisialisasi dengan instance yang sudah ada
      isConnected: (json['isConnected'] as bool).obs, // Konversi bool ke RxBool
      isAvailable: (json['isAvailable'] as bool).obs, // Konversi bool ke RxBool
    );
  }
}
