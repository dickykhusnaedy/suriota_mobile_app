import 'package:flutter/material.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/constants/app_gap.dart';
import 'package:gateway_config/core/constants/app_font.dart';
import 'package:gateway_config/core/constants/app_image_assets.dart';
import 'package:gateway_config/core/utils/app_helpers.dart';
import 'package:gateway_config/core/utils/extensions.dart';
import 'package:gateway_config/presentation/widgets/common/custom_button.dart';

class AboutApp extends StatelessWidget {
  const AboutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppPadding.horizontalMedium,
          child: _body(context),
        ),
      ),
    );
  }

  Column _body(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSpacing.lg,
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  ImageAsset.logoSuriotaAbout,
                  width: 130,
                  fit: BoxFit.contain,
                ),
              ),
              AppSpacing.sm,
              Text(
                'Gateway Config',
                style: context.h5.copyWith(
                  color: AppColor.blackColor,
                  fontWeight: FontWeightTheme.bold,
                ),
              ),
              AppSpacing.xs,
              Text(
                'version 1.0.0',
                style: context.bodySmall.copyWith(color: AppColor.grey),
              ),
            ],
          ),
        ),
        AppSpacing.lg,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About Company',
              style: context.h3.copyWith(color: AppColor.blackColor),
            ),
            AppSpacing.md,
            Text(
              'Who Are We?',
              style: context.h5.copyWith(color: AppColor.blackColor),
            ),
            AppSpacing.sm,
            Text(
              'PT Surya Inovasi Prioritas (Suriota) is a company engaged in Consulting Engineering Services, located in Batam, Riau Islands, Indonesia. Established in January 2023, Suriota focuses on providing innovative and sustainable solutions in four main areas: Electrical, Water Treatment, Automation, and Renewable Energy.',
              style: context.body.copyWith(color: AppColor.blackColor),
            ),
            AppSpacing.md,
            Text(
              'Vission',
              style: context.h5.copyWith(color: AppColor.blackColor),
            ),
            AppSpacing.sm,
            Text(
              'To become a leading company in Indonesia in the field of engineering consulting, providing innovative and sustainable solutions in the electrical, water treatment, renewable energy, and automation sectors to support digital transformation and business sustainability for our clients.',
              style: context.body.copyWith(color: AppColor.blackColor),
            ),
            AppSpacing.md,
            Text(
              'Our Mission',
              style: context.h5.copyWith(color: AppColor.blackColor),
            ),
            AppSpacing.sm,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '1.',
                  textAlign: TextAlign.left,
                  style: context.body.copyWith(color: AppColor.blackColor),
                ),
                AppSpacing.sm,
                Expanded(
                  child: Text(
                    'To provide innovative and sustainable engineering solutions in Suriota’s 4 focus areas.',
                    textAlign: TextAlign.left,
                    style: context.body.copyWith(color: AppColor.blackColor),
                  ),
                ),
              ],
            ),
            AppSpacing.sm,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '2.',
                  textAlign: TextAlign.left,
                  style: context.body.copyWith(color: AppColor.blackColor),
                ),
                AppSpacing.sm,
                Expanded(
                  child: Text(
                    'To use the latest technology to help clients enhance their business efficiency and productivity.',
                    textAlign: TextAlign.left,
                    style: context.body.copyWith(color: AppColor.blackColor),
                  ),
                ),
              ],
            ),
            AppSpacing.sm,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '3.',
                  textAlign: TextAlign.left,
                  style: context.body.copyWith(color: AppColor.blackColor),
                ),
                AppSpacing.sm,
                Expanded(
                  child: Text(
                    'To build mutually beneficial relationships with clients by delivering fast, accurate, and high-quality services.',
                    textAlign: TextAlign.left,
                    style: context.body.copyWith(color: AppColor.blackColor),
                  ),
                ),
              ],
            ),
            AppSpacing.sm,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '4.',
                  textAlign: TextAlign.left,
                  style: context.body.copyWith(color: AppColor.blackColor),
                ),
                AppSpacing.sm,
                Expanded(
                  child: Text(
                    'To strengthen the individual competencies of our team from a national to an international scale.',
                    textAlign: TextAlign.left,
                    style: context.body.copyWith(color: AppColor.blackColor),
                  ),
                ),
              ],
            ),
            AppSpacing.sm,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '5.',
                  textAlign: TextAlign.left,
                  style: context.body.copyWith(color: AppColor.blackColor),
                ),
                AppSpacing.sm,
                Expanded(
                  child: Text(
                    'To be a trusted partner by upholding Integrity and Credibility.',
                    textAlign: TextAlign.left,
                    style: context.body.copyWith(color: AppColor.blackColor),
                  ),
                ),
              ],
            ),
          ],
        ),
        AppSpacing.lg,
        Row(
          children: [
            Expanded(
              child: Button(
                width: double.infinity,
                onPressed: () {
                  final Uri url = Uri.parse(
                    'https://drive.google.com/file/d/1B77Mzzm0dMLm9qItgJSUfPSPCa8zjLUG/view?usp=sharing',
                  );
                  AppHelpers.launchInBrowser(url);
                },
                text: 'Company Profile',
                icons: const Icon(
                  Icons.file_open,
                  size: 15,
                  color: AppColor.whiteColor,
                ),
              ),
            ),
          ],
        ),
        AppSpacing.xxxxl,
        Text(
          'Copyright © 2025 PT Surya Inovasi Prioritas',
          textAlign: TextAlign.center,
          style: context.bodySmall.copyWith(color: AppColor.grey),
        ),
        AppSpacing.lg,
      ],
    );
  }

  AppBar _appBar(BuildContext context) {
    return AppBar(
      title: Text(
        'About App',
        style: context.h5.copyWith(color: AppColor.whiteColor),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      centerTitle: true,
      backgroundColor: AppColor.primaryColor,
    );
  }
}
