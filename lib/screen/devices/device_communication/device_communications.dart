import 'dart:math';

import 'package:flutter/material.dart';
import 'package:suriota_mobile_gateway/screen/devices/device_communication/data_display.dart';

import '../../../constant/app_color.dart';
import '../../../constant/font_setup.dart';
import '../../../constant/image_asset.dart';
import 'form_device_setup.dart';

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
      appBar: AppBar(
        title: const Text('Device Communications'),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const FomDeviceSetupView()));
              },
              icon: const Icon(Icons.add_circle))
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Connections Device',
              style: FontFamily.headlineMedium,
              overflow: TextOverflow.clip,
            ),
            const SizedBox(
              height: 5,
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: deviceList.length,
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
                  child: cardDeviceConnection(
                    context,
                    device['device']!,
                    randomModbusType, // Tampilkan tipe Modbus acak
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Card cardDeviceConnection(
      BuildContext context, String title, String? modbusType) {
    return Card(
      color: AppColor.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                      width: 60, child: Image.asset(ImageAsset.iconModbus)),
                  const SizedBox(
                    width: 24,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: FontFamily.headlineMedium,
                          overflow: TextOverflow.clip,
                          maxLines: 1,
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          'Device $modbusType',
                          style: FontFamily.normal,
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 23,
              child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const FomDeviceSetupView()));
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(
                        Theme.of(context).appBarTheme.backgroundColor),
                    shape: const WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(8)))),
                  ),
                  child: Text(
                    'Setup',
                    style: FontFamily.normal
                        .copyWith(fontSize: 10, color: Colors.white),
                  )),
            )
          ],
        ),
      ),
    );
  }
}
