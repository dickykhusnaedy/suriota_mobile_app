import 'package:flutter/material.dart';
import 'package:suriota_mobile_gateway/constant/font_setup.dart';
import 'package:suriota_mobile_gateway/constant/image_asset.dart';
import 'package:suriota_mobile_gateway/view/device_menu/logging_config/logging_page.dart';
import 'package:suriota_mobile_gateway/global/widgets/device_card.dart';

import 'detail_information_device.dart';
import 'device_communication/device_communications.dart';
import 'modbus_config/modbus_configuration_page.dart';
import 'server_config/server_config_page.dart';

class DeviceMenuConfigurationPage extends StatelessWidget {
  final String title;
  const DeviceMenuConfigurationPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Info'),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const DetailInformationDevicePage()));
              },
              icon: const Icon(Icons.info))
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  height: 72,
                  child: Image.asset(ImageAsset.iconBluetooth),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: FontFamily.headlineMedium,
                    ),
                    Text(
                      'CC:7B:5C:28:A4:7E',
                      style: FontFamily.normal.copyWith(fontSize: 16),
                    ),
                    Text(
                      'BONDED',
                      style: FontFamily.normal.copyWith(fontSize: 16),
                    ),
                  ],
                ),
                SizedBox(
                  height: 23,
                  child: ElevatedButton(
                      onPressed: () {},
                      style: ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(
                            Theme.of(context).appBarTheme.backgroundColor),
                        shape: const WidgetStatePropertyAll(
                            RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(8)))),
                      ),
                      child: Text(
                        'Connect',
                        style: FontFamily.normal
                            .copyWith(fontSize: 10, color: Colors.white),
                      )),
                )
              ],
            ),
            const SizedBox(
              height: 30,
            ),
            Text(
              'Configuration Menu',
              style: FontFamily.headlineMedium.copyWith(fontSize: 14),
            ),
            const SizedBox(
              height: 16,
            ),
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                InkWell(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const DeviceCommunicationsPage()));
                  },
                  child: cardMenu(
                      context, ImageAsset.iconDevice, 'Device Communications'),
                ),
                InkWell(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const ModbusConfigurationPage()));
                  },
                  child: cardMenu(
                      context, ImageAsset.iconConfig, 'Modbus Configurations'),
                ),
                InkWell(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ServerConfigPage(),
                        ));
                  },
                  child: cardMenu(
                      context, ImageAsset.iconServer, 'Server Configurations'),
                ),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const LoggingConfigurationPage()),
                    );
                  },
                  child: cardMenu(context, ImageAsset.iconLogging,
                      'Logging Configurations'),
                ),
              ],
            ),
            // cardMenu(context),
          ],
        ),
      ),
    );
  }
}
