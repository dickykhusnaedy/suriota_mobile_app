import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:suriota_mobile_gateway/constant/app_gap.dart';
import 'package:suriota_mobile_gateway/global/utils/text_extension.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_button.dart';

import '../../constant/app_color.dart';
import '../../constant/font_setup.dart';
import '../../constant/image_asset.dart';

Widget cardMenu(BuildContext context, String? iconImage, String? titleCard,
    {void Function()? onTap}) {
  double widthCard = MediaQuery.of(context).size.width * 0.45;

  return InkWell(
    onTap: onTap,
    child: SizedBox(
      height: 175,
      width: widthCard,
      child: Card(
        elevation: 0.0,
        color: AppColor.cardColor,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 80,
                child: Image.asset(
                  iconImage ?? 'Not Found',
                  width: 80,
                  fit: BoxFit.contain,
                ),
              ),
              // ignore: prefer_const_constructors
              SizedBox(
                height: 5,
              ),
              Text(
                titleCard ?? 'Enter The Title',
                textAlign: TextAlign.center,
                style: FontFamily.normal,
              )
            ],
          ),
        ),
      ),
    ),
  );
}

class DeviceCard extends StatelessWidget {
  final String? deviceTitle;
  final String? deviceAddress;
  final String? buttonTitle;
  final Color? colorButton;
  final VoidCallback? onPressed;

  const DeviceCard({
    super.key,
    this.deviceAddress,
    this.deviceTitle,
    this.buttonTitle,
    this.colorButton,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Card(
      color: AppColor.cardColor,
      elevation: 0.0,
      child: Padding(
        padding: AppPadding.medium,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: screenWidth * (screenWidth < 600 ? 0.45 : 0.6),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double boxWidth = constraints.maxWidth;

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Image.asset(ImageAsset.iconBluetooth,
                          width: 35, height: 35, fit: BoxFit.contain),
                      AppSpacing.sm,
                      SizedBox(
                        width: boxWidth - 50.w,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              deviceTitle!,
                              style: context.h6,
                              overflow: TextOverflow.ellipsis,
                            ),
                            AppSpacing.xs,
                            Text(
                              deviceAddress!,
                              style: context.body,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      )
                    ],
                  );
                },
              ),
            ),
            SizedBox(
              width: screenWidth * (screenWidth < 600 ? 0.33 : 0.2),
              height: 30,
              child: Button(
                  width: double.infinity,
                  onPressed: onPressed,
                  text: buttonTitle ?? '',
                  btnColor: colorButton,
                  customStyle: context.buttonTextSmall),
            ),
          ],
        ),
      ),
    );
  }
}
