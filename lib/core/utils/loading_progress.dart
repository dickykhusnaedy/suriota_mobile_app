import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:suriota_mobile_gateway/core/constants/app_color.dart';
import 'package:suriota_mobile_gateway/core/constants/app_gap.dart';
import 'package:suriota_mobile_gateway/core/utils/extensions.dart';

class LoadingProgress extends StatelessWidget {
  final double heightFactor;
  final RxInt receivedPackets;
  final RxInt expectedPackets;

  const LoadingProgress({
    Key? key,
    required this.receivedPackets,
    required this.expectedPackets,
    this.heightFactor = 0.85,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * heightFactor,
      alignment: Alignment.center,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 55,
              height: 55,
              child: CircularProgressIndicator(
                strokeWidth: 5,
                color: AppColor.primaryColor,
              ),
            ),
            AppSpacing.md,
            Obx(() {
              double percent = 0;
              if (expectedPackets.value > 0) {
                percent = (receivedPackets.value / expectedPackets.value * 100);
              }
              return Text(
                "Processing ${percent.toStringAsFixed(1)}% data ...",
                style: context.bodySmall.copyWith(
                    color: AppColor.grey, fontStyle: FontStyle.italic),
              );
            }),
          ],
        ),
      ),
    );
  }
}
