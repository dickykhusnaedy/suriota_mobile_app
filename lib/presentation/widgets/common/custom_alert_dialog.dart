import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:suriota_mobile_gateway/core/constants/app_color.dart';
import 'package:suriota_mobile_gateway/core/constants/app_gap.dart';
import 'package:suriota_mobile_gateway/core/constants/app_font.dart';
import 'package:suriota_mobile_gateway/presentation/widgets/common/custom_button.dart';

class CustomAlertDialog {
  static void show(
      {required String title,
      required String message,
      String primaryButtonText = 'Ok',
      String? secondaryButtonText,
      VoidCallback? onPrimaryPressed,
      VoidCallback? onSecondaryPressed,
      bool barrierDismissible = true}) {
    Get.dialog(
        AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: AppColor.whiteColor,
          surfaceTintColor: AppColor.whiteColor,
          contentPadding: AppPadding.medium,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: FontFamily.headlineLarge),
              AppSpacing.sm,
              Text(message, style: FontFamily.normal),
              AppSpacing.lg,
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (secondaryButtonText != null)
                    Flexible(
                      flex: 1,
                      child: Button(
                        height: 38,
                        onPressed: onSecondaryPressed ?? () => Get.back(),
                        text: secondaryButtonText,
                        btnColor: Colors.grey[300],
                        customStyle: FontFamily.normalText
                            .copyWith(color: Colors.grey[600]),
                      ),
                    ),
                  if (secondaryButtonText != null) AppSpacing.sm,
                  Flexible(
                    flex: 1,
                    child: Button(
                      height: 38,
                      onPressed: onPrimaryPressed ?? () => Get.back(),
                      text: primaryButtonText,
                      btnColor: AppColor.primaryColor,
                      customStyle: FontFamily.normalText
                          .copyWith(color: AppColor.whiteColor),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
        barrierDismissible: barrierDismissible);
  }
}
