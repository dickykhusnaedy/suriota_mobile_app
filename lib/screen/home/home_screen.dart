import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:suriota_mobile_gateway/constant/app_color.dart';
import 'package:suriota_mobile_gateway/constant/app_gap.dart';
import 'package:suriota_mobile_gateway/constant/image_asset.dart';
import 'package:suriota_mobile_gateway/controller/ble_controller.dart';
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
  final BLEController bleController = Get.put(BLEController());

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

  Column _homeContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hallo, Fulan👋', style: context.h1),
        AppSpacing.xs,
        Text('Connecting the device near you', style: context.body),
        AppSpacing.xxl,
        Text('Device List', style: context.h4),
        AppSpacing.sm,
        Obx(() {
          // ignore: prefer_is_empty
          if (bleController.devices.isEmpty || bleController.devices.length == 0) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.55,
              alignment: Alignment.center,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'No device found.\nFind devices near you by clicking the (+) button.',
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
                  buttonTitle: isConnected ? 'Disconnect' : 'Connect',
                  colorButton:
                      isConnected ? AppColor.redColor : AppColor.primaryColor,
                  onPressed: () async {
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
        // ListView.separated(
        //   shrinkWrap: true,
        //   physics: const NeverScrollableScrollPhysics(),
        //   itemCount: deviceList.length,
        //   separatorBuilder: (context, index) => AppSpacing.sm,
        //   itemBuilder: (BuildContext context, int index) {
        //     return InkWell(
        //         onTap: () {
        //           Navigator.push(
        //               context,
        //               MaterialPageRoute(
        //                   builder: (context) => DetailDeviceScreen(
        //                         title: 'Suriota Gateway ${index + 1}',
        //                       )));
        //         },
        //         child: DeviceCard(
        //           deviceTitle: deviceList[index].deviceTitle,
        //           deviceAddress: deviceList[index].deviceAddress,
        //           buttonTitle:
        //               deviceList[index].isConnected ? 'Disconnect' : 'Connect',
        //           colorButton: deviceList[index].isConnected
        //               ? AppColor.redColor
        //               : AppColor.primaryColor,
        //           onPressed: () {},
        //         ));
        //   },
        // ),
        AppSpacing.xxl,
      ],
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
                    builder: (context) => const AddDeviceScreen()));
          },
          child: const Icon(
            Icons.add_circle,
            size: 20,
            color: AppColor.whiteColor,
          ),
        ));
  }
}
