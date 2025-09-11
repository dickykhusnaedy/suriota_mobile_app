import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/constants/app_gap.dart';
import 'package:gateway_config/core/controllers/ble/ble_controller.dart';
import 'package:gateway_config/core/controllers/ble_controller.dart';
import 'package:gateway_config/core/utils/app_helpers.dart';
import 'package:gateway_config/core/utils/extensions.dart';
import 'package:gateway_config/core/utils/snackbar_custom.dart';
import 'package:gateway_config/presentation/pages/devices/widgets/device_list_widget.dart';
import 'package:gateway_config/presentation/widgets/common/custom_alert_dialog.dart';
import 'package:gateway_config/presentation/widgets/common/custom_button.dart';
import 'package:get/get.dart';

class AddDeviceScreen extends StatefulWidget {
  const AddDeviceScreen({super.key});

  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  final BLEController bleController = Get.put(BLEController());
  final controller = Get.put(BleController());

  bool isBluetoothOn = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkBluetoothStatus();
  }

  void disconnect(BluetoothDevice device) async {
    CustomAlertDialog.show(
      title: "Disconnect Device",
      message:
          "Are you sure you want to disconnect from ${device.platformName}?",
      primaryButtonText: 'Yes',
      secondaryButtonText: 'No',
      onPrimaryPressed: () async {
        Get.back();
        await Future.delayed(Duration.zero);

        setState(() {
          isLoading = true;
        });

        try {
          await bleController.disconnectDevice(device);
        } catch (e) {
          AppHelpers.debugLog('Error disconnecting from device: $e');
          Get.snackbar(
            'Error',
            'Failed to disconnect from device',
            backgroundColor: AppColor.redColor,
            colorText: AppColor.whiteColor,
          );
        } finally {
          setState(() {
            isLoading = false;
          });
        }
      },
      barrierDismissible: false,
    );
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
      controller.startScan();
    } else {
      SnackbarCustom.showSnackbar(
        'Bluetooth is off',
        'Please enable Bluetooth to scan devices.',
        AppColor.redColor,
        AppColor.whiteColor,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: _appBar(),
          body: SafeArea(child: SingleChildScrollView(child: _body())),
        ),
        // Obx(() {
        //   return LoadingOverlay(
        //     isLoading: controller.isLoading.value,
        //     message: "Connecting device...",
        //   );
        // }),
      ],
    );
  }

  AppBar _appBar() {
    return AppBar(
      centerTitle: true,
      iconTheme: const IconThemeData(color: Colors.white),
      backgroundColor: AppColor.primaryColor,
      title: Text(
        'Add Device',
        style: context.h5.copyWith(color: AppColor.whiteColor),
      ),
      actions: [
        Obx(
          () =>
              controller.scannedDevices.isNotEmpty &&
                  !controller.isLoading.value
              ? IconButton(
                  onPressed: _checkBluetoothDevice,
                  icon: const Icon(Icons.search, size: 24),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Obx _body() {
    return Obx(() {
      if (controller.isLoading.value) {
        return _scanningProgress();
      } else if (controller.scannedDevices.isEmpty) {
        return _findDevice(context);
      } else {
        return _deviceList();
      }
    });
  }

  Container _findDevice(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Find device', style: context.h2),
          AppSpacing.sm,
          Text(
            'Finding nearby devices with\nBluetooth connectivity...',
            textAlign: TextAlign.center,
            style: context.body.copyWith(color: AppColor.grey),
          ),
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
            width: MediaQuery.of(context).size.width * 0.3,
          ),
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
            if (controller.isLoading.value) {
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

  Widget _deviceList() {
    return Padding(
      padding: AppPadding.medium,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSpacing.sm,
          Text('Device List', style: context.h4),
          AppSpacing.sm,
          LayoutBuilder(
            builder: (context, constraints) {
              return Obx(() {
                if (controller.scannedDevices.isEmpty) {
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
                  itemCount: controller.scannedDevices.length,
                  itemBuilder: (context, index) {
                    final deviceModel = controller.scannedDevices[index];

                    return Obx(() {
                      return DeviceListWidget(
                        device: deviceModel.device,
                        isConnected: deviceModel.device.isConnected,
                        isLoadingConnection:
                            deviceModel.isLoadingConnection.value,
                        onConnect: () async {
                          if (!deviceModel.device.isConnected) {
                            await controller.connectToDevice(
                              deviceModel,
                            ); // Call connectToDevice from BleController
                          }
                        },
                        onDisconnect: () async {
                          if (deviceModel.device.isConnected) {
                            controller.disconnectFromDevice(deviceModel);
                          }
                        },
                      );
                    });
                  },
                );
              });
            },
          ),
          AppSpacing.md,
          Center(
            child: Text(
              'A total of ${controller.scannedDevices.length} devices were successfully discovered.',
              style: context.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
