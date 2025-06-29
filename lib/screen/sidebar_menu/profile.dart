import 'package:flutter/material.dart';
import 'package:suriota_mobile_gateway/core/constants/app_color.dart';
import 'package:suriota_mobile_gateway/core/constants/app_gap.dart';
import 'package:suriota_mobile_gateway/core/constants/app_image_assets.dart';
import 'package:suriota_mobile_gateway/core/utils/extensions.dart';
import 'package:suriota_mobile_gateway/global/widgets/field_data_widget.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppPadding.horizontalMedium,
          child: _bodyContent(context),
        ),
      ),
    );
  }

  Column _bodyContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSpacing.lg,
        const Center(
          child: CircleAvatar(
            radius: 75,
            backgroundImage: AssetImage(ImageAsset.profile2),
          ),
        ),
        AppSpacing.md,
        Center(
          child: Text(
            'Fulan bin Fulan',
            style: context.h3.copyWith(color: AppColor.blackColor),
          ),
        ),
        AppSpacing.lg,
        const FieldDataWidget(
          label: 'Full Name',
          description: 'Fulan bin Fulan',
        ),
        AppSpacing.md,
        const FieldDataWidget(
          label: 'Email',
          description: 'fulan@fulan.com',
        ),
        AppSpacing.md,
        const FieldDataWidget(
          label: 'Phone Number',
          description: '+6282377654557',
        ),
        AppSpacing.lg,
      ],
    );
  }

  AppBar _appBar(BuildContext context) {
    return AppBar(
      title: Text(
        'My Profile',
        style: context.h5.copyWith(color: AppColor.whiteColor),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      centerTitle: true,
      backgroundColor: AppColor.primaryColor,
    );
  }
}
