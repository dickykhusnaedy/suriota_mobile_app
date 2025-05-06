import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:suriota_mobile_gateway/constant/app_color.dart';
import 'package:suriota_mobile_gateway/controller/ble_controller.dart';
import 'package:suriota_mobile_gateway/global/widgets/device_card.dart';
import 'package:suriota_mobile_gateway/screen/devices/detail_device_screen.dart';

class DeviceListWidget extends StatelessWidget {
  final BluetoothDevice device;
  final bool isConnected;
  final bool isLoadingConnection;
  final VoidCallback onDisconnect;
  final VoidCallback onConnect;

  const DeviceListWidget({
    super.key,
    required this.device,
    required this.isConnected,
    required this.isLoadingConnection,
    required this.onConnect,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    final BLEController bleController = Get.put(BLEController());

    return InkWell(
      onTap: () {
        if (!isConnected) {
          bleController.showSnackbar(
              '',
              'Device is not connected, please connect the device first.',
              AppColor.redColor,
              AppColor.whiteColor);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailDeviceScreen(device: device),
            ),
          );
        }
      },
      child: DeviceCard(
        deviceTitle:
            device.platformName.isNotEmpty ? device.platformName : "N/A",
        deviceAddress: device.remoteId.toString(),
        buttonTitle: isLoadingConnection
            ? "Connecting..."
            : isConnected
                ? 'Disconnect'
                : 'Connect',
        colorButton: isConnected ? AppColor.redColor : AppColor.primaryColor,
        onPressed: isConnected ? onDisconnect : onConnect,
      ),
    );
  }
}
