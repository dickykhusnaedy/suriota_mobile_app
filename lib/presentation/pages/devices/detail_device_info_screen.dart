import 'package:flutter/material.dart';
import 'package:suriota_mobile_gateway/core/constants/app_gap.dart';
import 'package:suriota_mobile_gateway/core/utils/extensions.dart';

import '../../../core/constants/app_color.dart';

class DetailDeviceInfoScreen extends StatelessWidget {
  final String deviceName;

  const DetailDeviceInfoScreen({super.key, required this.deviceName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppPadding.horizontalMedium,
          child: _bodyContent(),
        ),
      ),
    );
  }

  Column _bodyContent() {
    return Column(
      children: [
        AppSpacing.md,
        ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            separatorBuilder: (context, index) => AppSpacing.sm,
            itemBuilder: (BuildContext context, int index) {
              return Card(
                color: AppColor.cardColor,
                margin: EdgeInsets.zero,
                elevation: 0.0,
                child: Padding(
                  padding: AppPadding.medium,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Generic Attribute',
                        style: context.h5,
                      ),
                      AppSpacing.xs,
                      Text(
                        'UUID : 0X1801',
                        style: context.bodySmall,
                      ),
                      AppSpacing.xs,
                      Text(
                        'PRIMARY ACCESS',
                        style: context.bodySmall,
                      ),
                    ],
                  ),
                ),
              );
            }),
        AppSpacing.md,
      ],
    );
  }

  AppBar _appBar(BuildContext context) {
    return AppBar(
      title: Text(
        'Detail Device $deviceName',
        style: context.h5.copyWith(color: AppColor.whiteColor),
      ),
      backgroundColor: AppColor.primaryColor,
      iconTheme: const IconThemeData(color: AppColor.whiteColor),
      centerTitle: true,
    );
  }
}
