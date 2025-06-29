import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:suriota_mobile_gateway/core/constants/app_color.dart';
import 'package:suriota_mobile_gateway/core/utils/snackbar_custom.dart';
import 'package:suriota_mobile_gateway/presentation/widgets/spesific/device_card.dart';
import 'package:suriota_mobile_gateway/presentation/pages/devices/detail_device_screen.dart';

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
    return InkWell(
      onTap: () {
        if (!isConnected) {
          SnackbarCustom.showSnackbar(
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
