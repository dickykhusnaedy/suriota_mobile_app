import 'package:flutter/material.dart';
import 'package:suriota_mobile_gateway/constant/app_color.dart';
import 'package:suriota_mobile_gateway/constant/app_gap.dart';
import 'package:suriota_mobile_gateway/global/utils/text_extension.dart';
import 'package:suriota_mobile_gateway/screen/devices/modbus_config/form_modbus_config_screen.dart';

class ModbusScreen extends StatefulWidget {
  const ModbusScreen({super.key});

  @override
  State<ModbusScreen> createState() => _ModbusScreenState();
}

class _ModbusScreenState extends State<ModbusScreen> {
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
      appBar: _appBar(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppPadding.horizontalMedium,
          child: Column(
            children: [
              AppSpacing.md,
              ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 5,
                  separatorBuilder: (context, builder) => AppSpacing.sm,
                  itemBuilder: (BuildContext context, int index) {
                    return cardDataConfig(connectionDevice, index);
                  }),
              AppSpacing.md,
            ],
          ),
        ),
      ),
    );
  }

  AppBar _appBar(BuildContext context) {
    return AppBar(
      title: Text(
        'Modbus Configuration',
        style: context.h5.copyWith(color: AppColor.whiteColor),
      ),
      backgroundColor: AppColor.primaryColor,
      centerTitle: true,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        IconButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const FormModbusConfigScreen()));
            },
            icon: const Icon(
              Icons.add_circle,
              size: 22,
            ))
      ],
    );
  }

  Card cardDataConfig(List<String> connectionDevice, int index) {
    return Card(
      color: AppColor.cardColor,
      elevation: 0.0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: AppPadding.medium,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              connectionDevice[index],
              style: context.h5,
            ),
            AppSpacing.sm,
            Text(
              'Slave ID : ${index + 1}',
              style: context.bodySmall,
            ),
            AppSpacing.xs,
            Text(
              'Address : 0x307$index',
              style: context.bodySmall,
            ),
            AppSpacing.xs,
            Text(
              'Function : Register Coils',
              style: context.bodySmall,
            ),
            AppSpacing.xs,
            Text(
              'Data Type : int16',
              style: context.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
