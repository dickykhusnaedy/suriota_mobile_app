import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:suriota_mobile_gateway/constant/app_color.dart';
import 'package:suriota_mobile_gateway/constant/app_gap.dart';
import 'package:suriota_mobile_gateway/controller/ble_controller.dart';
import 'package:suriota_mobile_gateway/controller/bluetooth_controller.dart';
import 'package:suriota_mobile_gateway/global/utils/text_extension.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_button.dart';
import 'package:suriota_mobile_gateway/global/widgets/device_card.dart';
import 'package:suriota_mobile_gateway/screen/devices/detail_device_screen.dart';

class AddDeviceScreen extends StatefulWidget {
  const AddDeviceScreen({super.key});

  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  final BluetoothController controller = Get.put(BluetoothController());
  final BLEController bleController = Get.put(BLEController());

  bool isBluetoothOn = false;

  @override
  void initState() {
    super.initState();
    _checkBluetoothStatus();
  }

  Future<void> _checkBluetoothStatus() async {
    // Mendengarkan status adapter Bluetooth
    FlutterBluePlus.adapterState.listen((state) {
      setState(() {
        isBluetoothOn = state == BluetoothAdapterState.on;
      });
    });
  }

  Future<void> _checkBluetoothDevice() async {
    if (isBluetoothOn) {
      bleController.scanAndConnect();
    } else {
      Get.snackbar(
        'Bluetooth is off',
        'Please enable Bluetooth to scan devices.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColor.redColor,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(),
      body: SafeArea(
        child: _body(),
      ),
    );
  }

  AppBar _appBar() {
    return AppBar(
      centerTitle: true,
      iconTheme: const IconThemeData(color: Colors.white),
      backgroundColor: AppColor.primaryColor,
      title: Text('Add Device',
          style: context.h5.copyWith(color: AppColor.whiteColor)),
      actions: [
        Obx(() => bleController.devices.isNotEmpty
            ? IconButton(
                onPressed: _checkBluetoothDevice,
                icon: const Icon(
                  Icons.search,
                  size: 24,
                ))
            : const SizedBox.shrink())
      ],
    );
  }

  Container _findDevice(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Find device',
            style: context.h2,
          ),
          AppSpacing.sm,
          Text('Finding nearby devices with\nBluetooth connectivity...',
              textAlign: TextAlign.center,
              style: context.body.copyWith(color: AppColor.grey)),
          AppSpacing.xxxl,
          Button(
              onPressed: _checkBluetoothDevice,
              text: 'Scan',
              icons: const Icon(
                Icons.search,
                color: AppColor.whiteColor,
                size: 23,
              ),
              height: 50,
              width: MediaQuery.of(context).size.width * 0.3),
        ],
      ),
    );
  }

  Container _scanningProgress() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(() {
            if (bleController.isLoading.value) {
              return const CircularProgressIndicator(
                color: AppColor.primaryColor,
              );
            } else {
              return const SizedBox.shrink();
            }
          }),
          AppSpacing.md,
          StreamBuilder<String>(
            stream: bleController.statusStream,
            builder: (context, snapshot) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  snapshot.data ?? "Scanning device...",
                  style: context.body.copyWith(color: AppColor.grey),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Obx _body() {
    return Obx(() {
      if (bleController.isLoading.value) {
        return _scanningProgress();
      } else if (bleController.devices.isEmpty) {
        return _findDevice(context);
      } else {
        return _deviceList();
      }
    });
  }

  Container _deviceList() {
    return Container(
      padding: AppPadding.medium,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSpacing.sm,
          Text('Device List', style: context.h4),
          AppSpacing.sm,
          Expanded(
            child: Obx(() {
              if (bleController.devices.isEmpty) {
                return Container(
                  height: MediaQuery.of(context).size.height * 0.55,
                  alignment: Alignment.center,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'No device found.\nFind device near you.',
                          textAlign: TextAlign.center,
                          style: context.body.copyWith(color: AppColor.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                separatorBuilder: (context, index) => AppSpacing.sm,
                itemCount: bleController.devices.length,
                itemBuilder: (context, index) {
                  final device = bleController.devices[index];
                  final deviceId = device.remoteId.toString();
                  final isConnected = bleController.getConnectionStatus(deviceId);
                  final isLoadingConnection = bleController.getLoadingStatus(deviceId);

                  return InkWell(
                    onTap: () {
                      if(isConnected) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailDeviceScreen(
                              title: device.platformName.isNotEmpty
                            ? device.platformName
                            : "Unknown Device",
                            deviceAddress: device.remoteId.toString(),
                            ),
                          ),
                        );
                      } else {
                        Get.snackbar(
                          '',
                          'Device is not connected, please connect the device first.',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: AppColor.redColor,
                          colorText: Colors.white,
                          duration: const Duration(seconds: 3),
                          margin: const EdgeInsets.all(16),
                          titleText: const SizedBox(),
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
                        );
                      } 
                    },
                    child: DeviceCard(
                      deviceTitle: device.platformName.isNotEmpty
                          ? device.platformName
                          : "Unknown Device",
                      deviceAddress: device.remoteId.toString(),
                      buttonTitle: isLoadingConnection
                        ? "Loading..." // Tampilkan loading jika sedang menghubungkan
                        : isConnected
                            ? 'Disconnect'
                            : 'Connect',
                      colorButton: isConnected
                          ? AppColor.redColor
                          : AppColor.primaryColor,
                      onPressed: () async {
                        if (isLoadingConnection) return;

                        if (isConnected) {
                          await bleController.disconnectDevice(device);
                        } else {
                          await bleController.connectToDevice(device);
                        }
                      },
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
