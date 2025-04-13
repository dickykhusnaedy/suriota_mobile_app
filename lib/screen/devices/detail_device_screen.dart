import 'package:flutter/material.dart';
import 'package:suriota_mobile_gateway/constant/app_color.dart';
import 'package:suriota_mobile_gateway/constant/app_gap.dart';
import 'package:suriota_mobile_gateway/constant/image_asset.dart';
import 'package:suriota_mobile_gateway/global/utils/text_extension.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_button.dart';
import 'package:suriota_mobile_gateway/global/widgets/device_card.dart';
import 'package:suriota_mobile_gateway/screen/devices/detail_device_info_screen.dart';
import 'package:suriota_mobile_gateway/screen/devices/device_communication/device_communications_screen.dart';
import 'package:suriota_mobile_gateway/screen/devices/logging_config/form_logging_config_screen.dart';
import 'package:suriota_mobile_gateway/screen/devices/modbus_config/modbus_screen.dart';
import 'package:suriota_mobile_gateway/screen/devices/server_config/form_config_server_screen.dart';

class DetailDeviceScreen extends StatelessWidget {
  final String title;
  final String deviceAddress;
  const DetailDeviceScreen({super.key, required this.title, required this.deviceAddress});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> menuItems = [
      {
        "text": "Device Communication",
        "imagePath": ImageAsset.iconDevice,
        "page": const DeviceCommunicationsScreen()
      },
      {
        "text": "Modbus Configurations",
        "imagePath": ImageAsset.iconConfig,
        "page": const ModbusScreen()
      },
      {
        "text": "Server Configurations",
        "imagePath": ImageAsset.iconServer,
        "page": const FormConfigServer()
      },
      {
        "text": "Logging Configurations",
        "imagePath": ImageAsset.iconLogging,
        "page": const FormLoggingConfigScreen()
      },
    ];

    return Scaffold(
      appBar: _appBar(context, title),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppPadding.horizontalMedium,
          child: _bodyContent(context, menuItems),
        ),
      ),
    );
  }

  Column _bodyContent(
      BuildContext context, List<Map<String, dynamic>> menuItems) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSpacing.md,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              flex: screenWidth <= 600 ? 2 : 3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Image.asset(ImageAsset.iconBluetooth,
                      width: 45, height: 45, fit: BoxFit.contain),
                  AppSpacing.md,
                  Flexible(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: context.h4,
                          overflow: TextOverflow.ellipsis,
                        ),
                        AppSpacing.xs,
                        Text(
                          deviceAddress,
                          style: context.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                        AppSpacing.xs,
                        Text(
                          'BONDED',
                          style: context.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            AppSpacing.sm,
            Flexible(
              flex: 1,
              child: SizedBox(
                height: 30,
                child: Button(
                    width: double.infinity,
                    onPressed: () {},
                    text: 'Disconnect',
                    btnColor: AppColor.redColor,
                    customStyle: context.buttonTextSmallest),
              ),
            ),
          ],
        ),
        AppSpacing.xl,
        Text(
          'Configuration Menu',
          style: context.h5,
        ),
        AppSpacing.md,
        LayoutBuilder(builder: (context, constraints) {
          double cardWidth = (constraints.maxWidth / 2) - 8;

          return Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.spaceBetween,
            children: menuItems
                .map((item) => CardMenu(
                    width: cardWidth,
                    text: item['text']!,
                    imagePath: item['imagePath']!,
                    page: item['page']))
                .toList(),
          );
        }),
        AppSpacing.lg,
      ],
    );
  }

  AppBar _appBar(BuildContext context, String title) {
    return AppBar(
      title: Text(
        'Detail Device',
        style: context.h5.copyWith(color: AppColor.whiteColor),
      ),
      backgroundColor: AppColor.primaryColor,
      iconTheme: const IconThemeData(color: AppColor.whiteColor),
      centerTitle: true,
      actions: [
        IconButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => DetailDeviceInfoScreen(
                            deviceName: title,
                          )));
            },
            icon: const Icon(Icons.info))
      ],
    );
  }
}
