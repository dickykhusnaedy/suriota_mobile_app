import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:suriota_mobile_gateway/constant/app_color.dart';
import 'package:suriota_mobile_gateway/constant/app_gap.dart';
import 'package:suriota_mobile_gateway/constant/image_asset.dart';
import 'package:suriota_mobile_gateway/controller/ble_controller.dart';
import 'package:suriota_mobile_gateway/controller/device_pagination_controller.dart';
import 'package:suriota_mobile_gateway/global/utils/text_extension.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_button.dart';
import 'package:suriota_mobile_gateway/screen/devices/device_communication/data_display_screen.dart';
import 'package:suriota_mobile_gateway/screen/devices/device_communication/form_setup_device_screen.dart';

class DeviceCommunicationsScreen extends StatefulWidget {
  const DeviceCommunicationsScreen({super.key});

  @override
  State<DeviceCommunicationsScreen> createState() =>
      _DeviceCommunicationsScreenState();
}

class _DeviceCommunicationsScreenState
    extends State<DeviceCommunicationsScreen> {
  final BLEController bleController = Get.put(BLEController());
  final controller = Get.put(DevicePaginationController());

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 10), () {
      bleController.sendCommand('READ|devices|page:1|pageSize:10');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(context),
      body: SafeArea(
        child: SingleChildScrollView(
            padding: AppPadding.horizontalMedium, child: _bodyContent(context)),
      ),
    );
  }

  Container _loadingProgress(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      alignment: Alignment.center,
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColor.primaryColor,
        ),
      ),
    );
  }

  AppBar _appBar(BuildContext context) {
    return AppBar(
      centerTitle: true,
      title: Text(
        'Device Communications',
        style: context.h5.copyWith(color: AppColor.whiteColor),
      ),
      iconTheme: const IconThemeData(color: AppColor.whiteColor),
      backgroundColor: AppColor.primaryColor,
      actions: [
        IconButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FormSetupDeviceScreen(),
                  ));
            },
            icon: const Icon(
              Icons.add_circle,
              size: 22,
            ))
      ],
    );
  }

  Column _bodyContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSpacing.md,
        Text(
          'Connections Device',
          style: context.h5,
          overflow: TextOverflow.ellipsis,
        ),
        AppSpacing.sm,
        Obx(() {
          if (bleController.isLoading.value) {
            return _loadingProgress(context);
          }

          if (controller.devices.isEmpty) {
            return _emptyView(context);
          }

          final data = controller.devices;

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: data.length,
            separatorBuilder: (context, index) => AppSpacing.sm,
            itemBuilder: (BuildContext context, int index) {
              final item = data[index];

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DisplayDataPage(
                        title: item['name'],
                        modbusType: item['modbus_type'],
                      ),
                    ),
                  );
                },
                child: _cardDeviceConnection(
                  context,
                  item['id'],
                  item['name'],
                  item['modbus_type'],
                ),
              );
            },
          );
        }),
        AppSpacing.md,
        if (controller.devices.isNotEmpty)
          Obx(() {
            final pagination = controller;

            return Center(
              child: Text(
                'Page ${pagination.page} from ${pagination.totalPages}',
                style: context.bodySmall,
              ),
            );
          }),
        AppSpacing.md,
      ],
    );
  }

  Container _emptyView(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.70,
      alignment: Alignment.center,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'No device found.',
              textAlign: TextAlign.center,
              style: context.body.copyWith(color: AppColor.grey),
            ),
          ],
        ),
      ),
    );
  }

  Card _cardDeviceConnection(
      BuildContext context, int deviceId, String title, String? modbusType) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Card(
      color: AppColor.cardColor,
      margin: EdgeInsets.zero,
      elevation: 0.0,
      child: Padding(
        padding: AppPadding.small,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
                flex: screenWidth <= 600 ? 2 : 3,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Image.asset(ImageAsset.iconModbus,
                        width: 50, height: 50, fit: BoxFit.contain),
                    AppSpacing.sm,
                    Flexible(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: context.h6,
                              overflow: TextOverflow.ellipsis,
                            ),
                            AppSpacing.xs,
                            Text(
                              'Device $modbusType',
                              style: context.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ))
                  ],
                )),
            AppSpacing.sm,
            Flexible(
              flex: 1,
              child: SizedBox(
                height: 30,
                child: Button(
                    width: double.infinity,
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  FormSetupDeviceScreen(id: deviceId)));
                    },
                    text: 'Setup',
                    btnColor: AppColor.primaryColor,
                    customStyle: context.buttonTextSmallest),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
