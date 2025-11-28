import 'package:flutter/material.dart';
import 'package:gateway_config/core/utils/app_helpers.dart';
import 'package:get/get.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/constants/app_font.dart';

class SnackbarCustom {
  static void showSnackbar(
    String title,
    String message,
    Color? bgColor,
    Color? textColor,
  ) {
    // Try to get context from GetX navigator
    final BuildContext? context = Get.context;

    if (context == null) {
      AppHelpers.debugLog('⚠️ Cannot show snackbar: No context available');
      return;
    }

    // Build full message with title if provided
    final String fullMessage = title.isEmpty ? message : '$title\n$message';

    // Use ScaffoldMessenger instead of GetX snackbar (more stable)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          fullMessage,
          style: FontFamily.normal.copyWith(
            color: textColor ?? AppColor.whiteColor,
          ),
        ),
        backgroundColor: bgColor ?? AppColor.redColor,
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
