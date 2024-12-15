import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:suriota_mobile_gateway/constant/app_color.dart';
import 'package:suriota_mobile_gateway/controller/bluetooth_controller.dart';
import 'package:suriota_mobile_gateway/global/widgets/device_card.dart';
import 'package:suriota_mobile_gateway/models/device_model.dart';

class BleScanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final BluetoothController bluetoothController =
        Get.put(BluetoothController());

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Add Device'),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: Obx(() {
        if (bluetoothController.isScanning.value) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColor.primaryColor,
            ),
          );
        } else if (bluetoothController.devices.isNotEmpty) {
          return ListView.builder(
            itemCount: bluetoothController.devices.length,
            itemBuilder: (context, index) {
              var device = bluetoothController.devices[index];

              return Obx(() {
                bool isConnected =
                    bluetoothController.connectedDevice.value == device;

                return DeviceCard(
                  deviceTitle:
                      device.name.isNotEmpty ? device.name : 'Unknown Device',
                  deviceAddress: device.id.toString(),
                  buttonTitle: isConnected ? 'Disconnect' : 'Pair',
                  colorButton: isConnected ? Colors.red : AppColor.primaryColor,
                  onPressed: () {
                    if (isConnected) {
                      bluetoothController.disconnectDevice();
                    } else {
                      bluetoothController.connectToDevice(device);
                      bluetoothController.savePairedDevice(DeviceModel(
                          deviceTitle: device.name.isNotEmpty
                              ? device.name
                              : 'Unknown Device',
                          deviceAddress: device.id.toString(),
                          isConnected: true.obs,
                          isAvailable: true.obs));
                    }
                  },
                );
              });
            },
          );
        } else {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('No devices found', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: bluetoothController.scanDevices,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primaryColor,
                  ),
                ),
              ],
            ),
          );
        }
      }),
    );
  }
}
