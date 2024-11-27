import 'package:flutter/material.dart';
import 'package:suriota_mobile_gateway/controller/device_controller.dart';
import 'package:suriota_mobile_gateway/models/device_model.dart';
import 'package:suriota_mobile_gateway/view/device_menu/device_menu.dart';
import 'package:suriota_mobile_gateway/global/widgets/device_card.dart';
import 'package:suriota_mobile_gateway/view/home/ble_scanner.dart';
import 'package:suriota_mobile_gateway/view/sidebar_menu/sidebar_menu.dart';

import '../../constant/app_color.dart';
import '../../constant/font_setup.dart';
import '../../constant/image_asset.dart';
import 'add_device_page.dart';
import 'package:get/get.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final deviceController = Get.put(DeviceController());
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
            Obx(
              () => (deviceController.deviceList.value == null ||
                      deviceController.deviceList.value.isEmpty)
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 80),
                        child: Text(
                          "No Device",
                          style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: AppColor.grey),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: deviceController.deviceList.length,
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
                          child: Obx(
                            () => DeviceCard(
                              deviceTitle: deviceController
                                  .deviceList[index].deviceTitle,
                              deviceAddress: deviceController
                                  .deviceList[index].deviceAddress,
                              buttonTitle: 'Connect',
                              colorButton: deviceController
                                      .deviceList[index].deviceStatus.value
                                  ? AppColor.primaryColor
                                  : AppColor.redColor,
                              onPressed: () {
                                // setState(() {
                                //   deviceList[index].deviceStatus =
                                //       !deviceList[index].deviceStatus;
                                // });
                                deviceController
                                        .deviceList[index].deviceStatus.value =
                                    !deviceController
                                        .deviceList[index].deviceStatus.value;
                                // deviceController.removeDevice(index: index);
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColor.primaryColor,
        onPressed: () {
          // Navigator.push(context,
          //     MaterialPageRoute(builder: (context) => const AddDevicePage()));
          // Navigator.push(
          //     context, MaterialPageRoute(builder: (context) => BleScanner()));
          deviceController.addDevice(name: "Name", address: 'Tittle');
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
