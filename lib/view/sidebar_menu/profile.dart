import 'package:flutter/material.dart';
import 'package:suriota_mobile_gateway/constant/app_color.dart';
import 'package:suriota_mobile_gateway/constant/font_setup.dart';
import 'package:suriota_mobile_gateway/constant/image_asset.dart';

import '../../global/widgets/custom_textfield.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: Text(
          'My Profile',
          style: FontFamily.tittleSmall.copyWith(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: CircleAvatar(
                radius: 75,
                backgroundImage: AssetImage(ImageAsset.profile2),
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            Center(
              child: Text(
                'Rudi Soru',
                style: FontFamily.titleMedium,
              ),
            ),
            const SizedBox(
              height: 24,
            ),
            const CustomTextFormField(
              readOnly: true,
              labelTxt: 'Full Name',
              hintTxt: 'Rudi Soru',
              prefixIcon: Icon(
                Icons.email,
                color: AppColor.primaryColor,
              ),
            ),
            const SizedBox(
              height: 13,
            ),
            const CustomTextFormField(
              readOnly: true,
              labelTxt: 'Email',
              hintTxt: 'rudisoru@dah.com',
              prefixIcon: Icon(
                Icons.email,
                color: AppColor.primaryColor,
              ),
            ),
            const SizedBox(
              height: 13,
            ),
            const CustomTextFormField(
              readOnly: true,
              labelTxt: 'Phone Number',
              hintTxt: '+6282377654557',
              prefixIcon: Icon(
                Icons.email,
                color: AppColor.primaryColor,
              ),
            ),
            const SizedBox(
              height: 13,
            ),
          ],
        ),
      ),
    );
  }
}
