import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';

class DeviceModel {
  final BluetoothDevice device;
  final RxBool isConnected;
  final RxBool isLoadingConnection;
  final Rx<DateTime?> lastConnectionTime;
  void Function() onConnect;
  void Function() onDisconnect;

  DeviceModel({
    required this.device,
    required this.onConnect,
    required this.onDisconnect,
  }) : isConnected = RxBool(false),
       isLoadingConnection = RxBool(false),
       lastConnectionTime = Rx<DateTime?>(null);
}
