import 'dart:math';

import 'package:flutter/material.dart';
import 'package:suriota_mobile_gateway/constant/app_color.dart';
import 'package:suriota_mobile_gateway/constant/app_gap.dart';
import 'package:suriota_mobile_gateway/constant/image_asset.dart';
import 'package:suriota_mobile_gateway/global/utils/text_extension.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_button.dart';
import 'package:suriota_mobile_gateway/screen/devices/device_communication/data_display.dart';
import 'package:suriota_mobile_gateway/screen/devices/device_communication/form_device_setup.dart';

class DeviceCommunicationsPage extends StatelessWidget {
  const DeviceCommunicationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    List<String> connectionDevice = [
      'Temperature Control 16B',
      'PZEM 004T',
      'Landstar 1102',
      'THDM Axial',
      'DSE 520',
    ];

    List<String> modbusType = ['RTU', 'TCP/IP'];

    // Gabungkan kedua list menjadi satu list pasangan
    List<Map<String, String>> deviceList = List.generate(
      connectionDevice.length,
      (index) => {
        'device': connectionDevice[index],
        'modbus': modbusType[index % modbusType.length],
      },
    );

    return Scaffold(
      appBar: _appBar(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppPadding.horizontalMedium,
          child:
              _bodyContent(context, deviceList, modbusType, connectionDevice),
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
                    builder: (context) => const FomDeviceSetupView(),
                  ));
            },
            icon: const Icon(
              Icons.add_circle,
              size: 22,
            ))
      ],
    );
  }

  Column _bodyContent(
      BuildContext context,
      List<Map<String, String>> deviceList,
      List<String> modbusType,
      List<String> connectionDevice) {
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
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: deviceList.length,
          separatorBuilder: (context, index) => AppSpacing.sm,
          itemBuilder: (BuildContext context, int index) {
            var device = deviceList[index];

            // Menggunakan Random untuk memilih tipe Modbus secara acak
            String randomModbusType =
                modbusType[Random().nextInt(modbusType.length)];

            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DisplayDataPage(
                      title: connectionDevice[index], // Nama perangkat
                      modbusType:
                          randomModbusType, // Modbus dipilih secara acak
                    ),
                  ),
                );
              },
              child: _cardDeviceConnection(
                context,
                device['device']!,
                randomModbusType, // Tampilkan tipe Modbus acak
              ),
            );
          },
        ),
        AppSpacing.md,
      ],
    );
  }

  Card _cardDeviceConnection(
      BuildContext context, String title, String? modbusType) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Card(
      color: AppColor.cardColor,
      margin: EdgeInsets.zero,
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
                                  const FomDeviceSetupView()));
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
