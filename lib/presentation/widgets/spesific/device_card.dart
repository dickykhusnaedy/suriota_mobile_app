import 'package:flutter/material.dart';
import 'package:gateway_config/core/constants/app_gap.dart';
import 'package:gateway_config/core/utils/extensions.dart';
import 'package:gateway_config/presentation/widgets/common/custom_button.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_color.dart';
import '../../../core/constants/app_font.dart';
import '../../../core/constants/app_image_assets.dart';

Widget cardMenu(
  BuildContext context,
  String? iconImage,
  String? titleCard, {
  void Function()? onTap,
}) {
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
              SizedBox(height: 5),
              Text(
                titleCard ?? 'Enter The Title',
                textAlign: TextAlign.center,
                style: FontFamily.normal,
              ),
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
  final IconData icon;
  final String page;

  const CardMenu({
    super.key,
    required this.text,
    required this.icon,
    required this.width,
    required this.page,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 160,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push(page),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: AppColor.whiteColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColor.primaryColor.withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColor.primaryColor.withValues(alpha: 0.15),
                          AppColor.lightPrimaryColor.withValues(alpha: 0.25),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColor.primaryColor.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: 32,
                      color: AppColor.primaryColor,
                    ),
                  ),
                  AppSpacing.sm,
                  Text(
                    text,
                    style: context.body.copyWith(
                      color: AppColor.blackColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
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
  final String? lastConnectionTime;

  const DeviceCard({
    super.key,
    this.deviceAddress,
    this.deviceTitle,
    this.buttonTitle,
    this.colorButton,
    this.onPressed,
    this.lastConnectionTime,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColor.whiteColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColor.primaryColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              flex: screenWidth <= 600 ? 2 : 3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColor.lightPrimaryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Image.asset(
                      ImageAsset.iconBluetooth,
                      fit: BoxFit.contain,
                    ),
                  ),
                  AppSpacing.sm,
                  Flexible(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deviceTitle!,
                          style: context.h6.copyWith(
                            color: AppColor.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        AppSpacing.xs,
                        Row(
                          children: [
                            Icon(
                              Icons.fingerprint,
                              size: 14,
                              color: AppColor.grey,
                            ),
                            AppSpacing.xs,
                            Expanded(
                              child: Text(
                                'ID: $deviceAddress',
                                style: context.bodySmall.copyWith(
                                  color: AppColor.grey,
                                  fontSize: 11,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (lastConnectionTime != null) ...[
                          AppSpacing.xs,
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: AppColor.grey,
                              ),
                              AppSpacing.xs,
                              Expanded(
                                child: Text(
                                  lastConnectionTime!,
                                  style: context.bodySmall.copyWith(
                                    color: AppColor.grey,
                                    fontSize: 11,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
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
                  customStyle: context.buttonTextSmallest.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColor.whiteColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
