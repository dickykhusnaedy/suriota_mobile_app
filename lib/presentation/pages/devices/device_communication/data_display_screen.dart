import 'package:flutter/material.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/constants/app_gap.dart';
import 'package:gateway_config/core/utils/extensions.dart';

class DisplayDataPage extends StatelessWidget {
  final String title; // Parameter untuk nama perangkat
  final String modbusType; // Parameter untuk tipe Modbus

  const DisplayDataPage({
    super.key,
    required this.title,
    required this.modbusType,
  });

  @override
  Widget build(BuildContext context) {
    List<String> addressData = [
      "0x3042",
      "0x2042",
      "0x8219",
      "0x8163",
      "0x6661",
      "0x6763",
    ];
    List<String> valueData = ["142", "920", "821", "710", "180", "170"];

    return Scaffold(
      appBar: _appBar(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppPadding.horizontalMedium,
          child: _bodyContent(context, addressData, valueData),
        ),
      ),
    );
  }

  AppBar _appBar(BuildContext context) {
    return AppBar(
      title: Text(
        'Display Data',
        style: context.h5.copyWith(color: AppColor.whiteColor),
      ),
      iconTheme: const IconThemeData(color: AppColor.whiteColor),
      backgroundColor: AppColor.primaryColor,
      centerTitle: true,
    );
  }

  Column _bodyContent(
    BuildContext context,
    List<String> addressData,
    List<String> valueData,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSpacing.md,
        Text(title, style: context.h5),
        AppSpacing.sm,
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 5,
          separatorBuilder: (context, index) => AppSpacing.sm,
          itemBuilder: (BuildContext context, int index) {
            return _card(context, addressData, index, valueData);
          },
        ),
      ],
    );
  }

  Stack _card(
    BuildContext context,
    List<String> addressData,
    int index,
    List<String> valueData,
  ) {
    return Stack(
      alignment: AlignmentDirectional.topEnd,
      children: [
        SizedBox(
          width: double.infinity,
          child: Card(
            color: AppColor.cardColor,
            margin: EdgeInsets.zero,
            elevation: 0.0,
            child: Padding(
              padding: AppPadding.medium,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width - 200,
                    child: Text(
                      'Address ${addressData[index]}',
                      style: context.h6,
                      overflow: TextOverflow.clip,
                    ),
                  ),
                  AppSpacing.xs,
                  Text(
                    'Value : ${valueData[index]}', // Tampilkan tipe Modbus
                    style: context.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(
          height: 30,
          width: 130,
          decoration: const BoxDecoration(
            color: AppColor.labelColor,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(10.0),
              bottomLeft: Radius.circular(10.0),
            ),
          ),
          child: Center(
            child: Text(
              '25 Aug 2024 13.00', // Data statis contoh
              textAlign: TextAlign.center,
              style: context.buttonTextSmallest,
            ),
          ),
        ),
      ],
    );
  }
}
