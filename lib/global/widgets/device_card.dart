import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:suriota_mobile_gateway/core/constants/app_gap.dart';
import 'package:suriota_mobile_gateway/core/utils/extensions.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_button.dart';

import '../../core/constants/app_color.dart';
import '../../core/constants/app_font.dart';
import '../../core/constants/app_image_assets.dart';

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

class CardMenu extends StatelessWidget {
  final String text;
  final double width;
  final String? imagePath;
  final Widget page;

  const CardMenu(
      {super.key,
      required this.text,
      this.imagePath,
      required this.width,
      required this.page});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 185,
      child: GestureDetector(
        onTap: () {
          Get.to(() => page);
        },
        child: Card(
          color: AppColor.cardColor,
          elevation: 0.0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: AppPadding.medium,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: Image.asset(imagePath!,
                        width: 100, fit: BoxFit.contain),
                  ),
                  AppSpacing.xs,
                  Text(
                    text,
                    style: context.body,
                    textAlign: TextAlign.center,
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
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
      color: AppColor.lightPrimaryColor,
      margin: EdgeInsets.zero,
      elevation: 0.0,
      child: Padding(
        padding: AppPadding.medium,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              flex: screenWidth <= 600 ? 2 : 3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Image.asset(ImageAsset.iconBluetooth,
                      width: 40, height: 40, fit: BoxFit.contain),
                  AppSpacing.sm,
                  Flexible(
                    flex: 1,
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
                          style: context.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            AppSpacing.sm,
            Flexible(
              flex: 1,
              child: SizedBox(
                height: 30,
                child: Button(
                    width: double.infinity,
                    onPressed: onPressed,
                    text: buttonTitle ?? '',
                    btnColor: colorButton,
                    customStyle: context.buttonTextSmallest),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
