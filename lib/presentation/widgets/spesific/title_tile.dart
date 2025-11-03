import 'package:flutter/material.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/constants/app_gap.dart';
import 'package:gateway_config/core/utils/extensions.dart';

class TitleTile extends StatelessWidget {
  final String title;
  final String? subTitle;
  final Color? bgColor;

  const TitleTile({
    super.key,
    required this.title,
    this.subTitle,
    this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppPadding.small,
      decoration: BoxDecoration(
        color: bgColor ?? AppColor.primaryColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.h5),
          if (subTitle != null) ...[
            AppSpacing.xs,
            Text(
              subTitle!,
              style: context.buttonTextSmall.copyWith(
                color: AppColor.grey,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
