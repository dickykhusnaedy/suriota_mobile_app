import 'package:flutter/material.dart';
import 'package:suriota_mobile_gateway/constant/app_gap.dart';
import 'package:suriota_mobile_gateway/global/utils/text_extension.dart';
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
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColor.whiteColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: SizedBox(
          width: screenWidth * (screenWidth <= 600 ? 0.4 : 0.2),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.asset(
              ImageAsset.logoSuriota,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppPadding.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hallo, Soru👋', style: context.h1),
              AppSpacing.xs,
              Text('Connecting the device near you', style: context.body),
              AppSpacing.xxl,
              Text('Device List', style: context.h4),
              AppSpacing.sm,
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: deviceList.length,
                separatorBuilder: (context, index) => AppSpacing.sm,
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
              AppSpacing.xxl,
            ],
          ),
        ),
      ),
      endDrawer: const SideBarMenu(),
      floatingActionButton: _floatingButtonCustom(context),
    );
  }

  Container _floatingButtonCustom(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Container(
        width: screenWidth * (screenWidth < 600 ? 0.3 : 0.15),
        height: 50,
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
              AppSpacing.sm,
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
