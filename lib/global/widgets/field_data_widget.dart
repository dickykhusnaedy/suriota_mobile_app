import 'package:flutter/material.dart';
import 'package:suriota_mobile_gateway/constant/app_color.dart';
import 'package:suriota_mobile_gateway/constant/app_gap.dart';
import 'package:suriota_mobile_gateway/global/utils/text_extension.dart';

class FieldDataWidget extends StatelessWidget {
  final String label;
  final String description;

  const FieldDataWidget(
      {super.key, required this.label, required this.description});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.h6),
        AppSpacing.sm,
        Text(description, style: context.body.copyWith(color: AppColor.grey))
      ],
    );
  }
}
