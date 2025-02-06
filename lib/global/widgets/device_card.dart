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
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                SizedBox(
                  height: 64,
                  child: Image.asset(
                    ImageAsset.iconBluetooth,
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deviceTitle!.length > 19
                          ? '${deviceTitle!.substring(0, 19)}...'
                          : deviceTitle ?? "Device Tittle",
                      style: FontFamily.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      deviceAddress!.length > 19
                          ? '${deviceAddress!.substring(0, 19)}...'
                          : deviceAddress ?? "address",
                      style: FontFamily.normal,
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    )
                  ],
                ),
              ],
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 99,
              height: 25,
              child: Button(
                  width: double.infinity,
                  onPressed: onPressed,
                  text: (buttonTitle ?? ''),
                  btnColor: colorButton,
                  customStyle: FontFamily.normal
                      .copyWith(fontSize: 12, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
