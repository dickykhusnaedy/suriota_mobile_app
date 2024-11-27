import 'package:flutter/material.dart';

import '../../constant/app_color.dart';
import '../../constant/font_setup.dart';

class TitleTile extends StatelessWidget {
  final String title;
  final Color? bgColor;
  const TitleTile({
    super.key,
    required this.title,  this.bgColor ,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(
          color: bgColor ??  AppColor.primaryColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8)),
      child: Text(
        title,
        style: FontFamily.headlineMedium,
      ),
    );
  }
}