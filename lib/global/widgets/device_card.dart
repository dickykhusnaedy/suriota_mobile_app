import 'package:flutter/material.dart';
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
        color: AppColor.cardColor,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 86,
                child: Image.asset(iconImage ?? 'Not Found'),
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
  const DeviceCard({
    super.key,
    this.deviceAddress,
    this.deviceTitle,
    this.buttonTitle,
    this.colorButton,
    this.onPressed,
  });
  final String? deviceTitle;
  final String? deviceAddress;
  final String? buttonTitle;
  final Color? colorButton;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColor.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                    width: 50,
                    height: 50,
                    child: Image.asset(ImageAsset.iconBluetooth)),
                const SizedBox(
                  width: 20,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deviceTitle!.length > 20
                          ? '${deviceTitle!.substring(0, 18)}...'
                          : deviceTitle ?? "Device Tittle",
                      style: FontFamily.headlineMedium,
                    ),
                    Text(
                      deviceAddress!.length > 20
                          ? '${deviceAddress!.substring(0, 20)}...'
                          : deviceAddress ?? "address",
                      style: FontFamily.normal,
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    )
                  ],
                ),
              ],
            ),
            CustomButton(
                colorButton: colorButton,
                height: 40,
                width: 90,
                titleButton: buttonTitle ?? 'Tittle',
                textStyle: FontFamily.normal.copyWith(
                    fontSize: 8,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
                onPressed: (onPressed))
          ],
        ),
      ),
    );
  }
}
