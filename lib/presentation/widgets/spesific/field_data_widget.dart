import 'package:flutter/material.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/constants/app_gap.dart';
import 'package:gateway_config/core/utils/extensions.dart';

class FieldDataWidget extends StatelessWidget {
  final String label;
  final String description;

  const FieldDataWidget({
    super.key,
    required this.label,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.h6.copyWith(color: AppColor.blackColor)),
        AppSpacing.sm,
        Text(description, style: context.body.copyWith(color: AppColor.grey)),
      ],
    );
  }
}
