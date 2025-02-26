import 'package:flutter/material.dart';
import 'package:suriota_mobile_gateway/constant/app_color.dart';
import 'package:suriota_mobile_gateway/constant/app_gap.dart';
import 'package:suriota_mobile_gateway/constant/image_asset.dart';
import 'package:suriota_mobile_gateway/global/utils/text_extension.dart';
import 'package:suriota_mobile_gateway/global/widgets/device_card.dart';
import 'package:suriota_mobile_gateway/models/device_dummy.dart';
import 'package:suriota_mobile_gateway/models/device_model.dart';
import 'package:suriota_mobile_gateway/screen/devices/detail_device_screen.dart';
import 'package:suriota_mobile_gateway/screen/devices/add_device_screen.dart';
import 'package:suriota_mobile_gateway/screen/sidebar_menu/sidebar_menu.dart';

// ignore: must_be_immutable
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<DeviceModel> deviceList = deviceDummy;

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: _appBar(screenWidth),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppPadding.screenPadding,
          child: _homeContent(context),
        ),
      ),
      endDrawer: const SideBarMenu(),
      floatingActionButton: _floatingButtonCustom(context),
    );
  }

  Column _homeContent(BuildContext context) {
    return Column(
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
                          builder: (context) => DetailDeviceScreen(
                                title: 'Suriota Gateway ${index + 1}',
                              )));
                },
                child: DeviceCard(
                  deviceTitle: deviceList[index].deviceTitle,
                  deviceAddress: deviceList[index].deviceAddress,
                  buttonTitle:
                      deviceList[index].isConnected ? 'Disconnect' : 'Connect',
                  colorButton: deviceList[index].isConnected
                      ? AppColor.redColor
                      : AppColor.primaryColor,
                  onPressed: () {},
                ));
          },
        ),
        AppSpacing.xxl,
      ],
    );
  }

  AppBar _appBar(double screenWidth) {
    return AppBar(
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
    );
  }

  Container _floatingButtonCustom(BuildContext context) {
    return Container(
        width: 50,
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: AppColor.primaryColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => AddDeviceScreen()));
          },
          child: const Icon(
            Icons.add_circle,
            size: 20,
            color: AppColor.whiteColor,
          ),
        ));
  }
}
