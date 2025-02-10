import 'package:flutter/material.dart';
import 'package:suriota_mobile_gateway/constant/app_color.dart';
import 'package:suriota_mobile_gateway/constant/app_gap.dart';
import 'package:suriota_mobile_gateway/global/utils/text_extension.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_button.dart';
import 'package:suriota_mobile_gateway/models/device_dummy.dart';
import 'package:suriota_mobile_gateway/models/device_model.dart';

class AddDevicePage extends StatefulWidget {
  const AddDevicePage({super.key});

  @override
  State<AddDevicePage> createState() => _AddDevicePageState();
}

class _AddDevicePageState extends State<AddDevicePage> {
  List<DeviceModel> deviceList = deviceDummy;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: _appBar(),
        body: SingleChildScrollView(
          padding: AppPadding.horizontalMedium,
          child: _findDevice(context),
        ));
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
      height: MediaQuery.of(context).size.height,
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
              onPressed: () {},
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
}
