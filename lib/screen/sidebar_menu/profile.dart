import 'package:flutter/material.dart';
import 'package:suriota_mobile_gateway/constant/app_color.dart';
import 'package:suriota_mobile_gateway/constant/app_gap.dart';
import 'package:suriota_mobile_gateway/constant/image_asset.dart';
import 'package:suriota_mobile_gateway/global/utils/text_extension.dart';
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
        AppSpacing.md,
        const Center(
          child: CircleAvatar(
            radius: 75,
            backgroundImage: AssetImage(ImageAsset.profile2),
          ),
        ),
        AppSpacing.md,
        Center(
          child: Text(
            'Rudi Soru',
            style: context.h3,
          ),
        ),
        AppSpacing.lg,
        const FieldDataWidget(
          label: 'Full Name',
          description: 'Rudi Soru',
        ),
        AppSpacing.md,
        const FieldDataWidget(
          label: 'Email',
          description: 'rudisoru@dah.com',
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
