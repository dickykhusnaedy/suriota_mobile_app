import 'package:flutter/material.dart';
import 'package:suriota_mobile_gateway/core/constants/app_color.dart';
import 'package:suriota_mobile_gateway/core/constants/app_gap.dart';
import 'package:suriota_mobile_gateway/core/utils/extensions.dart';

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final String? message;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return const SizedBox.shrink();

    return Container(
      color: Colors.black54, // Latar belakang gelap semi-transparan
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColor.whiteColor),
            ),
            if (message != null)
              Padding(
                padding: AppPadding.medium,
                child: Text(
                  message!,
                  style: context.h6.copyWith(color: AppColor.whiteColor),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
