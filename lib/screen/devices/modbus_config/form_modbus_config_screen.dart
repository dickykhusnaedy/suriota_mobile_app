import 'package:flutter/material.dart';
import 'package:suriota_mobile_gateway/constant/app_color.dart';
import 'package:suriota_mobile_gateway/constant/app_gap.dart';
import 'package:suriota_mobile_gateway/constant/theme.dart';
import 'package:suriota_mobile_gateway/global/utils/text_extension.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_button.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_dropdown.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_textfield.dart';

class FormModbusConfigScreen extends StatefulWidget {
  const FormModbusConfigScreen({super.key});

  @override
  State<FormModbusConfigScreen> createState() => _FormModbusConfigScreenState();
}

class _FormModbusConfigScreenState extends State<FormModbusConfigScreen> {
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
      '04 Read Input Register'
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
      appBar: _appBar(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppPadding.horizontalMedium,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSpacing.md,
              const CustomTextFormField(
                labelTxt: "Data Name",
                hintTxt: "Enter the Data Name",
                // readOnly: true,
              ),
              AppSpacing.md,
              const CustomTextFormField(
                labelTxt: "ID Slave",
                hintTxt: "Enter ID Slave",
                // readOnly: true,
              ),
              AppSpacing.md,
              Text(
                'Choose Device',
                style: context.h6,
              ),
              AppSpacing.sm,
              CustomDropdown(
                listItem: connectionDevice,
                hintText: 'Choose device',
                selectedItem: selectedDevice,
              ),
              AppSpacing.md,
              Text(
                'Choose Function',
                style: context.h6,
              ),
              AppSpacing.sm,
              CustomDropdown(
                listItem: functions,
                hintText: 'Choose the function',
                selectedItem: selectedFunction,
              ),
              AppSpacing.md,
              const CustomTextFormField(
                labelTxt: "Address",
                hintTxt: "Enter the address",
              ),
              AppSpacing.md,
              Text(
                'Choose Data Type',
                style: context.h6,
              ),
              AppSpacing.sm,
              CustomDropdown(
                listItem: typeData,
                hintText: 'Choose data type',
                selectedItem: selectedTypeData,
              ),
              AppSpacing.lg,
              Button(
                width: MediaQuery.of(context).size.width,
                onPressed: () {
                  ShowMessage.showCustomSnackBar(
                      context, "Feature for save data is coming soon!");
                },
                text: 'Save',
                height: 50,
              ),
              AppSpacing.lg,
            ],
          ),
        ),
      ),
    );
  }

  AppBar _appBar(BuildContext context) {
    return AppBar(
      title: Text(
        'Setup Modbus',
        style: context.h5.copyWith(color: AppColor.whiteColor),
      ),
      centerTitle: true,
      iconTheme: const IconThemeData(color: Colors.white),
      backgroundColor: AppColor.primaryColor,
    );
  }
}
