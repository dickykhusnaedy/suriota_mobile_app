import 'package:flutter/material.dart';
import 'package:suriota_mobile_gateway/core/constants/app_color.dart';
import 'package:suriota_mobile_gateway/core/constants/app_gap.dart';
import 'package:suriota_mobile_gateway/core/utils/extensions.dart';

class TitleTile extends StatelessWidget {
  final String title;
  final Color? bgColor;

  const TitleTile({
    super.key,
    required this.title,
    this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppPadding.small,
      decoration: BoxDecoration(
          color: bgColor ?? AppColor.primaryColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8)),
      child: Text(
        title,
        style: context.h6,
      ),
    );
  }
}
