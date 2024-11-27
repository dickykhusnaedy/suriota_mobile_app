import 'package:flutter/material.dart';

import '../../../constant/app_color.dart';
import '../../../constant/font_setup.dart';
import 'form_modbus_configuration.dart';

class ModbusConfigurationPage extends StatefulWidget {
  const ModbusConfigurationPage({super.key});

  @override
  State<ModbusConfigurationPage> createState() =>
      _ModbusConfigurationPageState();
}

class _ModbusConfigurationPageState extends State<ModbusConfigurationPage> {
  @override
  Widget build(BuildContext context) {
    List<String> connectionDevice = [
      'Temperature Control 16B',
      'PZEM 004T',
      'Landstar 1102',
      'THDM Axial',
      'DSE 520',
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modbus Configuration'),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const FormModbusConfigurationPage()));
              },
              icon: const Icon(Icons.add_circle))
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 5,
                itemBuilder: (BuildContext context, int index) {
                  return cardDataConfig(connectionDevice, index);
                })
          ],
        ),
      ),
    );
  }

  Card cardDataConfig(List<String> connectionDevice, int index) {
    return Card(
      color: AppColor.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              connectionDevice[index],
              style: FontFamily.headlineMedium,
            ),
            Text(
              'Slave ID : ${index + 1}',
              style: FontFamily.normal,
            ),
            Text(
              'Address : 0x307$index',
              style: FontFamily.normal,
            ),
            Text(
              'Function : Register Coils',
              style: FontFamily.normal,
            ),
            Text(
              'Data Type : int16',
              style: FontFamily.normal,
            ),
          ],
        ),
      ),
    );
  }
}
