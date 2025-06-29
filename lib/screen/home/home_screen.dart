import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:suriota_mobile_gateway/core/constants/app_color.dart';
import 'package:suriota_mobile_gateway/core/constants/app_gap.dart';
import 'package:suriota_mobile_gateway/core/constants/app_image_assets.dart';
import 'package:suriota_mobile_gateway/core/controllers/ble/ble_controller.dart';
import 'package:suriota_mobile_gateway/core/utils/extensions.dart';
import 'package:suriota_mobile_gateway/global/widgets/loading_overlay.dart';
import 'package:suriota_mobile_gateway/models/device_dummy.dart';
import 'package:suriota_mobile_gateway/models/device_model.dart';
import 'package:suriota_mobile_gateway/screen/devices/add_device_screen.dart';
import 'package:suriota_mobile_gateway/screen/devices/widgets/device_list_widget.dart';
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

    return Stack(
      children: [
        Scaffold(
          appBar: _appBar(screenWidth),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: AppPadding.screenPadding,
              child: _homeContent(context),
            ),
          ),
          endDrawer: const SideBarMenu(),
          floatingActionButton: _floatingButtonCustom(context),
        ),
        Obx(() {
          final isAnyDeviceLoading = bleController.isAnyDeviceLoading;
          return LoadingOverlay(
            isLoading: isAnyDeviceLoading,
            message: 'Connecting device...',
          );
        })
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

  Column _homeContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hallo, Fulan👋',
            style: context.h1.copyWith(color: AppColor.blackColor)),
        AppSpacing.xs,
        Text('Connecting the device near you',
            style: context.body.copyWith(color: AppColor.grey)),
        AppSpacing.xxl,
        Text('Device List',
            style: context.h4.copyWith(color: AppColor.blackColor)),
        AppSpacing.sm,
        Obx(() {
          // ignore: prefer_is_empty
          if (bleController.devices.isEmpty ||
              // ignore: prefer_is_empty
              bleController.devices.length == 0) {
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

              return Obx(() {
                final isConnected = bleController.getConnectionStatus(deviceId);
                final isLoadingConnection =
                    bleController.getLoadingStatus(deviceId);

                return DeviceListWidget(
                  device: device,
                  isConnected: isConnected,
                  isLoadingConnection: isLoadingConnection,
                  onConnect: () async {
                    if (!isLoadingConnection) {
                      await bleController.connectToDevice(device);
                    }
                  },
                  onDisconnect: () async {
                    if (!isLoadingConnection) {
                      await bleController.disconnectDevice(device);
                    }
                  },
                );
              });
            },
          );
        }),
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
