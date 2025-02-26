import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:suriota_mobile_gateway/constant/app_color.dart';
import 'package:suriota_mobile_gateway/constant/app_gap.dart';
import 'package:suriota_mobile_gateway/controller/bluetooth_controller.dart';
import 'package:suriota_mobile_gateway/global/utils/text_extension.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_button.dart';
import 'package:suriota_mobile_gateway/global/widgets/device_card.dart';
import 'package:suriota_mobile_gateway/models/device_dummy.dart';
import 'package:suriota_mobile_gateway/models/device_model.dart';
import 'package:suriota_mobile_gateway/screen/devices/detail_device_screen.dart';

class AddDeviceScreen extends StatefulWidget {
  const AddDeviceScreen({super.key});

  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  final BluetoothController controller = Get.put(BluetoothController());
  List<DeviceModel> deviceList = deviceDummy;

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
              onPressed: controller.startScan,
              text: 'Search devices',
              icons: const Icon(
                Icons.search,
                color: AppColor.whiteColor,
                size: 23,
              ),
              height: 50,
              width: MediaQuery.of(context).size.width * 0.5)
        ],
      ),
    );
  }

  Obx _body() {
    return Obx(() => controller.devices.isEmpty
        ? _findDevice(context)
        : Padding(
            padding: AppPadding.screenPadding,
            child: _deviceList(),
          ));
  }

  Column _deviceList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSpacing.sm,
        Text('Device List', style: context.h4),
        AppSpacing.sm,
        Expanded(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            separatorBuilder: (context, index) => AppSpacing.sm,
            itemCount: controller.devices.length,
            itemBuilder: (context, index) {
              final device = controller.devices[index];
              return InkWell(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => DetailDeviceScreen(
                                title: 'Suriota Gateway ${index + 1}',
                              )));
                },
                child: DeviceCard(
                  deviceTitle: device.platformName.isNotEmpty
                      ? device.platformName
                      : "Unknown Device",
                  deviceAddress: device.remoteId.toString(),
                  buttonTitle:
                      deviceList[index].isConnected ? 'Disconnect' : 'Connect',
                  colorButton: deviceList[index].isConnected
                      ? AppColor.redColor
                      : AppColor.primaryColor,
                  onPressed: () {},
                ),
              );
            },
          ),
        )
      ],
    );
  }
}
