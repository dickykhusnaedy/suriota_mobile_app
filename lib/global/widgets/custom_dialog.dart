import 'package:flutter/material.dart';
import 'package:suriota_mobile_gateway/core/constants/app_color.dart';
import 'package:suriota_mobile_gateway/core/constants/app_gap.dart';
import 'package:suriota_mobile_gateway/core/constants/app_font.dart';

class CustomDialog extends StatelessWidget {
  const CustomDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        decoration: dialogDecoration,
        child: mainContent,
      ),
    );
  }

  BoxDecoration get dialogDecoration => BoxDecoration(
        color: AppColor.cardColor,
        borderRadius: BorderRadius.circular(8),
      );
      
  Padding get mainContent => Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.dangerous_outlined,
              size: 75,
              color: AppColor.redColor,
            ),
            Text(
              'Gagal Login!',
              style: FontFamily.titleMedium,
            ),
            AppGap.gap8,
            Text(
              'Password yang anda masukkan salah',
              style: FontFamily.normalText,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}
