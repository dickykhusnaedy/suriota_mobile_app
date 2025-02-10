import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_button.dart';

import '../../../constant/font_setup.dart';
import '../../../constant/theme.dart';
import '../../../global/widgets/custom_dropdown.dart';
import '../../../global/widgets/custom_textfield.dart';

class FormModbusConfigurationPage extends StatefulWidget {
  const FormModbusConfigurationPage({super.key});

  @override
  State<FormModbusConfigurationPage> createState() =>
      _FormModbusConfigurationPageState();
}

class _FormModbusConfigurationPageState
    extends State<FormModbusConfigurationPage> {
  @override
  Widget build(BuildContext context) {
    List<String> connectionDevice = [
      'Temperature Control 16B',
      'PZEM 004T',
      'Landstar 1102',
      'THDM Axial',
      'DSE 520',
    ];
    List<String> functions = [
      '01 Read Coil',
      '02 Read Discreate Inputs',
      '03 Read Holding Register',
      '04 Read Input Register'
    ];
    List<String> typeData = [
      'Int16 (Signed)',
      'Uint16 (Unsigned)',
      'Int32 Big Endian',
      'Int32 Little Endian',
      'Int32 Little Endian Byte Swap',
      'Uint32 Big Endian',
      'Uint32 Little Endian',
      'Uint32 Little Endian Byte Swap',
      'Float32 Big Endian',
      'Float32 Little Endian',
      'Float32 Little Endian Byte Swap'
    ];
    String? selectedDevice;
    String? selectedFunction;
    String? selectedTypeData;

// INT16, UINT16, INT32BIGENDIAN, INT32LITTLEENDIAN, INT32LITTLEENDIANBYTESWAP, UINT32BIGENDIAN, UINT32LITTLEENDIAN, UINT32LITTLEENDIANBYTESWAP, FLOAT32BIGENDIAN, FLOAT32LITTLEENDIAN, FLOAT32LITTLEENDIANBYTESWAP,

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Modbus Configuration'),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CustomTextFormField(
              labelTxt: "Data Name",
              hintTxt: "Enter the Data Name",
              // readOnly: true,
            ),
            const CustomTextFormField(
              labelTxt: "ID Slave",
              hintTxt: "Enter ID Slave",
              // readOnly: true,
            ),
            const Gap(6),
            Text(
              'Choose Device',
              style: FontFamily.headlineMedium,
            ),
            const Gap(4),
            CustomDropdown(
              listItem: connectionDevice,
              hintText: 'Choose device',
              selectedItem: selectedDevice,
            ),
            const Gap(6),
            Text(
              'Choose Function',
              style: FontFamily.headlineMedium,
            ),
            const Gap(4),
            CustomDropdown(
              listItem: functions,
              hintText: 'Choose the function',
              selectedItem: selectedFunction,
            ),
            const Gap(6),
            const CustomTextFormField(
              labelTxt: "Address",
              hintTxt: "Enter the address",
              // readOnly: true,
            ),
            const Gap(6),
            Text(
              'Choose Data Type',
              style: FontFamily.headlineMedium,
            ),
            const Gap(4),
            CustomDropdown(
              listItem: typeData,
              hintText: 'Choose data type',
              selectedItem: selectedTypeData,
            ),
            const Gap(6),
            const Gap(150),
            CustomButton(
                titleButton: 'SAVE',
                onPressed: () {
                  dialogSuccess(context);
                })
          ],
        ),
      ),
    );
  }
}
