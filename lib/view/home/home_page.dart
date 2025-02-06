import 'package:flutter/material.dart';
import 'package:suriota_mobile_gateway/global/widgets/device_card.dart';
import 'package:suriota_mobile_gateway/models/device_dummy.dart';
import 'package:suriota_mobile_gateway/models/device_model.dart';
import 'package:suriota_mobile_gateway/view/device_menu/device_menu.dart';
import 'package:suriota_mobile_gateway/view/sidebar_menu/sidebar_menu.dart';

import '../../constant/app_color.dart';
import '../../constant/font_setup.dart';
import '../../constant/image_asset.dart';
import 'add_device_page.dart';

// ignore: must_be_immutable
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<DeviceModel> deviceList = deviceDummy;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Image.asset(
          ImageAsset.logoSuriota,
          width: 161,
          height: 38,
          fit: BoxFit.contain,
        ),
      ),
      endDrawer: const SideBarMenu(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hallo, Soru👋',
                style: FontFamily.titleLarge,
              ),
              Text(
                'Connecting the device near you',
                style: FontFamily.normal.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 50),
              Text(
                'Device List',
                style: FontFamily.headlineMedium,
              ),
              const SizedBox(height: 10),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: deviceList.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (BuildContext context, int index) {
                  return InkWell(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    DeviceMenuConfigurationPage(
                                      title: 'Suriota Gateway ${index + 1}',
                                    )));
                      },
                      child: DeviceCard(
                        deviceTitle: deviceList[index].deviceTitle,
                        deviceAddress: deviceList[index].deviceAddress,
                        buttonTitle: deviceList[index].isConnected
                            ? 'Disconnect'
                            : 'Connect',
                        colorButton: deviceList[index].isConnected
                            ? AppColor.redColor
                            : AppColor.primaryColor,
                        onPressed: () {},
                      ));
                },
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
      floatingActionButton: _floatingButtonCustom(context),
    );
  }

  Container _floatingButtonCustom(BuildContext context) {
    return Container(
        height: 50,
        width: 130,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: AppColor.primaryColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const AddDevicePage()));
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add_circle,
                size: 20,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Text(
                'Add Device',
                style: FontFamily.titleMedium
                    .copyWith(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ));
  }
}
