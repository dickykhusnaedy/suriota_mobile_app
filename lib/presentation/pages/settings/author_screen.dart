import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/constants/app_gap.dart';
import 'package:gateway_config/core/constants/app_image_assets.dart';
import 'package:gateway_config/core/utils/app_helpers.dart';
import 'package:gateway_config/core/utils/extensions.dart';
import 'package:gateway_config/presentation/widgets/common/custom_button.dart';

class AuthorScreen extends StatelessWidget {
  const AuthorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColor.primaryColor,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColor.whiteColor,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColor.backgroundColor,
        appBar: _appBar(context),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: AppPadding.screenPadding,
            child: _body(context),
          ),
        ),
      ),
    );
  }

  Column _body(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppSpacing.lg,
        // Company Logo
        Image.asset(ImageAsset.logoSuriota, height: 50, fit: BoxFit.contain),
        AppSpacing.xxl,
        // About Company Section
        _buildSection(
          context: context,
          title: 'About Company',
          children: [
            _buildSubSection(
              context: context,
              subtitle: 'Who Are We?',
              content:
                  'PT Surya Inovasi Prioritas (Suriota) is a company engaged in Consulting Engineering Services, located in Batam, Riau Islands, Indonesia. Established in January 2023, Suriota focuses on providing innovative and sustainable solutions in four main areas: Electrical, Water Treatment, Automation, and Renewable Energy.',
            ),
          ],
        ),
        AppSpacing.lg,
        // Vision Section
        _buildSection(
          context: context,
          title: 'Vision',
          children: [
            Text(
              'To become a leading company in Indonesia in the field of engineering consulting, providing innovative and sustainable solutions in the electrical, water treatment, renewable energy, and automation sectors to support digital transformation and business sustainability for our clients.',
              style: context.body.copyWith(
                color: AppColor.blackColor,
                height: 1.6,
              ),
            ),
          ],
        ),

        AppSpacing.lg,

        // Mission Section
        _buildSection(
          context: context,
          title: 'Our Mission',
          children: [
            _buildMissionItem(
              context: context,
              number: '1',
              text:
                  'To provide innovative and sustainable engineering solutions in Suriota\'s 4 focus areas.',
            ),
            AppSpacing.sm,
            _buildMissionItem(
              context: context,
              number: '2',
              text:
                  'To use the latest technology to help clients enhance their business efficiency and productivity.',
            ),
            AppSpacing.sm,
            _buildMissionItem(
              context: context,
              number: '3',
              text:
                  'To build mutually beneficial relationships with clients by delivering fast, accurate, and high-quality services.',
            ),
            AppSpacing.sm,
            _buildMissionItem(
              context: context,
              number: '4',
              text:
                  'To strengthen the individual competencies of our team from a national to an international scale.',
            ),
            AppSpacing.sm,
            _buildMissionItem(
              context: context,
              number: '5',
              text:
                  'To be a trusted partner by upholding Integrity and Credibility.',
            ),
          ],
        ),

        AppSpacing.xl,

        // Company Profile Button
        Button(
          width: double.infinity,
          onPressed: () {
            final Uri url = Uri.parse(
              'https://drive.google.com/file/d/1B77Mzzm0dMLm9qItgJSUfPSPCa8zjLUG/view?usp=sharing',
            );
            AppHelpers.launchInBrowser(url);
          },
          text: 'View Company Profile',
          icons: const Icon(
            Icons.file_open,
            size: 18,
            color: AppColor.whiteColor,
          ),
        ),

        AppSpacing.xl,

        // Copyright
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'Copyright © 2025 PT Surya Inovasi Prioritas',
            textAlign: TextAlign.center,
            style: context.bodySmall.copyWith(
              color: AppColor.grey,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColor.whiteColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColor.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: context.h4.copyWith(
              color: AppColor.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          AppSpacing.md,
          ...children,
        ],
      ),
    );
  }

  Widget _buildSubSection({
    required BuildContext context,
    required String subtitle,
    required String content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          subtitle,
          style: context.h6.copyWith(
            color: AppColor.blackColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        AppSpacing.sm,
        Text(
          content,
          style: context.body.copyWith(color: AppColor.blackColor, height: 1.6),
        ),
      ],
    );
  }

  Widget _buildMissionItem({
    required BuildContext context,
    required String number,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColor.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: context.body.copyWith(
              color: AppColor.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        AppSpacing.sm,
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              text,
              style: context.body.copyWith(
                color: AppColor.blackColor,
                height: 1.6,
              ),
            ),
          ),
        ),
      ],
    );
  }

  AppBar _appBar(BuildContext context) {
    return AppBar(
      title: Text(
        'Author',
        style: context.h5.copyWith(color: AppColor.whiteColor),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      centerTitle: true,
      backgroundColor: AppColor.primaryColor,
    );
  }
}
