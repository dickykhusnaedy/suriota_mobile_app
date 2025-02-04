import 'package:flutter/material.dart';
import 'package:suriota_mobile_gateway/models/device_dummy.dart';
import 'package:suriota_mobile_gateway/models/device_model.dart';
import 'package:suriota_mobile_gateway/view/device_menu/device_menu.dart';
import 'package:suriota_mobile_gateway/global/widgets/device_card.dart';
import 'package:suriota_mobile_gateway/view/sidebar_menu/sidebar_menu.dart';
import '../../constant/app_color.dart';
import '../../constant/font_setup.dart';
import '../../constant/image_asset.dart';
import 'add_device_page.dart';
// ignore: must_be_immutable
class HomePage extends StatelessWidget {
  List<DeviceModel> deviceList = deviceDummy;

  HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Transform.scale(
            alignment: Alignment.centerLeft,
            scale: 0.5,
            child: Image.asset(ImageAsset.logoSuriota)),
      ),
      endDrawer: const SideBarMenu(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Hallo, Soru👋',
              style: FontFamily.titleLarge,
            ),
            Text(
              'Connecting the device near you',
              style: FontFamily.normal.copyWith(fontSize: 18),
            ),
            const SizedBox(
              height: 32,
            ),
            Text(
              'Device List',
              style: FontFamily.headlineMedium,
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: deviceList.length,
              itemBuilder: (BuildContext context, int index) {
                return InkWell(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>DeviceMenuConfigurationPage(
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
                      )
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColor.primaryColor,
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const AddDevicePage()));
        },
        shape: (const CircleBorder()),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 25,
        ),
      ),
    );
  }
}
